-- Los enemigos no son Humanoids: son datos en el servidor. Los clientes los
-- dibujan, así aguantamos cientos de zombis a la vez.
--
-- Cada zombi camina en línea recta hacia un objetivo. Por defecto es la
-- campana; si un jugador se acerca, el zombi cambia de objetivo y lo persigue
-- (se recalcula su línea recta varias veces por segundo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Remotes = require(Shared.Remotes)

local hunt = Config.Hunt
local RETARGET_DISTANCE = 3 -- solo recalculamos si el jugador se movió más que esto
-- Los jugadores sobre el campanario están fuera del alcance de los zombis
-- (el HumanoidRootPart de alguien parado en el suelo está a ~3 studs)
local MAX_REACHABLE_HEIGHT = 7

export type Enemy = {
	Id: number,
	Type: string,
	Health: number,
	Path: EnemyMath.Path,
	Radius: number,
	HalfHeight: number,
	BellTarget: Vector3,
	Chasing: Player?,
	DamagePerSecond: number,
	PlayerDamage: number,
	Coins: number,
	IsBoss: boolean,
}

local EnemyService = {}

local enemies: { [number]: Enemy } = {}
local aliveCount = 0
local chaserCount = 0
local nextId = 0
local random = Random.new()
local pendingUpdates = {}
local killHandler: ((Player, Enemy) -> ())? = nil
local playerDamageHandler: ((Player, number) -> ())? = nil

function EnemyService.setKillHandler(handler: (Player, Enemy) -> ())
	killHandler = handler
end

function EnemyService.setPlayerDamageHandler(handler: (Player, number) -> ())
	playerDamageHandler = handler
end

function EnemyService.getAliveCount(): number
	return aliveCount
end

local function flatDistance(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Cambia la línea recta del zombi y la anota para mandarla a los clientes
local function setPath(enemy: Enemy, start: Vector3, target: Vector3, now: number)
	enemy.Path = EnemyMath.newPath(start, target, enemy.Path.Speed, now)
	pendingUpdates[enemy.Id] = enemy
end

local function stopChasing(enemy: Enemy)
	if enemy.Chasing then
		enemy.Chasing = nil
		chaserCount -= 1
	end
end

-- Punto junto al jugador, del lado por donde viene el zombi
local function chasePoint(enemy: Enemy, from: Vector3, playerPosition: Vector3): Vector3
	local offset = Vector3.new(from.X - playerPosition.X, 0, from.Z - playerPosition.Z)
	local direction = if offset.Magnitude > 0.01 then offset.Unit else Vector3.new(0, 0, -1)
	local point = playerPosition + direction * (enemy.Radius + 1)
	return Vector3.new(point.X, enemy.HalfHeight, point.Z)
end

-- Los zombis salen de un arco frente a la campana y caminan hacia ella
function EnemyService.spawn(typeName: string, healthMultiplier: number)
	local info = Config.Enemies[typeName]
	local arena = Config.Arena
	local halfHeight = info.Size.Y / 2

	local halfArc = math.rad(arena.SpawnArc / 2)
	local angle = random:NextNumber(-halfArc, halfArc)
	local outward = Vector3.new(math.sin(angle), 0, -math.cos(angle))
	local targetAngle = angle + random:NextNumber(-0.25, 0.25)
	local inward = Vector3.new(math.sin(targetAngle), 0, -math.cos(targetAngle))

	local start = outward * arena.SpawnRadius + Vector3.new(0, halfHeight, 0)
	local stopDistance = arena.StopRadius + info.HitRadius + random:NextNumber(0, arena.StopJitter)
	local target = inward * stopDistance + Vector3.new(0, halfHeight, 0)
	local spawnTime = workspace:GetServerTimeNow()

	nextId += 1
	enemies[nextId] = {
		Id = nextId,
		Type = typeName,
		Health = info.MaxHealth * healthMultiplier,
		Path = EnemyMath.newPath(start, target, info.Speed, spawnTime),
		Radius = info.HitRadius,
		HalfHeight = halfHeight,
		BellTarget = target,
		Chasing = nil,
		DamagePerSecond = info.DamagePerSecond,
		PlayerDamage = info.PlayerDamage,
		Coins = info.Coins,
		IsBoss = info.IsBoss == true,
	}
	aliveCount += 1

	Remotes.EnemySpawned:FireAllClients(nextId, typeName, start, target, info.Speed, spawnTime)
end

function EnemyService.damage(enemyId: number, amount: number, player: Player)
	local enemy = enemies[enemyId]
	if not enemy then
		return
	end

	enemy.Health -= amount
	if enemy.Health > 0 then
		Remotes.EnemyHit:FireAllClients(enemyId)
		return
	end

	stopChasing(enemy)
	enemies[enemyId] = nil
	pendingUpdates[enemyId] = nil
	aliveCount -= 1
	Remotes.EnemyDied:FireAllClients(enemyId)
	if killHandler then
		killHandler(player, enemy)
	end
end

function EnemyService.getPosition(enemyId: number, time: number): Vector3?
	local enemy = enemies[enemyId]
	return enemy and EnemyMath.getPosition(enemy.Path, time)
end

-- Ids de los zombis que cruza el rayo, del más cercano al más lejano.
-- Cada zombi se trata como una esfera para que sea barato revisar cientos.
function EnemyService.raycast(
	origin: Vector3,
	direction: Vector3,
	range: number,
	time: number,
	maxHits: number,
	extraRadius: number?
): { number }
	local hits = {}
	local padding = extraRadius or 0
	for id, enemy in enemies do
		local offset = EnemyMath.getPosition(enemy.Path, time) - origin
		local along = offset:Dot(direction)
		if along > 0 and along < range then
			local radius = enemy.Radius + padding
			if offset:Dot(offset) - along * along <= radius * radius then
				table.insert(hits, { Id = id, Along = along })
			end
		end
	end
	table.sort(hits, function(a, b)
		return a.Along < b.Along
	end)

	local ids = {}
	for index = 1, math.min(maxHits, #hits) do
		ids[index] = hits[index].Id
	end
	return ids
end

-- Ids de los zombis cuyo cuerpo está a menos de `radius` (medido sobre el suelo)
function EnemyService.getInRadius(center: Vector3, radius: number, time: number): { number }
	local ids = {}
	for id, enemy in enemies do
		if flatDistance(EnemyMath.getPosition(enemy.Path, time), center) <= radius + enemy.Radius then
			table.insert(ids, id)
		end
	end
	return ids
end

function EnemyService.findNearest(point: Vector3, maxDistance: number, time: number, exclude: { [number]: boolean }): number?
	local bestId, bestDistance = nil, maxDistance
	for id, enemy in enemies do
		if not exclude[id] then
			local distance = (EnemyMath.getPosition(enemy.Path, time) - point).Magnitude
			if distance < bestDistance then
				bestId, bestDistance = id, distance
			end
		end
	end
	return bestId
end

-- Empuja hacia atrás a los zombis cercanos: dejan de perseguir y retroceden
-- en dirección contraria a la campana.
function EnemyService.knockback(center: Vector3, radius: number, seconds: number, now: number)
	for _, id in EnemyService.getInRadius(center, radius, now) do
		local enemy = enemies[id]
		local position = EnemyMath.getPosition(enemy.Path, now)
		local away = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
		local direction = if away.Magnitude > 0.01 then away.Unit else Vector3.new(0, 0, -1)
		local pushed = position + direction * enemy.Path.Speed * seconds
		stopChasing(enemy)
		-- Arranca más atrás y vuelve a caminar hacia la campana
		setPath(enemy, Vector3.new(pushed.X, enemy.HalfHeight, pushed.Z), enemy.BellTarget, now)
	end
end

-- Jugadores vivos que los zombis pueden alcanzar, con su posición
local function getLivePlayers(): { [Player]: Vector3 }
	local positions = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local position = root and (root :: BasePart).Position
		if position and humanoid and humanoid.Health > 0 and position.Y < MAX_REACHABLE_HEIGHT then
			positions[player] = position
		end
	end
	return positions
end

-- Decide a quién persigue cada zombi y aplica el daño cuerpo a cuerpo
function EnemyService.think(now: number, dt: number)
	local players = getLivePlayers()

	for _, enemy in enemies do
		local position = EnemyMath.getPosition(enemy.Path, now)
		local target = enemy.Chasing
		local targetPosition = target and players[target]

		if target then
			if not targetPosition or flatDistance(position, targetPosition) > hunt.LeashRadius then
				stopChasing(enemy)
				setPath(enemy, position, enemy.BellTarget, now)
			else
				local desired = chasePoint(enemy, position, targetPosition)
				if (desired - EnemyMath.getTarget(enemy.Path)).Magnitude > RETARGET_DISTANCE then
					setPath(enemy, position, desired, now)
				end
				if flatDistance(position, targetPosition) <= enemy.Radius + hunt.MeleeRange and playerDamageHandler then
					playerDamageHandler(target, enemy.PlayerDamage * dt)
				end
			end
		elseif chaserCount < hunt.MaxChasers then
			local closest, closestDistance = nil, hunt.AggroRadius
			for player, playerPosition in players do
				local distance = flatDistance(position, playerPosition)
				if distance < closestDistance then
					closest, closestDistance = player, distance
				end
			end
			if closest then
				enemy.Chasing = closest
				chaserCount += 1
				setPath(enemy, position, chasePoint(enemy, position, players[closest]), now)
			end
		end
	end

	EnemyService.flushUpdates()
end

-- Manda a los clientes todos los cambios de camino juntos
function EnemyService.flushUpdates()
	local updates = {}
	for id, enemy in pendingUpdates do
		local path = enemy.Path
		table.insert(updates, { id, path.Start, EnemyMath.getTarget(path), path.SpawnTime })
	end
	table.clear(pendingUpdates)
	if #updates > 0 then
		Remotes.EnemyPathsUpdated:FireAllClients(updates)
	end
end

function EnemyService.getBellDamagePerSecond(now: number): number
	local total = 0
	for _, enemy in enemies do
		if not enemy.Chasing and EnemyMath.hasArrived(enemy.Path, now) then
			total += enemy.DamagePerSecond
		end
	end
	return total
end

function EnemyService.clear()
	table.clear(enemies)
	table.clear(pendingUpdates)
	aliveCount = 0
	chaserCount = 0
	Remotes.EnemiesCleared:FireAllClients()
end

-- Para jugadores que entran a mitad de una oleada
function EnemyService.getSnapshot()
	local snapshot = {}
	for id, enemy in enemies do
		local path = enemy.Path
		table.insert(snapshot, { id, enemy.Type, path.Start, EnemyMath.getTarget(path), path.Speed, path.SpawnTime })
	end
	return snapshot
end

return EnemyService
