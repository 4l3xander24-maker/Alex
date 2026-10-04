-- Construye el mapa por código para que el juego funcione en un lugar vacío:
-- un claro con la campana sobre un montículo (BellTower), el círculo de runas
-- donde aparecen los jugadores y el campamento detrás (fogata, tiendas,
-- empalizada y los NPC), al borde de un acantilado que cae al mar. Adelante,
-- un barranco con un río que solo se cruza por el puente de piedra
-- (BridgeBuilder); del otro lado, el bosque de donde salen los zombis.
-- Según el tema: noche medieval con velas, atardecer de otoño o noche con luna.
-- Usa materiales con textura y luz Future para verse lo más realista posible.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DayCycle = require(ReplicatedStorage.Shared.DayCycle)
local BellTower = require(script.Parent.BellTower)
local BridgeBuilder = require(script.Parent.BridgeBuilder)
local CampBuilder = require(script.Parent.CampBuilder)
local MedievalBuilder = require(script.Parent.MedievalBuilder)
local VoxelBuilder = require(script.Parent.VoxelBuilder)
local Props = require(script.Parent.Props)

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
	local half = arena.GroundSize / 2
	local cliffZ = arena.CliffZ
	local sea = arena.SeaLevel
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Grass, theme.Ground)
	-- Las manchas de LeafyGrass hacen de hojas caídas
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, theme.LeafLitter)
	terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(150, 142, 128))
	terrain:SetMaterialColor(Enum.Material.Ground, theme.Ground:Lerp(Color3.fromRGB(80, 60, 40), 0.65))
	terrain:SetMaterialColor(Enum.Material.Mud, theme.Ground:Lerp(Color3.fromRGB(50, 38, 28), 0.7))
	terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(78, 82, 88))
	terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(150, 140, 110))

	-- Suelo de pasto (arriba en y = 0) hasta el borde del acantilado
	local landLength = cliffZ + half
	terrain:FillBlock(CFrame.new(0, -4, cliffZ - landLength / 2), Vector3.new(arena.GroundSize, 8, landLength), Enum.Material.Grass)

	-- Pared de roca del acantilado, irregular, hasta debajo del mar
	local rockTop, rockBottom = -8, sea - 30
	terrain:FillBlock(CFrame.new(0, (rockTop + rockBottom) / 2, cliffZ - 15), Vector3.new(arena.GroundSize, rockTop - rockBottom, 30), Enum.Material.Rock)
	for x = -half, half, 16 do
		local position = Vector3.new(x + random:NextNumber(-6, 6), random:NextNumber(sea - 10, -6), cliffZ + random:NextNumber(-3, 2))
		terrain:FillBall(position, random:NextNumber(5, 11), Enum.Material.Rock)
	end

	-- El mar: fondo de arena, agua y rocas que asoman
	local seaLength = half - cliffZ
	terrain:FillBlock(CFrame.new(0, sea - 30, cliffZ + seaLength / 2), Vector3.new(arena.GroundSize, 10, seaLength), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, sea - 12.5, cliffZ + seaLength / 2), Vector3.new(arena.GroundSize, 25, seaLength), Enum.Material.Water)
	for _ = 1, 30 do
		local position = Vector3.new(random:NextNumber(-half, half), sea - random:NextNumber(2, 8), cliffZ + random:NextNumber(8, 160))
		terrain:FillBall(position, random:NextNumber(4, 14), Enum.Material.Rock)
	end
	terrain.WaterColor = Color3.fromRGB(25, 70, 80)
	terrain.WaterTransparency = 0.35
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.3
	terrain.WaterWaveSpeed = 10

	-- Manchas de pasto alto y lodo en el campo de batalla
	for _ = 1, 40 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(30, 230)
		local position = Vector3.new(math.cos(angle) * radius, -3.2, math.sin(angle) * radius)
		if position.Z < cliffZ - 12 then
			local material = if random:NextNumber() < 0.6 then Enum.Material.LeafyGrass else Enum.Material.Mud
			terrain:FillBall(position, random:NextNumber(4, 9), material)
		end
	end

	-- Tierra pisada en el campamento y el camino hacia la campana
	local camp = arena.CampCenter
	terrain:FillCylinder(CFrame.new(camp.X, -2, camp.Z), 4.1, arena.CampRadius, Enum.Material.Ground)
	-- Camino de adoquines del campamento a la campana, y un anillo alrededor de la torre
	terrain:FillBlock(CFrame.new(0, -2, camp.Z / 2), Vector3.new(9, 4.1, camp.Z), Enum.Material.Cobblestone)
	terrain:FillCylinder(CFrame.new(0, -2, 0), 4.1, arena.TowerSize / 2 + 5, Enum.Material.Cobblestone)
	-- Los caminos angostos por donde llegan los zombis
	MedievalBuilder.paintPaths(terrain)
	-- El barranco con el río (borra lo que se pintó encima)
	BridgeBuilder.carveTerrain(terrain)

	-- Pasto 3D animado (si Roblox lo permite desde un script)
	pcall(function()
		(terrain :: any).Decoration = true
	end)
end

-- Los árboles y rocas no van sobre el mar ni pegados al borde
local function onLand(position: Vector3, margin: number): boolean
	return position.Z < Config.Arena.CliffZ - margin
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
	local y = 0
	for _, segment in { { 10, 6 }, { 9, 6 }, { 8, 6 } } do
		makePart({ Name = "Wall", Shape = Enum.PartType.Cylinder, Size = Vector3.new(segment[2], segment[1], segment[1]), CFrame = CFrame.new(position + Vector3.new(0, y + segment[2] / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Cobblestone, Color = Props.vary(stone, 0.05, random), Parent = windmill })
		y += segment[2]
	end
	for index, width in { 9, 7, 5, 3, 1.5 } do
		makePart({ Name = "Roof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, width, width), CFrame = CFrame.new(position + Vector3.new(0, y + (index - 0.5) * 1.4, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.ClayRoofTiles, Color = Color3.fromRGB(130, 56, 42), Parent = windmill })
	end
	-- Puerta y ventanas mirando al campamento (+X)
	makeProp({ Name = "Door", Size = Vector3.new(0.4, 4.5, 2.6), Position = position + Vector3.new(4.9, 2.25, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(70, 46, 30), Parent = windmill })
	for _, height in { 8.5, 13.5 } do
		local window = makeProp({ Name = "Window", Size = Vector3.new(0.4, 1.6, 1.2), Position = position + Vector3.new(4.25 - height * 0.04, height, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 190, 110), Parent = windmill })
		Props.light(window, Color3.fromRGB(255, 180, 100), 10, 0.8)
	end
	windmill.Parent = map

	-- Aspas: un eje y cuatro brazos con velas de tela
	local blades = Instance.new("Model")
	blades.Name = "WindmillBlades"
	local hubCFrame = CFrame.new(position + Vector3.new(5.2, y - 1.5, 0)) * CFrame.Angles(0, math.pi / 2, 0)
	local hub = makeProp({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = hubCFrame * CFrame.Angles(0, math.pi / 2, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
	for index = 0, 3 do
		local arm = hubCFrame * CFrame.Angles(0, 0, index * math.pi / 2)
		makeProp({ Name = "Arm", Size = Vector3.new(0.5, 11, 0.4), CFrame = arm * CFrame.new(0, 5.8, 0), Material = Enum.Material.Wood, Color = TRUNK, Parent = blades })
		makeProp({ Name = "Sail", Size = Vector3.new(2.6, 8, 0.15), CFrame = arm * CFrame.new(1.4, 6.8, 0.1), Material = Enum.Material.Fabric, Color = Color3.fromRGB(225, 212, 185), Parent = blades })
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
	-- Muro de bosque alrededor del claro: de aquí salen los zombis
	for _ = 1, 190 do
		local position = randomRingPoint(200, 280)
		if position.Z < Config.Arena.CliffZ - 30 and MedievalBuilder.isClear(position, 5) then
			buildTree(map, position, random:NextNumber(1.1, 1.9))
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

	buildWindmill(map, Vector3.new(-68, 0, 18))
	buildPathFence(map)

	-- Montañas de bloques en el horizonte. Con StreamingEnabled se quedan
	-- siempre cargadas para que el horizonte no se vea vacío.
	local mountains = Instance.new("Model")
	mountains.Name = "Mountains"
	mountains.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	mountains.Parent = map
	for index = 1, 16 do
		local angle = (index / 16) * math.pi * 2 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(650, 800)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		if base.Z > Config.Arena.CliffZ then
			continue -- hacia el mar el horizonte queda abierto
		end
		local width = random:NextNumber(180, 260)
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
		BridgeBuilder.buildVoxelRavine(map)
	else
		buildTerrain()
	end
	buildScenery(map)
	buildTower(map)
	buildSpawnCircle(map)
	CampBuilder.build(map)
	map.Parent = workspace

	setupLighting()
	return map
end

return MapBuilder
