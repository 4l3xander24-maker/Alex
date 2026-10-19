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
-- true: el zombi de malla realista de la tienda; false: zombis de bloques
-- estilo Roblox (cuerpo R6, ojos rojos, ropa rota)
Config.ZombieMesh = false

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
	-- Dónde está la campana (su montículo). Antes en el centro (0, 0, 0); más
	-- adelante = más cerca del puente
	Bell = Vector3.new(0, 0, -24), -- frente a la puerta del castillo
	-- El bosque (al norte del canal) está más abajo que la isla del campamento;
	-- el puente de piedra sube como una rampa de un lado al otro
	-- Múltiplo de 4: el terreno de Roblox se arma en bloques de 4 studs y con
	-- otro valor el suelo queda redondeado (los zombis caminaban hundidos)
	ForestDrop = 8,
	-- El terreno de Roblox queda 2 studs por encima de lo que se rellena (va en
	-- bloques de 4): el suelo de verdad está en y = 2. Los zombis, las trampas
	-- y el puente usan esa altura (Paths.walkHeight)
	TerrainSurface = 2,
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
	Bridge = { From = Vector3.new(-29, 0, -127), To = Vector3.new(0, 0, -77), Width = 18 },
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
		-- Isla del Mercado, pegada a la aldea por el lado derecho
		Market = {
			Boxes = { { Center = Vector2.new(188, -10), Size = Vector2.new(34, 28) } },
			Disks = { { Center = Vector2.new(240, -10), Radius = 52 } },
		},
	},
	-- Mercado: plaza, Capitán (compañeros), Sastre (skins) y aldeanos
	Market = {
		Plaza = Vector3.new(240, 0, -10),
		Captain = Vector3.new(222, 0, -34),
		Villagers = {
			{ Offset = Vector3.new(-12, 0, 12), Name = "Marta", Role = "Aldeana", Lines = { "Los zombis odian las minas. ¡Pon varias!", "Mi marido dice que el bosque está cada vez más espeso...", "Entre oleadas, el molino te cura con pan caliente." } },
			{ Offset = Vector3.new(14, 0, 8), Name = "Tomás", Role = "Granjero", Lines = { "Yo no salgo de noche. Ni de día, la verdad.", "Cuida tu munición: cada zombi te da una bala.", "¿Viste los potenciadores? Algunos zombis los sueltan." } },
			{ Offset = Vector3.new(0, 0, 22), Name = "Lucía", Role = "Niña", Lines = { "¡Me encantan las mascotas! El Capitán vende compañeros.", "La Sastre del campamento tiene capas y skins brillantes para tus armas.", "Dicen que el Dragoncito escupe fuego." } },
		},
	},
	-- Zonas donde no crece ningún árbol (rectángulos: centro y tamaño en x, z)
	ClearZones = {
		{ Center = Vector3.new(29, 0, 9), Size = Vector2.new(34, 32) },
		{ Center = Vector3.new(100, 0, -8), Size = Vector2.new(16, 48) },
	},
	-- Bosque tupido: tantos árboles que no hay paso (de aquí salen los zombis)
	DenseForest = { XMin = -430, XMax = 430, ZMin = -335, ZMax = -140, Spacing = 13 },
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
	Lane = 4.5, -- cuánto se puede desviar cada zombi del centro del camino
	SpawnSpread = 12, -- en los senderos del bosque salen entre los árboles, repartidos a lo ancho
}

-- Antes de cada partida hay una fase de preparación: es el único momento en
-- que se puede comprar. La campana está destruida; la partida empieza al
-- reconstruirla (mantener E) o al acabarse el tiempo.
-- La partida empieza solo cuando alguien reconstruye la campana (sin tiempo límite)

Config.Bell = {
	MaxHealth = 40,
	-- Cuánto del DamagePerSecond de los zombis le llega a la campana. Con 1, 22
	-- zombis la destruían en ~7 segundos en la oleada 1.
	DamageTaken = 0.35,
	RepairAmount = 30, -- con el talento Reparador
	RepairCooldown = 1,
	-- Refuerzo de la campana (lo vende el Intendente, queda guardado). En la
	-- partida cuenta el nivel más alto entre los jugadores del servidor.
	Armor = {
		MaxLevel = 8,
		HealthPerLevel = 15, -- +15 de vida por nivel (40 -> 160 al máximo)
		Prices = { 70, 150, 270, 450, 680, 980, 1380, 1900 },
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
	MaxHealth = 20,
	-- El daño de los zombis (PlayerDamage) se pensó para 100 de vida: se escala
	-- para que con 20 aguantes lo mismo
	DamageScale = 0.2,
	WalkSpeed = 16,
	RespawnTime = 5, -- solo fuera de la partida: en la partida, si mueres, se acaba
	FallDamage = 4, -- caer al agua te devuelve al círculo de runas con menos vida
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
		Skin = Color3.fromRGB(110, 190, 80),
		Shirt = Color3.fromRGB(110, 116, 128),
		Pants = Color3.fromRGB(34, 34, 40),
		Eyes = Color3.fromRGB(255, 40, 30),
		Claws = true,
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
		Headband = true,
		Hunch = 0.35, -- va más encorvado
		Skin = Color3.fromRGB(96, 176, 140),
		Shirt = Color3.fromRGB(70, 80, 96),
		Pants = Color3.fromRGB(86, 62, 44),
		Eyes = Color3.fromRGB(255, 40, 30),
		Hair = Color3.fromRGB(34, 30, 30),
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
		Shirt = Color3.fromRGB(150, 130, 100),
		Pants = Color3.fromRGB(40, 60, 110),
		Eyes = Color3.fromRGB(255, 40, 30),
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
		HitExtra = 1.2, -- el modelo es más alto que Size (casco, cabeza)
		Sprite = "",
		Model = "Zombie",
		Sword = true,
		Hat = "Helmet",
		Armor = true,
		Skin = Color3.fromRGB(96, 150, 70),
		Shirt = Color3.fromRGB(120, 36, 40), -- túnica
		Pants = Color3.fromRGB(60, 56, 64),
		Eyes = Color3.fromRGB(255, 40, 30),
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
		Model = "Zombie",
		Belt = true,
		Skin = Color3.fromRGB(110, 196, 70),
		Shirt = Color3.fromRGB(110, 116, 124),
		Pants = Color3.fromRGB(30, 30, 34),
		Eyes = Color3.fromRGB(255, 40, 30),
		Buff = true,
	},
	-- Explosivo: rápido y frágil; al morir revienta y daña a los jugadores cercanos
	-- (hay que matarlo de lejos)
	Bomber = {
		DisplayName = "Explosivo",
		MaxHealth = 3,
		Speed = 11,
		DamagePerSecond = 1,
		PlayerDamage = 6,
		Coins = 3,
		Size = Vector2.new(3.4, 4.8),
		HitRadius = 1.7,
		Sprite = "",
		Model = "Zombie",
		Dynamite = true,
		ExplodeOnDeath = { Radius = 12, PlayerDamage = 30 },
		Skin = Color3.fromRGB(190, 150, 70),
		Shirt = Color3.fromRGB(190, 60, 36),
		Pants = Color3.fromRGB(60, 40, 30),
		Eyes = Color3.fromRGB(255, 170, 40),
	},
	-- Escupidor: se queda lejos y lanza ácido a los jugadores (ver Strike)
	Spitter = {
		DisplayName = "Escupidor",
		MaxHealth = 5,
		Speed = 4.5,
		DamagePerSecond = 1,
		PlayerDamage = 6,
		Coins = 3,
		Size = Vector2.new(3.6, 5),
		HitRadius = 1.8,
		Sprite = "",
		Model = "Zombie",
		Sac = true,
		Strike = { Name = "Escupitajo", Every = 6, Range = 45, Radius = 5, Damage = 12, Delay = 1.2, Color = Color3.fromRGB(150, 230, 60) },
		Skin = Color3.fromRGB(140, 190, 60),
		Shirt = Color3.fromRGB(90, 130, 40),
		Pants = Color3.fromRGB(40, 54, 30),
		Eyes = Color3.fromRGB(190, 255, 80),
	},
	-- Parásito: al morir suelta tres corredores
	Parasite = {
		DisplayName = "Parásito",
		MaxHealth = 6,
		Speed = 5.5,
		DamagePerSecond = 3,
		PlayerDamage = 14,
		Coins = 3,
		Size = Vector2.new(4, 5.2),
		HitRadius = 2,
		HitExtra = 1.5, -- el modelo es más alto que Size (casco, cabeza)
		Sprite = "",
		Model = "Zombie",
		Pustules = true,
		Tentacles = true,
		SpawnOnDeath = { Type = "Runner", Count = 3 },
		Skin = Color3.fromRGB(150, 90, 170),
		Shirt = Color3.fromRGB(80, 50, 100),
		Pants = Color3.fromRGB(40, 30, 54),
		Eyes = Color3.fromRGB(255, 120, 255),
	},
	-- Coloso: lento, enorme y con muchísima vida
	Colossus = {
		DisplayName = "Coloso",
		MaxHealth = 28,
		Speed = 3.6,
		DamagePerSecond = 9,
		PlayerDamage = 40,
		Coins = 8,
		Size = Vector2.new(8.5, 9.5),
		HitRadius = 4,
		Sprite = "",
		Model = "Zombie",
		Belt = true,
		Horns = true,
		Armor = true,
		Buff = true,
		Skin = Color3.fromRGB(104, 124, 110),
		Shirt = Color3.fromRGB(80, 84, 92),
		Pants = Color3.fromRGB(40, 42, 48),
		Eyes = Color3.fromRGB(255, 80, 40),
	},
	-- Jefes (6 veces más grandes que un zombi común)
	-- Mutante: tentáculos de enredadera en la espalda y ojos verdes que brillan
	Mutant = {
		DisplayName = "Mutante",
		MaxHealth = 9,
		Speed = 6,
		DamagePerSecond = 3,
		PlayerDamage = 16,
		Coins = 3,
		Size = Vector2.new(3.8, 5.2),
		HitRadius = 1.9,
		HitExtra = 1.5, -- el modelo es más alto que Size (casco, cabeza)
		Sprite = "",
		Model = "Zombie",
		Spines = true,
		Tentacles = true,
		Claws = true,
		Skin = Color3.fromRGB(60, 150, 60),
		Shirt = Color3.fromRGB(70, 90, 50),
		Pants = Color3.fromRGB(50, 60, 40),
		Eyes = Color3.fromRGB(120, 255, 90),
	},
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
		-- Escupe ácido a un jugador: marca el suelo y a los 1.4 s explota
		Strike = { Name = "Ácido", Every = 7, Range = 70, Radius = 9, Damage = 40, Delay = 1.4, Color = Color3.fromRGB(150, 230, 60) },
		Skin = Color3.fromRGB(150, 186, 80),
		Shirt = Color3.fromRGB(210, 200, 170),
		Pants = Color3.fromRGB(80, 60, 90),
		Eyes = Color3.fromRGB(255, 40, 30),
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
		Regal = true,
		Hat = "Crown",
		Cape = true,
		-- Pisotón: onda grande alrededor de él
		Strike = { Name = "Pisotón", Every = 9, Range = 26, Radius = 20, Damage = 55, Delay = 1.2, Color = Color3.fromRGB(255, 200, 70), OnSelf = true },
		Skin = Color3.fromRGB(110, 160, 96),
		Shirt = Color3.fromRGB(96, 40, 120), -- túnica real
		Pants = Color3.fromRGB(44, 36, 54),
		Eyes = Color3.fromRGB(255, 200, 60),
	},
	-- Reina Necromante: cada pocos segundos llama a un grupo de zombis
	Queen = {
		DisplayName = "Reina Necromante",
		Icon = "🧙",
		MaxHealth = 240,
		Speed = 3.2,
		DamagePerSecond = 28,
		PlayerDamage = 70,
		Coins = 50,
		IsBoss = true,
		Size = Vector2.new(18, 28),
		SpriteSize = Vector2.new(17, 28),
		HitRadius = 7.5,
		HitExtra = 6, -- el modelo es más alto que Size (casco, cabeza)
		Sprite = "",
		Model = "Zombie",
		Regal = true,
		Hat = "Crown",
		Cape = true,
		Summon = { Type = "Walker", Count = 4, Every = 9 },
		Skin = Color3.fromRGB(150, 190, 170),
		Shirt = Color3.fromRGB(70, 30, 110),
		Pants = Color3.fromRGB(34, 24, 50),
		Eyes = Color3.fromRGB(190, 90, 255),
	},
	Reaper = {
		DisplayName = "Segador",
		Icon = "💀",
		MaxHealth = 110,
		Speed = 4.4,
		DamagePerSecond = 30,
		PlayerDamage = 60,
		Coins = 70,
		IsBoss = true,
		Size = Vector2.new(13, 20),
		SpriteSize = Vector2.new(13, 20),
		HitRadius = 5.5,
		HitExtra = 4,
		Sprite = "",
		Model = "Zombie",
		Horns = true,
		Cape = true,
		Summon = { Type = "Runner", Count = 3, Every = 8 },
		Strike = { Name = "Guadaña", Every = 6, Range = 40, Radius = 14, Damage = 45, Delay = 1.0, Color = Color3.fromRGB(190, 90, 255) },
		Skin = Color3.fromRGB(200, 205, 215),
		Shirt = Color3.fromRGB(26, 22, 34),
		Pants = Color3.fromRGB(20, 18, 26),
		Eyes = Color3.fromRGB(255, 70, 90),
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
		-- Bola de fuego: marca el suelo bajo un jugador y cae a los 1.5 s
		Strike = { Name = "Fuego", Every = 8, Range = 90, Radius = 11, Damage = 45, Delay = 1.5, Color = Color3.fromRGB(255, 110, 40) },
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

-- Dificultades: al reconstruir la campana se elige una. Solo se ve la que
-- tienes abierta y la siguiente con candado; al superar las oleadas de Goal
-- se abre la que sigue. Count/Health/Spawn multiplican a los zombis; Growth
-- (si está) reemplaza a Waves.CountGrowth: cuánto crece la horda cada oleada;
-- Coins y Xp lo que ganas.
Config.Difficulties = {
	{ Id = 1, Name = "Normal", Icon = "⚔️", Color = Color3.fromRGB(110, 190, 120), Count = 0.88, Health = 0.55, Spawn = 0.91, Damage = 0.8, Coins = 1.0, Xp = 1.0, Goal = 8, Description = "Pocos zombis y muy débiles: ideal para aprender." },
	{ Id = 2, Name = "Difícil", Icon = "🔥", Color = Color3.fromRGB(240, 170, 70), Count = 1.1, Growth = 1.22, Health = 1.05, Spawn = 1.1, Coins = 1.2, Xp = 1.2, Goal = 10, Description = "Más zombis y más duros. Mejores premios." },
	{ Id = 3, Name = "Experto", Icon = "🎯", Color = Color3.fromRGB(110, 170, 240), Count = 1.15, Growth = 1.15, Health = 1.15, Spawn = 1.15, Coins = 1.45, Xp = 1.45, Goal = 12, Description = "Para quien ya domina el campamento." },
	{ Id = 4, Name = "Pesadilla", Icon = "💀", Color = Color3.fromRGB(220, 90, 90), Count = 1.4, Growth = 1.13, Health = 1.4, Spawn = 1.3, Coins = 1.7, Xp = 1.7, Goal = 14, Description = "Hordas enormes y zombis resistentes." },
	{ Id = 5, Name = "Infierno", Icon = "👹", Color = Color3.fromRGB(180, 70, 220), Count = 1.7, Growth = 1.1, Health = 1.7, Spawn = 1.5, Coins = 2.4, Xp = 2.4, Goal = 16, Description = "Solo para los mejores. Premios enormes." },
}

-- Misiones diarias: se reinician cada día (UTC). Stat: Kills (bajas), BossKills
-- (jefes) o Waves (oleadas superadas en una partida, la mejor del día).
Config.DailyMissions = {
	{ Id = "DKills", Icon = "🧟", Name = "Cazador del día", Description = "Elimina 150 zombis hoy", Stat = "Kills", Goal = 150, Reward = 250 },
	{ Id = "DBoss", Icon = "👹", Name = "Rompe-jefes", Description = "Derrota 2 jefes hoy", Stat = "BossKills", Goal = 2, Reward = 300 },
	{ Id = "DWaves", Icon = "🌊", Name = "Resistencia", Description = "Supera 6 oleadas en una partida", Stat = "Waves", Goal = 6, Reward = 400 },
}

-- Logros: se revisan al terminar cada partida. Reward = monedas. Stat: qué se mide
-- (Kills = bajas en total, Wave = mejor oleada, BossKills = jefes de la partida,
-- Level = nivel de cuenta, MatchKills = bajas en una partida).
Config.Achievements = {
	{ Id = "Kills100", Icon = "🧟", Name = "Cazador", Description = "100 zombis eliminados", Stat = "Kills", Goal = 100, Reward = 150 },
	{ Id = "Kills1000", Icon = "💀", Name = "Exterminador", Description = "1000 zombis eliminados", Stat = "Kills", Goal = 1000, Reward = 800 },
	{ Id = "Kills10000", Icon = "☠️", Name = "Plaga viviente", Description = "10000 zombis eliminados", Stat = "Kills", Goal = 10000, Reward = 5000 },
	{ Id = "Wave5", Icon = "🔔", Name = "Guardián", Description = "Llega a la oleada 5", Stat = "Wave", Goal = 5, Reward = 100 },
	{ Id = "Wave10", Icon = "🛡️", Name = "Defensor", Description = "Llega a la oleada 10", Stat = "Wave", Goal = 10, Reward = 300 },
	{ Id = "Wave20", Icon = "🏰", Name = "Leyenda de la campana", Description = "Llega a la oleada 20", Stat = "Wave", Goal = 20, Reward = 1500 },
	{ Id = "Boss1", Icon = "👹", Name = "Matajefes", Description = "Derrota un jefe", Stat = "BossKills", Goal = 1, Reward = 250 },
	{ Id = "Level10", Icon = "⭐", Name = "Veterano", Description = "Llega al nivel 10", Stat = "Level", Goal = 10, Reward = 400 },
	{ Id = "Match200", Icon = "🔥", Name = "Racha", Description = "200 bajas en una sola partida", Stat = "MatchKills", Goal = 200, Reward = 500 },
}

-- Objetivos secundarios: en algunas oleadas pide matar N zombis de un tipo que
-- venga en esa oleada, antes de que termine. Premio: monedas para todos.
Config.Objectives = {
	Chance = 0.4,
	FirstWave = 2,
	KillsBase = 8, -- cuántos pide en la primera oleada con objetivo
	KillsPerWave = 1.2,
	RewardPerKill = 4, -- monedas por cada zombi pedido, a cada jugador
}

-- Eventos de oleada: a veces una oleada (no de jefe, desde la 3) trae un giro.
-- Los números multiplican la cantidad, vida y velocidad de aparición de los
-- zombis y las monedas que dan.
Config.WaveEvents = {
	Chance = 0.3,
	FirstWave = 3,
	Types = {
		Swarm = { Name = "Enjambre", Icon = "🐝", Count = 1.4, Health = 0.75, Spawn = 1.3, Coins = 1.0, Description = "Muchísimos zombis, pero más débiles" },
		Armored = { Name = "Blindados", Icon = "🛡️", Count = 0.7, Health = 1.6, Spawn = 1.0, Coins = 1.5, Description = "Menos zombis, muy resistentes y con mejor premio" },
		Golden = { Name = "Fiebre del oro", Icon = "🤑", Count = 1.0, Health = 1.0, Spawn = 1.0, Coins = 2.0, Description = "Todos dan el doble de monedas" },
	},
}

-- Potenciadores: los zombis a veces los sueltan y se aplican a todo el equipo
Config.Powerups = {
	DropChance = 0.06,
	BossDropChance = 1,
	Types = {
		Ammo = { Name = "Munición llena", Icon = "🔫", Color = Color3.fromRGB(255, 200, 80), Weight = 3 },
		Heal = { Name = "Curación total", Icon = "💚", Color = Color3.fromRGB(110, 230, 120), Weight = 3 },
		Damage = { Name = "Daño x2", Icon = "💥", Color = Color3.fromRGB(255, 110, 90), Weight = 3, Duration = 15, Multiplier = 2 },
		Shield = { Name = "Escudo", Icon = "🛡️", Color = Color3.fromRGB(110, 190, 255), Weight = 2, Duration = 8 },
		Coins = { Name = "Lluvia de monedas", Icon = "💰", Color = Color3.fromRGB(255, 215, 90), Weight = 2, Base = 20, PerWave = 5 },
	},
}

-- Economía: qué tantas monedas dan los zombis (se multiplica con el Coins de cada
-- enemigo, la dificultad, el evento y los bonus). Subir los costos y bajar esto
-- alarga cuántas partidas hacen falta para comprarlo todo.
Config.Economy = {
	KillCoinScale = 0.45,
	-- Premio por completar la dificultad (todas las veces, a cada jugador)
	ClearBonus = { [1] = 120, [2] = 250, [3] = 450, [4] = 800, [5] = 1400 },
	-- Aunque pierdas, ganas algo por cada oleada que superaste (por la dificultad)
	ParticipationPerWave = 10,
	-- Maestría: los niveles altos de mejora exigen haber superado una dificultad.
	-- Gates[tipo][nivel al que subes] = dificultad que tienes que tener abierta
	-- (superar Normal abre 2, Difícil abre 3, Experto abre 4...).
	Gates = {
		Weapon = { [4] = 2, [5] = 3 },
		Storage = { [4] = 2, [5] = 3 },
		Armor = { [5] = 2, [6] = 2, [7] = 3, [8] = 3 },
	},
}

-- Modificadores opcionales de la partida: se eligen al votar la dificultad (vale
-- lo que marque quien vota primero). Hacen el juego más duro y pagan más.
Config.Modifiers = {
	{ Id = "Fast", Icon = "💨", Name = "Zombis veloces", Description = "Caminan un 30% más rápido", Speed = 1.3, Coins = 1.25 },
	{ Id = "Tanky", Icon = "🧱", Name = "Piel dura", Description = "Tienen un 50% más de vida", Health = 1.5, Coins = 1.25 },
	{ Id = "Horde", Icon = "🌊", Name = "Hordas gigantes", Description = "Un 40% más de zombis", Count = 1.4, Coins = 1.2 },
	{ Id = "Fragile", Icon = "🩸", Name = "Golpes mortales", Description = "Recibes un 50% más de daño", Damage = 1.5, Coins = 1.25 },
}

-- Versión del juego y lista de novedades que ve quien ya había jugado
Config.Version = {
	Id = "1.2",
	Title = "armas nuevas, mochila y más reto",
	Lines = {
		"🏹 Ballesta y 🔥 Lanzallamas nuevos en la Armería",
		"🎒 La cartuchera ahora es la Mochila: te cura al empezar cada oleada",
		"👑 Salón de la fama y 🗓️ reto semanal en el lobby",
		"🐾 Tus compañeros suben de nivel mientras pelean",
		"⚙️ Modificadores opcionales al elegir dificultad",
	},
}

-- Bestiario (se ve en la tienda del Veterano): orden y descripción de cada enemigo
Config.Bestiary = {
	Order = { "Walker", "Runner", "Cone", "Knight", "Brute", "Bomber", "Spitter", "Parasite", "Colossus", "Mutant", "Fatso", "King", "Dragon", "Queen", "Reaper" },
	Text = {
		Walker = "El zombi común. Lento y fácil de eliminar.",
		Runner = "Veloz y frágil: llega antes de que reacciones.",
		Cone = "Con cono de tránsito en la cabeza: aguanta un poco más.",
		Knight = "Casco, armadura y espada. Resistente y peligroso de cerca.",
		Brute = "Enorme y fuerte. Pega duro: mantén la distancia.",
		Bomber = "Chaleco de dinamita: explota al morir. Elimínalo de lejos.",
		Spitter = "Escupe ácido desde lejos y marca el suelo antes de caer.",
		Parasite = "Al morir suelta 3 corredores. No lo dejes llegar.",
		Colossus = "Gigante acorazado. También llega como mini-jefe cada 3 oleadas.",
		Mutant = "Tentáculos y mucha vida. Dispara con calma.",
		Fatso = "JEFE (oleada 5). Lanza ácido y suelta 8 zombis al morir.",
		King = "JEFE (oleada 10). Su pisotón golpea en un área enorme.",
		Dragon = "JEFE volador (oleada 15). Escupe fuego desde el aire.",
		Queen = "JEFE (oleada 20). Invoca zombis sin parar: elimínala rápido.",
		Reaper = "JEFE de la semana del Segador (cada 3 oleadas). Su guadaña golpea en un área grande y llama corredores.",
	},
}

-- Conquistas: la primera vez que superas una dificultad ganas monedas; el primer
-- jugador del mundo en superar Experto o más sube al Salón de la fama (sin límite
-- de tiempo), con título, monedas extra y, en Experto, un rastro exclusivo.
Config.Conquest = {
	Rewards = { [2] = 300, [3] = 1000, [4] = 2000, [5] = 4000 }, -- todos, la primera vez
	FirstFrom = 3, -- desde qué dificultad cuenta el "primero del mundo"
	FirstBonus = { [3] = 5000, [4] = 8000, [5] = 15000 },
	FirstTitle = { [3] = "Conquistador de Experto", [4] = "Rey de la Pesadilla", [5] = "Señor del Infierno" },
	FirstSkin = { [3] = "TracerCrown" }, -- skin exclusiva (Config.ObjectSkins)
}

-- Reto semanal: el modificador de las oleadas cambia cada semana y hay ranking
-- aparte; los 3 primeros de la semana cobran su premio al volver a entrar.
Config.Weekly = {
	Challenges = {
		{ Id = "Swarm", Event = "Swarm", Icon = "🐝", Name = "Semana del Enjambre", Description = "Hordas enormes pero más débiles" },
		{ Id = "Armored", Event = "Armored", Icon = "🛡️", Name = "Semana Blindada", Description = "Menos zombis, muy resistentes y con mejor premio" },
		{ Id = "Golden", Event = "Golden", Icon = "🤑", Name = "Semana del Oro", Description = "Todos dan el doble de monedas" },
		{ Id = "Reaper", Event = "Golden", Boss = "Reaper", Icon = "💀", Name = "Semana del Segador", Description = "Un jefe nuevo, el Segador, aparece cada 3 oleadas. ¡Premios dobles!" },
	},
	Prizes = { 1500, 1000, 600 }, -- monedas para el puesto 1, 2 y 3
	Top = 10, -- cuántos se ven en el tablero del lobby
}

Config.Waves = {
	FirstIntermission = 3,
	Intermission = 12,
	-- Cuando quedan estos zombis o menos (y ya salieron todos), viene la
	-- siguiente horda sin esperar a matarlos. No aplica en oleadas de jefe.
	NextWaveAt = 5,
	OverlapIntermission = 3, -- segundos entre hordas cuando quedaron zombis vivos
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
	Bosses = { "Fatso", "King", "Dragon", "Queen" },
	BossSpacing = 6, -- segundos entre un jefe y el siguiente
	GameOverDelay = 12,
	-- Desde qué oleada aparece cada tipo y qué tan seguido
	-- Qué zombis trae cada oleada: a veces un solo tipo, a veces una mezcla.
	-- Después de la última, cada oleada elige al azar 2 o 3 tipos de Random.
	Lineups = {
		{ "Walker" },
		{ "Runner" },
		{ "Walker", "Cone" },
		{ "Brute" },
		{ "Walker", "Runner" }, -- + el Gordo
		{ "Mutant", "Bomber" },
		{ "Cone", "Knight", "Parasite" },
		{ "Runner", "Brute", "Bomber" },
		{ "Mutant", "Knight", "Colossus" },
		{ "Walker", "Runner", "Spitter" }, -- + el Rey
	},
	Random = { "Walker", "Runner", "Cone", "Knight", "Brute", "Mutant", "Bomber", "Parasite", "Colossus", "Spitter" },
	-- Cada MiniBossEvery oleadas (que no sean de jefe) sale un Coloso con MiniBossHealth veces su vida
	MiniBossEvery = 3,
	MiniBossHealth = 2.5,
	-- Dificultad según cuántos jugadores hay en la partida: por cada jugador
	-- extra, estos porcentajes de más
	PerExtraPlayer = {
		Count = 0.6, -- +60% de zombis
		SpawnRate = 0.4, -- salen 40% más seguido
		Health = 0.15, -- +15% de vida de los zombis
		BossHealth = 0.5, -- +50% de vida de los jefes
	},
}

-- Lobby y salas: el juego tiene dos lugares. En el Lobby hay salas de hasta
-- MaxPlayers; al llenarse o acabarse la cuenta, el grupo va a una partida
-- privada en el lugar Match. Al terminar la partida vuelven al Lobby.
-- Los ids salen de create.roblox.com (Places). 0 = no configurado.
-- El Lobby es el lugar de inicio de la experiencia (ahí entra todo el mundo);
-- la partida es el segundo lugar.
Config.Places = {
	Lobby = 107080967531379,
	Match = 89403352500955,
}
-- Monetización. Los ids salen de create.roblox.com → tu experiencia →
-- Monetization (Passes y Developer Products). 0 = no configurado: sale como
-- "Pronto" en la tienda. El precio en Robux se pone allá y la tienda lo lee solo.
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end
Config.Monetization = {
	-- Pases: se compran una vez y quedan para siempre
	Passes = {
		StarterPack = { Id = 2038323296, Name = "Pack Inicial", Icon = "🎁", Description = "1000 monedas, pistola de Plata y la skin Pionero. ¡Solo una vez!", Coins = 1000, PistolLevel = 2 },
		DoubleCoins = { Id = 2039529121, Name = "Monedas x2", Icon = "💰", Description = "Ganas el doble de monedas por cada zombi, para siempre." },
		Vip = { Id = 2037177279, Name = "VIP", Icon = "👑", Description = "+25% de XP en cada partida y la skin Dorada." },
	},
	PassOrder = { "StarterPack", "DoubleCoins", "Vip" },
	-- Productos: se compran las veces que quieras (solo dentro de la partida)
	Products = {
		Revive = { Id = 3719236041, Name = "Revivir", Icon = "💖", Description = "Vuelves a la partida con la vida llena." },
		Continue = { Id = 3719236225, Name = "Continuar partida", Icon = "💖", Description = "Cuando caen todos: el equipo entero vuelve y la partida sigue." },
		PetGolem = { Id = 3719236383, Name = "Gólem de piedra", Icon = "🗿", Description = "Compañero que aplasta zombis en área.", Pet = "Golem" },
		PetPhoenix = { Id = 3719236411, Name = "Fénix", Icon = "🔥", Description = "Compañero que lanza fuego desde el aire.", Pet = "Phoenix" },
		ObjMineGalaxy = { Id = 3719283194, Name = "Mina galáctica", Icon = "🌌", Description = "Skin Premium de mina.", ObjectSkin = "MineGalaxy" },
		ObjMineGold = { Id = 3719282844, Name = "Mina de oro", Icon = "🥇", Description = "Skin Premium de mina.", ObjectSkin = "MineGold" },
		ObjGateFire = { Id = 3719282897, Name = "Reja de fuego", Icon = "🔥", Description = "Skin Premium de reja.", ObjectSkin = "GateFire" },
		ObjGateCrystal = { Id = 3719283030, Name = "Reja de cristal", Icon = "💎", Description = "Skin Premium de reja.", ObjectSkin = "GateCrystal" },
		ObjBellGold = { Id = 3719283075, Name = "Campana dorada", Icon = "🔔", Description = "Skin Premium de campana.", ObjectSkin = "BellGold" },
		ObjPetSun = { Id = 3719357860, Name = "Compañero solar", Icon = "☀️", Description = "Skin Premium de compañero.", ObjectSkin = "PetSun" },
		ObjPetVoid = { Id = 3719357910, Name = "Compañero del vacío", Icon = "🌀", Description = "Skin Premium de compañero.", ObjectSkin = "PetVoid" },
		ObjTracerStorm = { Id = 3719357961, Name = "Rastro de tormenta", Icon = "⚡", Description = "Skin Premium de rastro de balas.", ObjectSkin = "TracerStorm" },
		ObjTracerAurum = { Id = 3719358010, Name = "Rastro de oro", Icon = "✨", Description = "Skin Premium de rastro de balas.", ObjectSkin = "TracerAurum" },
		ObjDfLightning = { Id = 3719363441, Name = "Efecto Rayo", Icon = "⚡", Description = "Skin Premium de efecto al eliminar.", ObjectSkin = "DfLightning" },
		ObjDfGold = { Id = 3719363499, Name = "Efecto Lluvia de oro", Icon = "🪙", Description = "Skin Premium de efecto al eliminar.", ObjectSkin = "DfGold" },
		ObjFireSpirit = { Id = 3720070226, Name = "Fogata espectral", Icon = "👻", Description = "Skin Premium de la fogata del campamento.", ObjectSkin = "FireSpirit" },
		ObjDfRainbow = { Id = 3719363534, Name = "Efecto Arcoíris", Icon = "🌈", Description = "Skin Premium de efecto al eliminar.", ObjectSkin = "DfRainbow" },
		ObjBellFire = { Id = 3719283103, Name = "Campana infernal", Icon = "🌋", Description = "Skin Premium de campana.", ObjectSkin = "BellFire" },
		SkinBlood = { Id = 3719236493, Name = "Skin Sangrienta", Icon = "🟥", Description = "Skin de arma roja brillante.", WeaponSkin = "Blood" },
		SkinGalaxy = { Id = 3719236685, Name = "Skin Galaxia", Icon = "🟪", Description = "Skin de arma morada brillante.", WeaponSkin = "Galaxy" },
		SkinGold = { Id = 3719236545, Name = "Skin Oro Macizo", Icon = "🟨", Description = "Skin de arma dorada brillante.", WeaponSkin = "Gold" },
		CoinsSmall = { Id = 3719236258, Name = "Bolsa de monedas", Icon = "💰", Description = "+500 monedas.", Coins = 500 },
		CoinsBig = { Id = 3719236344, Name = "Cofre de monedas", Icon = "💎", Description = "+2000 monedas.", Coins = 2000 },
	},
	ReviveWindow = 10, -- segundos para comprar Revivir después de caer
	ContinueWindow = 10, -- cuenta cuando caen todos, para comprar Continuar
	ContinueSlowScale = 0.03, -- velocidad del mundo mientras tanto (cámara súper lenta)
	ReviveRefund = 300, -- monedas si compraste Revivir pero ya no se podía usar
	VipXpBonus = 0.25,
	-- Skins: capa (y armadura o sombrero) que ven todos. Cómo se consiguen:
	--   PassId: pase propio (Robux). CoinPrice: con monedas (en la partida).
	--   Con los dos: se elige cómo pagar. Pass: viene con un pase de arriba.
	-- Hat: "Hood" (capucha), "Crown", "Horns", "Helmet" o "Brim" (sombrero).
	-- Exclusive: sale marcada como EXCLUSIVA en la tienda.
	Skins = {
		{ Id = "Traveler", Name = "Capa de Viajero", CoinPrice = 1500, Cape = rgb(110, 76, 46), Trim = rgb(200, 170, 120), Hat = "Hood" },
		{ Id = "Hunter", Name = "Cazador de Zombis", CoinPrice = 4000, Cape = rgb(70, 80, 40), Trim = rgb(220, 210, 180), Armor = true, Hat = "Brim" },
		{ Id = "Crimson", Name = "Capa Carmesí", PassId = 2036469314, Cape = rgb(150, 30, 36), Trim = rgb(230, 190, 80) },
		{ Id = "Royal", Name = "Capa Real", PassId = 2040212826, Cape = rgb(40, 70, 170), Trim = rgb(240, 210, 90), Hat = "Crown" },
		{ Id = "Emerald", Name = "Caballero Esmeralda", PassId = 2036697254, Cape = rgb(30, 120, 70), Trim = rgb(200, 204, 214), Armor = true, Hat = "Helmet" },
		{ Id = "Shadow", Name = "Cazador de Sombras", PassId = 2040398833, Cape = rgb(30, 26, 40), Trim = rgb(150, 60, 220), Armor = true, Glow = true, Hat = "Hood" },
		{ Id = "BoneKing", Name = "Rey de los Huesos", PassId = 2037591271, CoinPrice = 12000, Exclusive = true, Cape = rgb(226, 220, 200), Trim = rgb(40, 36, 36), Armor = true, Glow = true, Hat = "Crown" },
		{ Id = "Inferno", Name = "Infernal", PassId = 2040596821, CoinPrice = 20000, Exclusive = true, Cape = rgb(110, 16, 10), Trim = rgb(255, 120, 30), Armor = true, Glow = true, Hat = "Horns" },
		-- Temporada de Halloween: solo se compran hasta Until (hora UTC, segundos); quien las compró las conserva
		{ Id = "Pumpkin", Name = "Calabaza maldita", CoinPrice = 2500, Until = 1794096000, Seasonal = "🎃 Halloween", Cape = rgb(230, 120, 20), Trim = rgb(40, 24, 10), Armor = true, Glow = true, Hat = "Brim" },
		{ Id = "Ghost", Name = "Fantasma", CoinPrice = 3500, Until = 1794096000, Seasonal = "🎃 Halloween", Cape = rgb(220, 230, 255), Trim = rgb(120, 140, 220), Glow = true, Hat = "Hood" },
		{ Id = "Pioneer", Name = "Pionero", Pass = "StarterPack", Exclusive = true, Cape = rgb(30, 110, 120), Trim = rgb(210, 214, 222), Armor = true, Hat = "Helmet" },
		{ Id = "Golden", Name = "Dorada", Pass = "Vip", Exclusive = true, Cape = rgb(220, 170, 50), Trim = rgb(255, 240, 160), Armor = true, Glow = true, Hat = "Crown" },
	},
}

Config.Rooms = {
	Count = 10, -- salas en el lobby
	MaxPlayers = 5,
	Capacities = { 5, 4, 3, 2, 1, 1, 2, 3, 4, 5 }, -- cuántos jugadores caben en cada sala (2 de cada tamaño, simétricas)
	Countdown = 15, -- segundos desde que entra el primero
	FullCountdown = 5, -- si se llena, sale antes
	ReturnDelay = 10, -- segundos del resumen antes de volver al lobby
	VoteMaxWait = 300, -- sin cuenta regresiva: si alguien no vota en tanto tiempo, cuenta como Reintentar
	CinematicTime = 9, -- duración de la cinemática de derrota
}

-- Armas que vende el Armero. Zoom solo se usa con el talento Puntería.
-- StartReserve: balas de reserva al empezar la partida.
-- MaxReserve: máximo de balas de reserva (lo sube la cartuchera del Intendente).
-- AmmoPerKill: balas que ganas por cada zombi eliminado (con cualquier arma): llena primero la pistola y, al llegar a su tope, la siguiente arma.
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
		StartReserve = 0, -- empiezas solo con el cargador: 12 balas
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
		Price = 200,
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
	Crossbow = {
		DisplayName = "Ballesta",
		Icon = "🏹",
		Price = 1200,
		Damage = 6, -- un virote atraviesa hasta 4 zombis en fila
		FireRate = 1.4,
		Magazine = 6,
		StartReserve = 18,
		MaxReserve = 60,
		AmmoPerKill = 1,
		ReloadTime = 2.0,
		Range = 320,
		Pellets = 1,
		Spread = 0.004,
		Pierce = 3,
		Zoom = 1.8,
	},
	Flamethrower = {
		DisplayName = "Lanzallamas",
		Icon = "🔥",
		Price = 1600,
		Flame = true, -- en vez de balas, lanza fuego (efecto en WeaponController)
		Damage = 0.9,
		FireRate = 14,
		Magazine = 90,
		StartReserve = 180,
		MaxReserve = 540,
		AmmoPerKill = 2,
		ReloadTime = 3.2,
		Range = 26, -- corto alcance: a cambio quema a varios a la vez
		Pellets = 2,
		Spread = 0.11,
		Pierce = 3,
		Zoom = 1.1,
	},
}
Config.WeaponOrder = { "Machete", "Pistol", "Shotgun", "Rifle", "Sniper", "Minigun", "Crossbow", "Flamethrower" }

-- Mejoras de arma en el Armero (por nivel de mejora)
Config.WeaponUpgrade = {
	MaxLevel = 5,
	DamagePerLevel = 0.2,
	MagazinePerLevel = 0.15,
	ReloadPerLevel = 0.06,
	BaseCost = 130, -- el costo crece con el precio del arma y el nivel
	-- Cuánto del precio base cuesta cada mejora (las primeras son baratas)
	CostFactor = { 0.35, 0.5, 0.75, 1.2, 1.8 },
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

-- Mochila de suministros (antes "cartuchera"): al empezar cada oleada te cura un
-- poco y, desde el nivel 3, te da un escudo corto cada 2 oleadas. Además suma un
-- poco de reserva de balas. Pensada para ayudar, no para volverte invencible.
Config.AmmoStorage = {
	MaxLevel = 5,
	PerLevel = 0.10, -- +10% de balas de reserva por nivel
	Prices = { 80, 160, 300, 520, 850 },
	Heal = { 0.10, 0.15, 0.20, 0.25, 0.30 }, -- fracción de la vida máxima, al empezar la oleada
	-- Escudo (segundos) al empezar la oleada; sale solo cada ShieldEvery oleadas
	Shield = { [3] = 3, [4] = 4, [5] = 5 },
	ShieldEvery = 2,
}

-- Trampas que vende el Intendente. Duran solo una partida.
Config.Traps = {
	Mine = {
		DisplayName = "Mina",
		Icon = "🪤",
		Price = 30, -- se gasta en una partida: barata frente a lo permanente (arma 700)
		MaxPerMatch = 8,
		Damage = 12, -- crece con la oleada igual que la vida de los zombis
		Radius = 10,
		TriggerRadius = 3,
		-- La mina espera a un grupo (o a un zombi duro) para no gastarse con uno solo
		MinTargets = 3, -- zombis dentro de Radius
		-- Mejoras (se compran acercándote a la mina, en la preparación)
		MaxLevel = 3,
		UpgradePrice = { 50, 100 }, -- de nivel 1 a 2 y de 2 a 3
		DamagePerLevel = 0.5, -- +50% de daño por nivel
		RadiusPerLevel = 0.15,
		HeavyHealth = 10, -- vida base desde la que un zombi suelto ya la activa (jefes siempre)
		-- Lugares donde se entierran: camino y distancia a la campana por el camino
		Spots = {
			-- (distancia a la campana por el camino: la campana está en Arena.Bell)
			{ "Main", 26 }, { "Main", 42 }, { "Main", 68 }, { "Main", 80 },
			{ "Main", 92 }, { "Main", 105 }, { "Main", 118 }, { "Main", 131 },
		},
	},
	Gate = {
		DisplayName = "Reja",
		Icon = "🚧",
		Price = 120,
		Health = 1500, -- con 800 una horda grande la rompía en ~8 segundos
		RepairPerWave = 0.35, -- entre oleadas la reja recupera este % de su vida
		-- Mejoras (se compran acercándote a la reja, en la preparación)
		MaxLevel = 3,
		UpgradePrice = { 120, 240 },
		HealthPerLevel = 0.6, -- +60% de vida por nivel (queda llena al mejorar)
		FireDamage = 1.5, -- nivel 3 (puerta de fuego): daño cada 0.5 s a los zombis pegados
		-- Rejas de metal en los dos extremos del puente; solo aparecen si las
		-- compras. At: distancia a la campana por el camino
		Slots = {
			Start = { Name = "Reja de la entrada del puente", Short = "Entrada del puente", Path = "Main", At = 107.3, Width = 20 },
			End = { Name = "Reja de la salida del puente", Short = "Salida del puente", Path = "Main", At = 56.5, Width = 20 },
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
Config.Pets.StunDamage = 2.5 -- daño de un golpe que aturde al compañero
Config.Pets.StunTime = 3.5
Config.PetOrder = { "Bat", "Wolf", "Owl", "Dragonling" }

-- Compañeros del Capitán (isla del Mercado): pelean a tu lado igual que las
-- mascotas (se usan los mismos campos). Product = producto de Robux (Monetization.Products).
Config.Pets.Soldier = { DisplayName = "Soldado", Icon = "💂", Price = 2200, Damage = 2.4, Rate = 1.4, Range = 38, Color = Color3.fromRGB(150, 60, 56), Shop = "Captain", Description = "Dispara a los zombis que se acercan" }
Config.Pets.Archer = { DisplayName = "Arquera", Icon = "🏹", Price = 3200, Damage = 3.2, Rate = 1.0, Range = 60, Color = Color3.fromRGB(70, 130, 70), Shop = "Captain", Description = "Flechas desde muy lejos" }
Config.Pets.Hound = { DisplayName = "Perro de guerra", Icon = "🐕", Price = 1500, Damage = 2.6, Rate = 1.1, Range = 20, Color = Color3.fromRGB(110, 80, 50), Shop = "Captain", Description = "Muerde rápido a los que se te acercan" }
Config.Pets.Golem = { DisplayName = "Gólem de piedra", Icon = "🗿", Price = 0, Product = "PetGolem", Damage = 4.5, Rate = 0.6, Range = 22, Splash = 9, Color = Color3.fromRGB(120, 124, 132), Shop = "Captain", Description = "Aplasta a varios zombis a la vez" }
Config.Pets.Phoenix = { DisplayName = "Fénix", Icon = "🔥", Price = 0, Product = "PetPhoenix", Damage = 3.8, Rate = 1.2, Range = 55, Splash = 6, Color = Color3.fromRGB(255, 130, 40), Shop = "Captain", Description = "Lluvia de fuego desde el aire" }
-- Los compañeros ganan experiencia con cada ataque y suben de nivel: más daño y
-- ataques más rápidos. XpNeeded[nivel] = ataques acumulados para llegar a ese nivel.
Config.PetLevels = {
	XpNeeded = { 0, 120, 400, 900, 1800 },
	DamagePerLevel = 0.12,
	RatePerLevel = 0.05,
}

Config.CompanionOrder = { "Hound", "Soldier", "Archer", "Golem", "Phoenix" }

-- Skins de objetos (las vende el Sastre): cambian cómo se ven tus minas, tus rejas
-- y la campana. Kind: "Mine", "Gate" o "Bell". CoinPrice = monedas; Product =
-- producto de Robux (Monetization.Products), y esas son Premium: brillan, sueltan
-- chispas y salen marcadas en la tienda. Main = cuerpo, Accent = detalles, Light =
-- luz (minas). Fire = llamas (rejas).
Config.ObjectSkins = {
	{ Id = "MineIce", Kind = "Mine", Name = "Mina de hielo", Icon = "❄️", CoinPrice = 800, Main = Color3.fromRGB(150, 205, 235), Accent = Color3.fromRGB(225, 245, 255), Light = Color3.fromRGB(120, 210, 255) },
	{ Id = "MineToxic", Kind = "Mine", Name = "Mina radiactiva", Icon = "☢️", CoinPrice = 1600, Main = Color3.fromRGB(70, 90, 40), Accent = Color3.fromRGB(150, 230, 60), Light = Color3.fromRGB(150, 255, 60) },
	{ Id = "MineGalaxy", Kind = "Mine", Name = "Mina galáctica", Icon = "🌌", Product = "ObjMineGalaxy", Premium = true, Main = Color3.fromRGB(34, 20, 80), Accent = Color3.fromRGB(190, 130, 255), Light = Color3.fromRGB(190, 120, 255) },
	{ Id = "MineGold", Kind = "Mine", Name = "Mina de oro", Icon = "🥇", Product = "ObjMineGold", Premium = true, Main = Color3.fromRGB(214, 170, 60), Accent = Color3.fromRGB(255, 235, 140), Light = Color3.fromRGB(255, 220, 90) },
	{ Id = "GateIron", Kind = "Gate", Name = "Reja de hierro negro", Icon = "⚫", CoinPrice = 1200, Main = Color3.fromRGB(56, 58, 66), Accent = Color3.fromRGB(30, 32, 38) },
	{ Id = "GateBronze", Kind = "Gate", Name = "Reja de bronce", Icon = "🟤", CoinPrice = 2200, Main = Color3.fromRGB(150, 104, 56), Accent = Color3.fromRGB(205, 140, 70) },
	{ Id = "GateFire", Kind = "Gate", Name = "Reja de fuego", Icon = "🔥", Product = "ObjGateFire", Premium = true, Fire = true, Main = Color3.fromRGB(70, 30, 24), Accent = Color3.fromRGB(255, 120, 40) },
	{ Id = "GateCrystal", Kind = "Gate", Name = "Reja de cristal", Icon = "💎", Product = "ObjGateCrystal", Premium = true, Main = Color3.fromRGB(150, 220, 245), Accent = Color3.fromRGB(110, 235, 255) },
	-- Compañeros y mascotas: tiñen su cuerpo (Main) y sus detalles. Rastros: color de las balas.
	{ Id = "PetFrost", Kind = "Pet", Name = "Compañero de escarcha", Icon = "🧊", CoinPrice = 1500, Main = Color3.fromRGB(150, 205, 240), Accent = Color3.fromRGB(230, 248, 255) },
	{ Id = "PetShadow", Kind = "Pet", Name = "Compañero sombra", Icon = "🌑", CoinPrice = 2500, Main = Color3.fromRGB(46, 36, 66), Accent = Color3.fromRGB(150, 90, 220) },
	{ Id = "PetSun", Kind = "Pet", Name = "Compañero solar", Icon = "☀️", Product = "ObjPetSun", Premium = true, Main = Color3.fromRGB(255, 190, 60), Accent = Color3.fromRGB(255, 240, 150) },
	{ Id = "PetVoid", Kind = "Pet", Name = "Compañero del vacío", Icon = "🌀", Product = "ObjPetVoid", Premium = true, Main = Color3.fromRGB(60, 30, 130), Accent = Color3.fromRGB(190, 120, 255) },
	{ Id = "TracerGreen", Kind = "Tracer", Name = "Rastro verde", Icon = "🟢", CoinPrice = 600, Main = Color3.fromRGB(90, 255, 120), Accent = Color3.fromRGB(200, 255, 210) },
	{ Id = "TracerPink", Kind = "Tracer", Name = "Rastro rosa", Icon = "🌸", CoinPrice = 900, Main = Color3.fromRGB(255, 110, 190), Accent = Color3.fromRGB(255, 200, 230) },
	{ Id = "TracerStorm", Kind = "Tracer", Name = "Rastro de tormenta", Icon = "⚡", Product = "ObjTracerStorm", Premium = true, Main = Color3.fromRGB(110, 220, 255), Accent = Color3.fromRGB(255, 255, 255) },
	{ Id = "TracerCrown", Kind = "Tracer", Name = "Rastro del Conquistador", Icon = "👑", Exclusive = true, Premium = true, Main = Color3.fromRGB(255, 190, 40), Accent = Color3.fromRGB(255, 80, 60) },
	{ Id = "TracerAurum", Kind = "Tracer", Name = "Rastro de oro", Icon = "✨", Product = "ObjTracerAurum", Premium = true, Main = Color3.fromRGB(255, 210, 70), Accent = Color3.fromRGB(255, 245, 190) },
	-- Efectos al eliminar zombis: estallido de cubos con los colores de Colors (los ve todo el equipo)
	{ Id = "FireBlue", Kind = "Campfire", Name = "Fogata azul", Icon = "🔵", CoinPrice = 1500, Main = Color3.fromRGB(80, 150, 255), Accent = Color3.fromRGB(190, 225, 255) },
	{ Id = "FireGreen", Kind = "Campfire", Name = "Fogata verde", Icon = "🟢", CoinPrice = 2200, Main = Color3.fromRGB(70, 230, 110), Accent = Color3.fromRGB(200, 255, 200) },
	{ Id = "FireViolet", Kind = "Campfire", Name = "Fogata violeta", Icon = "🟣", CoinPrice = 3000, Main = Color3.fromRGB(170, 90, 255), Accent = Color3.fromRGB(235, 200, 255) },
	{ Id = "FireSpirit", Kind = "Campfire", Name = "Fogata espectral", Icon = "👻", Product = "ObjFireSpirit", Premium = true, Main = Color3.fromRGB(120, 255, 235), Accent = Color3.fromRGB(255, 255, 255) },
	{ Id = "DfConfetti", Kind = "DeathFx", Name = "Confeti de fiesta", Icon = "🎉", CoinPrice = 700, Colors = { Color3.fromRGB(255, 90, 120), Color3.fromRGB(255, 220, 80), Color3.fromRGB(90, 200, 255), Color3.fromRGB(120, 255, 140) }, Main = Color3.fromRGB(255, 220, 80), Accent = Color3.fromRGB(255, 255, 255), Rise = 14 },
	{ Id = "DfSmoke", Kind = "DeathFx", Name = "Nube de humo", Icon = "💨", CoinPrice = 1200, Colors = { Color3.fromRGB(210, 210, 215), Color3.fromRGB(150, 152, 160), Color3.fromRGB(100, 102, 110) }, Main = Color3.fromRGB(190, 190, 200), Accent = Color3.fromRGB(240, 240, 245), Rise = 6, Big = true },
	{ Id = "DfEmber", Kind = "DeathFx", Name = "Brasas", Icon = "🔥", CoinPrice = 1800, Colors = { Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 190, 60), Color3.fromRGB(200, 60, 20) }, Main = Color3.fromRGB(255, 140, 40), Accent = Color3.fromRGB(255, 220, 120), Rise = 12 },
	{ Id = "DfLightning", Kind = "DeathFx", Name = "Rayo", Icon = "⚡", Product = "ObjDfLightning", Premium = true, Colors = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 140, 255) }, Main = Color3.fromRGB(120, 220, 255), Accent = Color3.fromRGB(255, 255, 255), Rise = 18, Column = true },
	{ Id = "DfGold", Kind = "DeathFx", Name = "Lluvia de oro", Icon = "🪙", Product = "ObjDfGold", Premium = true, Colors = { Color3.fromRGB(255, 210, 70), Color3.fromRGB(255, 240, 160), Color3.fromRGB(220, 160, 30) }, Main = Color3.fromRGB(255, 210, 70), Accent = Color3.fromRGB(255, 245, 190), Rise = 16 },
	{ Id = "DfRainbow", Kind = "DeathFx", Name = "Arcoíris", Icon = "🌈", Product = "ObjDfRainbow", Premium = true, Colors = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(255, 170, 60), Color3.fromRGB(255, 240, 80), Color3.fromRGB(90, 230, 110), Color3.fromRGB(80, 160, 255), Color3.fromRGB(190, 110, 255) }, Main = Color3.fromRGB(255, 170, 60), Accent = Color3.fromRGB(255, 255, 255), Rise = 18, Column = true },
	{ Id = "BellSilver", Kind = "Bell", Name = "Campana de plata", Icon = "🥈", CoinPrice = 2500, Main = Color3.fromRGB(176, 182, 196), Accent = Color3.fromRGB(235, 240, 250) },
	{ Id = "BellGold", Kind = "Bell", Name = "Campana dorada", Icon = "🔔", Product = "ObjBellGold", Premium = true, Main = Color3.fromRGB(220, 170, 50), Accent = Color3.fromRGB(255, 240, 150) },
	{ Id = "BellFire", Kind = "Bell", Name = "Campana infernal", Icon = "🌋", Product = "ObjBellFire", Premium = true, Fire = true, Main = Color3.fromRGB(120, 30, 22), Accent = Color3.fromRGB(255, 130, 40) },
}

-- Skins de armas (las vende el Sastre): cambian el color del arma que llevas.
-- CoinPrice = monedas; Product = producto de Robux (Monetization.Products).
Config.WeaponSkins = {
	{ Id = "Rust", Name = "Oxidada", Icon = "🟧", CoinPrice = 800, Main = Color3.fromRGB(110, 62, 36), Accent = Color3.fromRGB(190, 110, 50), Bonus = { Magazine = 0.10 } },
	{ Id = "Arctic", Name = "Ártica", Icon = "🟦", CoinPrice = 1800, Main = Color3.fromRGB(150, 200, 235), Accent = Color3.fromRGB(235, 248, 255), Bonus = { Reload = 0.10 } },
	{ Id = "Toxic", Name = "Tóxica", Icon = "🟩", CoinPrice = 3500, Main = Color3.fromRGB(40, 120, 50), Accent = Color3.fromRGB(120, 255, 90), Glow = true, Bonus = { Damage = 0.08 } },
	{ Id = "Blood", Name = "Sangrienta", Icon = "🟥", Product = "SkinBlood", Main = Color3.fromRGB(110, 14, 20), Accent = Color3.fromRGB(255, 50, 60), Glow = true, Bonus = { Damage = 0.06, Crit = 0.04 } },
	{ Id = "Galaxy", Name = "Galaxia", Icon = "🟪", Product = "SkinGalaxy", Main = Color3.fromRGB(40, 24, 90), Accent = Color3.fromRGB(170, 120, 255), Glow = true, Bonus = { FireRate = 0.08, Magazine = 0.10 } },
	{ Id = "Gold", Name = "Oro Macizo", Icon = "🟨", CoinPrice = 9000, Product = "SkinGold", Main = Color3.fromRGB(200, 150, 30), Accent = Color3.fromRGB(255, 230, 120), Glow = true, Bonus = { Damage = 0.12, Magazine = 0.12, Crit = 0.03 } },
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
	Firewall = {
		DisplayName = "Muro de fuego",
		Icon = "🔥",
		Key = Enum.KeyCode.V,
		Price = 600,
		MaxLevel = 5,
		Cooldown = 18,
		Damage = 1.2, -- por cada pulso (cada 0.5 s) a todo zombi que lo toque
		Length = 26,
		Width = 5,
		Duration = 6,
		Range = 70,
		Description = "Levanta un muro de fuego que quema a los zombis que lo cruzan",
		LevelText = "+30% daño y +1 s de duración",
	},
}
Config.PowerOrder = { "Grenade", "Chain", "Bell", "Firewall" }

-- Nivel de cuenta: la XP se gana al terminar cada partida
Config.Progression = {
	XpBase = 100, -- XP para pasar del nivel 1 al 2
	XpGrowth = 1.15, -- cada nivel pide 15% más
	-- Los primeros 5 niveles piden menos XP (sube rápido al empezar)
	EarlyXpFactor = { 0.4, 0.5, 0.6, 0.7, 0.8 },
	TalentEvery = 5, -- un punto de talento cada 5 niveles
	XpPerWave = 25,
	XpPerKill = 2,
	XpPerBossKill = 40,
}

-- Un punto por nivel. PerPoint es lo que suma cada punto.
Config.Stats = {
	{ Brief = "Más daño en cada disparo y golpe", Id = "Damage", Name = "Daño", Icon = "💥", PerPoint = 0.05, Max = 20, Text = "+%d%% de daño", Percent = true },
	{ Brief = "Aguantas más golpes antes de caer", Id = "Health", Name = "Vida", Icon = "❤️", PerPoint = 2, Max = 20, Text = "+%d de vida máxima" },
	{ Brief = "Caminas más rápido", Id = "Speed", Name = "Velocidad", Icon = "👟", PerPoint = 0.03, Max = 10, Text = "+%d%% de velocidad al caminar", Percent = true },
	{ Brief = "Recargas las armas en menos tiempo", Id = "Reload", Name = "Recarga", Icon = "🔄", PerPoint = 0.05, Max = 10, Text = "%d%% menos tiempo de recarga", Percent = true },
	{ Brief = "Disparas más rápido", Id = "FireRate", Name = "Cadencia", Icon = "⚡", PerPoint = 0.03, Max = 10, Text = "+%d%% de disparos por segundo", Percent = true },
	{ Brief = "Más balas dentro de cada cargador", Id = "Ammo", Name = "Munición", Icon = "📦", PerPoint = 0.08, Max = 10, Text = "+%d%% de balas por cargador", Percent = true },
	{ Brief = "Más chances de golpe crítico (daño extra)", Id = "Crit", Name = "Crítico", Icon = "🎯", PerPoint = 0.02, Max = 10, Text = "+%d%% de probabilidad de crítico", Percent = true },
	{ Brief = "Ganas más monedas por cada zombi", Id = "Loot", Name = "Botín", Icon = "💰", PerPoint = 0.05, Max = 10, Text = "+%d%% de monedas", Percent = true },
	{ Brief = "Tus poderes pegan más y se recargan antes", Id = "Power", Name = "Poder", Icon = "✨", PerPoint = 0.05, Max = 10, Text = "+%d%% de daño de poderes y menos espera", Percent = true },
}

-- Un talento cada 5 niveles. Cada uno se aprende una sola vez.
Config.Talents = {
	{ Brief = "Clic derecho: apuntas con zoom y más precisión", Id = "Aim", Name = "Puntería", Icon = "🔭", Description = "Mantén clic derecho para apuntar: zoom, -70% de dispersión y +15% de crítico" },
	{ Brief = "Mantén Shift para correr más rápido", Id = "Sprint", Name = "Correr", Icon = "🏃", Description = "Mantén Shift para correr un 60% más rápido (no puedes disparar mientras corres)" },
	{ Brief = "Recuperas vida si nadie te ataca", Id = "Regen", Name = "Regeneración", Icon = "💚", Description = "Recuperas 8 de vida por segundo si nadie te ataca durante 4 segundos" },
	{ Brief = "Cada baja te cura 3 de vida", Id = "Vampire", Name = "Vampiro", Icon = "🩸", Description = "Cada zombi que eliminas te cura 3 de vida" },
	{ Brief = "Un salto extra en el aire", Id = "DoubleJump", Name = "Doble salto", Icon = "🦘", Description = "Puedes saltar otra vez en el aire" },
	{ Brief = "Pulsa C: impulso rápido hacia adelante", Id = "Dash", Name = "Esquivar", Icon = "💨", Description = "Pulsa C para impulsarte hacia adelante (cada 3 segundos)" },
	{ Brief = "Sobrevives un golpe mortal por oleada", Id = "LastStand", Name = "Último aliento", Icon = "🛡️", Description = "Una vez por oleada, un golpe mortal te deja con 1 de vida y 2 segundos de invulnerabilidad" },
	{ Brief = "Algunas balas explotan y dañan en área", Id = "Explosive", Name = "Balas explosivas", Icon = "🧨", Description = "10% de probabilidad de que una bala explote y dañe a los zombis cercanos" },
	{ Brief = "+25% de monedas por cada zombi", Id = "Greed", Name = "Codicia", Icon = "💰", Description = "+25% de monedas por cada zombi" },
	{ Brief = "Mantén E junto a la campana para repararla", Id = "Repair", Name = "Reparador", Icon = "🔧", Description = "Puedes reparar la campana manteniendo E junto a ella" },
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
