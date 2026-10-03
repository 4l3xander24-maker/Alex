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
