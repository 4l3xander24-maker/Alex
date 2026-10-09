-- Personaje de cada jugador: vida, velocidad, cámara, daño recibido y los
-- talentos que actúan en el servidor (Regeneración, Último aliento, Reparador).
-- También revisa si alguien cayó por el acantilado al mar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GameState = require(script.Parent.GameState)

local talents = Config.TalentValues
local REGEN_TICK = 0.5

type State = {
	LastDamaged: number,
	InvulnerableUntil: number,
	LastStandUsed: boolean,
	LastRepair: number,
}

local PlayerService = {}

local states: { [Player]: State } = {}

local function getState(player: Player): State
	local state = states[player]
	if not state then
		state = { LastDamaged = 0, InvulnerableUntil = 0, LastStandUsed = false, LastRepair = 0 }
		states[player] = state
	end
	return state
end

local function getHumanoid(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function hasTalent(player: Player, id: string): boolean
	local data = DataService.get(player)
	return data ~= nil and Progression.hasTalent(data, id)
end

-- Aplica vida máxima y velocidad según las mejoras del perfil
local function applyStats(player: Player, refill: boolean)
	local data = DataService.get(player)
	local humanoid = getHumanoid(player)
	if not data or not humanoid or humanoid.Health <= 0 then
		return
	end
	local stats = Progression.getPlayerStats(data)
	local ratio = humanoid.Health / humanoid.MaxHealth
	humanoid.MaxHealth = stats.MaxHealth
	humanoid.Health = if refill then stats.MaxHealth else math.max(1, ratio * stats.MaxHealth)
	humanoid.WalkSpeed = stats.WalkSpeed
	-- El cliente lo usa como base para el talento Correr
	player:SetAttribute("BaseWalkSpeed", stats.WalkSpeed)
end

local function onCharacterAdded(player: Player, character: Model)
	character:WaitForChild("Humanoid")
	local state = getState(player)
	state.InvulnerableUntil = 0
	applyStats(player, true)
end

function PlayerService.damagePlayer(player: Player, amount: number)
	local humanoid = getHumanoid(player)
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	local state = getState(player)
	local now = os.clock()
	if now < state.InvulnerableUntil then
		return
	end
	state.LastDamaged = now

	if humanoid.Health - amount <= 0 and not state.LastStandUsed and hasTalent(player, "LastStand") then
		state.LastStandUsed = true
		state.InvulnerableUntil = now + talents.LastStandInvulnerable
		humanoid.Health = 1
		Remotes.Notify:FireClient(player, "🛡️ ¡Último aliento!")
		return
	end
	humanoid:TakeDamage(amount)
end

function PlayerService.heal(player: Player, amount: number)
	local humanoid = getHumanoid(player)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + amount)
	end
end

function PlayerService.onKill(player: Player)
	if hasTalent(player, "Vampire") then
		PlayerService.heal(player, talents.VampireHeal)
	end
end

-- Último aliento se recarga en cada oleada
function PlayerService.onWaveStart()
	for _, state in states do
		state.LastStandUsed = false
	end
end

-- Talento Reparador: mantener E junto a la campana
function PlayerService.bindRepairPrompt(prompt: ProximityPrompt)
	prompt.Triggered:Connect(function(player)
		if not hasTalent(player, "Repair") then
			Remotes.Notify:FireClient(player, "Necesitas el talento Reparador (Veterano)")
			return
		end
		local state = getState(player)
		local now = os.clock()
		if now - state.LastRepair < Config.Bell.RepairCooldown then
			return
		end
		state.LastRepair = now
		if GameState.repairBell(Config.Bell.RepairAmount) then
			Remotes.Notify:FireClient(player, `🔧 +{Config.Bell.RepairAmount} a la campana`)
		end
	end)
end

-- Se llama cuando el perfil del jugador terminó de cargar
function PlayerService.onPlayerReady(player: Player)
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

-- En la partida no se reaparece: quien muere queda afuera hasta la próxima
-- preparación, y si caen todos se acaba la partida (WaveService)
local inMatch = false
local fallen: { [Player]: boolean } = {}

local function loadCharacter(player: Player)
	if player.Parent then
		pcall(player.LoadCharacter, player)
	end
end

local function watchDeath(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		if inMatch then
			fallen[player] = true
			Remotes.Notify:FireClient(player, "💀 Caíste. Si caen todos, se acaba la partida")
		else
			task.delay(Config.Player.RespawnTime, loadCharacter, player)
		end
	end)
end

function PlayerService.setInMatch(value: boolean)
	inMatch = value
	if not value then
		-- Vuelven todos los que cayeron
		for player in fallen do
			loadCharacter(player)
		end
		table.clear(fallen)
		for _, player in Players:GetPlayers() do
			local humanoid = getHumanoid(player)
			if not humanoid or humanoid.Health <= 0 then
				loadCharacter(player)
			end
		end
	end
end

-- true si no queda ningún jugador vivo
function PlayerService.allDown(): boolean
	for _, player in Players:GetPlayers() do
		local humanoid = getHumanoid(player)
		if humanoid and humanoid.Health > 0 then
			return false
		end
	end
	return true
end

function PlayerService.init()
	Players.RespawnTime = Config.Player.RespawnTime
	Players.CharacterAutoLoads = false
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			watchDeath(player, character)
		end)
		loadCharacter(player)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(character)
			watchDeath(player, character)
		end)
		if player.Character then
			task.spawn(watchDeath, player, player.Character)
		else
			loadCharacter(player)
		end
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
		fallen[player] = nil
	end)

	DataService.onChanged(function(player, reason)
		if reason ~= "Equip" then
			applyStats(player, false)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(REGEN_TICK)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local state = states[player]
				if state and now - state.LastDamaged >= talents.RegenDelay and hasTalent(player, "Regen") then
					PlayerService.heal(player, talents.RegenPerSecond * REGEN_TICK)
				end
				-- Quien cae al agua vuelve al círculo de runas con un poco menos de vida
				local humanoid = getHumanoid(player)
				local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if humanoid and humanoid.Health > 0 and root and (root :: BasePart).Position.Y < Config.Arena.FallKillY then
					local spawn = Config.Arena.SpawnCircle
					local character = player.Character :: Model
					local rootPart = root :: BasePart
					character:PivotTo(CFrame.new(spawn + Vector3.new(0, 4, 0)))
					rootPart.AssemblyLinearVelocity = Vector3.zero
					humanoid:TakeDamage(Config.Player.FallDamage)
					Remotes.Notify:FireClient(player, "🌊 ¡Caíste al agua! Te sacaron, pero perdiste vida")
				end
			end
		end
	end)
end

return PlayerService
