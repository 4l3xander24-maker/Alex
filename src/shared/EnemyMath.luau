-- Los zombis caminan en línea recta hacia la campana. Como el movimiento es
-- determinista, servidor y clientes calculan la misma posición a partir del
-- tiempo del servidor sin tener que replicar posiciones cada frame.
-- Para empujarlos hacia atrás basta con cambiar SpawnTime.
local EnemyMath = {}

export type Path = {
	Start: Vector3,
	Direction: Vector3,
	Distance: number,
	Speed: number,
	SpawnTime: number,
}

function EnemyMath.newPath(start: Vector3, target: Vector3, speed: number, spawnTime: number): Path
	local offset = target - start
	local distance = offset.Magnitude
	return {
		Start = start,
		Direction = if distance > 0 then offset / distance else Vector3.zero,
		Distance = distance,
		Speed = speed,
		SpawnTime = spawnTime,
	}
end

function EnemyMath.getTarget(path: Path): Vector3
	return path.Start + path.Direction * path.Distance
end

function EnemyMath.getTraveled(path: Path, now: number): number
	return math.clamp((now - path.SpawnTime) * path.Speed, 0, path.Distance)
end

function EnemyMath.getPosition(path: Path, now: number): Vector3
	return path.Start + path.Direction * EnemyMath.getTraveled(path, now)
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
