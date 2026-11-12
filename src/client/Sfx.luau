-- Sonidos y música. Todo es local: cada cliente escucha sus disparos, los
-- zombis que tiene cerca y la música según el estado de la partida.
-- Los ids están en Shared.Sounds. Los efectos usan voces recicladas: cada
-- sonido tiene unas pocas copias (Config.Graphics.SoundVoices) que se vuelven a
-- tocar; si todas siguen sonando se corta la que empezó primero.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Sounds = require(Shared.Sounds)
local DeathFx = require(script.Parent.DeathFx)

-- Separación mínima entre dos sonidos iguales, para que una ráfaga o una
-- horda no se vuelva ruido
local MIN_GAP = {
	ZombieDeath = 0.08,
	ZombieGrowl = 0.9,
	HitMarker = 0.05,
	BellHit = 0.4,
	PlayerHurt = 0.25,
	XpPickup = 0.06,
	SmallExplosion = 0.1,
	DryFire = 0.3,
}
local DEFAULT_GAP = 0.03
-- Sonidos que solo existen aquí (reusan audios de Shared.Sounds con otro tono)
local EXTRA_SOUNDS = {
	DryFire = { Id = Sounds.UiClick.Id, Volume = 0.45, Pitch = 1.4 }, -- clic seco del arma vacía
}
-- Daño recibido: los zombis pegan de a poquito, así que se suma lo perdido
-- en una ventana corta y suena al pasar el umbral (con una pausa entre quejidos)
local HURT_WINDOW = 0.6
local HURT_THRESHOLD = 2
local HURT_COOLDOWN = 0.7
local MIN_DISTANCE = 10
local graphics = Config.Graphics

local Sfx = {}

local player = Players.LocalPlayer
local random = Random.new()
local lastPlayed: { [string]: number } = {}
local bossesAlive = 0
local musicTrack: string? = nil
local musicSound: Sound? = nil
local lowQuality = player:GetAttribute("LowQuality") == true

-- Copia de un sonido para reusar. Holder: el punto del mundo de donde sale (o nil)
type Voice = { Sound: Sound, Holder: Attachment?, Started: number }
local voices: { [string]: { Voice } } = {}

local function pickId(spec): number
	if spec.Ids then
		return spec.Ids[random:NextInteger(1, #spec.Ids)]
	end
	return spec.Id
end

-- Grupos de volumen que controla el menú de ajustes
local function getGroup(name: string): SoundGroup
	local group = SoundService:FindFirstChild(name)
	if not group then
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	return group :: SoundGroup
end

-- Audio y tono (los que tienen varios audios o un rango de tono varían cada vez)
local function pickSound(sound: Sound, spec)
	sound.SoundId = `rbxassetid://{pickId(spec)}`
	sound.PlaybackSpeed = if spec.PitchRange
		then random:NextNumber(spec.PitchRange[1], spec.PitchRange[2])
		else spec.Pitch or 1
end

local function newSound(spec, parent: Instance, music: boolean?): Sound
	local sound = Instance.new("Sound")
	sound.Volume = spec.Volume or 0.5
	pickSound(sound, spec)
	if spec.Distance then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = MIN_DISTANCE
		sound.RollOffMaxDistance = spec.Distance
	end
	sound.SoundGroup = getGroup(if music then "MusicGroup" else "SfxGroup")
	sound.Parent = parent
	return sound
end

-- false si sonó hace muy poco
local function canPlay(key: string): boolean
	local now = os.clock()
	if now - (lastPlayed[key] or 0) < (MIN_GAP[key] or DEFAULT_GAP) then
		return false
	end
	lastPlayed[key] = now
	return true
end

local function newVoice(spec, attached: boolean): Voice
	if not attached then
		return { Sound = newSound(spec, SoundService), Holder = nil, Started = 0 }
	end
	local holder = Instance.new("Attachment")
	holder.Parent = workspace.Terrain
	return { Sound = newSound(spec, holder), Holder = holder, Started = 0 }
end

-- Toca `spec` con una voz libre de `key` (o una nueva, o la más vieja si ya
-- hay tantas como el tope). position: de dónde sale en el mundo (o en la cabeza)
local function playVoice(key: string, spec, position: Vector3?)
	local list = voices[key]
	if not list then
		list = {}
		voices[key] = list
	end
	local chosen: Voice? = nil
	local oldest: Voice? = nil
	for index, voice in list do
		if not voice.Sound.Parent or (voice.Holder and not voice.Holder.Parent) then
			-- Se borró por fuera: se reemplaza
			voice = newVoice(spec, position ~= nil)
			list[index] = voice
		end
		if not voice.Sound.IsPlaying then
			chosen = voice
			break
		end
		if not oldest or voice.Started < oldest.Started then
			oldest = voice
		end
	end
	if not chosen then
		local limit = if lowQuality then graphics.LowSoundVoices else graphics.SoundVoices
		if #list < limit or not oldest then
			local fresh = newVoice(spec, position ~= nil)
			table.insert(list, fresh)
			chosen = fresh
		else
			chosen = oldest
		end
	end
	local voice = chosen :: Voice
	if position and voice.Holder then
		voice.Holder.WorldPosition = position
	end
	pickSound(voice.Sound, spec)
	voice.Sound.TimePosition = 0
	voice.Sound:Play()
	voice.Started = os.clock()
end

-- Sonido "en la cabeza" del jugador (armas, interfaz)
function Sfx.play(name: string)
	local spec = Sounds[name] or EXTRA_SOUNDS[name]
	if not spec or not canPlay(name) then
		return
	end
	playVoice(name, spec, nil)
end

-- Sonido en un punto del mundo: se oye más bajo cuanto más lejos
function Sfx.playAt(name: string, position: Vector3)
	local spec = Sounds[name]
	if not spec or not canPlay(name) then
		return
	end
	local distance = (position - workspace.CurrentCamera.CFrame.Position).Magnitude
	if spec.Distance and distance > spec.Distance then
		return
	end
	playVoice(`At.{name}`, spec, position)
end

function Sfx.weapon(weaponId: string)
	local spec = Sounds.Weapons[weaponId]
	if not spec or not canPlay(`Weapon.{weaponId}`) then
		return
	end
	playVoice(`Weapon.{weaponId}`, spec, nil)
end

-- Música en bucle con fundido entre canciones
local function setMusic(track: string)
	if track == musicTrack then
		return
	end
	musicTrack = track
	local fade = TweenInfo.new(Sounds.MusicFade)
	local old = musicSound
	if old then
		TweenService:Create(old, fade, { Volume = 0 }):Play()
		Debris:AddItem(old, Sounds.MusicFade)
	end
	local spec = Sounds.Music[track]
	local sound = newSound(spec, SoundService, true)
	sound.Looped = true
	sound.Volume = 0
	sound:Play()
	TweenService:Create(sound, fade, { Volume = spec.Volume }):Play()
	musicSound = sound
end

-- La pista intensa entra en las oleadas altas o con la campana casi caída (con
-- histéresis: entra por debajo del 35% de vida y sale por encima del 55%)
local lowBell = false
local function wantsIntense(): boolean
	local folder = ReplicatedStorage:FindFirstChild("GameState")
	if not folder then
		return false
	end
	local ratio = (folder:GetAttribute("BellHealth") or 0) / math.max(folder:GetAttribute("BellMaxHealth") or 1, 1)
	if ratio < 0.35 and ratio > 0 then
		lowBell = true
	elseif ratio > 0.55 then
		lowBell = false
	end
	return lowBell or (folder:GetAttribute("Wave") or 0) >= Sounds.IntenseFromWave
end

local function updateMusic(state: string?)
	if state == "GameOver" then
		setMusic("GameOver")
	elseif bossesAlive > 0 then
		setMusic("Boss")
	elseif state == "Wave" or state == "Intermission" then
		setMusic(if wantsIntense() then "Intense" else "Wave")
	else
		setMusic("Lobby")
	end
end

-- Estado de la partida; nil si todavía no llegó del servidor
local function currentState(): string?
	local folder = ReplicatedStorage:FindFirstChild("GameState")
	return if folder then folder:GetAttribute("State") else nil
end

local function bellPosition(): Vector3?
	local map = workspace:FindFirstChild("Map")
	local bell = map and map:FindFirstChild("Bell")
	return if bell and bell:IsA("Model") then bell:GetPivot().Position else nil
end

function Sfx.onEnemySpawned(typeName: string)
	local info = Config.Enemies[typeName]
	-- Los zombis no hacen ruido al caminar: solo al morir
	if info and info.IsBoss then
		bossesAlive += 1
		updateMusic(currentState())
		-- Rugido grave y campanazo lento: llega un jefe
		Sfx.play("BossRoar")
		local position = bellPosition()
		if position then
			task.delay(0.4, Sfx.playAt, "BossBell", position)
		end
	end
end

function Sfx.onEnemyRemoved(typeName: string, position: Vector3?, killed: boolean)
	local info = Config.Enemies[typeName]
	if info and info.IsBoss then
		bossesAlive = math.max(bossesAlive - 1, 0)
		updateMusic(currentState())
	end
	if killed and position then
		Sfx.playAt("ZombieDeath", position)
		-- Explosivo: estallido que se ve y se oye
		if info and info.ExplodeOnDeath then
			Sfx.playAt("SmallExplosion", position)
			-- Solo visual (el daño lo calcula el servidor): cubos de fuego del pool de DeathFx,
			-- con tope propio, en vez de crear una Explosion por cada zombi
			local speed = info.ExplodeOnDeath.Radius * 1.4
			for _ = 1, math.min(10, DeathFx.budget()) do
				local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.2, 1.2), random:NextNumber(-1, 1)).Unit
				local color = if random:NextInteger(1, 2) == 1 then Color3.fromRGB(255, 140, 40) else Color3.fromRGB(255, 210, 90)
				DeathFx.addCube(position + Vector3.new(0, 2, 0), color, random:NextNumber(0.5, 1), direction * random:NextNumber(speed * 0.5, speed), 40, random:NextNumber(0.3, 0.6), true)
			end
		end
	end
end

function Sfx.onEnemiesCleared()
	bossesAlive = 0
	updateMusic(currentState())
end

local function watchHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local last = humanoid.Health
	local lost = 0
	local lastLoss = 0
	local lastHurt = 0
	humanoid.HealthChanged:Connect(function(health)
		local now = os.clock()
		if health < last and health > 0 then
			if now - lastLoss > HURT_WINDOW then
				lost = 0
			end
			lost += last - health
			lastLoss = now
			if lost >= HURT_THRESHOLD and now - lastHurt >= HURT_COOLDOWN then
				lost = 0
				lastHurt = now
				Sfx.play("PlayerHurt")
			end
		end
		last = health
	end)
end

function Sfx.init()
	player:GetAttributeChangedSignal("LowQuality"):Connect(function()
		lowQuality = player:GetAttribute("LowQuality") == true
	end)
	local ambience = newSound(Sounds.Ambience, SoundService, true)
	ambience.Looped = true
	ambience:Play()

	local folder = ReplicatedStorage:WaitForChild("GameState")
	local lastState = folder:GetAttribute("State")
	local lastBellHealth = folder:GetAttribute("BellHealth") or 0
	updateMusic(lastState)

	folder:GetAttributeChangedSignal("State"):Connect(function()
		local state = folder:GetAttribute("State")
		local position = bellPosition()
		if lastState == "Lobby" and state == "Intermission" then
			-- Reconstruyeron la campana: martillazo y campanazo
			Sfx.play("Rebuild")
			Sfx.play("MatchStart")
			if position then
				task.delay(0.6, Sfx.playAt, "BellToll", position)
			end
		elseif state == "Wave" and position then
			Sfx.playAt("BellToll", position)
		elseif lastState == "Wave" and state == "Intermission" then
			Sfx.play("WaveClear")
		end
		lastState = state
		updateMusic(state)
	end)
	folder:GetAttributeChangedSignal("Wave"):Connect(function()
		updateMusic(currentState())
	end)
	folder:GetAttributeChangedSignal("BellHealth"):Connect(function()
		local health = folder:GetAttribute("BellHealth") or 0
		updateMusic(currentState())
		local position = bellPosition()
		if health < lastBellHealth and position then
			Sfx.playAt("BellHit", position)
		end
		lastBellHealth = health
	end)

	if player.Character then
		task.spawn(watchHealth, player.Character)
	end
	player.CharacterAdded:Connect(watchHealth)

	-- Latido: con la campana casi caída y durante la cámara lenta de Continuar;
	-- en los últimos segundos de la cuenta, un tic por segundo
	task.spawn(function()
		local lastTick = 0
		while true do
			task.wait(1.1)
			local endsAt = folder:GetAttribute("ContinueEnds") or 0
			local left = endsAt - workspace:GetServerTimeNow()
			local maxHealth = folder:GetAttribute("BellMaxHealth") or 1
			local lowBell = (folder:GetAttribute("BellHealth") or 0) > 0 and (folder:GetAttribute("BellHealth") or 0) / maxHealth < 0.2 and folder:GetAttribute("State") == "Wave"
			if left > 0 or lowBell then
				Sfx.play("Heartbeat")
				if left > 0 and left <= 5 and os.clock() - lastTick > 0.9 then
					lastTick = os.clock()
					task.delay(0.5, Sfx.play, "Tick")
				end
			end
		end
	end)

end

return Sfx
