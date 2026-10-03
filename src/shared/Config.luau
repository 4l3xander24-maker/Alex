-- Todos los números del juego en un solo lugar para balancear fácil.
local Config = {}

Config.Arena = {
	GroundSize = 700,
	CastleWidth = 90,
	CastleHeight = 20,
	CastleDepth = 16,
	SpawnZ = -280,
	SpawnHalfWidth = 80,
	-- Los goblins se detienen justo frente al muro (el frente está en z = -CastleDepth / 2)
	StopZ = -10,
	StopJitter = 4,
}

Config.Castle = {
	MaxHealth = 500,
}

Config.Weapon = {
	Name = "Pistola",
	Damage = 1,
	FireRate = 6, -- disparos por segundo
	Range = 450,
}

Config.Enemies = {
	Goblin = {
		MaxHealth = 3,
		Speed = 10,
		DamagePerSecond = 2, -- daño al castillo cuando llega al muro
		Gold = 1,
		Size = Vector3.new(2, 3, 2),
		Color = Color3.fromRGB(96, 168, 64),
	},
}

Config.Waves = {
	Intermission = 8,
	FirstWaveCount = 15,
	CountGrowth = 1.3, -- cada oleada trae 30% más goblins
	FirstSpawnRate = 4, -- goblins por segundo
	SpawnRateGrowth = 1.5,
	MaxSpawnRate = 40,
	MaxAlive = 400,
	HealthGrowth = 0.15, -- +15% de vida por oleada
	GameOverDelay = 8,
}

Config.Anticheat = {
	MaxOriginDistance = 12, -- distancia máxima entre la cabeza y el origen del disparo
	FireRateTolerance = 0.5,
	MaxRewind = 0.25, -- segundos de compensación de lag
}

return Config
