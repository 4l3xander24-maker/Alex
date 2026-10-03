-- Los enemigos no son Humanoids: son datos en el servidor. Los clientes los
-- dibujan, así aguantamos cientos de zombis a la vez.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Remotes = require(Shared.Remotes)

export type Enemy = {
	Id: number,
	Type: string,
	Health: number,
	Path: EnemyMath.Path,
	Radius: number,
	DamagePerSecond: number,
	Coins: number,
	Xp: number,
}

local EnemyService = {}

local enemies: { [number]: Enemy } = {}
local aliveCount = 0
local nextId = 0
local random = Random.new()
local killHandler: ((Player, Enemy) -> ())? = nil

function EnemyService.setKillHandler(handler: (Player, Enemy) -> ())
	killHandler = handler
end

function EnemyService.getAliveCount(): number
	return aliveCount
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
		DamagePerSecond = info.DamagePerSecond,
		Coins = info.Coins,
		Xp = info.Xp,
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

	enemies[enemyId] = nil
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
	local flatCenter = Vector3.new(center.X, 0, center.Z)
	for id, enemy in enemies do
		local position = EnemyMath.getPosition(enemy.Path, time)
		if (Vector3.new(position.X, 0, position.Z) - flatCenter).Magnitude <= radius + enemy.Radius then
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

-- Empuja hacia atrás a los zombis cercanos cambiando su SpawnTime
function EnemyService.knockback(center: Vector3, radius: number, seconds: number, now: number)
	local updates = {}
	for _, id in EnemyService.getInRadius(center, radius, now) do
		local path = enemies[id].Path
		path.SpawnTime = EnemyMath.pushedBackSpawnTime(path, now, seconds)
		table.insert(updates, { id, path.SpawnTime })
	end
	if #updates > 0 then
		Remotes.EnemyPathsUpdated:FireAllClients(updates)
	end
end

function EnemyService.getBellDamagePerSecond(now: number): number
	local total = 0
	for _, enemy in enemies do
		if EnemyMath.hasArrived(enemy.Path, now) then
			total += enemy.DamagePerSecond
		end
	end
	return total
end

function EnemyService.clear()
	table.clear(enemies)
	aliveCount = 0
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
