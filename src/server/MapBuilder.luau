-- Construye el mapa por código para que el juego funcione en un lugar vacío:
-- la isla principal con la campana sobre un montículo (BellTower), el círculo
-- de runas donde aparecen los jugadores y el campamento detrás (fogata,
-- tiendas, empalizada y los NPC); la isla de la aldea (la Bruja y el molino),
-- a la que se llega por un puente de madera roto; y al norte, cruzando el
-- puente de piedra en diagonal (BridgeBuilder), el bosque de donde salen los
-- zombis. Todo lo demás es mar (IslandBuilder).
-- Según el tema: noche medieval con velas, atardecer de otoño o noche con luna.
-- Usa materiales con textura y luz Future para verse lo más realista posible.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DayCycle = require(ReplicatedStorage.Shared.DayCycle)
local Paths = require(ReplicatedStorage.Shared.Paths)
local BellTower = require(script.Parent.BellTower)
local BridgeBuilder = require(script.Parent.BridgeBuilder)
local CampBuilder = require(script.Parent.CampBuilder)
local IslandBuilder = require(script.Parent.IslandBuilder)
local MedievalBuilder = require(script.Parent.MedievalBuilder)
local VoxelBuilder = require(script.Parent.VoxelBuilder)
local Props = require(script.Parent.Props)
local ModelLibrary = require(script.Parent.ModelLibrary)

local MOON_DIRECTION = Vector3.new(0, 0.42, -1).Unit
-- De día el sol queda bajo, a un lado y detrás del jugador que mira a la horda
local SUN_DIRECTION = Vector3.new(0.75, 0.32, 0.55).Unit
local TRUNK = Color3.fromRGB(88, 62, 44)

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local voxel = Props.voxel
local random = Random.new(7)
local makePart, makeProp = Props.makePart, Props.makeProp

local MapBuilder = {}

local function buildTerrain()
	local terrain = workspace.Terrain
	local arena = Config.Arena
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Grass, theme.Ground)
	-- Las manchas de LeafyGrass hacen de hojas caídas
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, theme.LeafLitter)
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(150, 142, 128))
	terrain:SetMaterialColor(Enum.Material.Ground, theme.Ground:Lerp(Color3.fromRGB(80, 60, 40), 0.65))
	terrain:SetMaterialColor(Enum.Material.Mud, theme.Ground:Lerp(Color3.fromRGB(50, 38, 28), 0.7))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(78, 82, 88))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(150, 140, 110))

	-- Mar, bosque al norte e islas
	IslandBuilder.buildTerrain(terrain)

	-- Manchas de pasto alto y lodo en el campo de batalla
	for _ = 1, 40 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(30, 230)
		local position = Vector3.new(math.cos(angle) * radius, -3.2, math.sin(angle) * radius)
		position += Vector3.new(0, Paths.groundHeight(position), 0)
		if Paths.isGround(position, 10) then
			local material = if random:NextNumber() < 0.6 then Enum.Material.LeafyGrass else Enum.Material.Mud
			terrain:FillBall(position, random:NextNumber(4, 9), material)
		end
	end

	-- Tierra pisada en el campamento y el camino hacia la campana
	local camp = arena.CampCenter
	terrain:FillCylinder(CFrame.new(camp.X, -2, camp.Z), 4.1, arena.CampRadius, Enum.Material.Ground)
	-- Camino de adoquines del campamento a la campana, y un anillo alrededor de la torre
	local bell = arena.Bell
	terrain:FillBlock(CFrame.new(bell.X, -2, (bell.Z + camp.Z) / 2), Vector3.new(9, 4.1, camp.Z - bell.Z), Enum.Material.Cobblestone)
	terrain:FillCylinder(CFrame.new(bell.X, -2, bell.Z), 4.1, arena.TowerSize / 2 + 5, Enum.Material.Cobblestone)
	-- Los caminos angostos por donde llegan los zombis (no sobre el agua)
	MedievalBuilder.paintPaths(terrain)

	-- Pasto 3D animado (si Roblox lo permite desde un script)
	pcall(function()
		(terrain :: any).Decoration = true
	end)
end

-- Los árboles y rocas van en tierra firme, no pegados al borde. En la aldea
-- no hay árboles sueltos: ahí van las casas, el molino y la Bruja.
local function onLand(position: Vector3, margin: number): boolean
	return Paths.isGround(position, margin) and not Paths.onIsland(position, "Village", -6)
end

-- La campana (destruida al empezar) sobre su montículo, con los avisos para
-- reconstruirla y repararla
local function buildTower(map: Instance)
	local mound = BellTower.build(map)

	-- Talento Reparador: mantener E junto al montículo
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RepairPrompt"
	prompt.ActionText = "Reparar campana"
	prompt.ObjectText = "Campana"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Repair", true)
	prompt.Parent = mound

	-- Durante la preparación: reconstruir la campana para empezar la partida
	local start = Instance.new("ProximityPrompt")
	start.Name = "StartPrompt"
	start.ActionText = "Reconstruir la campana"
	start.ObjectText = "Campana destruida"
	start.HoldDuration = 1.5
	start.MaxActivationDistance = 18
	start.RequiresLineOfSight = false
	start.UIOffset = Vector2.new(0, 60)
	start.Parent = mound
end

-- Círculo negro de runas donde aparecen los jugadores (como en Guns 'n
-- Goblins): un octágono oscuro con runas que brillan un poco, rodeado de losas
local function buildSpawnCircle(map: Instance)
	local center = Config.Arena.SpawnCircle
	local radius = 5
	local circle = Instance.new("Model")
	circle.Name = "SpawnCircle"
	-- Cuatro rectángulos girados de a 45° forman el octágono
	local side = radius * 2 * math.tan(math.rad(22.5))
	for index = 0, 3 do
		makePart({ Name = "RuneStone", Size = Vector3.new(side, 0.35, radius * 2), CFrame = CFrame.new(center + Vector3.new(0, 0.175, 0)) * CFrame.Angles(0, index * math.pi / 4, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(24, 26, 30), Parent = circle })
	end
	-- Losas claras alrededor, una por cada lado del octágono
	for index = 0, 7 do
		local angle = index * math.pi / 4 + math.pi / 8
		local flag = CFrame.new(center) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.12, -(radius + 1.1))
		makePart({ Name = "CircleFlagstone", Size = Vector3.new(side + 1.6, 0.24, 2.2), CFrame = flag, Material = Enum.Material.Slate, Color = Props.vary(Color3.fromRGB(150, 150, 140), 0.08, random), Parent = circle })
		if random:NextNumber() < 0.5 then
			makeProp({ Name = "Moss", Size = Vector3.new(random:NextNumber(0.6, 1.4), 0.06, random:NextNumber(0.4, 1)), CFrame = flag * CFrame.new(random:NextNumber(-1, 1), 0.14, random:NextNumber(-0.5, 0.5)), Material = Enum.Material.LeafyGrass, Color = Color3.fromRGB(80, 130, 60), Parent = circle })
		end
	end
	-- Runas: tres renglones de marcas que brillan apenas
	local rune = Color3.fromRGB(150, 210, 190)
	for row = -1, 1 do
		local count = if row == 0 then 7 else 5
		for column = 1, count do
			local x = (column - (count + 1) / 2) * 1.05
			local base = CFrame.new(center + Vector3.new(x, 0.36, row * 1.8))
			for stroke = 1, random:NextInteger(2, 3) do
				local tall = random:NextNumber() < 0.5
				local size = if tall then Vector3.new(0.14, 0.04, random:NextNumber(0.5, 0.9)) else Vector3.new(random:NextNumber(0.4, 0.7), 0.04, 0.14)
				makeProp({ Name = "Rune", Size = size, CFrame = base * CFrame.new(random:NextNumber(-0.25, 0.25), 0, random:NextNumber(-0.3, 0.3)) * CFrame.Angles(0, if stroke == 3 then math.rad(45) else 0, 0), Material = Enum.Material.Neon, Color = rune, Transparency = 0.35, CastShadow = false, Parent = circle })
			end
		end
	end
	local glow = makeProp({ Name = "RuneGlow", Size = Vector3.one * 0.2, Position = center + Vector3.new(0, 1, 0), Transparency = 1, Parent = circle })
	Props.light(glow, rune, 12, 0.6)
	circle.Parent = map

	-- Donde aparecen: invisible, sobre el círculo, mirando a la campana
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "RuneSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = CFrame.lookAt(center + Vector3.new(0, 0.5, 0), Vector3.new(0, 0.5, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Parent = map
	local decal = spawn:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end
end

local function buildPine(map: Instance, position: Vector3, scale: number)
	local tree = Instance.new("Model")
	tree.Name = "Pine"
	makeProp({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 1.3, 1.3) * scale, CFrame = CFrame.new(position + Vector3.new(0, 2 * scale, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Wood, Color = TRUNK, Parent = tree })
	local color = Props.vary(theme.Tree, 0.15, random)
	local y = 4 * scale
	for index, width in { 9, 7, 5, 3 } do
		local layerHeight = (if index == 4 then 2.5 else 3.2) * scale
		local leaves = makeProp({
			Name = "Leaves",
			Size = Vector3.new(width * scale, layerHeight, width * scale),
			CFrame = CFrame.new(position + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi / 2), 0),
			Material = Enum.Material.LeafyGrass,
			Color = color:Lerp(Color3.new(1, 1, 1), index * 0.03),
			Parent = tree,
		})
		-- Las capas de arriba se mecen más
		Props.sway(leaves, position, 0.012 * index)
		y += layerHeight * 0.8
	end
	tree.Parent = map
end

local function pickFoliage(): Color3
	local palette = theme.Foliage
	return Props.vary(palette[random:NextInteger(1, #palette)], 0.08, random)
end

-- Árbol de otoño: tronco, dos ramas y una copa redonda de varias bolas de hojas
local function buildAutumnTree(map: Instance, position: Vector3, scale: number)
	-- Modelo 3D de la tienda: casi siempre el árbol B (4 piezas, más liviano)
	local name = if random:NextNumber() < 0.75 then "TreeB" else "TreeA"
	local rotation = CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
	if ModelLibrary.place(name, CFrame.new(position) * rotation, { Height = 14 * scale * random:NextNumber(0.9, 1.1) }, false, map) then
		return
	end
	local tree = Instance.new("Model")
	tree.Name = "AutumnTree"
	local height = 8 * scale
	makeProp({ Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, 1.3 * scale, 1.3 * scale), CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Wood, Color = TRUNK, Parent = tree })
	for _, side in { -1, 1 } do
		makeProp({ Name = "Branch", Size = Vector3.new(0.5, 3.4, 0.5) * scale, CFrame = CFrame.new(position + Vector3.new(side * 1.1 * scale, height * 0.7, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi), side * 0.7), Material = Enum.Material.Wood, Color = TRUNK, Parent = tree })
	end
	local base = pickFoliage()
	local blobs = {
		{ Vector3.new(0, 1.6, 0), 4.6 },
		{ Vector3.new(2.6, 0, 0.8), 3.4 },
		{ Vector3.new(-2.4, 0.2, -0.6), 3.5 },
		{ Vector3.new(0.6, -0.2, 2.6), 3.2 },
		{ Vector3.new(-0.5, 0.4, -2.6), 3.3 },
	}
	for _, blob in blobs do
		local radius = blob[2] * scale * random:NextNumber(0.9, 1.1)
		local leaves = makeProp({
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * radius * 2,
			Position = position + Vector3.new(0, height, 0) + blob[1] * scale,
			Material = Enum.Material.LeafyGrass,
			Color = Props.vary(base, 0.06, random),
			Parent = tree,
		})
		Props.sway(leaves, position, 0.035)
	end
	tree.Parent = map
end

-- Árbol seco y retorcido para la noche medieval
local function buildDeadTree(map: Instance, position: Vector3, scale: number)
	local tree = Instance.new("Model")
	tree.Name = "DeadTree"
	local bark = Color3.fromRGB(62, 52, 46)
	local height = 9 * scale
	local lean = CFrame.Angles(random:NextNumber(-0.12, 0.12), random:NextNumber(0, math.pi * 2), random:NextNumber(-0.12, 0.12))
	local base = CFrame.new(position) * lean
	makeProp({ Name = "Trunk", Size = Vector3.new(1.3, height, 1.3) * Vector3.new(scale, 1, scale), CFrame = base * CFrame.new(0, height / 2, 0), Material = Enum.Material.Wood, Color = bark, Parent = tree })
	for index = 1, random:NextInteger(3, 5) do
		local y = height * random:NextNumber(0.45, 0.95)
		local length = random:NextNumber(3, 5.5) * scale
		local angle = index / 5 * math.pi * 2 + random:NextNumber(-0.4, 0.4)
		local branch = base * CFrame.new(0, y, 0) * CFrame.Angles(0, angle, 0) * CFrame.Angles(0, 0, random:NextNumber(0.6, 1.1))
		local limb = makeProp({ Name = "Branch", Size = Vector3.new(0.45 * scale, length, 0.45 * scale), CFrame = branch * CFrame.new(0, length / 2, 0), Material = Enum.Material.Wood, Color = bark, Parent = tree })
		-- Ramita en la punta
		local twig = makeProp({ Name = "Twig", Size = Vector3.new(0.25 * scale, length * 0.45, 0.25 * scale), CFrame = branch * CFrame.new(0, length, 0) * CFrame.Angles(0, 0, -0.8) * CFrame.new(0, length * 0.2, 0), Material = Enum.Material.Wood, Color = bark, Parent = tree })
		-- Las ramas secas crujen con el viento desde donde salen del tronco
		local joint = (base * CFrame.new(0, y, 0)).Position
		Props.sway(limb, joint, 0.04)
		Props.sway(twig, joint, 0.06)
	end
	tree.Parent = map
end

local function buildTree(map: Instance, position: Vector3, scale: number)
	if theme.DeadTrees and random:NextNumber() < 0.35 then
		buildDeadTree(map, position, scale)
	elseif theme.Foliage and random:NextNumber() < 0.7 then
		buildAutumnTree(map, position, scale * 0.9)
	else
		buildPine(map, position, scale)
	end
end

local function buildBush(map: Instance, position: Vector3)
	local color = if theme.Foliage then pickFoliage() else Props.vary(theme.Tree, 0.15, random)
	for index = 1, random:NextInteger(1, 3) do
		-- En pixel art 3D son cubos más chicos para que no parezcan muros
		local radius = random:NextNumber(1.2, 2.4) * (if voxel then 0.6 else 1)
		local bush = makeProp({
			Name = "Bush",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * radius * 2,
			Position = position + Vector3.new(random:NextNumber(-1.5, 1.5) * (index - 1), radius * 0.6, random:NextNumber(-1.5, 1.5) * (index - 1)),
			Material = Enum.Material.LeafyGrass,
			Color = Props.vary(color, 0.08, random),
			CastShadow = false,
			Parent = map,
		})
		Props.sway(bush, position, 0.05)
	end
end

-- Molino de viento de piedra al lado del campamento. Las aspas las gira
-- cada cliente (WorldFx), así no gasta red.
local function buildWindmill(map: Instance, position: Vector3)
	local windmill = Instance.new("Model")
	windmill.Name = "Windmill"
	local stone = Color3.fromRGB(150, 140, 125)
	local upright = CFrame.Angles(0, 0, math.pi / 2)
	local function ring(name: string, height: number, diameter: number, y: number, material: Enum.Material, color: Color3, prop: boolean?)
		local props = { Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(height, diameter, diameter), CFrame = CFrame.new(position + Vector3.new(0, y, 0)) * upright, Material = material, Color = color, Parent = windmill }
		return if prop then makeProp(props) else makePart(props)
	end
	-- Zócalo y torre que se angosta hacia arriba
	ring("Plinth", 1.4, 12, 0.7, Enum.Material.Cobblestone, Props.vary(stone, 0.06, random))
	local y = 1.4
	for index = 0, 7 do
		local height = 2.3
		ring("Wall", height, 10.4 - index * 0.38, y + height / 2, Enum.Material.Cobblestone, Props.vary(stone, 0.05, random))
		y += height
	end
	local top = y
	-- Balcón de madera alrededor, con baranda
	ring("Gallery", 0.4, 11.2, top - 4.4, Enum.Material.WoodPlanks, Color3.fromRGB(110, 76, 46))
	for index = 0, 15 do
		local angle = index / 16 * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 5.4, top - 3.6, math.sin(angle) * 5.4)
		makeProp({ Name = "Baluster", Size = Vector3.new(0.18, 1.4, 0.18), Position = position + offset, Material = Enum.Material.Wood, Color = TRUNK, Parent = windmill })
	end
	ring("Rail", 0.2, 11, top - 2.9, Enum.Material.Wood, TRUNK, true)
	-- Techo cónico de tejas, más suave (más capas)
	ring("Eave", 0.6, 9.6, top + 0.3, Enum.Material.Wood, TRUNK)
	local roofY = top + 0.6
	for index = 0, 9 do
		local width = 9.2 - index * 0.9
		ring("Roof", 0.8, width, roofY + 0.4 + index * 0.8, Enum.Material.ClayRoofTiles, Color3.fromRGB(130, 56, 42))
	end
	makeProp({ Name = "RoofKnob", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.8, Position = position + Vector3.new(0, roofY + 8.6, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = windmill })
	-- Puerta con marco y escalón, mirando al campamento (+X)
	makePart({ Name = "DoorStep", Size = Vector3.new(1.4, 0.6, 3.6), Position = position + Vector3.new(5.6, 0.3, 0), Material = Enum.Material.Slate, Color = stone, Parent = windmill })
	makeProp({ Name = "Door", Size = Vector3.new(0.4, 4.4, 2.4), Position = position + Vector3.new(5.15, 3.6, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 46, 30), Parent = windmill })
	makeProp({ Name = "DoorFrame", Size = Vector3.new(0.5, 0.5, 3.2), Position = position + Vector3.new(5.2, 6, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = windmill })
	for _, z in { -1.4, 1.4 } do
		makeProp({ Name = "DoorFrame", Size = Vector3.new(0.5, 4.6, 0.4), Position = position + Vector3.new(5.2, 3.7, z), Material = Enum.Material.Wood, Color = TRUNK, Parent = windmill })
	end
	-- Ventanas con luz cálida y marco, en dos pisos
	for _, height in { 9, 14 } do
		local radius = 5 - height * 0.045
		local window = makeProp({ Name = "Window", Size = Vector3.new(0.3, 1.6, 1.2), Position = position + Vector3.new(radius, height, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 190, 110), Parent = windmill })
		Props.light(window, Color3.fromRGB(255, 180, 100), 10, 0.8)
		makeProp({ Name = "WindowFrame", Size = Vector3.new(0.35, 0.2, 1.5), Position = position + Vector3.new(radius + 0.05, height + 0.9, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = windmill })
		makeProp({ Name = "WindowSill", Size = Vector3.new(0.6, 0.2, 1.6), Position = position + Vector3.new(radius + 0.15, height - 0.9, 0), Material = Enum.Material.Slate, Color = stone, Parent = windmill })
	end
	windmill.Parent = map

	-- Aspas: eje, cuatro brazos y velas de tela sobre un enrejado de madera
	local blades = Instance.new("Model")
	blades.Name = "WindmillBlades"
	local hubCFrame = CFrame.new(position + Vector3.new(5.6, top - 1.2, 0)) * CFrame.Angles(0, math.pi / 2, 0)
	local hub = makeProp({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 1.6, 1.6), CFrame = hubCFrame * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
	makeProp({ Name = "HubCap", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, CFrame = hubCFrame * CFrame.new(0, 0, -0.9), Material = Enum.Material.Metal, Color = Props.Colors.Iron, Parent = blades })
	for index = 0, 3 do
		local arm = hubCFrame * CFrame.Angles(0, 0, index * math.pi / 2)
		makeProp({ Name = "Arm", Size = Vector3.new(0.5, 12, 0.4), CFrame = arm * CFrame.new(0, 6.3, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
		makeProp({ Name = "Sail", Size = Vector3.new(2.8, 8.4, 0.12), CFrame = arm * CFrame.new(1.5, 7.4, 0.12), Material = Enum.Material.Fabric, Color = Color3.fromRGB(225, 212, 185), Parent = blades })
		-- Enrejado: largueros y travesaños sobre la vela
		makeProp({ Name = "SailEdge", Size = Vector3.new(0.18, 8.6, 0.18), CFrame = arm * CFrame.new(2.9, 7.4, 0.18), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
		for rung = 0, 4 do
			makeProp({ Name = "SailRung", Size = Vector3.new(2.9, 0.14, 0.16), CFrame = arm * CFrame.new(1.5, 3.4 + rung * 2, 0.2), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
		end
	end
	blades.PrimaryPart = hub
	blades.Parent = map
end

-- Cerca de madera a los lados del camino de adoquines
local function buildPathFence(map: Instance)
	for _, x in { -5.5, 5.5 } do
		local previous = nil
		for z = 26, 34, 4 do
			makePart({ Name = "PathPost", Size = Vector3.new(0.5, 2.6, 0.5), Position = Vector3.new(x, 1.3, z), Material = Enum.Material.Wood, Color = TRUNK, Parent = map })
			if previous then
				for _, height in { 1, 2.1 } do
					makePart({ Name = "PathRail", Size = Vector3.new(0.25, 0.3, 4), Position = Vector3.new(x, height, z - 2), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 86, 58), Parent = map })
				end
			end
			previous = z
		end
	end
end

local function randomRingPoint(minRadius: number, maxRadius: number): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(minRadius, maxRadius)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function buildScenery(map: Instance)
	-- Cementerio, castillo (y casas en el tema medieval) y el puente de piedra
	MedievalBuilder.build(map)
	BridgeBuilder.build(map)
	-- Puente roto a la aldea: las tablas que faltan quedan guardadas para que
	-- cada cliente las ponga cuando su jugador lo repara (VillageService)
	local planks, sign = BridgeBuilder.buildVillageBridge(map)
	planks.Parent = ReplicatedStorage
	local repair = Instance.new("ProximityPrompt")
	repair.Name = "VillageRepairPrompt"
	repair.ActionText = `Reparar puente ({Config.Arena.VillageBridge.Price} 🪙)`
	repair.ObjectText = "Puente a la aldea"
	repair.HoldDuration = 1
	repair.MaxActivationDistance = 12
	repair.RequiresLineOfSight = false
	repair.Parent = sign

	-- Rocas sueltas
	for _ = 1, 45 do
		local position = randomRingPoint(40, 260)
		if not onLand(position, 6) or not MedievalBuilder.isClear(position, 4) then
			continue
		end
		local size = random:NextNumber(2, 6)
		-- En pixel art 3D las rocas quedan derechas, como bloques apilados
		local tilt = if voxel then 0 else 0.3
		makePart({
			Name = "Rock",
			Size = Vector3.new(size * 1.3, size * 0.7, size),
			CFrame = CFrame.new(position + Vector3.new(0, size * 0.25, 0)) * CFrame.Angles(random:NextNumber(-tilt, tilt), random:NextNumber(0, math.pi), random:NextNumber(-tilt, tilt)),
			Material = Enum.Material.Slate,
			Color = Props.vary(Color3.fromRGB(96, 100, 104), 0.12, random),
			Parent = map,
		})
	end

	-- Bosque alrededor del claro
	for _ = 1, 170 do
		local position = randomRingPoint(225, 430)
		if onLand(position, 8) and MedievalBuilder.isClear(position, 6) then
			buildTree(map, position, random:NextNumber(1, 1.8))
		end
	end
	-- Muro de bosque alrededor del claro
	for _ = 1, 190 do
		local position = randomRingPoint(200, 280)
		if onLand(position, 6) and MedievalBuilder.isClear(position, 5) then
			buildTree(map, position, random:NextNumber(1.1, 1.9))
		end
	end
	-- El bosque del norte, tupido: de entre estos árboles salen los zombis
	for _ = 1, 280 do
		local position = Vector3.new(random:NextNumber(-430, 430), 0, random:NextNumber(-360, -135))
		if onLand(position, 8) and MedievalBuilder.isClear(position, 5) then
			buildTree(map, position, random:NextNumber(1, 1.8))
		end
	end
	-- Algunos pinos sueltos a los lados y detrás del campamento
	for _ = 1, 40 do
		local position = randomRingPoint(95, 210)
		if (position.Z > 0 or math.abs(position.X) > 120) and onLand(position, 8) and MedievalBuilder.isClear(position, 6) then
			buildTree(map, position, random:NextNumber(0.9, 1.5))
		end
	end

	-- Arbustos por el campo y junto al campamento
	for _ = 1, 60 do
		local position = randomRingPoint(35, 200)
		local nearCamp = (position - Config.Arena.CampCenter).Magnitude < 50
		if onLand(position, 6) and not nearCamp and math.abs(position.X) > 6 and MedievalBuilder.isClear(position, 3) then
			buildBush(map, position)
		end
	end

	-- Calabazas sueltas (solo en otoño)
	if theme.Foliage then
		for _ = 1, 30 do
			local position = randomRingPoint(30, 180)
			if onLand(position, 6) and MedievalBuilder.isClear(position, 2) and (position - Config.Arena.CampCenter).Magnitude > 30 then
				local size = random:NextNumber(1.2, 2.2)
				local pumpkin = makeProp({
					Name = "Pumpkin",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(size * 1.25, size, size * 1.25),
					Position = position + Vector3.new(0, size * 0.4, 0),
					Material = Enum.Material.SmoothPlastic,
					Color = Props.vary(Color3.fromRGB(226, 120, 30), 0.08, random),
					Parent = map,
				})
				makeProp({
					Name = "Stem",
					Size = Vector3.new(0.25, 0.5, 0.25),
					Position = pumpkin.Position + Vector3.new(0, size * 0.5 + 0.15, 0),
					Material = Enum.Material.Wood,
					Color = Color3.fromRGB(80, 96, 40),
					Parent = map,
				})
			end
		end
	end

	-- El molino está en la aldea (VillageService cura a quien está cerca entre oleadas)
	local windmillPosition = Config.Arena.Windmill.Position
	buildWindmill(map, windmillPosition)
	local note = makeProp({ Name = "WindmillNote", Size = Vector3.one * 0.2, Position = windmillPosition + Vector3.new(0, 32, 0), Transparency = 1, Parent = map })
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(220, 46)
	billboard.MaxDistance = 90
	billboard.Parent = note
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Config.PixelFont
	text.TextScaled = true
	text.TextColor3 = Color3.fromRGB(255, 225, 140)
	text.TextStrokeTransparency = 0.2
	text.Text = "🍞 MOLINO\nentre oleadas te cura"
	text.Parent = billboard
	buildPathFence(map)

	-- Montañas de bloques en el horizonte. Con StreamingEnabled se quedan
	-- siempre cargadas para que el horizonte no se vea vacío.
	local mountains = Instance.new("Model")
	mountains.Name = "Mountains"
	mountains.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	mountains.Parent = map
	-- Montañas de malla de la tienda (estilo realista): las de roca toman el
	-- color del tema; la nevada conserva su textura. Se hunden un poco para que
	-- no se vea el borde de la malla.
	local function meshMountain(base: Vector3, width: number, height: number, snowy: boolean): boolean
		local name = if snowy then "MountainC" elseif random:NextNumber() < 0.5 then "MountainA" else "MountainB"
		local frame = CFrame.new(base - Vector3.new(0, height * 0.06, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0)
		local part = ModelLibrary.placeStretched(name, frame, Vector3.new(width, height, width), mountains)
		if not part then
			return false
		end
		part.CastShadow = false
		if not snowy then
			part.Material = Enum.Material.Rock
			part.Color = Props.vary(theme.Mountain, 0.1, random)
		end
		return true
	end

	-- Cordillera al norte, detrás del bosque: tapa el horizonte
	for x = -820, 820, 110 do
		local base = Vector3.new(x + random:NextNumber(-30, 30), 0, random:NextNumber(-540, -450))
		local width = random:NextNumber(150, 230)
		-- Algunas más altas y nevadas al fondo
		if meshMountain(base, width * 1.5, random:NextNumber(170, 260), random:NextNumber() < 0.3) then
			continue
		end
		local y = 0
		for step = 1, 4 do
			local layerWidth = width * (1 - (step - 1) * 0.22)
			local layerHeight = random:NextNumber(45, 90)
			makeProp({ Name = "Mountain", Size = Vector3.new(layerWidth, layerHeight, layerWidth), CFrame = CFrame.new(base + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Rock, Color = Props.vary(Color3.fromRGB(98, 80, 66), 0.1, random), CastShadow = false, Parent = mountains })
			y += layerHeight * 0.85
		end
	end
	for index = 1, 16 do
		local angle = (index / 16) * math.pi * 2 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(650, 800)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if base.Z > Config.Arena.CliffZ then
			continue -- hacia el mar el horizonte queda abierto
		end
		local width = random:NextNumber(180, 260)
		if meshMountain(base, width * 1.6, random:NextNumber(150, 230), random:NextNumber() < 0.4) then
			continue
		end
		local y = 0
		for step = 1, 3 do
			local layerWidth = width * (1 - (step - 1) * 0.3)
			local layerHeight = random:NextNumber(50, 80)
			makeProp({ Name = "Mountain", Size = Vector3.new(layerWidth, layerHeight, layerWidth), CFrame = CFrame.new(base + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Rock, Color = Props.vary(theme.Mountain, 0.08, random), CastShadow = false, Parent = mountains })
			y += layerHeight * 0.9
		end
	end

	-- De noche: luciérnagas. De día: hojas que caen flotando. En pixel art 3D
	-- las luciérnagas son cubitos que hace cada cliente (WorldFx).
	if voxel then
		return
	end
	local ambient = makeProp({ Name = "AmbientParticles", Size = Vector3.new(260, 8, 200), Position = Vector3.new(0, if theme.Night then 4 else 14, -40), Transparency = 1, Parent = map })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "AmbientEmitter"
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) })
	if theme.Night then
		emitter.Rate = 25
		emitter.Lifetime = NumberRange.new(5, 9)
		emitter.Speed = NumberRange.new(0.3, 1)
		emitter.Size = NumberSequence.new(0.25)
		emitter.LightEmission = 1
		emitter.Color = ColorSequence.new(Color3.fromRGB(220, 255, 140))
	else
		emitter.Rate = 18
		emitter.Lifetime = NumberRange.new(6, 10)
		emitter.Speed = NumberRange.new(1, 2)
		emitter.Acceleration = Vector3.new(1.5, -1.2, 0.5)
		emitter.RotSpeed = NumberRange.new(-90, 90)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Size = NumberSequence.new(0.35)
		emitter.Color = ColorSequence.new(theme.Foliage[1], theme.Foliage[2])
	end
	emitter.Parent = ambient
end

-- Busca hora y latitud para que el astro (luna o sol) quede donde queremos.
-- La luna: grande, frente a la campana. El sol: bajo, iluminando a la horda.
local function aimSky(getDirection: () -> Vector3, target: Vector3, wantNight: boolean, minClock: number, maxClock: number)
	local bestClock, bestLatitude, bestScore = minClock, 0, -math.huge
	for latitude = -60, 60, 5 do
		Lighting.GeographicLatitude = latitude
		for clock = minClock, maxClock, 0.25 do
			Lighting.ClockTime = clock % 24
			local sunY = Lighting:GetSunDirection().Y
			if (wantNight and sunY < -0.2) or (not wantNight and sunY > 0.12) then
				local score = getDirection():Dot(target)
				if score > bestScore then
					bestClock, bestLatitude, bestScore = clock % 24, latitude, score
				end
			end
		end
	end
	Lighting.GeographicLatitude = bestLatitude
	Lighting.ClockTime = bestClock
end

local function setupLighting()
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	Lighting.Brightness = theme.Brightness
	Lighting.Ambient = theme.Ambient
	Lighting.OutdoorAmbient = theme.Ambient
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	-- Pixel art 3D: sombras nítidas, sin desenfoque
	Lighting.ShadowSoftness = if Props.flat then 0 elseif voxel then 0.15 else 0.35
	-- "Future" se pone desde default.project.json (los scripts no pueden cambiarlo)

	local sky = Instance.new("Sky")
	sky.MoonAngularSize = 24
	sky.SunAngularSize = 14
	sky.StarCount = if theme.Night then 2500 else 0
	if Config.SkyTextures.Moon ~= "" then
		sky.MoonTextureId = Config.SkyTextures.Moon
	end
	if Config.SkyTextures.Sun ~= "" then
		sky.SunTextureId = Config.SkyTextures.Sun
	end
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = theme.Density
	atmosphere.Offset = 0.15
	atmosphere.Color = theme.Atmosphere
	atmosphere.Decay = theme.Decay
	atmosphere.Glare = if theme.Night then 0.2 else 0.5
	atmosphere.Haze = theme.Haze
	atmosphere.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.TintColor = theme.Tint
	colorCorrection.Saturation = if voxel then 0.28 else 0.18
	colorCorrection.Contrast = if voxel then 0.16 else 0.12
	colorCorrection.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = if theme.Night then 0.8 else 0.5
	bloom.Size = if voxel then 18 else 30
	bloom.Threshold = if theme.Night then 1.4 else 1.8
	bloom.Parent = Lighting

	-- Desenfoque suave a lo lejos, como en una foto (el cliente lo apaga en calidad
	-- baja). En pixel art 3D todo se ve nítido.
	if not voxel then
		local depthOfField = Instance.new("DepthOfFieldEffect")
		depthOfField.FarIntensity = 0.18
		depthOfField.FocusDistance = 40
		depthOfField.InFocusRadius = 90
		depthOfField.NearIntensity = 0
		depthOfField.Parent = Lighting
	end

	if DayCycle.isEnabled() then
		-- Ciclo de día y noche: latitud donde la luna pasa frente a la campana de
		-- noche. Después la hora la mueve cada cliente (WorldFx).
		local bestLatitude, bestScore = 0, -math.huge
		for latitude = -60, 60, 5 do
			Lighting.GeographicLatitude = latitude
			local score = 0
			for clock = 20, 28, 0.5 do
				Lighting.ClockTime = clock % 24
				score += math.max(0, Lighting:GetMoonDirection():Dot(MOON_DIRECTION))
			end
			if score > bestScore then
				bestLatitude, bestScore = latitude, score
			end
		end
		Lighting.GeographicLatitude = bestLatitude
		DayCycle.applyLighting(DayCycle.getClock(workspace:GetServerTimeNow()))
		-- Rayos de sol entre los árboles de día (en pixel art todo nítido)
		if not voxel then
			local sunRays = Instance.new("SunRaysEffect")
			sunRays.Intensity = 0.06
			sunRays.Spread = 0.5
			sunRays.Parent = Lighting
		end
	elseif theme.Night then
		aimSky(function()
			return Lighting:GetMoonDirection()
		end, MOON_DIRECTION, true, 0, 24)
	else
		local sunRays = Instance.new("SunRaysEffect")
		sunRays.Intensity = 0.08
		sunRays.Spread = 0.6
		sunRays.Parent = Lighting
		aimSky(function()
			return Lighting:GetSunDirection()
		end, SUN_DIRECTION, false, theme.ClockTime - 2, theme.ClockTime + 1)
	end
end

-- Todo se construye a la altura de las islas; lo que quedó en el bosque (al
-- norte del canal) baja ForestDrop studs junto con el terreno. El puente de
-- piedra no: ya es una rampa (BridgeBuilder).
local function lowerForest(map: Instance)
	local drop = Config.Arena.ForestDrop or 0
	if drop == 0 or Config.Style.Tiles then
		return
	end
	local offset = Vector3.new(0, -drop, 0)
	local bridge = map:FindFirstChild("StoneBridge")
	for _, part in map:GetDescendants() do
		if not part:IsA("BasePart") or (bridge and part:IsDescendantOf(bridge)) then
			continue
		end
		if not Paths.onNorthLand(part.Position) then
			continue
		end
		part.CFrame += offset
		-- Los puntos de giro guardados (viento, trabajo) bajan con la pieza
		for name, value in part:GetAttributes() do
			if typeof(value) == "Vector3" and string.sub(name, -5) == "Pivot" then
				part:SetAttribute(name, value + offset)
			end
		end
	end
end

function MapBuilder.build(): Folder
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	-- Viento que mueve el pasto 3D, las nubes y las partículas (cada cliente le
	-- agrega ráfagas en WorldFx)
	workspace.GlobalWind = Config.Wind.Direction.Unit * Config.Wind.Speed

	local map = Instance.new("Folder")
	map.Name = "Map"
	if Config.Style.Tiles then
		-- Pixel art 3D: suelo de baldosas en vez del terreno de Roblox
		VoxelBuilder.build(map)
		IslandBuilder.buildVoxel(map)
	else
		buildTerrain()
	end
	buildScenery(map)
	buildTower(map)
	buildSpawnCircle(map)
	CampBuilder.build(map)
	lowerForest(map)
	map.Parent = workspace

	setupLighting()
	return map
end

return MapBuilder
