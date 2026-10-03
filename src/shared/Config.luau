-- Todos los números del juego en un solo lugar para balancear fácil.
local Config = {}

-- Paleta del mapa: "Verde", "Morado" o "Ambar"
Config.Theme = "Verde"

Config.Themes = {
	Verde = {
		Ground = Color3.fromRGB(46, 96, 60),
		Tree = Color3.fromRGB(28, 80, 64),
		Mountain = Color3.fromRGB(30, 70, 66),
		Atmosphere = Color3.fromRGB(80, 150, 128),
		Decay = Color3.fromRGB(30, 76, 66),
		Tint = Color3.fromRGB(205, 255, 232),
		Ambient = Color3.fromRGB(60, 100, 90),
	},
	Morado = {
		Ground = Color3.fromRGB(92, 52, 80),
		Tree = Color3.fromRGB(58, 36, 72),
		Mountain = Color3.fromRGB(60, 40, 80),
		Atmosphere = Color3.fromRGB(150, 90, 160),
		Decay = Color3.fromRGB(70, 40, 90),
		Tint = Color3.fromRGB(255, 220, 255),
		Ambient = Color3.fromRGB(95, 70, 110),
	},
	Ambar = {
		Ground = Color3.fromRGB(70, 82, 48),
		Tree = Color3.fromRGB(60, 60, 40),
		Mountain = Color3.fromRGB(90, 70, 50),
		Atmosphere = Color3.fromRGB(200, 150, 100),
		Decay = Color3.fromRGB(120, 80, 50),
		Tint = Color3.fromRGB(255, 235, 205),
		Ambient = Color3.fromRGB(110, 95, 70),
	},
}

Config.Arena = {
	GroundSize = 1400,
	TowerSize = 18, -- plataforma del campanario donde están los jugadores
	TowerHeight = 6,
	SpawnRadius = 210,
	SpawnArc = 140, -- grados de frente (-Z) por donde llegan los zombis
	StopRadius = 11, -- distancia a la campana donde se paran a golpear
	StopJitter = 3,
}

Config.Bell = {
	MaxHealth = 600,
}

Config.Weapon = {
	Name = "Pistola",
	Damage = 1,
	FireRate = 5, -- disparos por segundo
	Magazine = 12,
	ReloadTime = 1.4,
	Range = 450,
	Pellets = 1,
	Spread = 0.012, -- radianes
	Pierce = 0, -- zombis extra que atraviesa cada bala
	CritChance = 0.05,
	CritMultiplier = 2,
}

-- Sprite: pega aquí el id de la imagen subida a Roblox ("rbxassetid://123...").
-- Si está vacío se usa un modelo de bloques como reemplazo.
-- Size: ancho y alto del sprite en studs (respeta la proporción de la imagen).
Config.Enemies = {
	Walker = {
		DisplayName = "Caminante",
		MaxHealth = 3,
		Speed = 7,
		DamagePerSecond = 2,
		Coins = 1,
		Xp = 1,
		Size = Vector2.new(3.6, 5),
		HitRadius = 1.8,
		Sprite = "",
		Skin = Color3.fromRGB(128, 168, 112),
		Shirt = Color3.fromRGB(72, 92, 138),
		Pants = Color3.fromRGB(82, 66, 54),
	},
	Runner = {
		DisplayName = "Corredor",
		MaxHealth = 2,
		Speed = 13,
		DamagePerSecond = 1,
		Coins = 1,
		Xp = 1,
		Size = Vector2.new(3.05, 4.4),
		HitRadius = 1.6,
		Sprite = "",
		Skin = Color3.fromRGB(160, 172, 150),
		Shirt = Color3.fromRGB(150, 50, 46),
		Pants = Color3.fromRGB(60, 66, 80),
	},
	Brute = {
		DisplayName = "Bruto",
		MaxHealth = 14,
		Speed = 4.5,
		DamagePerSecond = 6,
		Coins = 4,
		Xp = 4,
		Size = Vector2.new(6.5, 7),
		HitRadius = 3,
		Sprite = "",
		Skin = Color3.fromRGB(150, 160, 90),
		Shirt = Color3.fromRGB(190, 180, 150),
		Pants = Color3.fromRGB(70, 60, 80),
	},
	Giant = {
		DisplayName = "Abominación",
		MaxHealth = 120,
		Speed = 3,
		DamagePerSecond = 25,
		Coins = 30,
		Xp = 30,
		Size = Vector2.new(14, 15),
		HitRadius = 6.5,
		Sprite = "",
		Skin = Color3.fromRGB(130, 100, 140),
		Shirt = Color3.fromRGB(110, 30, 40),
		Pants = Color3.fromRGB(40, 40, 50),
	},
}

Config.Waves = {
	Intermission = 10,
	FirstWaveCount = 15,
	CountGrowth = 1.25, -- cada oleada trae 25% más zombis
	FirstSpawnRate = 3, -- zombis por segundo
	SpawnRateGrowth = 1.2,
	MaxSpawnRate = 30,
	MaxAlive = 300,
	HealthGrowth = 0.12, -- +12% de vida por oleada
	BossEvery = 5, -- una Abominación cada 5 oleadas
	GameOverDelay = 10,
	-- Desde qué oleada aparece cada tipo y qué tan seguido
	Mix = {
		{ Type = "Walker", FromWave = 1, Weight = 1 },
		{ Type = "Runner", FromWave = 2, Weight = 0.35 },
		{ Type = "Brute", FromWave = 3, Weight = 0.12 },
	},
}

Config.Progression = {
	XpBase = 6, -- XP para pasar del nivel 1 al 2
	XpGrowth = 1.25, -- cada nivel pide 25% más XP
	ChoicesPerLevel = 3,
}

-- Poderes: se desbloquean como mejora al subir de nivel
Config.Powers = {
	Grenade = {
		DisplayName = "Granada",
		Icon = "💣",
		Key = Enum.KeyCode.Q,
		Cooldown = 8,
		Damage = 6,
		Radius = 12,
		Range = 140,
		FlightTime = 0.6,
	},
	Chain = {
		DisplayName = "Rayo",
		Icon = "🌩️",
		Key = Enum.KeyCode.E,
		Cooldown = 7,
		Damage = 5,
		Targets = 5,
		JumpRange = 22,
	},
	Bell = {
		DisplayName = "Campanazo",
		Icon = "🔔",
		Key = Enum.KeyCode.F,
		Cooldown = 25,
		Damage = 2,
		Radius = 70,
		KnockbackSeconds = 4, -- los zombis retroceden lo que caminan en este tiempo
	},
}
Config.PowerOrder = { "Grenade", "Chain", "Bell" }

Config.Anticheat = {
	MaxOriginDistance = 12, -- distancia máxima entre la cabeza y el origen del disparo
	FireRateTolerance = 0.5,
	ReloadTolerance = 0.25,
	MaxRewind = 0.25, -- segundos de compensación de lag
}

return Config
