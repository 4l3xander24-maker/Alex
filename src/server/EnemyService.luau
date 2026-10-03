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
	Gold: number,
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

function EnemyService.spawn(typeName: string, healthMultiplier: number)
	local info = Config.Enemies[typeName]
	local arena = Config.Arena
	local halfHeight = info.Size.Y / 2

	local startX = random:NextNumber(-arena.SpawnHalfWidth, arena.SpawnHalfWidth)
	local limit = arena.CastleWidth / 2 - info.Size.X
	local targetX = math.clamp(startX + random:NextNumber(-10, 10), -limit, limit)
	local start = Vector3.new(startX, halfHeight, arena.SpawnZ)
	local target = Vector3.new(targetX, halfHeight, arena.StopZ - random:NextNumber(0, arena.StopJitter))
	local spawnTime = workspace:GetServerTimeNow()

	nextId += 1
	local enemy: Enemy = {
		Id = nextId,
		Type = typeName,
		Health = math.ceil(info.MaxHealth * healthMultiplier),
		Path = EnemyMath.newPath(start, target, info.Speed, spawnTime),
		Radius = info.HitRadius,
		DamagePerSecond = info.DamagePerSecond,
		Gold = info.Gold,
	}
	enemies[nextId] = enemy
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

-- Devuelve el id del zombi más cercano que cruza el rayo, o nil.
-- Cada zombi se trata como una esfera para que sea barato revisar cientos.
function EnemyService.raycast(origin: Vector3, direction: Vector3, range: number, time: number): number?
	local bestId, bestDistance = nil, range
	for id, enemy in enemies do
		local offset = EnemyMath.getPosition(enemy.Path, time) - origin
		local along = offset:Dot(direction)
		if along > 0 and along < bestDistance then
			local missSquared = offset:Dot(offset) - along * along
			if missSquared <= enemy.Radius * enemy.Radius then
				bestId, bestDistance = id, along
			end
		end
	end
	return bestId
end

function EnemyService.getCastleDamagePerSecond(now: number): number
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
