-- Los zombis caminan por una línea quebrada (una lista de puntos) a velocidad
-- constante. Como el movimiento es determinista, servidor y clientes calculan
-- la misma posición a partir del tiempo del servidor sin tener que replicar
-- posiciones cada frame. Para empujarlos hacia atrás basta con cambiar SpawnTime.
local EnemyMath = {}

export type Path = {
	Points: { Vector3 },
	Ends: { number }, -- distancia recorrida al final de cada tramo
	Distance: number,
	Speed: number,
	SpawnTime: number,
}

function EnemyMath.newRoute(points: { Vector3 }, speed: number, spawnTime: number): Path
	local ends = {}
	local total = 0
	for index = 2, #points do
		total += (points[index] - points[index - 1]).Magnitude
		ends[index - 1] = total
	end
	return {
		Points = points,
		Ends = ends,
		Distance = total,
		Speed = speed,
		SpawnTime = spawnTime,
	}
end

-- Camino de un solo tramo en línea recta
function EnemyMath.newPath(start: Vector3, target: Vector3, speed: number, spawnTime: number): Path
	return EnemyMath.newRoute({ start, target }, speed, spawnTime)
end

function EnemyMath.getTarget(path: Path): Vector3
	return path.Points[#path.Points]
end

function EnemyMath.getTraveled(path: Path, now: number): number
	return math.clamp((now - path.SpawnTime) * path.Speed, 0, path.Distance)
end

-- Posición y dirección después de recorrer `traveled` studs
function EnemyMath.locate(path: Path, traveled: number): (Vector3, Vector3)
	local points, ends = path.Points, path.Ends
	local segmentStart = 0
	for index, segmentEnd in ends do
		if traveled <= segmentEnd or index == #ends then
			local from, to = points[index], points[index + 1]
			local length = segmentEnd - segmentStart
			if length < 1e-6 then
				return to, Vector3.zero
			end
			local direction = (to - from) / length
			return from + direction * math.min(traveled - segmentStart, length), direction
		end
		segmentStart = segmentEnd
	end
	return points[1], Vector3.zero
end

function EnemyMath.getPosition(path: Path, now: number): Vector3
	local position = EnemyMath.locate(path, EnemyMath.getTraveled(path, now))
	return position
end

function EnemyMath.getDirection(path: Path, now: number): Vector3
	local _, direction = EnemyMath.locate(path, EnemyMath.getTraveled(path, now))
	return direction
end

function EnemyMath.hasArrived(path: Path, now: number): boolean
	return (now - path.SpawnTime) * path.Speed >= path.Distance
end

-- SpawnTime que deja al enemigo `seconds` de camino más atrás que ahora
function EnemyMath.pushedBackSpawnTime(path: Path, now: number, seconds: number): number
	local traveled = math.max(0, EnemyMath.getTraveled(path, now) - path.Speed * seconds)
	return now - traveled / path.Speed
end

return EnemyMath
