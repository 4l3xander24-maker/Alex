-- Partes del mapa de la Edad Media:
--   * Caminos angostos de tierra por donde llegan los zombis, con antorchas y
--     velas a los lados. Todos se juntan antes del puente de piedra.
--   * Cementerio con cripta al principio del camino del cementerio.
--   * Ruinas de un castillo detrás de la campana: el camino pasa por su arco.
--   * Casas con entramado de madera, pozo, carreta y estandartes.
-- Las velas y antorchas solo se ponen en el tema medieval.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Paths = require(ReplicatedStorage.Shared.Paths)
local Props = require(script.Parent.Props)
local ModelLibrary = require(script.Parent.ModelLibrary)

local makePart, makeProp = Props.makePart, Props.makeProp
local STONE = Props.Colors.Stone
local DARK_WOOD = Props.Colors.DarkWood
local PLASTER = Color3.fromRGB(214, 202, 172)
local ROOF = Color3.fromRGB(96, 52, 40)
local WINDOW = Color3.fromRGB(255, 184, 96)
local GRAVE = Color3.fromRGB(110, 112, 118)

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(23)

local MedievalBuilder = {}

-- Dónde empiezan los caminos con cripta o ruinas (ahí no hay árboles). Los
-- senderos del bosque nacen entre los árboles, sin claro.
function MedievalBuilder.getEntrances(): { Vector3 }
	local entrances = {}
	for _, name in Config.PathOrder do
		if Config.Paths[name].Entrance then
			table.insert(entrances, Config.Paths[name].Points[1])
		end
	end
	return entrances
end

-- true si el punto está libre de caminos, entradas, castillo y barranco (para
-- árboles, rocas, casas...)
function MedievalBuilder.isClear(position: Vector3, margin: number): boolean
	if Paths.distanceToAny(position) < Config.PathStyle.Width / 2 + margin then
		return false
	end
	if not Paths.isGround(position, margin) then
		return false -- en el agua o pegado al acantilado
	end
	local castle = Config.Arena.Castle
	if (Vector3.new(position.X, 0, position.Z) - castle).Magnitude < 40 + margin then
		return false
	end
	for _, entrance in MedievalBuilder.getEntrances() do
		if (Vector3.new(position.X, 0, position.Z) - entrance).Magnitude < 34 + margin then
			return false
		end
	end
	return true
end

-- Pinta los caminos de tierra en el terreno. Primero los senderos del bosque,
-- así los tramos compartidos quedan del material del camino al que se unen.
-- (Lo que cae sobre el barranco lo borra después BridgeBuilder.)
function MedievalBuilder.paintPaths(terrain: Terrain)
	local width = Config.PathStyle.Width
	local order = {}
	for _, name in Config.PathOrder do
		if not Config.Paths[name].Entrance then
			table.insert(order, name)
		end
	end
	for _, name in Config.PathOrder do
		if Config.Paths[name].Entrance then
			table.insert(order, name)
		end
	end
	for _, name in order do
		local material = Enum.Material.Ground
		local points = Paths.getPoints(name)
		for index = 2, #points do
			local a, b = points[index - 1], points[index]
			local length = (b - a).Magnitude
			local middle = (a + b) / 2
			terrain:FillBlock(CFrame.lookAt(middle, b) * CFrame.new(0, -2, 0), Vector3.new(width, 4.1, length), material)
			-- Esquinas redondeadas en cada curva
			terrain:FillCylinder(CFrame.new(a.X, -2, a.Z), 4.1, width / 2, material)
		end
		-- Charcos de lodo en el camino de tierra
		if name == "Main" then
			for distance = 60, 220, 45 do
				local point = Paths.pointFromBell(name, distance + random:NextNumber(-8, 8))
				terrain:FillBall(point + Vector3.new(random:NextNumber(-1.5, 1.5), -3.4, random:NextNumber(-1.5, 1.5)), random:NextNumber(2.5, 3.5), Enum.Material.Mud)
			end
		end
	end
end

-- Antorchas y velas a los lados de los caminos
local function lightPaths(map: Instance)
	local width = Config.PathStyle.Width
	for _, name in Config.PathOrder do
		if not Config.Paths[name].Entrance then
			continue -- los senderos del bosque quedan a oscuras
		end
		local spacing = if name == "Main" then 34 else 42
		local side = 1
		for distance = 48, 240, spacing do
			local point, direction = Paths.pointFromBell(name, distance)
			if (point - Config.Paths[name].Points[1]).Magnitude < 20 then
				break
			end
			-- El puente tiene sus propias antorchas, y junto al castillo no caben
			if not Paths.isGround(point, 8) or (point - Config.Arena.Castle).Magnitude < 14 then
				continue
			end
			local across = Vector3.new(-direction.Z, 0, direction.X)
			Props.torch(map, point + across * side * (width / 2 + 1.5))
			-- Velas del otro lado, entre antorcha y antorcha
			local candlePoint = Paths.pointFromBell(name, distance + spacing / 2)
			Props.candles(map, candlePoint - across * side * (width / 2 + 1.2), nil, true)
			side = -side
		end
	end
end

local function tombstone(map: Instance, position: Vector3, facing: number)
	local kind = random:NextNumber()
	local lean = CFrame.Angles(random:NextNumber(-0.12, 0.12), facing, random:NextNumber(-0.12, 0.12))
	if kind < 0.35 then
		-- Cruz de piedra
		makeProp({ Name = "Cross", Size = Vector3.new(0.6, 4, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * lean, Material = Enum.Material.Slate, Color = Props.vary(GRAVE, 0.1, random), Parent = map })
		makeProp({ Name = "Cross", Size = Vector3.new(2.4, 0.6, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 2.9, 0)) * lean, Material = Enum.Material.Slate, Color = Props.vary(GRAVE, 0.1, random), Parent = map })
	else
		local height = random:NextNumber(2.4, 3.6)
		makePart({ Name = "Tombstone", Size = Vector3.new(2.2, height, 0.6), CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * lean, Material = Enum.Material.Slate, Color = Props.vary(GRAVE, 0.1, random), Parent = map })
		makeProp({ Name = "TombTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 2.2, 2.2), CFrame = CFrame.new(position + Vector3.new(0, height, 0)) * lean * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Slate, Color = Props.vary(GRAVE, 0.1, random), Parent = map })
	end
	-- Tierra removida delante de la tumba
	makeProp({ Name = "Grave", Size = Vector3.new(2.4, 0.3, 4.5), CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, facing, 0) * CFrame.new(0, 0, -2.6), Material = Enum.Material.Ground, Color = Color3.fromRGB(64, 50, 38), Parent = map })
end

-- Cripta de piedra con la puerta abierta mirando al camino
local function buildCrypt(map: Instance, frame: CFrame)
	local crypt = Instance.new("Model")
	crypt.Name = "Crypt"
	makePart({ Name = "CryptBase", Size = Vector3.new(16, 1, 14), CFrame = frame * CFrame.new(0, 0.5, 4), Material = Enum.Material.Cobblestone, Color = STONE, Parent = crypt })
	for _, side in { -1, 1 } do
		makePart({ Name = "CryptWall", Size = Vector3.new(2, 10, 12), CFrame = frame * CFrame.new(side * 6, 6, 4), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = crypt })
		makePart({ Name = "CryptFront", Size = Vector3.new(3.5, 10, 2), CFrame = frame * CFrame.new(side * 3.25, 6, -1), Material = Enum.Material.Slate, Color = STONE, Parent = crypt })
		makePart({ Name = "CryptRoof", Size = Vector3.new(16, 3, 7.5), CFrame = frame * CFrame.new(0, 12.5, 4 + side * 3.5) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 72, 80), Parent = crypt }, "WedgePart")
		makeProp({ Name = "Pillar", Size = Vector3.new(1.4, 10, 1.4), CFrame = frame * CFrame.new(side * 6.5, 6, -2.4), Material = Enum.Material.Marble, Color = Color3.fromRGB(150, 150, 156), Parent = crypt })
	end
	makePart({ Name = "CryptBack", Size = Vector3.new(10, 10, 2), CFrame = frame * CFrame.new(0, 6, 9), Material = Enum.Material.Slate, Color = STONE, Parent = crypt })
	makePart({ Name = "Lintel", Size = Vector3.new(4, 3, 2), CFrame = frame * CFrame.new(0, 9.5, -1), Material = Enum.Material.Slate, Color = STONE, Parent = crypt })
	-- Oscuridad adentro y una calavera sobre la puerta
	makeProp({ Name = "Darkness", Size = Vector3.new(3, 7.6, 0.2), CFrame = frame * CFrame.new(0, 4.8, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(8, 10, 12), Parent = crypt })
	makeProp({ Name = "Skull", Size = Vector3.new(1.2, 1.1, 0.6), CFrame = frame * CFrame.new(0, 9.6, -2.1), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(226, 220, 200), Parent = crypt })
	local glow = makeProp({ Name = "SkullEyes", Size = Vector3.new(0.8, 0.22, 0.1), CFrame = frame * CFrame.new(0, 9.75, -2.42), Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 255, 120), Parent = crypt })
	Props.light(glow, Color3.fromRGB(120, 255, 120), 14, 1.2)
	crypt.Parent = map
end

-- Cementerio con reja de hierro alrededor y la cripta al fondo
local function buildGraveyard(map: Instance, entrance: Vector3, outward: Vector3)
	local facing = math.atan2(-outward.X, -outward.Z)
	local frame = CFrame.lookAt(entrance, entrance + outward)
	buildCrypt(map, frame * CFrame.new(0, 0, -6) * CFrame.Angles(0, math.pi, 0))
	for row = 1, 3 do
		for column = -3, 3 do
			-- Las columnas del centro quedan libres para la cripta y el camino
			if math.abs(column) >= 2 and random:NextNumber() < 0.85 then
				local spot = frame * CFrame.new(column * 5 + random:NextNumber(-0.8, 0.8), 0, -row * 6.5 + 4)
				tombstone(map, spot.Position, facing + math.pi)
				if theme.Medieval and random:NextNumber() < 0.35 then
					Props.candles(map, (spot * CFrame.new(0, 0, -1.5)).Position, 3, random:NextNumber() < 0.5)
				end
			end
		end
	end
	-- Reja de hierro con hueco en la entrada
	local half = 20
	for step = -half, half, 2 do
		for _, post in { Vector3.new(step, 0, 6), Vector3.new(-half, 0, step - 14), Vector3.new(half, 0, step - 14) } do
			if math.abs(post.X) > 5 or post.Z ~= 6 then
				makeProp({ Name = "FenceBar", Size = Vector3.new(0.18, 3.6, 0.18), CFrame = frame * CFrame.new(post + Vector3.new(0, 1.8, 0)), Material = Enum.Material.Metal, Color = Props.Colors.Iron, Parent = map })
			end
		end
	end
	for _, side in { -1, 1 } do
		makePart({ Name = "GatePillar", Size = Vector3.new(1.6, 5, 1.6), CFrame = frame * CFrame.new(side * 5, 2.5, 6), Material = Enum.Material.Slate, Color = STONE, Parent = map })
		if theme.Medieval then
			Props.torch(map, (frame * CFrame.new(side * 5, 5, 6)).Position, 1.2)
		end
	end
end

-- Ruinas de un castillo: muros rotos, una torre partida y un arco por donde
-- pasa el camino (archHalf: medio ancho del hueco del arco)
local function buildRuins(map: Instance, entrance: Vector3, outward: Vector3, archHalf: number)
	local frame = CFrame.lookAt(entrance, entrance + outward)
	local function wall(offset: CFrame, length: number, height: number, battlements: boolean)
		local cf = frame * offset
		makePart({ Name = "RuinWall", Size = Vector3.new(length, height, 3), CFrame = cf * CFrame.new(0, height / 2, 0), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.08, random), Parent = map })
		-- Zócalo más ancho abajo y cornisa arriba
		makePart({ Name = "WallPlinth", Size = Vector3.new(length + 0.4, 1.4, 3.8), CFrame = cf * CFrame.new(0, 0.7, 0), Material = Enum.Material.Cobblestone, Color = Props.vary(STONE, 0.1, random), Parent = map })
		makeProp({ Name = "WallCornice", Size = Vector3.new(length + 0.3, 0.5, 3.5), CFrame = cf * CFrame.new(0, height - 0.25, 0), Material = Enum.Material.Slate, Color = STONE:Lerp(Color3.new(1, 1, 1), 0.1), Parent = map })
		-- Hiedra y musgo del lado del campamento
		for _ = 1, math.floor(length / 7) do
			local ivyHeight = random:NextNumber(2, height * 0.8)
			local ivy = makeProp({ Name = "Ivy", Size = Vector3.new(random:NextNumber(1.5, 4), ivyHeight, 0.3), CFrame = cf * CFrame.new(random:NextNumber(-length / 2 + 2, length / 2 - 2), ivyHeight / 2 + 0.6, 1.6), Material = Enum.Material.LeafyGrass, Color = Props.vary(Color3.fromRGB(58, 96, 44), 0.12, random), Parent = map })
			Props.sway(ivy, (cf * CFrame.new(0, height, 1.6)).Position, 0.01)
		end
		makeProp({ Name = "Moss", Size = Vector3.new(length, 0.5, 0.25), CFrame = cf * CFrame.new(0, 1.55, 1.95), Material = Enum.Material.Grass, Color = Color3.fromRGB(70, 104, 50), Parent = map })
		if battlements then
			for x = -length / 2 + 1, length / 2 - 1, 3 do
				if random:NextNumber() < 0.7 then
					makeProp({ Name = "Merlon", Size = Vector3.new(1.6, 1.6, 3), CFrame = cf * CFrame.new(x, height + 0.8, 0), Material = Enum.Material.Slate, Color = STONE, Parent = map })
				end
			end
		end
		-- Piedras caídas al pie del muro
		for _ = 1, 3 do
			local size = random:NextNumber(1, 2.4)
			makeProp({ Name = "Rubble", Size = Vector3.one * size, CFrame = cf * CFrame.new(random:NextNumber(-length / 2, length / 2), size / 2, random:NextNumber(2, 4)) * CFrame.Angles(random:NextNumber(0, 1), random:NextNumber(0, 3), 0), Material = Enum.Material.Cobblestone, Color = STONE, Parent = map })
		end
	end
	-- Arco de medio punto por donde pasan los zombis (los jefes caben: la
	-- clave queda a 14 + pillarX studs)
	local pillarX = archHalf + 1.5
	local spring = 14 -- altura donde arranca la curva
	local crown = spring + pillarX + 1.5
	for _, side in { -1, 1 } do
		makePart({ Name = "ArchPillar", Size = Vector3.new(3.4, crown, 3.4), CFrame = frame * CFrame.new(side * pillarX, crown / 2, -3), Material = Enum.Material.Slate, Color = STONE, Parent = map })
		makePart({ Name = "ArchBase", Size = Vector3.new(4.2, 1.6, 4.2), CFrame = frame * CFrame.new(side * pillarX, 0.8, -3), Material = Enum.Material.Cobblestone, Color = Props.vary(STONE, 0.1, random), Parent = map })
		wall(CFrame.new(side * (pillarX + 11), 0, -3), 19, random:NextNumber(7, 11), true)
	end
	local stones = 13
	for index = 0, stones - 1 do
		local angle = (index + 0.5) / stones * math.pi
		local position = Vector3.new(math.cos(angle) * pillarX, spring + math.sin(angle) * pillarX, -3)
		local keystone = index == math.floor(stones / 2)
		makePart({
			Name = if keystone then "Keystone" else "Voussoir",
			Size = Vector3.new(pillarX * math.pi / stones * 1.04, if keystone then 3.6 else 3, if keystone then 3.4 else 3),
			CFrame = frame * CFrame.new(position) * CFrame.Angles(0, 0, angle - math.pi / 2),
			Material = Enum.Material.Slate,
			Color = if keystone then STONE:Lerp(Color3.new(1, 1, 1), 0.15) else Props.vary(STONE, 0.07, random),
			Parent = map,
		})
	end
	makePart({ Name = "ArchTop", Size = Vector3.new(pillarX * 2 + 3.4, 2.4, 3.4), CFrame = frame * CFrame.new(0, crown + 1.2, -3), Material = Enum.Material.Slate, Color = STONE, Parent = map })
	for x = -pillarX, pillarX, 3 do
		makeProp({ Name = "Merlon", Size = Vector3.new(1.6, 1.8, 3.2), CFrame = frame * CFrame.new(x, crown + 3.3, -3), Material = Enum.Material.Slate, Color = STONE, Parent = map })
	end
	wall(CFrame.new(-(pillarX + 20), 0, -14) * CFrame.Angles(0, math.pi / 2, 0), 20, 7, true)
	wall(CFrame.new(pillarX + 20, 0, -16) * CFrame.Angles(0, math.pi / 2, 0), 16, 4, false)

	-- Dos torres redondas con techo cónico de tejas, troneras y bandera
	for _, side in { 1, -1 } do
		local towerCenter = frame * CFrame.new(side * (pillarX + 18), 0, -20)
		local diameter = 10
		local height = 24
		makePart({ Name = "TowerBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, diameter + 1.4, diameter + 1.4), CFrame = towerCenter * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Cobblestone, Color = Props.vary(STONE, 0.08, random), Parent = map })
		makePart({ Name = "Tower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter), CFrame = towerCenter * CFrame.new(0, height / 2, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.06, random), Parent = map })
		makePart({ Name = "TowerRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, diameter + 1.2, diameter + 1.2), CFrame = towerCenter * CFrame.new(0, height + 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = STONE:Lerp(Color3.new(1, 1, 1), 0.1), Parent = map })
		-- Troneras mirando al campamento
		for _, slitY in { 8, 14, 20 } do
			makeProp({ Name = "ArrowSlit", Size = Vector3.new(0.5, 2.2, 0.3), CFrame = towerCenter * CFrame.new(0, slitY, diameter / 2 - 0.05), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(24, 22, 26), Parent = map })
		end
		-- Techo cónico de tejas
		local roofY = height + 1.2
		for index, width in { diameter + 2, diameter, diameter - 2.2, diameter - 4.4, diameter - 6.4, 2, 0.8 } do
			makePart({ Name = "TowerRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, width, width), CFrame = towerCenter * CFrame.new(0, roofY + (index - 0.5) * 1.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.ClayRoofTiles, Color = Color3.fromRGB(128, 54, 40), Parent = map })
		end
		local poleTop = roofY + 7 * 1.6 + 4
		makeProp({ Name = "FlagPole", Size = Vector3.new(0.3, 5, 0.3), CFrame = towerCenter * CFrame.new(0, poleTop - 2.5, 0), Material = Enum.Material.Wood, Color = Color3.fromRGB(70, 48, 30), Parent = map })
		local flag = makeProp({ Name = "Flag", Size = Vector3.new(2.8, 1.6, 0.1), CFrame = towerCenter * CFrame.new(1.55, poleTop - 0.9, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 110, 60), Parent = map })
		Props.sway(flag, (towerCenter * CFrame.new(0, poleTop - 0.9, 0)).Position, 0.08)
	end
	if theme.Medieval then
		Props.torch(map, (frame * CFrame.new(-pillarX, 0, 0)).Position)
		Props.torch(map, (frame * CFrame.new(pillarX, 0, 0)).Position)
		Props.banner(map, (frame * CFrame.new(-(pillarX + 5), 0, 0)).Position, math.atan2(-outward.X, -outward.Z), Color3.fromRGB(40, 110, 60))
	end
end

-- Casa con entramado de madera, techo de tejas, chimenea y ventanas encendidas
local HOUSE_MODELS = { "HouseA", "HouseB", "HouseC" }
local houseCount = 0

local function buildHouse(map: Instance, frame: CFrame, width: number, depth: number)
	-- Casa medieval de la tienda (se van turnando los tres modelos)
	houseCount += 1
	local name = HOUSE_MODELS[(houseCount - 1) % #HOUSE_MODELS + 1]
	if ModelLibrary.place(name, frame, { Footprint = math.max(width, depth) * 1.7 }, true, map) then
		if theme.Medieval then
			Props.candles(map, (frame * CFrame.new(2.6, 0, -depth / 2 - 3)).Position, 3, false)
		end
		return
	end
	local house = Instance.new("Model")
	house.Name = "House"
	local wallHeight = 9
	local roofHeight = depth * 0.45
	makePart({ Name = "Foundation", Size = Vector3.new(width + 0.6, 1.6, depth + 0.6), CFrame = frame * CFrame.new(0, 0.8, 0), Material = Enum.Material.Cobblestone, Color = STONE, Parent = house })
	makePart({ Name = "Walls", Size = Vector3.new(width, wallHeight - 1.6, depth), CFrame = frame * CFrame.new(0, 1.6 + (wallHeight - 1.6) / 2, 0), Material = Enum.Material.Plaster, Color = PLASTER, Parent = house })

	-- Vigas: esquinas, horizontales y diagonales
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		makeProp({ Name = "Post", Size = Vector3.new(0.7, wallHeight, 0.7), CFrame = frame * CFrame.new(corner.X * width / 2, wallHeight / 2, corner.Z * depth / 2), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
	end
	for _, y in { 4.6, wallHeight } do
		for _, side in { -1, 1 } do
			makeProp({ Name = "Beam", Size = Vector3.new(width + 0.2, 0.5, 0.3), CFrame = frame * CFrame.new(0, y, side * (depth / 2 + 0.05)), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
			makeProp({ Name = "Beam", Size = Vector3.new(0.3, 0.5, depth + 0.2), CFrame = frame * CFrame.new(side * (width / 2 + 0.05), y, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
		end
	end
	for _, side in { -1, 1 } do
		for _, x in { -width / 3, width / 3 } do
			local brace = math.sqrt((width / 3) ^ 2 + 4.4 ^ 2)
			makeProp({ Name = "Brace", Size = Vector3.new(0.4, brace, 0.3), CFrame = frame * CFrame.new(x, 6.8, side * (depth / 2 + 0.06)) * CFrame.Angles(0, 0, math.atan2(width / 3, 4.4) * (if x > 0 then 1 else -1) * 0.6), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
		end
	end

	-- Techo a dos aguas con los triángulos de los lados
	for _, side in { -1, 1 } do
		local turn = CFrame.Angles(0, if side > 0 then math.pi else 0, 0)
		makePart({ Name = "Roof", Size = Vector3.new(width + 1.6, roofHeight, depth / 2 + 0.9), CFrame = frame * CFrame.new(0, wallHeight + roofHeight / 2, side * (depth / 4 + 0.45)) * turn, Material = Enum.Material.ClayRoofTiles, Color = Props.vary(ROOF, 0.1, random), Parent = house }, "WedgePart")
		for _, end_ in { -1, 1 } do
			makeProp({ Name = "Gable", Size = Vector3.new(0.4, roofHeight, depth / 2), CFrame = frame * CFrame.new(end_ * (width / 2 - 0.2), wallHeight + roofHeight / 2, side * depth / 4) * turn, Material = Enum.Material.Plaster, Color = PLASTER, Parent = house }, "WedgePart")
		end
	end
	makePart({ Name = "Chimney", Size = Vector3.new(1.8, roofHeight + 3, 1.8), CFrame = frame * CFrame.new(width / 2 - 2, wallHeight + (roofHeight + 3) / 2, depth / 5), Material = Enum.Material.Brick, Color = Color3.fromRGB(120, 70, 56), Parent = house })

	-- Puerta y ventanas (la del frente con luz cálida)
	makeProp({ Name = "Door", Size = Vector3.new(2.6, 4.4, 0.3), CFrame = frame * CFrame.new(0, 3.8, -depth / 2 - 0.1), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 44, 28), Parent = house })
	for index, x in { -width / 4 - 0.6, width / 4 + 0.6 } do
		for _, side in { -1, 1 } do
			local window = makeProp({ Name = "Window", Size = Vector3.new(1.8, 1.8, 0.2), CFrame = frame * CFrame.new(x, 6.6, side * (depth / 2 + 0.08)), Material = Enum.Material.Neon, Color = WINDOW, Parent = house })
			makeProp({ Name = "WindowBar", Size = Vector3.new(0.2, 1.9, 0.25), CFrame = window.CFrame, Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
			makeProp({ Name = "WindowBar", Size = Vector3.new(1.9, 0.2, 0.25), CFrame = window.CFrame, Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = house })
			if index == 1 and side < 0 then
				Props.flickerLight(window, WINDOW, 16, 0.9)
			end
		end
	end
	house.Parent = map
	if theme.Medieval then
		Props.candles(map, (frame * CFrame.new(2.6, 0, -depth / 2 - 1.5)).Position, 3, false)
	end
end

local function buildWell(map: Instance, position: Vector3)
	makePart({ Name = "WellRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 6, 6), CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Cobblestone, Color = STONE, Parent = map })
	makeProp({ Name = "WellWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 4.6, 4.6), CFrame = CFrame.new(position + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Glass, Color = Color3.fromRGB(16, 30, 40), Parent = map })
	for _, side in { -1, 1 } do
		makePart({ Name = "WellPost", Size = Vector3.new(0.5, 6.5, 0.5), Position = position + Vector3.new(side * 2.6, 3.25, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makeProp({ Name = "WellRoof", Size = Vector3.new(6.5, 1.6, 2.4), CFrame = CFrame.new(position + Vector3.new(0, 7.2, side * 1.2)) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0), Material = Enum.Material.WoodPlanks, Color = ROOF, Parent = map }, "WedgePart")
	end
	makeProp({ Name = "Crank", Size = Vector3.new(5.6, 0.3, 0.3), Position = position + Vector3.new(0, 5.4, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	makeProp({ Name = "Bucket", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 0.9, 0.9), CFrame = CFrame.new(position + Vector3.new(0, 4.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 76, 46), Parent = map })
end

local function buildCart(map: Instance, frame: CFrame)
	makePart({ Name = "CartBed", Size = Vector3.new(4.5, 1.6, 7), CFrame = frame * CFrame.new(0, 2.4, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(116, 80, 50), Parent = map })
	makeProp({ Name = "Hay", Size = Vector3.new(4, 1.5, 6), CFrame = frame * CFrame.new(0, 3.6, 0), Material = Enum.Material.LeafyGrass, Color = Color3.fromRGB(196, 170, 90), Parent = map })
	for _, side in { -1, 1 } do
		makeProp({ Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 3.4, 3.4), CFrame = frame * CFrame.new(side * 2.5, 1.7, 0.6), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makeProp({ Name = "Handle", Size = Vector3.new(0.3, 0.3, 4.5), CFrame = frame * CFrame.new(side * 1.4, 1.6, -5.4) * CFrame.Angles(-0.25, 0, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
end

-- Cementerio y castillo existen en todos los temas; casas, velas, antorchas
-- y estandartes solo en el medieval.
function MedievalBuilder.build(map: Instance)
	local mainPoints = Config.Paths.Main.Points
	buildGraveyard(map, mainPoints[1], (mainPoints[1] - mainPoints[2]).Unit)
	-- El castillo mira hacia el puente; el arco deja pasar a los jefes grandes
	buildRuins(map, Config.Arena.Castle, Vector3.new(0, 0, -1), 8.5)
	if not theme.Medieval then
		return
	end

	lightPaths(map)

	-- La aldea, en su isla: casas mirando a la plaza, el pozo y una carreta
	local village = Config.Arena.Islands.Village.Disks[1]
	local plaza = Vector3.new(village.Center.X, 0, village.Center.Y)
	local houses = {
		{ Vector3.new(125, 0, -45), 14, 10 },
		{ Vector3.new(160, 0, -35), 12, 9 },
		{ Vector3.new(168, 0, 5), 13, 10 },
		{ Vector3.new(145, 0, 28), 12, 9 },
	}
	for _, house in houses do
		local frame = CFrame.lookAt(house[1], plaza) * CFrame.Angles(0, random:NextNumber(-0.2, 0.2), 0)
		buildHouse(map, frame, house[2], house[3])
	end
	buildWell(map, plaza + Vector3.new(0, 0, 5))
	buildCart(map, CFrame.new(plaza + Vector3.new(16, 0, -10)) * CFrame.Angles(0, 0.6, 0))
	Props.banner(map, plaza + Vector3.new(-8, 0, -6), 0, Color3.fromRGB(40, 110, 60))

	-- Velas al pie del montículo de la campana
	for _, corner in { Vector3.new(-12, 0, 6), Vector3.new(12, 0, 6), Vector3.new(-12, 0, -6), Vector3.new(12, 0, -6) } do
		Props.candles(map, corner, 5, true)
	end
end

return MedievalBuilder
