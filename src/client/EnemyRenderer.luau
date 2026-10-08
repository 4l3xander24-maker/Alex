-- Dibuja los zombis localmente. La posición sale de EnemyMath con el tiempo
-- del servidor, y se mueven todos de una vez con BulkMoveTo.
--
-- Estilo "3D": muñecos de bloques de dibujo animado (ZombieModels) con
-- animación de caminar, golpear y, en el dragón, aletear y escupir fuego.
-- Estilo "Pixel": sprite que siempre mira a la cámara (si tiene Sprite).
-- Al morir revientan en cubitos (DeathFx).
--
-- Optimización: los zombis detrás de la cámara no se mueven en pantalla, los
-- lejanos no se animan y los muy lejanos se actualizan cada 3 cuadros.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Remotes = require(Shared.Remotes)
local ResolvedAssets = require(Shared.ResolvedAssets)
local DamageNumbers = require(script.Parent.DamageNumbers)
local DeathFx = require(script.Parent.DeathFx)
local ZombieAnimator = require(script.Parent.ZombieAnimator)
local ZombieModels = require(script.Parent.ZombieModels)
local Sfx = require(script.Parent.Sfx)
local XpDrops = require(script.Parent.XpDrops)

local FLASH_COLOR = Color3.new(1, 1, 1)
local FLASH_TINT = Color3.new(1, 0.35, 0.35)
local FLASH_TIME = 0.08
local SWAY_SPEED = 4
local TURN_RATE = 5 -- qué tan rápido giran hacia donde caminan
-- Pose quieta para los zombis lejanos (no se anima)
local REST_POSE = ZombieAnimator.newPose()
local DIRT = { Color3.fromRGB(92, 70, 48), Color3.fromRGB(70, 54, 38), Color3.fromRGB(60, 90, 50) }
local SPRITE_SWAY = 0.06
local BOB_HEIGHT = 0.12
local BREATH_DISTANCE = 320
local BLOOD = Color3.fromRGB(120, 22, 26)
local graphics = Config.Graphics
-- Pixel art 3D: colores planos, y el fuego del dragón son cubitos
local voxel = Config.Style.Blocky
local FIRE_CUBES_PER_SECOND = 40
local FIRE_COLORS = { Color3.fromRGB(150, 255, 120), Color3.fromRGB(200, 255, 110), Color3.fromRGB(255, 200, 70), Color3.fromRGB(255, 140, 40) }

type PartSpec = ZombieModels.PartSpec

type Piece = {
	Part: BasePart,
	Spec: PartSpec?,
	Color: Color3,
	Glows: boolean,
	-- Pose fija ya escalada (para piezas sin animación)
	Static: CFrame?,
	Pivot: Vector3,
	Hang: Vector3,
	Role: string?,
	OnTorso: boolean, -- se mueve con el torso (cabeza, brazos, ropa) o con la raíz (piernas)
}

type Visual = {
	Type: string,
	Pieces: { Piece },
	Decal: Decal?,
	Breath: ParticleEmitter?,
	BreathLight: PointLight?,
	BreathPart: BasePart?, -- de dónde sale el fuego (estilo voxel)
	SpriteFrames: { string }?, -- dos cuadros de caminar (estilo Pixel)
	SpriteFrame: number,
	FireBudget: number,
	Path: EnemyMath.Path,
	Speed: number,
	Scale: number,
	Extent: number, -- medio tamaño, para no ocultar a los jefes grandes antes de tiempo
	Flying: boolean,
	Facing: Vector3, -- hacia dónde mira (gira suave hacia donde camina)
	Gait: ZombieAnimator.Gait,
	Pose: ZombieAnimator.Pose,
	Hip: Vector3,
	HitAt: number,
	SpawnAt: number,
	FlashUntil: number,
	Phase: number,
	Slot: number, -- para repartir las actualizaciones de los lejanos entre cuadros
}

local EnemyRenderer = {}

local folder = Instance.new("Folder")
folder.Name = "ClientEnemies"
folder.Parent = workspace
EnemyRenderer.folder = folder

local visuals: { [number]: Visual } = {}
-- Ids que ya murieron, para ignorarlos si llegan tarde en el snapshot
local deadIds: { [number]: boolean } = {}

local parts: { BasePart } = {}
local cframes: { CFrame } = {}
local frame = 0
local random = Random.new()

local function newPart(name: string, size: Vector3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	return part
end

local function createSprite(typeName: string, info, frames: { string }): ({ Piece }, Decal)
	local size = info.SpriteSize or info.Size
	local part = newPart(typeName, Vector3.new(size.X, size.Y, 0.05), Enum.Material.SmoothPlastic)
	part.Transparency = 1
	local decal = Instance.new("Decal")
	decal.Texture = frames[1]
	decal.Face = Enum.NormalId.Front
	decal.Parent = part
	part.Parent = folder
	return { { Part = part, Spec = nil, Color = info.Skin, Glows = false, Pivot = Vector3.zero, Hang = Vector3.zero, OnTorso = false } }, decal
end

-- Fuego del dragón: llamas verdes y naranjas que salen de la boca
local function addBreath(part: BasePart, scale: number): (ParticleEmitter?, PointLight)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(150, 255, 110)
	light.Range = math.min(12 * scale, 60)
	light.Brightness = 3
	light.Enabled = false
	light.Parent = part
	if voxel then
		return nil, light
	end
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.EmissionDirection = Enum.NormalId.Front
	fire.Rate = 70
	fire.Lifetime = NumberRange.new(0.5, 0.8)
	fire.Speed = NumberRange.new(9 * scale, 13 * scale)
	fire.SpreadAngle = Vector2.new(10, 10)
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 * scale), NumberSequenceKeypoint.new(1, 2.2 * scale) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	fire.Color = ColorSequence.new(Color3.fromRGB(150, 255, 120), Color3.fromRGB(255, 140, 40))
	fire.LightEmission = 1
	fire.Enabled = false
	fire.Parent = part
	return fire, light
end

local function createBody(typeName: string, info, scale: number): ({ Piece }, ParticleEmitter?, PointLight?, BasePart?)
	local pieces = {}
	local breath, breathLight, breathPart = nil, nil, nil
	for _, spec in ZombieModels.get(typeName, info) do
		local color, glows = ZombieModels.resolveColor(info, spec.Color)
		local material = if glows then Enum.Material.Neon else spec.Material
		if Config.Style.Flat and material ~= Enum.Material.Neon then
			material = Enum.Material.SmoothPlastic
		end
		local part: BasePart
		if spec.Mesh then
			-- Malla de la tienda: conserva su textura y color
			part = spec.Mesh:Clone()
			part.Size = spec.Size * scale
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.CastShadow = false
			color = part.Color
		else
			part = newPart(spec.Name, spec.Size * scale, material)
			part.Color = color
		end
		if spec.Transparent then
			part.Transparency = 1
			breath, breathLight = addBreath(part, scale)
			breathPart = part
		end
		part.Parent = folder
		local pivot, hang = spec.Pivot * scale, spec.Hang * scale
		local dragon = info.Model == "Dragon"
		-- La cabeza (con su cara y sombrero) se mueve entera: mira a los lados
		local role = spec.Role or (if not dragon and spec.Group == "Head" then "Head" else nil)
		local piece: Piece = {
			Part = part,
			Spec = spec,
			Color = color,
			Glows = material == Enum.Material.Neon,
			Pivot = pivot,
			Hang = hang,
			Role = role,
			OnTorso = not dragon and spec.Group ~= "Leg",
		}
		if not role then
			piece.Static = CFrame.new(pivot) * CFrame.Angles(-spec.Tilt, 0, 0) * CFrame.new(hang) * (spec.Turn or CFrame.identity)
		end
		table.insert(pieces, piece)
	end
	return pieces, breath, breathLight, breathPart
end

local function setFlash(visual: Visual, flashing: boolean)
	if visual.Decal then
		visual.Decal.Color3 = if flashing then FLASH_TINT else FLASH_COLOR
		return
	end
	for _, piece in visual.Pieces do
		if not piece.Glows then
			piece.Part.Color = if flashing then FLASH_COLOR else piece.Color
		end
	end
end

local function addEnemy(id: number, typeName: string, points: { Vector3 }, speed: number, spawnTime: number)
	if visuals[id] or deadIds[id] then
		return
	end
	local info = Config.Enemies[typeName]
	if not info then
		return
	end

	local scale = info.Size.Y / 5
	local pieces, decal, breath, breathLight, breathPart
	-- Sprite pixelado si se subió (tools/upload_assets.py) o si se pegó uno en Config
	local frames = if Config.ZombieStyle == "Pixel" then ResolvedAssets.getSprite(typeName) else nil
	if not frames and Config.ZombieStyle == "Pixel" and info.Sprite ~= "" then
		frames = { info.Sprite, info.Sprite }
	end
	if frames then
		pieces, decal = createSprite(typeName, info, frames)
		if info.Flying then
			-- El dragón de sprite también ilumina con su fuego
			breathLight = Instance.new("PointLight")
			breathLight.Color = Color3.fromRGB(150, 255, 110)
			breathLight.Range = 40
			breathLight.Brightness = 3
			breathLight.Enabled = false
			breathLight.Parent = pieces[1].Part
		end
	else
		pieces, breath, breathLight, breathPart = createBody(typeName, info, scale)
	end
	visuals[id] = {
		Type = typeName,
		Pieces = pieces,
		Decal = decal,
		Breath = breath,
		BreathLight = breathLight,
		BreathPart = breathPart,
		SpriteFrames = frames,
		SpriteFrame = 1,
		FireBudget = 0,
		Path = EnemyMath.newRoute(points, speed, spawnTime),
		Speed = speed,
		Scale = scale,
		Extent = math.max(info.Size.X, info.Size.Y) / 2,
		Flying = info.Flying == true,
		Facing = Vector3.new(0, 0, 1),
		Gait = ZombieAnimator.newGait(id, info),
		Pose = ZombieAnimator.newPose(),
		Hip = ZombieModels.getHip(info) * scale,
		HitAt = -math.huge,
		SpawnAt = -math.huge,
		FlashUntil = 0,
		Phase = id * 0.37,
		Slot = id % 3,
	}

	-- Recién nacido (no el que ya estaba al entrar al juego): sale de la tierra
	local visual = visuals[id]
	local now = workspace:GetServerTimeNow()
	local age = now - spawnTime
	Sfx.onEnemySpawned(typeName)
	if not visual.Flying and age < ZombieAnimator.EMERGE_TIME then
		visual.SpawnAt = os.clock() - math.max(age, 0)
		visual.Facing = Vector3.new(visual.Path.Points[#visual.Path.Points].X - points[1].X, 0, visual.Path.Points[#visual.Path.Points].Z - points[1].Z)
		visual.Facing = if visual.Facing.Magnitude > 0.01 then visual.Facing.Unit else Vector3.new(0, 0, 1)
		local position = EnemyMath.getPosition(visual.Path, now)
		if (position - workspace.CurrentCamera.CFrame.Position).Magnitude < graphics.DeathFxDistance then
			-- Tierra que salta al salir
			for _ = 1, math.min(6, DeathFx.budget()) do
				local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.6, 1.4), random:NextNumber(-1, 1)).Unit
				DeathFx.addCube(Vector3.new(position.X, 0.3, position.Z), DIRT[random:NextInteger(1, #DIRT)], 0.4 * scale ^ 0.8, direction * 8 * scale ^ 0.5, 50, random:NextNumber(0.5, 0.8))
			end
		end
	end
end

local function destroyPieces(visual: Visual)
	for _, piece in visual.Pieces do
		piece.Part:Destroy()
	end
end

-- Reparte los cubitos entre las piezas según su tamaño (cabeza, torso, piernas)
local function cubeShares(visual: Visual, total: number): { [Piece]: number }
	local volumes = {}
	local sum = 0
	for _, piece in visual.Pieces do
		local size = piece.Part.Size
		local volume = size.X * size.Y * size.Z
		volumes[piece] = volume
		sum += volume
	end
	local shares = {}
	for piece, volume in volumes do
		shares[piece] = math.floor(total * volume / sum + 0.35)
	end
	return shares
end

-- Muerte al estilo pixelado: destello blanco, la cabeza sale volando, el
-- cuerpo se desarma hacia atrás y cada pedazo revienta en cubitos.
local function explode(visual: Visual, position: Vector3, cameraPosition: Vector3)
	local info = Config.Enemies[visual.Type]
	local scale = visual.Scale
	local boost = scale ^ 0.6
	local gravity = 60 * boost
	local away = Vector3.new(position.X - cameraPosition.X, 0, position.Z - cameraPosition.Z)
	away = if away.Magnitude > 0.01 then away.Unit else -visual.Facing
	local cubeSize = 0.42 * scale ^ 0.8
	local wanted = if info.IsBoss then 70 else 14
	local shares = cubeShares(visual, math.min(wanted, DeathFx.budget()))
	local goo = info.Skin:Lerp(Color3.new(0, 0, 0), 0.35)

	for _, piece in visual.Pieces do
		local spec = piece.Spec
		if spec and spec.Transparent then
			piece.Part:Destroy()
			continue
		end
		local group = if spec then spec.Group else "Torso"
		local velocity, spin, life
		if visual.Decal then
			-- El sprite cae de espaldas y revienta
			velocity = away * 3 + Vector3.new(0, 5, 0)
			spin = Vector3.new(-6, 0, 0)
			life = 0.4
		elseif visual.Flying then
			-- El dragón se desploma desde el cielo y revienta al tocar el suelo
			velocity = away * random:NextNumber(2, 6) * boost + Vector3.new(0, random:NextNumber(-2, 4) * boost, 0)
			spin = Vector3.new(random:NextNumber(-2, 2), random:NextNumber(-2, 2), random:NextNumber(-2, 2))
			life = 2.5
		elseif group == "Head" then
			velocity = away * 6 * boost + Vector3.new(random:NextNumber(-2, 2), 15, random:NextNumber(-2, 2)) * boost
			spin = Vector3.new(random:NextNumber(6, 10), random:NextNumber(-4, 4), random:NextNumber(-3, 3))
			life = 0.8
		elseif group == "Leg" then
			velocity = away * random:NextNumber(1, 3) * boost + Vector3.new(0, random:NextNumber(1, 3) * boost, 0)
			spin = Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-3, 3))
			life = random:NextNumber(0.45, 0.6)
		else
			velocity = away * random:NextNumber(3, 6) * boost + Vector3.new(random:NextNumber(-2, 2), random:NextNumber(4, 8), random:NextNumber(-2, 2)) * boost
			spin = Vector3.new(random:NextNumber(-5, 5), random:NextNumber(-5, 5), random:NextNumber(-5, 5))
			life = random:NextNumber(0.5, 0.7)
		end
		DeathFx.addPiece(piece.Part, piece.Part.CFrame, {
			Velocity = velocity,
			Spin = spin,
			Gravity = gravity,
			Life = life,
			BurstColors = { piece.Color, piece.Color, goo, BLOOD },
			BurstCount = if visual.Decal then math.min(10, DeathFx.budget()) else shares[piece] or 0,
			BurstSize = cubeSize,
			BurstSpeed = 11 * boost,
			BurstOnGround = visual.Flying,
			Flash = visual.Decal == nil,
		})
	end
	if visual.Decal then
		visual.Decal.Color3 = FLASH_TINT
	end
	DeathFx.splat(position, math.max(1.6, info.Size.X * 0.45), goo, if info.IsBoss then 8 else 4)
end

local function removeEnemy(id: number, animate: boolean)
	deadIds[id] = true
	local visual = visuals[id]
	if not visual then
		return
	end
	visuals[id] = nil

	if not animate then
		Sfx.onEnemyRemoved(visual.Type, nil, false)
		destroyPieces(visual)
		return
	end
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	Sfx.onEnemyRemoved(visual.Type, position, true)
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	-- Muy lejos no vale la pena el efecto: desaparece
	if (position - cameraPosition).Magnitude > graphics.DeathFxDistance + visual.Extent then
		destroyPieces(visual)
		return
	end
	explode(visual, position, cameraPosition)
end

-- Número de daño sobre la cabeza del enemigo
local function showDamage(id: number, amount: number, killed: boolean)
	local visual = visuals[id]
	if not visual or type(amount) ~= "number" then
		return
	end
	local info = Config.Enemies[visual.Type]
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	local top = (info.SpriteSize or info.Size).Y / 2 + 0.8
	DamageNumbers.show(position + Vector3.new(0, top, 0), amount, killed)
end

-- Salpicadura de sangre en cubitos (la malla con textura no se pone blanca)
local function splatter(visual: Visual)
	local info = Config.Enemies[visual.Type]
	if not info or DeathFx.budget() < 4 then
		return
	end
	local position = EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow())
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	if (position - cameraPosition).Magnitude > graphics.DeathFxDistance then
		return
	end
	local scale = info.Size.Y / 5
	local chest = position + Vector3.new(0, info.Size.Y * 0.15, 0)
	-- Salen hacia el lado de la cámara, que es de donde vino el tiro
	local toward = Vector3.new(cameraPosition.X - chest.X, 0, cameraPosition.Z - chest.Z).Unit
	for _ = 1, 4 do
		local direction = (toward + Vector3.new(random:NextNumber(-0.8, 0.8), random:NextNumber(0.3, 1.2), random:NextNumber(-0.8, 0.8))).Unit
		DeathFx.addCube(chest, BLOOD, 0.22 * scale ^ 0.7, direction * random:NextNumber(6, 11), 45, random:NextNumber(0.3, 0.55))
	end
end

local function flashEnemy(id: number)
	local visual = visuals[id]
	if visual then
		setFlash(visual, true)
		visual.FlashUntil = os.clock() + FLASH_TIME
		visual.HitAt = os.clock()
		if visual.Pieces[1] and visual.Pieces[1].Spec and visual.Pieces[1].Spec.Mesh then
			splatter(visual)
		end
	end
end

local function render(dt: number)
	frame += 1
	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	local camera = workspace.CurrentCamera.CFrame
	local cameraPosition = camera.Position
	local look = camera.LookVector
	table.clear(parts)
	table.clear(cframes)

	for _, visual in visuals do
		local traveled = EnemyMath.getTraveled(visual.Path, now)
		local position, direction = EnemyMath.locate(visual.Path, traveled)
		local toEnemy = position - cameraPosition
		local distance = toEnemy.Magnitude

		-- Detrás de la cámara no hace falta moverlo: se ubica en cuanto vuelva a verse
		local behind = distance > graphics.CullBehindDistance + visual.Extent and toEnemy:Dot(look) < -visual.Extent
		local skipFar = distance > graphics.FarDistance + visual.Extent and frame % 3 ~= visual.Slot
		if behind or skipFar then
			continue
		end

		-- Gira suave hacia donde camina (no de golpe en cada curva del camino)
		local flatDirection = Vector3.new(direction.X, 0, direction.Z)
		if flatDirection.Magnitude > 0.01 then
			local turned = visual.Facing:Lerp(flatDirection.Unit, math.min(1, dt * TURN_RATE))
			if turned.Magnitude > 0.01 then
				visual.Facing = turned.Unit
			end
		end
		local arrived = traveled >= visual.Path.Distance
		local wave = math.sin(clock * SWAY_SPEED + visual.Phase)

		if visual.Decal then
			-- Sprite: mira siempre a la cámara (solo en horizontal), alterna sus dos
			-- cuadros al caminar, sale de la tierra y se echa atrás al recibir un golpe
			local pose = visual.Pose
			local hitAge = clock - visual.HitAt
			local spawnAge = clock - visual.SpawnAt
			if visual.Flying then
				ZombieAnimator.flyer(pose, clock, visual.Phase, arrived, visual.Scale, hitAge)
			else
				ZombieAnimator.walker(pose, visual.Gait, clock, visual.Speed, visual.Scale, visual.Phase, arrived, hitAge, spawnAge)
			end
			local frames = visual.SpriteFrames
			if frames and distance < graphics.AnimateDistance + visual.Extent then
				local beat = if arrived then clock * 6 else clock * visual.Speed * 0.9 / math.sqrt(visual.Scale) * visual.Gait.Cadence
				local index = if math.sin(beat + visual.Phase) > 0 then 1 else 2
				if index ~= visual.SpriteFrame then
					visual.SpriteFrame = index;
					(visual.Decal :: Decal).Texture = frames[index]
				end
			end
			local bobbed = position + Vector3.new(0, math.max(pose.Lift, -visual.Extent * 2) + math.abs(wave) * BOB_HEIGHT, 0) - visual.Facing * pose.Back
			local facing = Vector3.new(cameraPosition.X, bobbed.Y, cameraPosition.Z)
			if (facing - bobbed).Magnitude < 0.01 then
				facing = bobbed - visual.Facing
			end
			local lean = if hitAge < 0.28 then (1 - hitAge / 0.28) * 0.35 else 0
			local root = CFrame.lookAt(bobbed, facing) * CFrame.Angles(lean, 0, wave * SPRITE_SWAY)
			table.insert(parts, visual.Pieces[1].Part)
			table.insert(cframes, root)

			-- Dragón de sprite: escupe cubitos de fuego hacia la campana
			local light = visual.BreathLight
			if light then
				local breathing = arrived and distance < BREATH_DISTANCE
				if light.Enabled ~= breathing then
					light.Enabled = breathing
				end
				if breathing then
					local mouth = CFrame.lookAt(position + Vector3.new(0, visual.Extent * 0.3, 0), Vector3.new(0, 4, 0))
					visual.FireBudget += dt * FIRE_CUBES_PER_SECOND
					while visual.FireBudget >= 1 do
						visual.FireBudget -= 1
						local spread = Vector3.new(random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15))
						local velocity = (mouth.LookVector + spread).Unit * 11 * visual.Scale * random:NextNumber(0.8, 1.2)
						DeathFx.addCube(mouth.Position, FIRE_COLORS[random:NextInteger(1, #FIRE_COLORS)], 0.5 * visual.Scale ^ 0.8 * random:NextNumber(0.7, 1.3), velocity, 0, random:NextNumber(0.45, 0.7), true)
					end
				end
			end
		else
			local animate = distance < graphics.AnimateDistance + visual.Extent
			local scale = visual.Scale
			local pose = visual.Pose
			local hitAge = clock - visual.HitAt
			local spawnAge = clock - visual.SpawnAt
			if not animate and spawnAge >= ZombieAnimator.EMERGE_TIME then
				-- Lejos: pose quieta (no vale la pena calcular la animación)
				pose = REST_POSE
			elseif visual.Flying then
				ZombieAnimator.flyer(pose, clock, visual.Phase, arrived, scale, hitAge)
			else
				ZombieAnimator.walker(pose, visual.Gait, clock, visual.Speed, scale, visual.Phase, arrived, hitAge, spawnAge)
			end

			local lifted = position + Vector3.new(0, pose.Lift, 0) - visual.Facing * pose.Back
			local root = CFrame.lookAt(lifted, lifted + visual.Facing)
			-- El torso gira sobre la cadera y lleva consigo la cabeza y los brazos
			local hip = visual.Hip
			local torso = root * CFrame.new(hip) * CFrame.Angles(-pose.TorsoPitch, pose.TorsoYaw, pose.TorsoRoll) * CFrame.new(-hip)
			local mouth: CFrame? = nil
			for _, piece in visual.Pieces do
				table.insert(parts, piece.Part)
				local frameOf = if piece.OnTorso then torso else root
				local static = piece.Static
				local cframe
				if static then
					cframe = frameOf * static
				else
					local spec = piece.Spec :: PartSpec
					cframe = frameOf * CFrame.new(piece.Pivot) * ZombieAnimator.rotation(piece.Role, spec.Tilt, pose) * CFrame.new(piece.Hang) * (spec.Turn or CFrame.identity)
				end
				table.insert(cframes, cframe)
				if piece.Part == visual.BreathPart then
					mouth = cframe
				end
			end

			local breathLight = visual.BreathLight
			if breathLight then
				local breathing = arrived and distance < BREATH_DISTANCE
				if breathLight.Enabled ~= breathing then
					breathLight.Enabled = breathing
					if visual.Breath then
						visual.Breath.Enabled = breathing
					end
				end
				if breathing and voxel and mouth then
					-- Fuego de cubitos que salen de la boca hacia la campana
					visual.FireBudget += dt * FIRE_CUBES_PER_SECOND
					while visual.FireBudget >= 1 do
						visual.FireBudget -= 1
						local spread = Vector3.new(random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15), random:NextNumber(-0.15, 0.15))
						local velocity = (mouth.LookVector + spread).Unit * 11 * scale * random:NextNumber(0.8, 1.2)
						DeathFx.addCube(mouth.Position, FIRE_COLORS[random:NextInteger(1, #FIRE_COLORS)], 0.5 * scale ^ 0.8 * random:NextNumber(0.7, 1.3), velocity, 0, random:NextNumber(0.45, 0.7), true)
					end
				end
			end
		end

		if visual.FlashUntil > 0 and clock >= visual.FlashUntil then
			visual.FlashUntil = 0
			setFlash(visual, false)
		end
	end

	DeathFx.step(dt, parts, cframes)

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function EnemyRenderer.init()
	DeathFx.init(folder)
	DamageNumbers.init()

	-- El servidor junta los eventos de cada cuadro en un solo mensaje
	Remotes.EnemySpawned.OnClientEvent:Connect(function(spawns)
		for _, entry in spawns do
			addEnemy(table.unpack(entry))
		end
	end)
	-- Golpes y muertes llegan como { id, daño }: el número salta sobre la cabeza
	Remotes.EnemyHit.OnClientEvent:Connect(function(hits)
		for _, hit in hits do
			showDamage(hit[1], hit[2], false)
			flashEnemy(hit[1])
		end
	end)
	Remotes.EnemyDied.OnClientEvent:Connect(function(deaths)
		for _, death in deaths do
			local visual = visuals[death[1]]
			if visual then
				-- Rombo de experiencia que vuela hacia quien lo mató
				XpDrops.spawn(EnemyMath.getPosition(visual.Path, workspace:GetServerTimeNow()), death[3] or 0, visual.Type)
			end
			showDamage(death[1], death[2], true)
			removeEnemy(death[1], true)
		end
	end)
	-- Cambios de recorrido: persiguen a un jugador, vuelven al camino o los empujan
	Remotes.EnemyPathsUpdated.OnClientEvent:Connect(function(updates)
		for _, update in updates do
			local visual = visuals[update[1]]
			if visual then
				visual.Path = EnemyMath.newRoute(update[2], visual.Speed, update[3])
			end
		end
	end)
	Remotes.EnemiesCleared.OnClientEvent:Connect(function()
		for id in visuals do
			removeEnemy(id, false)
		end
		table.clear(deadIds)
		DeathFx.clear()
		Sfx.onEnemiesCleared()
	end)

	task.spawn(function()
		local ok, snapshot = pcall(function()
			return Remotes.GetSnapshot:InvokeServer()
		end)
		if ok and type(snapshot) == "table" then
			for _, entry in snapshot do
				addEnemy(table.unpack(entry))
			end
		end
	end)

	RunService.RenderStepped:Connect(render)
end

return EnemyRenderer
