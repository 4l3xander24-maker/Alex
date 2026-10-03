-- Todos los números del juego en un solo lugar para balancear fácil.
local Config = {}

-- Paleta y hora del mapa:
--   "Medieval" → noche medieval con luna, velas, antorchas y árboles secos
--   "Otono"    → atardecer dorado de otoño (árboles naranjas, camino de adoquines)
--   "Verde", "Morado", "Ambar" → de noche con luna enorme
Config.Theme = "Medieval"

-- Night: de noche (luna) o de día (sol bajo). Foliage: colores de las copas
-- de los árboles (si no hay, solo pinos). LeafLitter: color de las manchas
-- de hojas caídas en el suelo.
Config.Themes = {
	Medieval = {
		Night = true,
		Medieval = true, -- velas, antorchas, casas y ruinas
		DeadTrees = true, -- mezcla pinos con árboles secos
		Brightness = 1.5,
		Ground = Color3.fromRGB(58, 84, 54),
		LeafLitter = Color3.fromRGB(84, 70, 48),
		Tree = Color3.fromRGB(30, 62, 50),
		Mountain = Color3.fromRGB(42, 50, 76),
		Atmosphere = Color3.fromRGB(86, 96, 150),
		Decay = Color3.fromRGB(40, 38, 74),
		Density = 0.36,
		Haze = 1.7,
		Tint = Color3.fromRGB(226, 222, 255),
		Ambient = Color3.fromRGB(70, 72, 105),
	},
	Otono = {
		Night = false,
		ClockTime = 17.4,
		Brightness = 2.6,
		Ground = Color3.fromRGB(104, 122, 52),
		LeafLitter = Color3.fromRGB(196, 110, 40),
		Tree = Color3.fromRGB(44, 86, 56),
		Foliage = {
			Color3.fromRGB(222, 104, 34),
			Color3.fromRGB(238, 156, 44),
			Color3.fromRGB(196, 62, 34),
			Color3.fromRGB(246, 196, 70),
			Color3.fromRGB(170, 120, 40),
		},
		Mountain = Color3.fromRGB(110, 124, 150),
		Atmosphere = Color3.fromRGB(255, 205, 160),
		Decay = Color3.fromRGB(150, 110, 100),
		Density = 0.28,
		Haze = 1.4,
		Tint = Color3.fromRGB(255, 242, 225),
		Ambient = Color3.fromRGB(120, 100, 90),
	},
	Verde = {
		Night = true,
		Brightness = 1.4,
		Ground = Color3.fromRGB(46, 96, 60),
		LeafLitter = Color3.fromRGB(56, 110, 64),
		Tree = Color3.fromRGB(28, 80, 64),
		Mountain = Color3.fromRGB(30, 70, 66),
		Atmosphere = Color3.fromRGB(80, 150, 128),
		Decay = Color3.fromRGB(30, 76, 66),
		Density = 0.36,
		Haze = 1.8,
		Tint = Color3.fromRGB(205, 255, 232),
		Ambient = Color3.fromRGB(60, 100, 90),
	},
	Morado = {
		Night = true,
		Brightness = 1.4,
		Ground = Color3.fromRGB(92, 52, 80),
		LeafLitter = Color3.fromRGB(110, 60, 90),
		Tree = Color3.fromRGB(58, 36, 72),
		Mountain = Color3.fromRGB(60, 40, 80),
		Atmosphere = Color3.fromRGB(150, 90, 160),
		Decay = Color3.fromRGB(70, 40, 90),
		Density = 0.36,
		Haze = 1.8,
		Tint = Color3.fromRGB(255, 220, 255),
		Ambient = Color3.fromRGB(95, 70, 110),
	},
	Ambar = {
		Night = true,
		Brightness = 1.4,
		Ground = Color3.fromRGB(70, 82, 48),
		LeafLitter = Color3.fromRGB(150, 100, 50),
		Tree = Color3.fromRGB(60, 60, 40),
		Mountain = Color3.fromRGB(90, 70, 50),
		Atmosphere = Color3.fromRGB(200, 150, 100),
		Decay = Color3.fromRGB(120, 80, 50),
		Density = 0.36,
		Haze = 1.8,
		Tint = Color3.fromRGB(255, 235, 205),
		Ambient = Color3.fromRGB(110, 95, 70),
	},
}

-- Cómo se dibujan los zombis:
--   "3D"    → muñecos 3D con materiales y animación de caminar (va con los gráficos realistas)
--   "Pixel" → sprites pixelados (necesita subir las imágenes, ver README)
Config.ZombieStyle = "3D"

-- Optimización en el cliente
Config.Graphics = {
	CullBehindDistance = 40, -- zombis detrás de la cámara a más de esto no se mueven en pantalla
	AnimateDistance = 120, -- más lejos que esto no se anima caminar
	FarDistance = 170, -- más lejos que esto se actualizan cada 3 cuadros
	DeathFxDistance = 150, -- más lejos que esto mueren sin reventar en cubitos
}

-- El campanario está en el origen. El campamento queda detrás (+Z), al
-- borde de un acantilado sobre el mar, y los zombis llegan del bosque (-Z).
Config.Arena = {
	GroundSize = 1400,
	TowerSize = 14,
	TowerHeight = 6,
	StopRadius = 9, -- distancia a la campana donde se paran a golpear
	StopJitter = 3,
	CampCenter = Vector3.new(0, 0, 38),
	CampRadius = 34,
	CliffZ = 82, -- borde del acantilado
	SeaLevel = -50,
	FallKillY = -30, -- si caes por debajo de esta altura, te lleva el mar
}

-- Caminos por donde llegan los zombis a la campana (de lejos a cerca; el
-- último tramo siempre termina en la campana). Casi todos van por el
-- principal; Weight es la probabilidad de cada uno. Los jefes voladores no
-- usan caminos: van en línea recta por el aire.
Config.Paths = {
	Main = {
		Name = "Camino del cementerio",
		Weight = 0.75,
		Points = {
			Vector3.new(-30, 0, -245),
			Vector3.new(-55, 0, -195),
			Vector3.new(-40, 0, -150),
			Vector3.new(5, 0, -120),
			Vector3.new(30, 0, -85),
			Vector3.new(15, 0, -50),
			Vector3.new(0, 0, -25),
		},
	},
	Side = {
		Name = "Camino de las ruinas",
		Weight = 0.25,
		Points = {
			Vector3.new(190, 0, -150),
			Vector3.new(150, 0, -140),
			Vector3.new(120, 0, -100),
			Vector3.new(85, 0, -75),
			Vector3.new(55, 0, -40),
			Vector3.new(24, 0, -16),
		},
	},
}
Config.PathOrder = { "Main", "Side" }
Config.PathStyle = {
	Width = 8, -- camino angosto de tierra
	Lane = 2.5, -- cuánto se puede desviar cada zombi del centro del camino
}

-- Antes de cada partida hay una fase de preparación: es el único momento en
-- que se puede comprar. Empieza al tocar la campana o al acabarse el tiempo.
Config.Match = {
	LobbyTime = 120,
	StartCountdown = 5,
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
-- Si está vacío se usa el modelo 3D de bloques.
-- Size: ancho y alto en studs. Los jefes miden unas 6 veces un zombi común.
-- Model: "Zombie", "Fat" (gordo) o "Dragon". Hat: "Cone", "Helmet" o "Crown".
-- DamagePerSecond es contra la campana; PlayerDamage contra los jugadores.
-- Flying: vuela recto a la campana (no usa caminos, ignora rejas y minas).
-- SpawnOnDeath: al morir suelta zombis más chicos.
Config.Enemies = {
	Walker = {
		DisplayName = "Zombi",
		MaxHealth = 3,
		Speed = 7,
		DamagePerSecond = 2,
		PlayerDamage = 12,
		Coins = 1,
		Size = Vector2.new(3.6, 5),
		HitRadius = 1.8,
		Sprite = "",
		Model = "Zombie",
		Skin = Color3.fromRGB(104, 186, 64),
		Shirt = Color3.fromRGB(232, 232, 222),
		Pants = Color3.fromRGB(46, 92, 168),
		Eyes = Color3.fromRGB(255, 255, 255),
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
		Model = "Zombie",
		Hunch = 0.35, -- va más encorvado
		Skin = Color3.fromRGB(70, 160, 70),
		Shirt = Color3.fromRGB(58, 140, 60), -- sin camisa
		Pants = Color3.fromRGB(70, 74, 120),
		Eyes = Color3.fromRGB(255, 255, 255),
	},
	Cone = {
		DisplayName = "Zombi con cono",
		MaxHealth = 7,
		Speed = 6.5,
		DamagePerSecond = 2,
		PlayerDamage = 12,
		Coins = 2,
		Size = Vector2.new(3.6, 5),
		HitRadius = 1.8,
		Sprite = "",
		SpriteSize = Vector2.new(3.6, 6.5), -- el sprite incluye el cono
		Model = "Zombie",
		Hat = "Cone",
		Skin = Color3.fromRGB(120, 196, 72),
		Shirt = Color3.fromRGB(236, 236, 228),
		Pants = Color3.fromRGB(40, 100, 180),
		Eyes = Color3.fromRGB(255, 255, 255),
	},
	Knight = {
		DisplayName = "Caballero zombi",
		MaxHealth = 10,
		Speed = 5.5,
		DamagePerSecond = 4,
		PlayerDamage = 18,
		Coins = 3,
		Size = Vector2.new(3.8, 5.3),
		HitRadius = 1.9,
		Sprite = "",
		Model = "Zombie",
		Hat = "Helmet",
		Armor = true,
		Skin = Color3.fromRGB(96, 150, 70),
		Shirt = Color3.fromRGB(120, 36, 40), -- túnica
		Pants = Color3.fromRGB(60, 56, 64),
		Eyes = Color3.fromRGB(255, 70, 50),
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
		Model = "Fat",
		Skin = Color3.fromRGB(130, 176, 70),
		Shirt = Color3.fromRGB(214, 206, 180),
		Pants = Color3.fromRGB(86, 66, 52),
		Eyes = Color3.fromRGB(255, 255, 255),
	},
	-- Jefes (6 veces más grandes que un zombi común)
	Fatso = {
		DisplayName = "Zombi Gordo",
		Icon = "🤢",
		MaxHealth = 150,
		Speed = 2.6,
		DamagePerSecond = 25,
		PlayerDamage = 60,
		Coins = 30,
		IsBoss = true,
		Size = Vector2.new(26, 30),
		HitRadius = 11,
		Sprite = "",
		Model = "Fat",
		SpawnOnDeath = { Type = "Walker", Count = 8 },
		Skin = Color3.fromRGB(150, 186, 80),
		Shirt = Color3.fromRGB(210, 200, 170),
		Pants = Color3.fromRGB(80, 60, 90),
		Eyes = Color3.fromRGB(255, 255, 255),
	},
	King = {
		DisplayName = "Rey Zombi",
		Icon = "👑",
		MaxHealth = 220,
		Speed = 3,
		DamagePerSecond = 30,
		PlayerDamage = 80,
		Coins = 45,
		IsBoss = true,
		Size = Vector2.new(20, 30),
		HitRadius = 8,
		Sprite = "",
		Model = "Zombie",
		Hat = "Crown",
		Cape = true,
		Skin = Color3.fromRGB(110, 160, 96),
		Shirt = Color3.fromRGB(96, 40, 120), -- túnica real
		Pants = Color3.fromRGB(44, 36, 54),
		Eyes = Color3.fromRGB(255, 200, 60),
	},
	Dragon = {
		DisplayName = "Dragón Zombi",
		Icon = "🐉",
		MaxHealth = 300,
		Speed = 5,
		DamagePerSecond = 40,
		PlayerDamage = 0,
		Coins = 60,
		IsBoss = true,
		Flying = true,
		FlyHeight = 30, -- altura del centro del cuerpo
		Size = Vector2.new(48, 24),
		HitRadius = 12,
		Sprite = "",
		Model = "Dragon",
		Skin = Color3.fromRGB(92, 120, 84),
		Shirt = Color3.fromRGB(220, 212, 186), -- huesos
		Pants = Color3.fromRGB(58, 62, 56), -- alas
		Eyes = Color3.fromRGB(120, 255, 120),
	},
}

Config.Waves = {
	FirstIntermission = 5,
	Intermission = 12,
	FirstWaveCount = 15,
	CountGrowth = 1.25, -- cada oleada trae 25% más zombis
	FirstSpawnRate = 3, -- zombis por segundo
	SpawnRateGrowth = 1.2,
	MaxSpawnRate = 30,
	MaxAlive = 300,
	HealthGrowth = 0.12, -- +12% de vida por oleada
	BossEvery = 5, -- jefes cada 5 oleadas
	-- Orden de los jefes: oleada 5 el Gordo, 10 el Rey, 15 el Dragón... y en
	-- las siguientes vienen varios juntos (uno más cada 5 oleadas)
	Bosses = { "Fatso", "King", "Dragon" },
	BossSpacing = 6, -- segundos entre un jefe y el siguiente
	GameOverDelay = 12,
	-- Desde qué oleada aparece cada tipo y qué tan seguido
	Mix = {
		{ Type = "Walker", FromWave = 1, Weight = 1 },
		{ Type = "Runner", FromWave = 2, Weight = 0.35 },
		{ Type = "Cone", FromWave = 2, Weight = 0.25 },
		{ Type = "Brute", FromWave = 3, Weight = 0.12 },
		{ Type = "Knight", FromWave = 4, Weight = 0.15 },
	},
}

-- Armas que vende el Armero. Zoom solo se usa con el talento Puntería.
-- StartReserve: balas de reserva al empezar la partida.
-- MaxReserve: máximo de balas de reserva (lo sube la cartuchera del Intendente).
-- AmmoPerKill: balas que ganas por cada zombi eliminado con esa arma en la mano.
Config.Weapons = {
	Machete = {
		DisplayName = "Machete",
		Icon = "🔪",
		Price = 0,
		Melee = true,
		Damage = 3,
		FireRate = 2.2, -- golpes por segundo
		Range = 7,
		Arc = 70, -- grados frente al jugador que cubre el tajo
		MaxTargets = 3,
		Zoom = 1,
	},
	Pistol = {
		DisplayName = "Pistola",
		Icon = "🔫",
		Price = 0,
		Damage = 1,
		FireRate = 5,
		Magazine = 12,
		StartReserve = 36,
		MaxReserve = 96,
		AmmoPerKill = 3,
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
		StartReserve = 18,
		MaxReserve = 48,
		AmmoPerKill = 2,
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
		StartReserve = 60,
		MaxReserve = 240,
		AmmoPerKill = 6,
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
		StartReserve = 10,
		MaxReserve = 30,
		AmmoPerKill = 1,
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
		StartReserve = 240,
		MaxReserve = 720,
		AmmoPerKill = 15,
		ReloadTime = 4.5,
		Range = 350,
		Pellets = 1,
		Spread = 0.04,
		Pierce = 1,
		Zoom = 1.3,
	},
}
Config.WeaponOrder = { "Machete", "Pistol", "Shotgun", "Rifle", "Sniper", "Minigun" }

-- Mejoras de arma en el Armero (por nivel de mejora)
Config.WeaponUpgrade = {
	MaxLevel = 5,
	DamagePerLevel = 0.2,
	MagazinePerLevel = 0.15,
	ReloadPerLevel = 0.06,
	BaseCost = 150, -- el costo crece con el precio del arma y el nivel
}

-- El arma cambia de color con cada mejora para que se note que es más fuerte.
-- Main pinta el cuerpo del arma y Accent los detalles; Glow hace brillar los detalles.
Config.WeaponTiers = {
	{ Name = "Normal", Main = Color3.fromRGB(48, 48, 54), Accent = Color3.fromRGB(125, 128, 138) },
	{ Name = "Bronce", Main = Color3.fromRGB(120, 72, 40), Accent = Color3.fromRGB(205, 127, 50) },
	{ Name = "Plata", Main = Color3.fromRGB(150, 155, 165), Accent = Color3.fromRGB(225, 230, 240) },
	{ Name = "Oro", Main = Color3.fromRGB(190, 140, 30), Accent = Color3.fromRGB(255, 215, 90) },
	{ Name = "Esmeralda", Main = Color3.fromRGB(20, 110, 70), Accent = Color3.fromRGB(80, 255, 160), Glow = true },
	{ Name = "Legendaria", Main = Color3.fromRGB(70, 20, 110), Accent = Color3.fromRGB(200, 90, 255), Glow = true },
}

-- Cartuchera del Intendente: sube el máximo de balas y las balas iniciales
Config.AmmoStorage = {
	MaxLevel = 8,
	PerLevel = 0.25,
	Prices = { 100, 180, 280, 400, 550, 750, 1000, 1300 },
}

-- Trampas que vende el Intendente. Duran solo una partida.
Config.Traps = {
	Mine = {
		DisplayName = "Mina",
		Icon = "🪤",
		Price = 40,
		MaxPerMatch = 8,
		Damage = 12, -- crece con la oleada igual que la vida de los zombis
		Radius = 10,
		TriggerRadius = 3,
		-- Lugares donde se entierran: camino y distancia a la campana por el camino
		Spots = {
			{ "Main", 50 }, { "Main", 72 }, { "Main", 96 }, { "Main", 125 }, { "Main", 160 },
			{ "Side", 55 }, { "Side", 85 }, { "Side", 120 },
		},
	},
	Gate = {
		DisplayName = "Reja",
		Icon = "🚧",
		Price = 150,
		Health = 800,
		-- Una reja cruzada en cada camino. At: distancia a la campana por el camino
		Slots = {
			Main = { Name = "Reja del cementerio", Short = "Cementerio", Path = "Main", At = 36, Width = 16 },
			Side = { Name = "Reja de las ruinas", Short = "Ruinas", Path = "Side", At = 36, Width = 16 },
		},
		SlotOrder = { "Main", "Side" },
	},
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
