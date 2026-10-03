-- Animación de los zombis (solo en el cliente). Cada zombi tiene su propia
-- manera de caminar (Gait): largo del paso, ritmo, cojera, cabeza ladeada...
-- así la horda no se mueve como soldados en fila.
--
-- La pose se arma por capas:
--   * caminar: piernas, balanceo y giro del torso, brazos que suben y bajan,
--     cabeza que se bambolea y mira a los lados
--   * atacar: embestidas con el torso y zarpazos con los brazos
--   * golpe recibido: el torso y la cabeza se echan hacia atrás un instante
--   * aparecer: sale de la tierra arañando con los brazos para arriba
local ZombieAnimator = {}

local BOB_HEIGHT = 0.12
local FLINCH_TIME = 0.28
ZombieAnimator.EMERGE_TIME = 1.1

export type Gait = {
	Stride: number,
	Cadence: number,
	Limp: number, -- 0 = camina normal; más = arrastra una pierna
	LimpSide: number, -- -1 izquierda, 1 derecha
	HeadTilt: number,
	ArmSpread: number,
	Waddle: number, -- balanceo de lado a lado (los gordos más)
	Lean: number, -- encorvado hacia adelante
	Flail: number, -- cuánto mueven los brazos al correr
}

export type Pose = {
	LegL: number,
	LegR: number,
	ArmL: number,
	ArmR: number,
	Spread: number,
	TorsoPitch: number, -- positivo = se inclina hacia adelante
	TorsoYaw: number,
	TorsoRoll: number,
	HeadPitch: number,
	HeadYaw: number,
	HeadRoll: number,
	Lift: number, -- desplazamiento vertical del cuerpo (studs)
	Back: number, -- empujón hacia atrás (studs)
	Cape: number,
	Flap: number,
	Tail: number,
	Neck: number,
	Jaw: number,
}

function ZombieAnimator.newPose(): Pose
	return {
		LegL = 0,
		LegR = 0,
		ArmL = 0,
		ArmR = 0,
		Spread = 0,
		TorsoPitch = 0,
		TorsoYaw = 0,
		TorsoRoll = 0,
		HeadPitch = 0,
		HeadYaw = 0,
		HeadRoll = 0,
		Lift = 0,
		Back = 0,
		Cape = 0,
		Flap = 0,
		Tail = 0,
		Neck = 0,
		Jaw = 0,
	}
end

-- Manera de caminar de un zombi (siempre la misma para el mismo id)
function ZombieAnimator.newGait(id: number, info): Gait
	local random = Random.new(id * 7919)
	local runner = info.Speed >= 10
	local fat = info.Model == "Fat"
	local limps = not runner and random:NextNumber() < 0.35
	return {
		Stride = if runner then random:NextNumber(0.75, 0.9) else random:NextNumber(0.4, 0.65),
		Cadence = random:NextNumber(0.85, 1.15),
		Limp = if limps then random:NextNumber(0.3, 0.6) else 0,
		LimpSide = if random:NextNumber() < 0.5 then -1 else 1,
		HeadTilt = random:NextNumber(-0.22, 0.22),
		ArmSpread = random:NextNumber(0, 0.25),
		Waddle = if fat then 0.12 else random:NextNumber(0.04, 0.08),
		Lean = (info.Hunch or 0) * 0.3 + (if runner then 0.12 else 0),
		Flail = if runner then 0.45 else random:NextNumber(0.08, 0.16),
	}
end

local function easeOut(t: number): number
	return 1 - (1 - t) * (1 - t)
end

-- Pose de un zombi que camina o ataca.
-- hitAge: segundos desde el último golpe. spawnAge: segundos desde que apareció.
function ZombieAnimator.walker(pose: Pose, gait: Gait, clock: number, speed: number, scale: number, phase: number, attacking: boolean, hitAge: number, spawnAge: number)
	-- Los grandes se mueven más lento para que se sientan pesados
	local tempo = 1 / math.sqrt(scale)
	local t = clock * speed * 0.9 * tempo * gait.Cadence + phase
	local idle = clock * tempo + phase

	if attacking then
		-- Embestidas: el torso se tira hacia adelante y los brazos dan zarpazos
		local lunge = math.abs(math.sin(clock * 6 * tempo + phase))
		pose.LegL = math.sin(clock * 3 * tempo + phase) * 0.12
		pose.LegR = -pose.LegL
		pose.ArmL = -0.5 - lunge * 0.9
		pose.ArmR = -0.5 - math.abs(math.sin(clock * 6 * tempo + phase + 0.9)) * 0.75
		pose.TorsoPitch = 0.18 + lunge * 0.22
		pose.TorsoYaw = math.sin(clock * 3 * tempo + phase) * 0.15
		pose.TorsoRoll = math.sin(clock * 2 * tempo + phase) * gait.Waddle
		pose.HeadPitch = 0.12 + lunge * 0.1
		pose.HeadYaw = math.sin(clock * 1.7 + phase) * 0.12
		pose.Lift = 0
	else
		local walk = math.sin(t)
		local step = math.abs(walk)
		pose.LegL = walk * gait.Stride
		pose.LegR = -walk * gait.Stride
		-- Cojera: una pierna apenas se mueve y el cuerpo se hunde al pisar con ella
		local dip = 0
		if gait.Limp > 0 then
			if gait.LimpSide > 0 then
				pose.LegR *= 1 - gait.Limp
			else
				pose.LegL *= 1 - gait.Limp
			end
			dip = math.max(0, walk * gait.LimpSide) * gait.Limp * 0.35
		end
		-- Brazos estirados que suben y bajan despacio, cada uno a su ritmo
		pose.ArmL = -0.08 + math.sin(idle * 1.3) * 0.12 + walk * gait.Flail
		pose.ArmR = -0.08 + math.sin(idle * 1.1 + 1.7) * 0.12 - walk * gait.Flail
		pose.TorsoPitch = gait.Lean + step * 0.06
		pose.TorsoYaw = walk * 0.14
		pose.TorsoRoll = math.cos(t) * gait.Waddle + gait.Limp * gait.LimpSide * 0.1
		pose.HeadPitch = math.sin(t * 2) * 0.05
		-- Mira a los lados, como buscando algo
		pose.HeadYaw = math.sin(idle * 0.6) * 0.3 + math.sin(idle * 1.7) * 0.08
		pose.Lift = (step * BOB_HEIGHT - dip * 0.5) * scale
	end
	pose.Spread = gait.ArmSpread
	pose.HeadRoll = gait.HeadTilt + math.sin(idle * 0.9) * 0.07
	pose.Cape = -math.abs(math.sin(t)) * 0.15 - math.sin(clock * 1.6 + phase) * 0.05

	-- Golpe recibido: se echa hacia atrás y vuelve
	if hitAge < FLINCH_TIME then
		local flinch = 1 - hitAge / FLINCH_TIME
		flinch *= flinch
		pose.TorsoPitch -= 0.45 * flinch
		pose.HeadPitch -= 0.4 * flinch
		pose.ArmL += 0.3 * flinch
		pose.ArmR += 0.3 * flinch
		pose.Back = 0.5 * flinch * scale
	else
		pose.Back = 0
	end

	-- Recién aparecido: sube desde abajo de la tierra arañando
	if spawnAge < ZombieAnimator.EMERGE_TIME then
		local rise = 1 - easeOut(spawnAge / ZombieAnimator.EMERGE_TIME)
		pose.Lift -= rise * 5 * scale * 0.95
		pose.ArmL += rise * (1.3 + math.sin(clock * 14) * 0.3)
		pose.ArmR += rise * (1.3 + math.sin(clock * 14 + 2) * 0.3)
		pose.TorsoPitch += rise * 0.35
	end
end

-- Pose del dragón: aletea, mece la cola y abre la mandíbula para escupir fuego
function ZombieAnimator.flyer(pose: Pose, clock: number, phase: number, attacking: boolean, scale: number, hitAge: number)
	local sway = math.sin(clock * 1.6 + phase)
	pose.Flap = math.sin(clock * 2.4 + phase) * 0.6
	pose.Tail = sway * 0.3 + math.sin(clock * 0.9 + phase) * 0.1
	pose.Neck = if attacking then -0.25 + sway * 0.05 else sway * 0.08
	local bite = math.abs(math.sin(clock * 8 + phase))
	pose.Jaw = if attacking then -0.45 - bite * 0.12 else -0.08
	pose.Lift = math.sin(clock * 2.4 + phase - 0.6) * 0.25 * scale
	pose.Back = if hitAge < FLINCH_TIME then (1 - hitAge / FLINCH_TIME) * 0.4 * scale else 0
end

-- Giro de una pieza alrededor de su pivote según su papel y la pose
function ZombieAnimator.rotation(role: string?, tilt: number, pose: Pose): CFrame
	if role == "LegL" then
		return CFrame.Angles(pose.LegL - tilt, 0, 0)
	elseif role == "LegR" then
		return CFrame.Angles(pose.LegR - tilt, 0, 0)
	elseif role == "ArmL" then
		return CFrame.Angles(pose.ArmL - tilt, pose.Spread, 0)
	elseif role == "ArmR" then
		return CFrame.Angles(pose.ArmR - tilt, -pose.Spread, 0)
	elseif role == "Head" then
		return CFrame.Angles(-pose.HeadPitch - tilt, pose.HeadYaw, pose.HeadRoll)
	elseif role == "Cape" then
		return CFrame.Angles(pose.Cape - tilt, 0, 0)
	elseif role == "WingL" then
		return CFrame.Angles(-tilt, 0, 0) * CFrame.Angles(0, 0, -pose.Flap)
	elseif role == "WingR" then
		return CFrame.Angles(-tilt, 0, 0) * CFrame.Angles(0, 0, pose.Flap)
	elseif role == "Tail" then
		return CFrame.Angles(-tilt, pose.Tail, 0)
	elseif role == "Neck" then
		return CFrame.Angles(pose.Neck - tilt, 0, 0)
	elseif role == "Jaw" then
		return CFrame.Angles(pose.Jaw - tilt, 0, 0)
	end
	return CFrame.Angles(-tilt, 0, 0)
end

return ZombieAnimator
