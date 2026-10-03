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

-- El campanario está en el origen. El campamento queda detrás (+Z) y los
-- zombis llegan del bosque por delante (-Z).
Config.Arena = {
	GroundSize = 1400,
	TowerSize = 14,
	TowerHeight = 6,
	SpawnRadius = 210,
	SpawnArc = 140, -- grados de frente por donde llegan los zombis
	StopRadius = 9, -- distancia a la campana donde se paran a golpear
	StopJitter = 3,
	CampCenter = Vector3.new(0, 0, 38),
	CampRadius = 34,
}

Config.Bell = {
	MaxHealth = 600,
	RepairAmount = 30, -- con el talento Reparador
	RepairCooldown = 1,
}

-- Cómo se comportan los zombis con los jugadores
Config.Hunt = {
	AggroRadius = 22, -- si pasas a esta distancia, te persiguen
	LeashRadius = 45, -- si te alejas más, vuelven a la campana
	MaxChasers = 40, -- máximo de zombis persiguiendo jugadores a la vez
	MeleeRange = 2.5,
	ThinkInterval = 0.25,
}

Config.Player = {
	MaxHealth = 100,
	WalkSpeed = 16,
	RespawnTime = 5,
}

-- Sprite: pega aquí el id de la imagen subida a Roblox ("rbxassetid://123...").
-- Si está vacío se usa un modelo de bloques como reemplazo.
-- Size: ancho y alto del sprite en studs (respeta la proporción de la imagen).
-- DamagePerSecond es contra la campana; PlayerDamage contra los jugadores.
Config.Enemies = {
	Walker = {
		DisplayName = "Caminante",
		MaxHealth = 3,
		Speed = 7,
		DamagePerSecond = 2,
		PlayerDamage = 12,
		Coins = 1,
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
		PlayerDamage = 8,
		Coins = 1,
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
		PlayerDamage = 30,
		Coins = 4,
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
		PlayerDamage = 70,
		Coins = 30,
		IsBoss = true,
		Size = Vector2.new(14, 15),
		HitRadius = 6.5,
		Sprite = "",
		Skin = Color3.fromRGB(130, 100, 140),
		Shirt = Color3.fromRGB(110, 30, 40),
		Pants = Color3.fromRGB(40, 40, 50),
	},
}

Config.Waves = {
	FirstIntermission = 25, -- tiempo para comprar antes de la primera oleada
	Intermission = 15,
	FirstWaveCount = 15,
	CountGrowth = 1.25, -- cada oleada trae 25% más zombis
	FirstSpawnRate = 3, -- zombis por segundo
	SpawnRateGrowth = 1.2,
	MaxSpawnRate = 30,
	MaxAlive = 300,
	HealthGrowth = 0.12, -- +12% de vida por oleada
	BossEvery = 5, -- una Abominación cada 5 oleadas
	GameOverDelay = 12,
	-- Desde qué oleada aparece cada tipo y qué tan seguido
	Mix = {
		{ Type = "Walker", FromWave = 1, Weight = 1 },
		{ Type = "Runner", FromWave = 2, Weight = 0.35 },
		{ Type = "Brute", FromWave = 3, Weight = 0.12 },
	},
}

-- Armas que vende el Armero. Zoom solo se usa con el talento Puntería.
Config.Weapons = {
	Pistol = {
		DisplayName = "Pistola",
		Icon = "🔫",
		Price = 0,
		Damage = 1,
		FireRate = 5,
		Magazine = 12,
		ReloadTime = 1.4,
		Range = 350,
		Pellets = 1,
		Spread = 0.012,
		Pierce = 0,
		Zoom = 1.3,
	},
	Shotgun = {
		DisplayName = "Escopeta",
		Icon = "💥",
		Price = 300,
		Damage = 0.8,
		FireRate = 1.4,
		Magazine = 6,
		ReloadTime = 2.2,
		Range = 110,
		Pellets = 7,
		Spread = 0.07,
		Pierce = 0,
		Zoom = 1.2,
	},
	Rifle = {
		DisplayName = "Rifle de asalto",
		Icon = "🪖",
		Price = 700,
		Damage = 1.3,
		FireRate = 8,
		Magazine = 30,
		ReloadTime = 1.8,
		Range = 400,
		Pellets = 1,
		Spread = 0.018,
		Pierce = 0,
		Zoom = 1.6,
	},
	Sniper = {
		DisplayName = "Francotirador",
		Icon = "🎯",
		Price = 1000,
		Damage = 9,
		FireRate = 0.9,
		Magazine = 5,
		ReloadTime = 2.6,
		Range = 600,
		Pellets = 1,
		Spread = 0.002,
		Pierce = 4,
		Zoom = 3.5,
	},
	Minigun = {
		DisplayName = "Ametralladora",
		Icon = "⚙️",
		Price = 2000,
		Damage = 1.1,
		FireRate = 15,
		Magazine = 120,
		ReloadTime = 4.5,
		Range = 350,
		Pellets = 1,
		Spread = 0.04,
		Pierce = 1,
		Zoom = 1.3,
	},
}
Config.WeaponOrder = { "Pistol", "Shotgun", "Rifle", "Sniper", "Minigun" }

-- Mejoras de arma en el Armero (por nivel de mejora)
Config.WeaponUpgrade = {
	MaxLevel = 5,
	DamagePerLevel = 0.2,
	MagazinePerLevel = 0.15,
	ReloadPerLevel = 0.06,
	BaseCost = 150, -- el costo crece con el precio del arma y el nivel
}

Config.CritMultiplier = 2
Config.BaseCritChance = 0.05

-- Poderes que vende la Bruja
Config.Powers = {
	Grenade = {
		DisplayName = "Granada",
		Icon = "💣",
		Key = Enum.KeyCode.G,
		Price = 200,
		MaxLevel = 5,
		Cooldown = 8,
		Damage = 6,
		Radius = 12,
		Range = 140,
		FlightTime = 0.6,
		Description = "Lanza una granada que explota en área",
		LevelText = "+50% daño y +15% radio",
	},
	Chain = {
		DisplayName = "Rayo en cadena",
		Icon = "🌩️",
		Key = Enum.KeyCode.Q,
		Price = 400,
		MaxLevel = 5,
		Cooldown = 7,
		Damage = 5,
		Targets = 5,
		JumpRange = 22,
		Description = "Un rayo salta entre varios zombis",
		LevelText = "+2 saltos y +30% daño",
	},
	Bell = {
		DisplayName = "Campanazo",
		Icon = "🔔",
		Key = Enum.KeyCode.F,
		Price = 500,
		MaxLevel = 4,
		Cooldown = 25,
		Damage = 2,
		Radius = 70,
		KnockbackSeconds = 4, -- los zombis retroceden lo que caminan en este tiempo
		Description = "La campana empuja a los zombis cercanos",
		LevelText = "-20% de espera y más empuje",
	},
}
Config.PowerOrder = { "Grenade", "Chain", "Bell" }

-- Nivel de cuenta: la XP se gana al terminar cada partida
Config.Progression = {
	XpBase = 100, -- XP para pasar del nivel 1 al 2
	XpGrowth = 1.15, -- cada nivel pide 15% más
	TalentEvery = 5, -- un punto de talento cada 5 niveles
	XpPerWave = 25,
	XpPerKill = 2,
	XpPerBossKill = 40,
}

-- Un punto por nivel. PerPoint es lo que suma cada punto.
Config.Stats = {
	{ Id = "Damage", Name = "Daño", Icon = "💥", PerPoint = 0.05, Max = 20, Text = "+%d%% de daño", Percent = true },
	{ Id = "Health", Name = "Vida", Icon = "❤️", PerPoint = 10, Max = 20, Text = "+%d de vida máxima" },
	{ Id = "Speed", Name = "Velocidad", Icon = "👟", PerPoint = 0.03, Max = 10, Text = "+%d%% de velocidad al caminar", Percent = true },
	{ Id = "Reload", Name = "Recarga", Icon = "🔄", PerPoint = 0.05, Max = 10, Text = "%d%% menos tiempo de recarga", Percent = true },
	{ Id = "FireRate", Name = "Cadencia", Icon = "⚡", PerPoint = 0.03, Max = 10, Text = "+%d%% de disparos por segundo", Percent = true },
	{ Id = "Ammo", Name = "Munición", Icon = "📦", PerPoint = 0.08, Max = 10, Text = "+%d%% de balas por cargador", Percent = true },
	{ Id = "Crit", Name = "Crítico", Icon = "🎯", PerPoint = 0.02, Max = 10, Text = "+%d%% de probabilidad de crítico", Percent = true },
	{ Id = "Loot", Name = "Botín", Icon = "🪙", PerPoint = 0.05, Max = 10, Text = "+%d%% de monedas", Percent = true },
	{ Id = "Power", Name = "Poder", Icon = "✨", PerPoint = 0.05, Max = 10, Text = "+%d%% de daño de poderes y menos espera", Percent = true },
}

-- Un talento cada 5 niveles. Cada uno se aprende una sola vez.
Config.Talents = {
	{ Id = "Aim", Name = "Puntería", Icon = "🔭", Description = "Mantén clic derecho para apuntar: zoom, -70% de dispersión y +15% de crítico" },
	{ Id = "Sprint", Name = "Correr", Icon = "🏃", Description = "Mantén Shift para correr un 60% más rápido (no puedes disparar mientras corres)" },
	{ Id = "Regen", Name = "Regeneración", Icon = "💚", Description = "Recuperas 8 de vida por segundo si nadie te ataca durante 4 segundos" },
	{ Id = "Vampire", Name = "Vampiro", Icon = "🩸", Description = "Cada zombi que eliminas te cura 3 de vida" },
	{ Id = "DoubleJump", Name = "Doble salto", Icon = "🦘", Description = "Puedes saltar otra vez en el aire" },
	{ Id = "Dash", Name = "Esquivar", Icon = "💨", Description = "Pulsa C para impulsarte hacia adelante (cada 3 segundos)" },
	{ Id = "LastStand", Name = "Último aliento", Icon = "🛡️", Description = "Una vez por oleada, un golpe mortal te deja con 1 de vida y 2 segundos de invulnerabilidad" },
	{ Id = "Explosive", Name = "Balas explosivas", Icon = "🧨", Description = "10% de probabilidad de que una bala explote y dañe a los zombis cercanos" },
	{ Id = "Greed", Name = "Codicia", Icon = "💰", Description = "+25% de monedas por cada zombi" },
	{ Id = "Repair", Name = "Reparador", Icon = "🔧", Description = "Puedes reparar la campana manteniendo E junto a ella" },
}

Config.TalentValues = {
	AimSpread = 0.3,
	AimCrit = 0.15,
	SprintMultiplier = 1.6,
	RegenDelay = 4,
	RegenPerSecond = 8,
	VampireHeal = 3,
	DashSpeed = 80,
	DashTime = 0.18,
	DashCooldown = 3,
	LastStandInvulnerable = 2,
	ExplosiveChance = 0.1,
	ExplosiveRadius = 6,
	ExplosiveDamage = 0.5, -- fracción del daño de la bala
	GreedBonus = 0.25,
}

Config.Anticheat = {
	MaxOriginDistance = 12, -- distancia máxima entre la cabeza y el origen del disparo
	FireRateTolerance = 0.5,
	ReloadTolerance = 0.25,
	MaxRewind = 0.25, -- segundos de compensación de lag
}

return Config
