-- Todos los números del juego en un solo lugar para balancear fácil.
local Config = {}

-- Paleta y hora del mapa:
--   "Medieval" → noche medieval con luna, velas, antorchas y árboles secos
--   "Otono"    → atardecer dorado de otoño (árboles naranjas, camino de adoquines)
--   "OtonoMedieval" → la aldea medieval con día y noche, pero de otoño: árboles
--                      naranjas y dorados, cielo azul y luz cálida (estilo realista)
--   "Verde", "Morado", "Ambar" → de noche con luna enorme
Config.Theme = "OtonoMedieval"

-- Estilo de dibujo del mundo:
--   "Pixel"     → pixel art 3D como Guns 'n Goblins: cubos con texturas pixeladas
--                 (assets/textures, hay que subirlas: ver README), terreno con pasto
--                 3D que se mueve con el viento y enemigos de sprites pixelados
--   "Texturado" → cubos con las texturas normales de Roblox (madera, piedra, hojas)
--   "Voxel"     → pixel art 3D: cubos de colores planos y suelo de baldosas
--   "Realista"  → formas redondas, materiales con textura, desenfoque y fuego de partículas
Config.ArtStyle = "Realista"

-- Qué implica cada estilo: Blocky = bolas y cilindros se vuelven bloques (y el
-- fuego, las nubes y las luciérnagas son de cubitos); Flat = colores planos sin
-- textura; Tiles = suelo de baldosas en vez del terreno de Roblox
-- PixelTextures = usa las texturas pixeladas subidas en lugar de las de Roblox
Config.ArtStyles = {
	Pixel = { Blocky = true, Flat = false, Tiles = false, PixelTextures = true },
	Texturado = { Blocky = true, Flat = false, Tiles = false, PixelTextures = false },
	Voxel = { Blocky = true, Flat = true, Tiles = true, PixelTextures = false },
	Realista = { Blocky = false, Flat = false, Tiles = false, PixelTextures = false },
}
Config.Style = Config.ArtStyles[Config.ArtStyle] or Config.ArtStyles.Realista

-- Árboles y casas con modelos 3D de la Creator Store (src/models) en vez de
-- bloques. Solo en los estilos que no son de cubos (Realista).
Config.UseStoreModels = true

-- Viento: mueve el pasto 3D del terreno, las nubes, los árboles, los arbustos y
-- los estandartes. Cada cliente le agrega ráfagas suaves.
Config.Wind = {
	Direction = Vector3.new(1, 0, 0.35),
	Speed = 9,
	Gusts = 0.5, -- cuánto cambia con las ráfagas (0 = viento parejo)
}

-- Ciclo de día y noche (en los temas que tienen paleta de día, como el medieval).
-- Todos los jugadores ven la misma hora: se calcula con el reloj del servidor.
Config.DayCycle = {
	Enabled = true,
	Length = 1200, -- segundos que dura un día completo (20 minutos)
	StartClock = 10, -- hora del día cuando arranca el servidor
	-- De noche llegan más zombis por segundo (1 = igual que de día)
	NightSpawnMultiplier = 1.3,
	-- Con cada oleada el cielo se pone más rojo: en FullAtWave ya está todo
	-- teñido de sangre (y la luna es roja si subiste MoonRed, ver README)
	BloodMoon = {
		FullAtWave = 15,
		Atmosphere = Color3.fromRGB(150, 50, 46),
		Decay = Color3.fromRGB(96, 24, 32),
		Tint = Color3.fromRGB(255, 176, 166),
		Ambient = Color3.fromRGB(120, 62, 62),
		RedMoonAt = 0.6, -- desde qué tanto rojo se cambia a la luna roja
	},
}

-- Texturas pixeladas opcionales para la luna y el sol (assets/sky/, ver README).
-- Vacío = las de Roblox.
Config.SkyTextures = {
	Moon = "",
	Sun = "",
}

-- Letra pixelada para los números grandes del HUD (oleada, munición, monedas)
Config.PixelFont = Enum.Font.Arcade

-- Night: de noche (luna) o de día (sol bajo). Foliage: colores de las copas
-- de los árboles (si no hay, solo pinos). LeafLitter: color de las manchas
-- de hojas caídas en el suelo.
Config.Themes = {
	Medieval = {
		Night = true,
		Medieval = true, -- velas, antorchas, casas y ruinas
		DeadTrees = true, -- mezcla pinos con árboles secos
		-- Paletas del ciclo de día y noche (los valores de abajo son los de la noche)
		-- Neblina verdosa como en Guns 'n Goblins
		Day = {
			Brightness = 3,
			Ambient = Color3.fromRGB(150, 160, 150),
			Atmosphere = Color3.fromRGB(170, 205, 178),
			Decay = Color3.fromRGB(100, 135, 110),
			Density = 0.24,
			Haze = 0.8,
			Tint = Color3.fromRGB(255, 252, 244),
		},
		Dusk = {
			Brightness = 2,
			Ambient = Color3.fromRGB(140, 100, 100),
			Atmosphere = Color3.fromRGB(255, 160, 120),
			Decay = Color3.fromRGB(130, 70, 110),
			Density = 0.32,
			Haze = 1.6,
			Tint = Color3.fromRGB(255, 226, 210),
		},
		Brightness = 1.5,
		Ground = Color3.fromRGB(66, 104, 58),
		LeafLitter = Color3.fromRGB(84, 70, 48),
		Tree = Color3.fromRGB(44, 92, 62),
		Mountain = Color3.fromRGB(42, 50, 76),
		Atmosphere = Color3.fromRGB(80, 118, 112),
		Decay = Color3.fromRGB(36, 58, 62),
		Density = 0.36,
		Haze = 1.7,
		Tint = Color3.fromRGB(226, 222, 255),
		Ambient = Color3.fromRGB(70, 72, 105),
	},
	-- Como "Medieval" (mismos edificios y ciclo de día y noche) pero de otoño y
	-- con luz de cine: cielo azul limpio de día, árboles naranjas, hojas en el suelo
	OtonoMedieval = {
		Night = true,
		Medieval = true,
		Day = {
			Brightness = 3.2,
			Ambient = Color3.fromRGB(150, 140, 125),
			Atmosphere = Color3.fromRGB(180, 205, 240),
			Decay = Color3.fromRGB(110, 140, 190),
			Density = 0.05, -- poca neblina: se ven las montañas del fondo
			Haze = 0,
			Tint = Color3.fromRGB(255, 244, 228),
		},
		Dusk = {
			Brightness = 2.2,
			Ambient = Color3.fromRGB(150, 105, 85),
			Atmosphere = Color3.fromRGB(255, 175, 120),
			Decay = Color3.fromRGB(150, 85, 90),
			Density = 0.3,
			Haze = 1.5,
			Tint = Color3.fromRGB(255, 226, 200),
		},
		Brightness = 1.5,
		Ground = Color3.fromRGB(96, 116, 50),
		LeafLitter = Color3.fromRGB(200, 108, 38),
		Tree = Color3.fromRGB(46, 84, 56),
		Foliage = {
			Color3.fromRGB(230, 108, 32),
			Color3.fromRGB(244, 162, 42),
			Color3.fromRGB(204, 64, 32),
			Color3.fromRGB(250, 200, 70),
			Color3.fromRGB(176, 124, 40),
		},
		Mountain = Color3.fromRGB(92, 98, 104),
		Atmosphere = Color3.fromRGB(80, 100, 130),
		Decay = Color3.fromRGB(40, 50, 75),
		Density = 0.34,
		Haze = 1.6,
		Tint = Color3.fromRGB(226, 226, 255),
		Ambient = Color3.fromRGB(72, 74, 105),
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
--   "Pixel" → sprites pixelados de dos cuadros, como Guns 'n Goblins (hay que subir
--             las imágenes con tools/upload_assets.py; mientras tanto se ven en 3D)
--   "3D"    → muñecos 3D de bloques con animación de caminar
Config.ZombieStyle = "3D"

-- Optimización en el cliente
Config.Graphics = {
	CullBehindDistance = 40, -- zombis detrás de la cámara a más de esto no se mueven en pantalla
	AnimateDistance = 120, -- más lejos que esto no se anima caminar
	FarDistance = 170, -- más lejos que esto se actualizan cada 3 cuadros
	DeathFxDistance = 150, -- más lejos que esto mueren sin reventar en cubitos
}

-- La campana está en el origen, sobre un montículo con un castillo en ruinas
-- detrás. Todo el sur es agua (el mar, abajo de los acantilados) con dos islas:
-- la PRINCIPAL (campana, castillo y campamento) y la de la ALDEA (la Bruja, las
-- mascotas y el molino), unidas por un puente de madera roto que se repara con
-- monedas. Al norte (-Z), del otro lado del canal, el bosque de donde salen los
-- zombis: el único paso es el puente de piedra, en diagonal.
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
	FallKillY = -30, -- si caes por debajo de esta altura, te lleva el mar (o el río)
	-- Círculo negro de runas donde aparecen los jugadores
	SpawnCircle = Vector3.new(0, 0, 17),
	-- Canal entre el bosque (z < ZMin) y la isla principal (empieza en ZMax)
	Ravine = { ZMin = -122, ZMax = -82 },
	-- Puente de piedra sobre el canal, en diagonal: de From (orilla del bosque)
	-- a To (isla principal)
	Bridge = { From = Vector3.new(-29, 0, -127), To = Vector3.new(0, 0, -77), Width = 12 },
	-- Islas de tierra firme al sur (x, z): rectángulos y círculos. La principal
	-- termina atrás en el acantilado (CliffZ)
	Islands = {
		Main = {
			Boxes = {
				{ Center = Vector2.new(1, -41), Size = Vector2.new(70, 82) }, -- del puente a la campana
				{ Center = Vector2.new(41, -7), Size = Vector2.new(22, 26) }, -- muelle hacia la aldea
			},
			Disks = { { Center = Vector2.new(0, 38), Radius = 58 } }, -- campamento
		},
		Village = {
			Boxes = {},
			Disks = { { Center = Vector2.new(135, -10), Radius = 50 } },
		},
	},
	-- Puente de madera a la aldea: empieza ROTO y cada jugador lo repara una vez
	VillageBridge = { From = Vector3.new(49, 0, -8), To = Vector3.new(88, 0, -8), Width = 6, Price = 500 },
	-- El molino de la aldea: entre oleadas, cerca de él te curas (pan recién hecho)
	Windmill = { Position = Vector3.new(112, 0, 20), Radius = 18, HealPerSecond = 15 },
	-- Puesto de la Bruja (pociones y mascotas) en la aldea, mirando al puente
	MysticStall = { Position = Vector3.new(108, 0, -16), LookAt = Vector3.new(88, 0, -8) },
	-- Castillo en ruinas detrás de la campana; el camino pasa por su arco
	Castle = Vector3.new(0, 0, -40),
}

-- Caminos por donde llegan los zombis a la campana (de lejos a cerca; el
-- último tramo siempre termina en la campana). Weight es la probabilidad de
-- cada uno. Todos se juntan antes del barranco: hay UN solo camino hasta la
-- campana, por el puente de piedra y el arco del castillo. Los senderos del
-- bosque nacen entre los árboles; el del cementerio sale de la cripta.
-- Entrance: qué hay donde empieza (cripta; nada = bosque).
-- Los jefes voladores no usan caminos: van en línea recta por el aire.
local BRIDGE_ROAD = {
	Vector3.new(-45, 0, -155), -- cruce de los senderos
	Config.Arena.Bridge.From, -- entrada del puente
	Config.Arena.Bridge.To, -- salida del puente
	Vector3.new(0, 0, -40), -- arco del castillo
}
local function road(points: { Vector3 }): { Vector3 }
	return table.move(BRIDGE_ROAD, 1, #BRIDGE_ROAD, #points + 1, points)
end
Config.Paths = {
	Main = {
		Name = "Camino del cementerio",
		Entrance = "Crypt",
		Weight = 0.35,
		Points = road({
			Vector3.new(-40, 0, -265),
			Vector3.new(-55, 0, -215),
			Vector3.new(-50, 0, -180),
		}),
	},
	ForestNorth = {
		Name = "Sendero del bosque norte",
		Weight = 0.25,
		Points = road({
			Vector3.new(55, 0, -310),
			Vector3.new(35, 0, -240),
			Vector3.new(0, 0, -185),
		}),
	},
	ForestWest = {
		Name = "Sendero del bosque oeste",
		Weight = 0.2,
		Points = road({
			Vector3.new(-270, 0, -205),
			Vector3.new(-190, 0, -195),
			Vector3.new(-110, 0, -180),
			Vector3.new(-70, 0, -168),
		}),
	},
	ForestEast = {
		Name = "Sendero del bosque este",
		Weight = 0.2,
		Points = road({
			Vector3.new(270, 0, -215),
			Vector3.new(190, 0, -200),
			Vector3.new(110, 0, -185),
			Vector3.new(30, 0, -170),
		}),
	},
}
Config.PathOrder = { "Main", "ForestNorth", "ForestWest", "ForestEast" }
Config.PathStyle = {
	Width = 8, -- camino angosto de tierra
	Lane = 2.5, -- cuánto se puede desviar cada zombi del centro del camino
	SpawnSpread = 12, -- en los senderos del bosque salen entre los árboles, repartidos a lo ancho
}

-- Antes de cada partida hay una fase de preparación: es el único momento en
-- que se puede comprar. La campana está destruida; la partida empieza al
-- reconstruirla (mantener E) o al acabarse el tiempo.
-- La partida empieza solo cuando alguien reconstruye la campana (sin tiempo límite)

Config.Bell = {
	MaxHealth = 300,
	-- Cuánto del DamagePerSecond de los zombis le llega a la campana. Con 1, 22
	-- zombis la destruían en ~7 segundos en la oleada 1.
	DamageTaken = 0.35,
	RepairAmount = 30, -- con el talento Reparador
	RepairCooldown = 1,
	-- Refuerzo de la campana (lo vende el Intendente, queda guardado). En la
	-- partida cuenta el nivel más alto entre los jugadores del servidor.
	Armor = {
		MaxLevel = 8,
		HealthPerLevel = 60, -- +60 de vida por nivel (300 -> 780 al máximo)
		Prices = { 120, 200, 320, 450, 600, 800, 1050, 1350 },
	},
	BarHeight = 28, -- altura de la barra de vida sobre la campana (studs)
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
		SpriteSize = Vector2.new(27, 30),
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
		SpriteSize = Vector2.new(19, 30),
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
		SpriteSize = Vector2.new(48, 32.5),
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
	FirstIntermission = 3,
	Intermission = 12,
	FirstWaveCount = 22,
	CountGrowth = 1.3, -- cada oleada trae 30% más zombis
	FirstSpawnRate = 3.5, -- zombis por segundo
	SpawnRateGrowth = 1.5,
	SpeedMultiplier = 1.2, -- todos los zombis caminan 20% más rápido que su Speed
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
-- AmmoPerKill: balas que ganas por cada zombi eliminado con esa arma en la mano (1 en todas).
Config.Weapons = {
	Machete = {
		DisplayName = "Cuchillo",
		Icon = "🔪",
		Price = 0,
		Melee = true,
		Damage = 1.5, -- antes 3: el cuchillo es para emergencias
		FireRate = 2.2, -- golpes por segundo
		Range = 7,
		Arc = 70, -- grados frente al jugador que cubre el tajo
		MaxTargets = 3,
		Zoom = 1,
		-- Energía (el círculo blanco junto al cuchillo): cada tajo gasta un
		-- poco y se recarga sola cuando dejas de atacar
		Energy = { Cost = 0.2, Regen = 0.5, Delay = 0.4 },
	},
	Pistol = {
		DisplayName = "Pistola",
		Icon = "🔫",
		Price = 0,
		Damage = 1,
		FireRate = 5,
		Magazine = 12,
		StartReserve = 60,
		MaxReserve = 96,
		AmmoPerKill = 1,
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
		AmmoPerKill = 1,
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
		AmmoPerKill = 1,
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
		AmmoPerKill = 1,
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
			{ "Main", 32 }, { "Main", 50 }, { "Main", 66 }, { "Main", 92 },
			{ "Main", 104 }, { "Main", 116 }, { "Main", 142 }, { "Main", 155 },
		},
	},
	Gate = {
		DisplayName = "Reja",
		Icon = "🚧",
		Price = 150,
		Health = 800,
		-- Rejas de metal en los dos extremos del puente; solo aparecen si las
		-- compras. At: distancia a la campana por el camino
		Slots = {
			Start = { Name = "Reja de la entrada del puente", Short = "Entrada del puente", Path = "Main", At = 131.3, Width = 14 },
			End = { Name = "Reja de la salida del puente", Short = "Salida del puente", Path = "Main", At = 80.5, Width = 14 },
		},
		SlotOrder = { "Start", "End" },
	},
}

-- Mascotas que vende la Bruja en la aldea. Te siguen y, durante las oleadas,
-- atacan solas al zombi más cercano que esté a su alcance (Range, desde ti).
-- Damage crece con la oleada igual que la vida de los zombis. Splash: daño en
-- área alrededor del zombi. Se compran una vez y quedan guardadas.
Config.Pets = {
	Bat = {
		DisplayName = "Murciélago",
		Icon = "🦇",
		Price = 600,
		Damage = 1,
		Rate = 1.6, -- ataques por segundo
		Range = 26,
		Color = Color3.fromRGB(70, 60, 80),
		Description = "Muerde rápido a los zombis cercanos",
	},
	Wolf = {
		DisplayName = "Lobo",
		Icon = "🐺",
		Price = 1200,
		Damage = 3.2,
		Rate = 0.8,
		Range = 18,
		Color = Color3.fromRGB(130, 132, 140),
		Description = "Muerde fuerte a los que se te acercan",
	},
	Owl = {
		DisplayName = "Búho",
		Icon = "🦉",
		Price = 1800,
		Damage = 2.6,
		Rate = 0.7,
		Range = 45,
		Color = Color3.fromRGB(150, 110, 70),
		Description = "Ataca desde lejos",
	},
	Dragonling = {
		DisplayName = "Dragoncito",
		Icon = "🐲",
		Price = 3500,
		Damage = 2.2,
		Rate = 0.6,
		Range = 32,
		Splash = 7,
		Color = Color3.fromRGB(80, 170, 90),
		Description = "Escupe fuego que quema a varios zombis",
	},
}
Config.PetOrder = { "Bat", "Wolf", "Owl", "Dragonling" }

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
