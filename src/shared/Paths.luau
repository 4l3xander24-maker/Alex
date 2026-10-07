-- Geometría de los caminos de los zombis (Config.Paths). La usan el servidor
-- (rutas, minas, rejas, mapa) y el cliente.
local Config = require(script.Parent.Config)

local Paths = {}

local BELL = Vector3.zero

-- Puntos del camino de lejos a cerca, terminando en la campana
function Paths.getPoints(name: string): { Vector3 }
	local points = table.clone(Config.Paths[name].Points)
	table.insert(points, BELL)
	return points
end

-- Elige un camino al azar según su Weight
function Paths.pick(random: Random): string
	local total = 0
	for _, name in Config.PathOrder do
		total += Config.Paths[name].Weight
	end
	local roll = random:NextNumber(0, total)
	for _, name in Config.PathOrder do
		roll -= Config.Paths[name].Weight
		if roll <= 0 then
			return name
		end
	end
	return Config.PathOrder[1]
end

-- Punto del camino a `distance` studs de la campana (medido por el camino) y
-- la dirección del camino ahí (hacia la campana)
function Paths.pointFromBell(name: string, distance: number): (Vector3, Vector3)
	local points = Paths.getPoints(name)
	local remaining = distance
	for index = #points, 2, -1 do
		local near, far = points[index], points[index - 1]
		local length = (far - near).Magnitude
		if remaining <= length or index == 2 then
			local direction = (near - far).Unit
			return near - direction * math.min(remaining, length), direction
		end
		remaining -= length
	end
	return points[1], Vector3.new(0, 0, 1)
end

-- Distancia sobre el suelo de un punto al tramo a-b
function Paths.segmentDistance(point: Vector3, a: Vector3, b: Vector3): number
	local abx, abz = b.X - a.X, b.Z - a.Z
	local apx, apz = point.X - a.X, point.Z - a.Z
	local lengthSquared = abx * abx + abz * abz
	local t = if lengthSquared > 0 then math.clamp((apx * abx + apz * abz) / lengthSquared, 0, 1) else 0
	local dx, dz = apx - abx * t, apz - abz * t
	return math.sqrt(dx * dx + dz * dz)
end

-- Tierra firme: el bosque al norte del canal y las islas del sur (todo lo
-- demás es agua, abajo de los acantilados). Los zombis solo pisan el bosque,
-- el puente de piedra y la isla principal: nunca van a la aldea.

-- true si el punto está dentro de la isla (con `margin` studs hacia adentro)
function Paths.onIsland(point: Vector3, name: string, margin: number?): boolean
	local inset = margin or 0
	local island = Config.Arena.Islands[name]
	if name == "Main" and point.Z > Config.Arena.CliffZ - inset then
		return false
	end
	for _, box in island.Boxes do
		if math.abs(point.X - box.Center.X) <= box.Size.X / 2 - inset and math.abs(point.Z - box.Center.Y) <= box.Size.Y / 2 - inset then
			return true
		end
	end
	for _, disk in island.Disks do
		local dx, dz = point.X - disk.Center.X, point.Z - disk.Center.Y
		if dx * dx + dz * dz <= (disk.Radius - inset) ^ 2 then
			return true
		end
	end
	return false
end

-- true si está en el bosque, del lado norte del canal
function Paths.onNorthLand(point: Vector3, margin: number?): boolean
	return point.Z <= Config.Arena.Ravine.ZMin - (margin or 0)
end

-- true si es tierra firme (sin contar los puentes)
function Paths.isGround(point: Vector3, margin: number?): boolean
	if Paths.onNorthLand(point, margin) then
		return true
	end
	for name in Config.Arena.Islands do
		if Paths.onIsland(point, name, margin) then
			return true
		end
	end
	return false
end

-- Distancia al eje de un puente {From, To} y cuánto se avanzó sobre él (0 a 1)
local function bridgeOffset(bridge, point: Vector3): (number, number)
	local from, to = bridge.From, bridge.To
	local dx, dz = to.X - from.X, to.Z - from.Z
	local length = math.sqrt(dx * dx + dz * dz)
	local ux, uz = dx / length, dz / length
	local px, pz = point.X - from.X, point.Z - from.Z
	return math.abs(px * uz - pz * ux), (px * ux + pz * uz) / length
end

-- true si el punto está sobre el puente de piedra (sin contar los muros)
function Paths.onBridge(point: Vector3): boolean
	local bridge = Config.Arena.Bridge
	local across, along = bridgeOffset(bridge, point)
	return across <= bridge.Width / 2 - 1 and along >= -0.02 and along <= 1.02
end

-- Donde pueden caminar los zombis: el bosque, el puente de piedra y la isla principal
function Paths.isEnemyGround(point: Vector3): boolean
	return Paths.onNorthLand(point) or Paths.onBridge(point) or Paths.onIsland(point, "Main")
end

local STEP = 2.5

-- true si ir en línea recta de a hasta b obliga a pasar por el agua (los
-- zombis no pueden: se caerían). Se revisa cada pocos studs.
function Paths.crossesChasm(a: Vector3, b: Vector3): boolean
	local offset = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local steps = math.max(1, math.ceil(offset.Magnitude / STEP))
	for index = 0, steps do
		if not Paths.isEnemyGround(a + offset * (index / steps)) then
			return true
		end
	end
	return false
end

-- El punto más lejos de `from` hacia `to` al que se llega sin pisar el agua
function Paths.lastWalkable(from: Vector3, to: Vector3): Vector3
	local offset = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	local steps = math.max(1, math.ceil(offset.Magnitude / STEP))
	local best = from
	for index = 1, steps do
		local point = from + offset * (index / steps)
		if not Paths.isEnemyGround(point) then
			break
		end
		best = point
	end
	return Vector3.new(best.X, to.Y, best.Z)
end

-- Distancia al camino más cercano (para no poner árboles encima)
function Paths.distanceToAny(point: Vector3): number
	local best = math.huge
	for _, name in Config.PathOrder do
		local points = Paths.getPoints(name)
		for index = 2, #points do
			best = math.min(best, Paths.segmentDistance(point, points[index - 1], points[index]))
		end
	end
	return best
end

return Paths
