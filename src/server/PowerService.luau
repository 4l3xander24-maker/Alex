-- Poderes activos: Granada (G), Rayo en cadena (Q) y Campanazo (F).
-- Se compran y mejoran con la Bruja del campamento.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)

local COOLDOWN_TOLERANCE = 0.25
local BELL_CENTER = Vector3.zero

local PowerService = {}

local cooldowns: { [Player]: { [string]: number } } = {}

-- Punto del suelo al que apunta el jugador, limitado por el alcance
local function getGroundTarget(origin: Vector3, direction: Vector3, range: number): Vector3
	if direction.Y < -0.01 then
		local distance = -origin.Y / direction.Y
		if distance <= range then
			local point = origin + direction * distance
			return Vector3.new(point.X, 0, point.Z)
		end
	end
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	local point = origin + flat.Unit * range
	return Vector3.new(point.X, 0, point.Z)
end

local handlers = {}

function handlers.Grenade(player: Player, stats, origin: Vector3, aim: Vector3, time: number)
	local target = getGroundTarget(origin, aim, stats.Range)
	local hitId = EnemyService.raycast(origin, aim, stats.Range, time, 1)[1]
	local hitPosition = hitId and EnemyService.getPosition(hitId, time)
	if hitPosition then
		target = Vector3.new(hitPosition.X, 0, hitPosition.Z)
	end

	Remotes.PowerFx:FireAllClients("Grenade", origin, target, stats.Radius, stats.FlightTime)
	task.delay(stats.FlightTime, function()
		for _, enemyId in EnemyService.getInRadius(target, stats.Radius, workspace:GetServerTimeNow()) do
			EnemyService.damage(enemyId, stats.Damage, player)
		end
	end)
end

function handlers.Chain(player: Player, stats, origin: Vector3, aim: Vector3, time: number)
	local points = { origin }
	local first = EnemyService.raycast(origin, aim, 400, time, 1, 2)[1]
	if not first then
		table.insert(points, origin + aim * 40)
		Remotes.PowerFx:FireAllClients("Chain", points)
		return
	end

	local targets = { first }
	local visited = { [first] = true }
	local current = first
	while #targets < stats.Targets do
		local position = EnemyService.getPosition(current, time)
		local nextId = position and EnemyService.findNearest(position, stats.JumpRange, time, visited)
		if not nextId then
			break
		end
		visited[nextId] = true
		table.insert(targets, nextId)
		current = nextId
	end

	-- Primero guardamos las posiciones: al dañar, algunos mueren y desaparecen
	for _, enemyId in targets do
		local position = EnemyService.getPosition(enemyId, time)
		if position then
			table.insert(points, position)
		end
	end
	Remotes.PowerFx:FireAllClients("Chain", points)
	for _, enemyId in targets do
		EnemyService.damage(enemyId, stats.Damage, player)
	end
end

function handlers.Bell(player: Player, stats)
	local now = workspace:GetServerTimeNow()
	local affected = EnemyService.getInRadius(BELL_CENTER, stats.Radius, now)
	EnemyService.knockback(BELL_CENTER, stats.Radius, stats.KnockbackSeconds, now)
	EnemyService.flushUpdates()
	Remotes.PowerFx:FireAllClients("Bell", BELL_CENTER, stats.Radius)
	for _, enemyId in affected do
		EnemyService.damage(enemyId, stats.Damage, player)
	end
end

local function onUsePower(player: Player, name: any, origin: any, direction: any, shotTime: any)
	if typeof(name) ~= "string" or not handlers[name] then
		return
	end
	local data = DataService.get(player)
	if not data or (data.Powers[name] or 0) < 1 then
		return
	end

	local playerCooldowns = cooldowns[player] or {}
	cooldowns[player] = playerCooldowns
	local now = os.clock()
	if (playerCooldowns[name] or 0) > now + COOLDOWN_TOLERANCE then
		return
	end

	local aim, time = CombatService.validateAim(player, origin, direction, shotTime)
	if not aim then
		return
	end

	local stats = Progression.getPowerStats(data, name)
	playerCooldowns[name] = now + stats.Cooldown
	handlers[name](player, stats, origin, aim, time)
end

function PowerService.init()
	Remotes.UsePower.OnServerEvent:Connect(onUsePower)
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)
	-- Al reaparecer los poderes están listos
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			cooldowns[player] = nil
		end)
	end)
end

return PowerService
