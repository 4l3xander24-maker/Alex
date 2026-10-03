-- Todos los números del juego en un solo lugar para balancear fácil.
local Config = {}

Config.Arena = {
	GroundSize = 700,
	CastleWidth = 90,
	CastleHeight = 20,
	CastleDepth = 16,
	SpawnZ = -220,
	SpawnHalfWidth = 80,
	-- Los zombis se detienen justo frente al muro (el frente está en z = -CastleDepth / 2)
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
	Zombie = {
		MaxHealth = 3,
		Speed = 7, -- lentos pero muchos
		DamagePerSecond = 2, -- daño al castillo cuando llega al muro
		Gold = 1,
		Size = Vector3.new(2, 5, 1.2), -- caja total del cuerpo
		HitRadius = 1.8, -- esfera de impacto centrada en el torso
		Skin = Color3.fromRGB(122, 150, 104),
		Shirt = Color3.fromRGB(70, 82, 110),
		Pants = Color3.fromRGB(58, 48, 40),
	},
}

Config.Waves = {
	Intermission = 8,
	FirstWaveCount = 15,
	CountGrowth = 1.3, -- cada oleada trae 30% más zombis
	FirstSpawnRate = 4, -- zombis por segundo
	SpawnRateGrowth = 1.5,
	MaxSpawnRate = 40,
	MaxAlive = 300,
	HealthGrowth = 0.15, -- +15% de vida por oleada
	GameOverDelay = 8,
}

Config.Anticheat = {
	MaxOriginDistance = 12, -- distancia máxima entre la cabeza y el origen del disparo
	FireRateTolerance = 0.5,
	MaxRewind = 0.25, -- segundos de compensación de lag
}

return Config
