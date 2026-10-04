-- Los enemigos no son Humanoids: son datos en el servidor. Los clientes los
-- dibujan, así aguantamos cientos de zombis a la vez.
--
-- Cada zombi sigue uno de los caminos (Config.Paths) hasta la campana. Si un
-- jugador se acerca, el zombi deja el camino y lo persigue (se recalcula su
-- línea recta varias veces por segundo); al soltarlo vuelve al camino. Si hay
-- una reja en el camino, se detiene frente a ella y la golpea hasta romperla.
-- Los jefes voladores van en línea recta por el aire. El barranco solo se
-- cruza por el puente: no persiguen a nadie si tendrían que saltarlo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local EnemyMath = require(Shared.EnemyMath)
local Paths = require(Shared.Paths)
local Remotes = require(Shared.Remotes)
local GameState = require(script.Parent.GameState)

local hunt = Config.Hunt
local RETARGET_DISTANCE = 3 -- solo recalculamos si el jugador se movió más que esto
-- Los jugadores muy altos (sobre muros o techos) están fuera del alcance de los
-- zombis (el HumanoidRootPart de alguien parado en el suelo está a ~3 studs;
-- sobre el montículo de la campana, a ~6)
local MAX_REACHABLE_HEIGHT = 7

export type Enemy = {
	Id: number,
	Type: string,
	Health: number,
	Path: EnemyMath.Path,
	Radius: number,
	HalfHeight: number, -- altura del centro del cuerpo (en los voladores, la de vuelo)
	BodyHalf: number, -- medio alto del cuerpo
	BellTarget: Vector3, -- dónde se para a golpear la campana
	Route: string, -- camino que sigue
	Lane: Vector3, -- desvío respecto al centro del camino
	Flying: boolean,
	Chasing: Player?,
	Blocking: string?, -- reja que tiene enfrente (si hay)
	DamagePerSecond: number,
	PlayerDamage: number,
	Coins: number,
	IsBoss: boolean,
	HealthMultiplier: number,
}

local EnemyService = {}

local enemies: { [number]: Enemy } = {}
local aliveCount = 0
local chaserCount = 0
local nextId = 0
local random = Random.new()
local pendingUpdates = {}
-- Eventos del cuadro: se mandan juntos en flushEvents para ahorrar red
local pendingSpawns = {}
local pendingHits = {}
local pendingDeaths = {}
local killHandler: ((Player, Enemy) -> ())? = nil
-- Jefe cuya vida se muestra arriba en la pantalla
local shownBoss: Enemy? = nil
local playerDamageHandler: ((Player, number) -> ())? = nil

export type Barrier = { Id: string, A: Vector3, B: Vector3 }
local barrierProvider: () -> { Barrier } = function()
	return {}
end

-- Las rejas las maneja TrapService; aquí solo pedimos dónde están
function EnemyService.setBarrierProvider(provider: () -> { Barrier })
	barrierProvider = provider
end

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

-- Cambia el recorrido del zombi y lo anota para mandarlo a los clientes
local function setRoute(enemy: Enemy, points: { Vector3 }, now: number)
	enemy.Path = EnemyMath.newRoute(points, enemy.Path.Speed, now)
	pendingUpdates[enemy.Id] = enemy
end

local function setPath(enemy: Enemy, start: Vector3, target: Vector3, now: number)
	setRoute(enemy, { start, target }, now)
end

local function stopChasing(enemy: Enemy)
	if enemy.Chasing then
		enemy.Chasing = nil
		chaserCount -= 1
	end
end

-- Dónde cruza el tramo from→to la primera reja (fracción del tramo e id)
local function firstBarrierHit(from: Vector3, to: Vector3): (number?, string?)
	local px, pz = from.X, from.Z
	local rx, rz = to.X - px, to.Z - pz
	local bestT, bestId = nil, nil
	for _, barrier in barrierProvider() do
		local qx, qz = barrier.A.X, barrier.A.Z
		local sx, sz = barrier.B.X - qx, barrier.B.Z - qz
		local denominator = rx * sz - rz * sx
		if math.abs(denominator) > 1e-9 then
			local t = ((qx - px) * sz - (qz - pz) * sx) / denominator
			local u = ((qx - px) * rz - (qz - pz) * rx) / denominator
			if t >= 0 and t <= 1 and u >= 0 and u <= 1 and (not bestT or t < bestT) then
				bestT, bestId = t, barrier.Id
			end
		end
	end
	return bestT, bestId
end

-- Puntos del camino de este zombi (con su desvío), sin la campana
local function routeWaypoints(enemy: Enemy): { Vector3 }
	local points = Paths.getPoints(enemy.Route)
	local waypoints = {}
	for index = 1, #points - 1 do
		local point = points[index] + enemy.Lane
		waypoints[index] = Vector3.new(point.X, enemy.HalfHeight, point.Z)
	end
	return waypoints
end

-- Ruta desde `from` hasta la campana: vuelve al camino en el siguiente punto
-- después del tramo más cercano y lo sigue hasta el final
local function routeFrom(enemy: Enemy, from: Vector3): { Vector3 }
	if enemy.Flying then
		return { from, enemy.BellTarget }
	end
	local waypoints = routeWaypoints(enemy)
	table.insert(waypoints, enemy.BellTarget)
	local bestIndex, bestDistance = #waypoints, math.huge
	for index = 2, #waypoints do
		local distance = Paths.segmentDistance(from, waypoints[index - 1], waypoints[index])
		if distance < bestDistance then
			bestIndex, bestDistance = index, distance
		end
	end
	-- Si en línea recta tendría que cruzar el barranco, primero va a la entrada del puente
	while bestIndex > 2 and Paths.crossesChasm(from, waypoints[bestIndex]) do
		bestIndex -= 1
	end
	local route = { from }
	for index = bestIndex, #waypoints do
		table.insert(route, waypoints[index])
	end
	return route
end

-- Si una reja corta la ruta, la ruta termina frente a ella
local function cutAtBarrier(enemy: Enemy, route: { Vector3 }): ({ Vector3 }, string?)
	if enemy.Flying then
		return route, nil
	end
	for index = 2, #route do
		local from, to = route[index - 1], route[index]
		local t, barrierId = firstBarrierHit(from, to)
		if t then
			local offset = to - from
			local stop = math.max(0, offset.Magnitude * t - enemy.Radius - 0.5)
			local cut = table.move(route, 1, index - 1, 1, {})
			table.insert(cut, from + offset.Unit * stop)
			return cut, barrierId
		end
	end
	return route, nil
end

-- Vuelve a caminar hacia la campana por su camino
local function goToBell(enemy: Enemy, from: Vector3, now: number)
	local route, barrierId = cutAtBarrier(enemy, routeFrom(enemy, from))
	enemy.Blocking = barrierId
	setRoute(enemy, route, now)
end

-- Punto junto al jugador, del lado por donde viene el zombi
local function chasePoint(enemy: Enemy, from: Vector3, playerPosition: Vector3): Vector3
	local offset = Vector3.new(from.X - playerPosition.X, 0, from.Z - playerPosition.Z)
	local direction = if offset.Magnitude > 0.01 then offset.Unit else Vector3.new(0, 0, -1)
	local point = playerPosition + direction * (enemy.Radius + 1)
	return Vector3.new(point.X, enemy.HalfHeight, point.Z)
end

-- Publica la vida del jefe que se muestra (o elige otro si murió)
local function publishBoss()
	if shownBoss and not enemies[shownBoss.Id] then
		shownBoss = nil
	end
	if not shownBoss then
		for _, enemy in enemies do
			if enemy.IsBoss then
				shownBoss = enemy
				break
			end
		end
	end
	local boss = shownBoss
	if not boss then
		GameState.set("BossName", "")
		return
	end
	local info = Config.Enemies[boss.Type]
	GameState.set("BossName", `{info.Icon or "💀"} {info.DisplayName}`)
	GameState.set("BossMaxHealth", math.ceil(info.MaxHealth * boss.HealthMultiplier))
	GameState.set("BossHealth", math.max(0, math.ceil(boss.Health)))
end

-- Crea un zombi en `start` (o al principio de su camino) y lo manda a la campana
local function create(typeName: string, healthMultiplier: number, start: Vector3?, routeName: string?)
	local info = Config.Enemies[typeName]
	local arena = Config.Arena
	local flying = info.Flying == true
	local halfHeight = if flying then info.FlyHeight else info.Size.Y / 2
	local route = routeName or Paths.pick(random)
	local lane = Config.PathStyle.Lane
	local laneOffset = Vector3.new(random:NextNumber(-lane, lane), 0, random:NextNumber(-lane, lane))

	-- Se para frente a la campana, del lado por donde llega su camino
	local points = Config.Paths[route].Points
	local approach = Vector3.new(points[#points].X, 0, points[#points].Z).Unit
	local angle = math.atan2(approach.X, -approach.Z) + random:NextNumber(-0.5, 0.5)
	local stopDistance = arena.StopRadius + info.HitRadius + random:NextNumber(0, arena.StopJitter)
	local target = Vector3.new(math.sin(angle), 0, -math.cos(angle)) * stopDistance + Vector3.new(0, halfHeight, 0)

	local origin = start
	if not origin then
		-- Del bosque salen repartidos a lo ancho, como si vinieran de entre los árboles
		local spread = if Config.Paths[route].Entrance then 0 else Config.PathStyle.SpawnSpread
		local along = (points[2] - points[1]).Unit
		local across = Vector3.new(-along.Z, 0, along.X)
		origin = points[1] + laneOffset + across * random:NextNumber(-spread, spread)
	end
	origin = Vector3.new(origin.X, halfHeight, origin.Z)
	local spawnTime = workspace:GetServerTimeNow()

	nextId += 1
	local enemy: Enemy = {
		Id = nextId,
		Type = typeName,
		Health = info.MaxHealth * healthMultiplier,
		HealthMultiplier = healthMultiplier,
		Path = EnemyMath.newPath(origin, target, info.Speed, spawnTime),
		Radius = info.HitRadius,
		HalfHeight = halfHeight,
		BodyHalf = info.Size.Y / 2,
		BellTarget = target,
		Route = route,
		Lane = laneOffset,
		Flying = flying,
		Chasing = nil,
		Blocking = nil,
		DamagePerSecond = info.DamagePerSecond,
		PlayerDamage = info.PlayerDamage,
		Coins = info.Coins,
		IsBoss = info.IsBoss == true,
	}
	enemies[nextId] = enemy
	aliveCount += 1
	goToBell(enemy, origin, spawnTime)
	pendingUpdates[nextId] = nil

	table.insert(pendingSpawns, { nextId, typeName, enemy.Path.Points, info.Speed, spawnTime })
	if enemy.IsBoss then
		publishBoss()
	end
end

-- Un zombi nuevo al principio de uno de los caminos
function EnemyService.spawn(typeName: string, healthMultiplier: number)
	create(typeName, healthMultiplier, nil, nil)
end

-- Los jefes como el Gordo sueltan zombis al morir
local function spawnChildren(enemy: Enemy, position: Vector3)
	local info = Config.Enemies[enemy.Type]
	local children = info.SpawnOnDeath
	if not children then
		return
	end
	local multiplier = enemy.HealthMultiplier
	for index = 1, children.Count do
		local angle = index / children.Count * math.pi * 2
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * enemy.Radius * 0.6
		-- Si revienta sobre el puente, los hijos quedan arriba del puente
		create(children.Type, multiplier, Paths.clampToBridge(position + offset), enemy.Route)
	end
end

function EnemyService.damage(enemyId: number, amount: number, player: Player)
	local enemy = enemies[enemyId]
	if not enemy then
		return
	end

	local before = math.ceil(enemy.Health)
	enemy.Health -= amount
	if enemy.Health > 0 then
		-- Id y daño (para los números que saltan en los clientes)
		table.insert(pendingHits, { enemyId, amount })
		if enemy == shownBoss and math.ceil(enemy.Health) ~= before then
			GameState.set("BossHealth", math.ceil(enemy.Health))
		end
		return
	end

	stopChasing(enemy)
	enemies[enemyId] = nil
	pendingUpdates[enemyId] = nil
	aliveCount -= 1
	table.insert(pendingDeaths, { enemyId, amount })
	if killHandler then
		killHandler(player, enemy)
	end
	spawnChildren(enemy, EnemyMath.getPosition(enemy.Path, workspace:GetServerTimeNow()))
	if enemy.IsBoss then
		publishBoss()
	end
end

function EnemyService.getPosition(enemyId: number, time: number): Vector3?
	local enemy = enemies[enemyId]
	return enemy and EnemyMath.getPosition(enemy.Path, time)
end

-- Ids de los zombis que cruza el rayo, del más cercano al más lejano.
-- Cada zombi se trata como una cápsula vertical (una esfera estirada a lo
-- alto) para que sea barato revisar cientos y los jefes altos se puedan
-- golpear en todo el cuerpo.
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
		local center = EnemyMath.getPosition(enemy.Path, time)
		local reach = math.max(0, enemy.BodyHalf - enemy.Radius)
		-- Punto del eje de la cápsula más cercano al rayo (dos pasadas bastan)
		local along = (center - origin):Dot(direction)
		local axisPoint = center
		for _ = 1, 2 do
			local rayPoint = origin + direction * along
			axisPoint = Vector3.new(center.X, math.clamp(rayPoint.Y, center.Y - reach, center.Y + reach), center.Z)
			along = (axisPoint - origin):Dot(direction)
		end
		if along > 0 and along < range then
			local radius = enemy.Radius + padding
			local gap = axisPoint - (origin + direction * along)
			if gap:Dot(gap) <= radius * radius then
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

-- Ids de los zombis cuyo cuerpo está a menos de `radius` (medido sobre el
-- suelo). Los que vuelan muy alto quedan fuera de las explosiones en el suelo.
function EnemyService.getInRadius(center: Vector3, radius: number, time: number): { number }
	local ids = {}
	for id, enemy in enemies do
		local position = EnemyMath.getPosition(enemy.Path, time)
		local heightGap = math.abs(position.Y - center.Y) - enemy.BodyHalf
		if heightGap <= radius and flatDistance(position, center) <= radius + enemy.Radius then
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
		-- Nunca los tira al barranco: si caen fuera del puente, quedan en el borde
		local pushed = Paths.clampToBridge(position + direction * enemy.Path.Speed * seconds)
		stopChasing(enemy)
		-- Arranca más atrás y vuelve a caminar hacia la campana por su camino
		goToBell(enemy, Vector3.new(pushed.X, enemy.HalfHeight, pushed.Z), now)
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
			local desired = targetPosition and chasePoint(enemy, position, targetPosition)
			if
				not targetPosition
				or flatDistance(position, targetPosition) > hunt.LeashRadius
				or firstBarrierHit(position, desired)
				or Paths.crossesChasm(position, desired)
			then
				-- Se alejó, murió, quedó detrás de una reja o del otro lado del barranco: vuelve a la campana
				stopChasing(enemy)
				goToBell(enemy, position, now)
			else
				if (desired - EnemyMath.getTarget(enemy.Path)).Magnitude > RETARGET_DISTANCE then
					setPath(enemy, position, desired, now)
				end
				if flatDistance(position, targetPosition) <= enemy.Radius + hunt.MeleeRange and playerDamageHandler then
					playerDamageHandler(target, enemy.PlayerDamage * dt)
				end
			end
		elseif chaserCount < hunt.MaxChasers and not enemy.Flying then
			local closest, closestDistance = nil, hunt.AggroRadius
			for player, playerPosition in players do
				local distance = flatDistance(position, playerPosition)
				-- Las rejas y el barranco protegen: no persiguen a quien está del otro lado
				if distance < closestDistance and not firstBarrierHit(position, playerPosition) and not Paths.crossesChasm(position, playerPosition) then
					closest, closestDistance = player, distance
				end
			end
			if closest then
				enemy.Chasing = closest
				enemy.Blocking = nil
				chaserCount += 1
				setPath(enemy, position, chasePoint(enemy, position, players[closest]), now)
			end
		end
	end

	EnemyService.flushUpdates()
end

-- Manda a los clientes, en un mensaje por tipo, todo lo que pasó en el cuadro:
-- nacimientos, cambios de camino, golpes y muertes (en ese orden)
function EnemyService.flushEvents()
	if #pendingSpawns > 0 then
		Remotes.EnemySpawned:FireAllClients(pendingSpawns)
		pendingSpawns = {}
	end
	EnemyService.flushUpdates()
	if #pendingHits > 0 then
		Remotes.EnemyHit:FireAllClients(pendingHits)
		pendingHits = {}
	end
	if #pendingDeaths > 0 then
		Remotes.EnemyDied:FireAllClients(pendingDeaths)
		pendingDeaths = {}
	end
end

-- Manda a los clientes todos los cambios de camino juntos
function EnemyService.flushUpdates()
	local updates = {}
	for id, enemy in pendingUpdates do
		local path = enemy.Path
		table.insert(updates, { id, path.Points, path.SpawnTime })
	end
	table.clear(pendingUpdates)
	if #updates > 0 then
		Remotes.EnemyPathsUpdated:FireAllClients(updates)
	end
end

function EnemyService.getBellDamagePerSecond(now: number): number
	local total = 0
	for _, enemy in enemies do
		if not enemy.Chasing and not enemy.Blocking and EnemyMath.hasArrived(enemy.Path, now) then
			total += enemy.DamagePerSecond
		end
	end
	return total
end

-- Daño por segundo que recibe cada reja de los zombis parados frente a ella
function EnemyService.getBarrierDamage(now: number): { [string]: number }
	local damage = {}
	for _, enemy in enemies do
		local barrierId = enemy.Blocking
		if barrierId and not enemy.Chasing and EnemyMath.hasArrived(enemy.Path, now) then
			damage[barrierId] = (damage[barrierId] or 0) + enemy.DamagePerSecond
		end
	end
	return damage
end

-- La reja se rompió (o se quitó): los que la golpeaban siguen hacia la campana
function EnemyService.releaseBarrier(barrierId: string, now: number)
	for _, enemy in enemies do
		if enemy.Blocking == barrierId and not enemy.Chasing then
			goToBell(enemy, EnemyMath.getPosition(enemy.Path, now), now)
		end
	end
	EnemyService.flushUpdates()
end

-- Zombis frente al jugador para un tajo de machete, del más cercano al más lejano
function EnemyService.getInCone(origin: Vector3, direction: Vector3, range: number, arcDegrees: number, time: number, maxTargets: number): { number }
	local flatDirection = Vector3.new(direction.X, 0, direction.Z)
	if flatDirection.Magnitude < 0.01 then
		return {}
	end
	flatDirection = flatDirection.Unit
	local minDot = math.cos(math.rad(arcDegrees / 2))
	local hits = {}
	for id, enemy in enemies do
		local position = EnemyMath.getPosition(enemy.Path, time)
		local offset = Vector3.new(position.X - origin.X, 0, position.Z - origin.Z)
		local distance = offset.Magnitude - enemy.Radius
		local heightGap = math.abs(position.Y - origin.Y) - enemy.BodyHalf
		if distance <= range and heightGap <= range then
			if offset.Magnitude < enemy.Radius + 1 or offset.Unit:Dot(flatDirection) >= minDot then
				table.insert(hits, { Id = id, Distance = distance })
			end
		end
	end
	table.sort(hits, function(a, b)
		return a.Distance < b.Distance
	end)
	local ids = {}
	for index = 1, math.min(maxTargets, #hits) do
		ids[index] = hits[index].Id
	end
	return ids
end

function EnemyService.clear()
	table.clear(enemies)
	table.clear(pendingUpdates)
	pendingSpawns = {}
	pendingHits = {}
	pendingDeaths = {}
	aliveCount = 0
	chaserCount = 0
	shownBoss = nil
	GameState.set("BossName", "")
	Remotes.EnemiesCleared:FireAllClients()
end

-- Para jugadores que entran a mitad de una oleada
function EnemyService.getSnapshot()
	local snapshot = {}
	for id, enemy in enemies do
		local path = enemy.Path
		table.insert(snapshot, { id, enemy.Type, path.Points, path.Speed, path.SpawnTime })
	end
	return snapshot
end

return EnemyService
