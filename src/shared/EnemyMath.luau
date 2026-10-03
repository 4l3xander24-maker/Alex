-- Los goblins caminan en línea recta hacia el castillo. Como el movimiento es
-- determinista, servidor y clientes calculan la misma posición a partir del
-- tiempo del servidor sin tener que replicar posiciones cada frame.
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

function EnemyMath.getPosition(path: Path, now: number): Vector3
	local traveled = math.clamp((now - path.SpawnTime) * path.Speed, 0, path.Distance)
	return path.Start + path.Direction * traveled
end

function EnemyMath.hasArrived(path: Path, now: number): boolean
	return (now - path.SpawnTime) * path.Speed >= path.Distance
end

return EnemyMath
