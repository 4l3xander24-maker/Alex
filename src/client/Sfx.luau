-- Sonidos y música. Todo es local: cada cliente escucha sus disparos, los
-- zombis que tiene cerca y la música según el estado de la partida.
-- Los ids están en Shared.Sounds.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Sounds = require(Shared.Sounds)

-- Separación mínima entre dos sonidos iguales, para que una ráfaga o una
-- horda no se vuelva ruido
local MIN_GAP = {
	ZombieDeath = 0.08,
	HitMarker = 0.05,
	BellHit = 0.4,
	PlayerHurt = 0.25,
	SmallExplosion = 0.1,
}
local DEFAULT_GAP = 0.03
local MIN_DISTANCE = 10
local MAX_LIFETIME = 15

local Sfx = {}

local player = Players.LocalPlayer
local random = Random.new()
local lastPlayed: { [string]: number } = {}
local bossesAlive = 0
local musicTrack: string? = nil
local musicSound: Sound? = nil

local function pickId(spec): number
	if spec.Ids then
		return spec.Ids[random:NextInteger(1, #spec.Ids)]
	end
	return spec.Id
end

local function newSound(spec, parent: Instance): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{pickId(spec)}`
	sound.Volume = spec.Volume or 0.5
	sound.PlaybackSpeed = if spec.PitchRange
		then random:NextNumber(spec.PitchRange[1], spec.PitchRange[2])
		else spec.Pitch or 1
	if spec.Distance then
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = MIN_DISTANCE
		sound.RollOffMaxDistance = spec.Distance
	end
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

local function playOnce(sound: Sound, holder: Instance)
	sound.Ended:Once(function()
		holder:Destroy()
	end)
	sound:Play()
	Debris:AddItem(holder, MAX_LIFETIME)
end

-- Sonido "en la cabeza" del jugador (armas, interfaz)
function Sfx.play(name: string)
	local spec = Sounds[name]
	if not spec or not canPlay(name) then
		return
	end
	local sound = newSound(spec, SoundService)
	playOnce(sound, sound)
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
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain
	playOnce(newSound(spec, attachment), attachment)
end

function Sfx.weapon(weaponId: string)
	local spec = Sounds.Weapons[weaponId]
	if not spec or not canPlay(`Weapon.{weaponId}`) then
		return
	end
	local sound = newSound(spec, SoundService)
	playOnce(sound, sound)
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
	local sound = newSound(spec, SoundService)
	sound.Looped = true
	sound.Volume = 0
	sound:Play()
	TweenService:Create(sound, fade, { Volume = spec.Volume }):Play()
	musicSound = sound
end

local function updateMusic(state: string?)
	if state == "GameOver" then
		setMusic("GameOver")
	elseif bossesAlive > 0 then
		setMusic("Boss")
	elseif state == "Wave" or state == "Intermission" then
		setMusic("Wave")
	else
		setMusic("Lobby")
	end
end

-- Estado de la partida; nil si todavía no llegó del servidor
local function currentState(): string?
	local folder = ReplicatedStorage:FindFirstChild("GameState")
	return if folder then folder:GetAttribute("State") else nil
end

function Sfx.onEnemySpawned(typeName: string)
	local info = Config.Enemies[typeName]
	-- Los zombis no hacen ruido al caminar: solo al morir
	if info and info.IsBoss then
		bossesAlive += 1
		updateMusic(currentState())
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
	end
end

function Sfx.onEnemiesCleared()
	bossesAlive = 0
	updateMusic(currentState())
end

local function watchHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local last = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if health < last - 0.5 and health > 0 then
			Sfx.play("PlayerHurt")
		end
		last = health
	end)
end

local function bellPosition(): Vector3?
	local map = workspace:FindFirstChild("Map")
	local bell = map and map:FindFirstChild("Bell")
	return if bell and bell:IsA("Model") then bell:GetPivot().Position else nil
end

function Sfx.init()
	local ambience = newSound(Sounds.Ambience, SoundService)
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
			if position then
				task.delay(0.6, Sfx.playAt, "BellToll", position)
			end
		elseif state == "Wave" and position then
			Sfx.playAt("BellToll", position)
		end
		lastState = state
		updateMusic(state)
	end)
	folder:GetAttributeChangedSignal("BellHealth"):Connect(function()
		local health = folder:GetAttribute("BellHealth") or 0
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

end

return Sfx
