-- Construye el mapa por código para que el juego funcione en un lugar vacío:
-- un claro en el bosque con el campanario al frente y el campamento detrás
-- (fogata, tiendas, empalizada y los NPC). De noche, con niebla de color y
-- una luna enorme.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local CampBuilder = require(script.Parent.CampBuilder)
local Props = require(script.Parent.Props)

local STONE = Props.Colors.Stone
local WOOD = Props.Colors.Wood
local DARK_WOOD = Props.Colors.DarkWood
local BRASS = Color3.fromRGB(205, 165, 70)
local MOON_DIRECTION = Vector3.new(0, 0.42, -1).Unit

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(7)
local makePart, makeProp = Props.makePart, Props.makeProp

local MapBuilder = {}

local function buildTerrain()
	local terrain = workspace.Terrain
	local arena = Config.Arena
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Grass, theme.Ground)
	terrain:SetMaterialColor(Enum.Material.LeafyGrass, theme.Ground:Lerp(Color3.new(1, 1, 1), 0.08))
	terrain:SetMaterialColor(Enum.Material.Ground, theme.Ground:Lerp(Color3.fromRGB(80, 60, 40), 0.65))
	terrain:SetMaterialColor(Enum.Material.Mud, theme.Ground:Lerp(Color3.fromRGB(50, 38, 28), 0.7))

	-- Suelo de pasto con la parte de arriba en y = 0
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(arena.GroundSize, 8, arena.GroundSize), Enum.Material.Grass)

	-- Manchas de pasto alto y lodo en el campo de batalla
	for _ = 1, 40 do
		local angle = random:NextNumber(0, math.pi * 2)
		local radius = random:NextNumber(30, 230)
		local material = if random:NextNumber() < 0.6 then Enum.Material.LeafyGrass else Enum.Material.Mud
		terrain:FillBall(Vector3.new(math.cos(angle) * radius, -3.2, math.sin(angle) * radius), random:NextNumber(4, 9), material)
	end

	-- Tierra pisada en el campamento y el camino hacia la campana
	local camp = arena.CampCenter
	terrain:FillCylinder(CFrame.new(camp.X, -2, camp.Z), 4.1, arena.CampRadius, Enum.Material.Ground)
	terrain:FillBlock(CFrame.new(0, -2, camp.Z / 2), Vector3.new(8, 4.1, camp.Z), Enum.Material.Ground)

	-- Pasto 3D animado (si Roblox lo permite desde un script)
	pcall(function()
		(terrain :: any).Decoration = true
	end)
end

local function buildTower(map: Instance)
	local arena = Config.Arena
	local size, height = arena.TowerSize, arena.TowerHeight

	makePart({ Name = "TowerBase", Size = Vector3.new(size, height, size), Position = Vector3.new(0, height / 2, 0), Material = Enum.Material.Cobblestone, Color = STONE, Parent = map })
	makePart({ Name = "Deck", Size = Vector3.new(size - 1, 0.4, size - 1), Position = Vector3.new(0, height + 0.2, 0), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	local top = height + 0.4
	local edge = size / 2 - 0.5

	-- Rampa hacia el campamento (lado +Z)
	makePart({
		Name = "Ramp",
		Size = Vector3.new(5, height, 13),
		CFrame = CFrame.new(0, height / 2, size / 2 + 6.5) * CFrame.Angles(0, math.pi, 0),
		Material = Enum.Material.WoodPlanks,
		Color = WOOD,
		Parent = map,
	}, "WedgePart")

	-- Baranda con hueco donde llega la rampa
	makePart({ Name = "Rail", Size = Vector3.new(size, 0.4, 0.4), Position = Vector3.new(0, top + 2.2, -edge), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	for _, side in { -1, 1 } do
		makePart({ Name = "Rail", Size = Vector3.new(0.4, 0.4, size), Position = Vector3.new(side * edge, top + 2.2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "Rail", Size = Vector3.new(size / 2 - 3, 0.4, 0.4), Position = Vector3.new(side * (size / 4 + 1.5), top + 2.2, edge), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	for offset = -edge, edge, 2.6 do
		local spots = { Vector3.new(offset, 0, -edge), Vector3.new(-edge, 0, offset), Vector3.new(edge, 0, offset) }
		if math.abs(offset) > 3 then
			table.insert(spots, Vector3.new(offset, 0, edge))
		end
		for _, spot in spots do
			makePart({ Name = "Post", Size = Vector3.new(0.5, 2.4, 0.5), Position = spot + Vector3.new(0, top + 1.2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		end
	end
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		Props.lantern(map, corner * (edge - 0.6) + Vector3.new(0, top, 0))
	end

	-- Estructura que sostiene la campana
	local frameHeight = 11
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		makePart({ Name = "Pillar", Size = Vector3.new(1, frameHeight, 1), Position = corner * 3.2 + Vector3.new(0, top + frameHeight / 2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	for _, side in { -1, 1 } do
		makePart({ Name = "Beam", Size = Vector3.new(7.4, 0.8, 1), Position = Vector3.new(0, top + frameHeight, side * 3.2), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "Beam", Size = Vector3.new(1, 0.8, 7.4), Position = Vector3.new(side * 3.2, top + frameHeight, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	local roofY = top + frameHeight + 1.9
	for _, side in { -1, 1 } do
		makePart({
			Name = "Roof",
			Size = Vector3.new(9, 3, 4.6),
			CFrame = CFrame.new(0, roofY, side * 2.3) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
			Material = Enum.Material.WoodPlanks,
			Color = DARK_WOOD,
			Parent = map,
		}, "WedgePart")
	end

	-- La campana
	local bell = Instance.new("Model")
	bell.Name = "Bell"
	local bellTop = top + frameHeight - 0.6
	makePart({ Name = "Yoke", Size = Vector3.new(3, 0.6, 1), Position = Vector3.new(0, bellTop, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = bell })
	local y = bellTop - 0.3
	for _, layer in { { 1.6, 0.8 }, { 2.6, 1.6 }, { 3.4, 1.4 }, { 4, 0.5 } } do
		y -= layer[2] / 2
		makePart({ Name = "BellBody", Size = Vector3.new(layer[1], layer[2], layer[1]), Position = Vector3.new(0, y, 0), Material = Enum.Material.Metal, Color = BRASS, Parent = bell })
		y -= layer[2] / 2
	end
	makePart({ Name = "Clapper", Size = Vector3.new(0.6, 0.8, 0.6), Position = Vector3.new(0, y - 0.3, 0), Material = Enum.Material.Metal, Color = BRASS:Lerp(Color3.new(0, 0, 0), 0.4), Parent = bell })
	bell.Parent = map

	-- Talento Reparador: mantener E junto a la base
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RepairPrompt"
	prompt.ActionText = "Reparar campana"
	prompt.ObjectText = "Campana"
	prompt.HoldDuration = 1
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Repair", true)
	prompt.Parent = map:FindFirstChild("TowerBase")
end

local function buildPine(map: Instance, position: Vector3, scale: number)
	local tree = Instance.new("Model")
	tree.Name = "Pine"
	makeProp({ Name = "Trunk", Size = Vector3.new(1.4, 4, 1.4) * scale, Position = position + Vector3.new(0, 2 * scale, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = tree })
	local color = Props.vary(theme.Tree, 0.15, random)
	local y = 4 * scale
	for index, width in { 9, 7, 5, 3 } do
		local layerHeight = (if index == 4 then 2.5 else 3.2) * scale
		makeProp({
			Name = "Leaves",
			Size = Vector3.new(width * scale, layerHeight, width * scale),
			CFrame = CFrame.new(position + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi / 2), 0),
			Material = Enum.Material.Grass,
			Color = color:Lerp(Color3.new(1, 1, 1), index * 0.03),
			Parent = tree,
		})
		y += layerHeight * 0.8
	end
	tree.Parent = map
end

local function randomRingPoint(minRadius: number, maxRadius: number): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = random:NextNumber(minRadius, maxRadius)
	return Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function buildScenery(map: Instance)
	local arena = Config.Arena

	-- Lápidas donde nacen los zombis
	local halfArc = math.rad(arena.SpawnArc / 2 + 10)
	for _ = 1, 40 do
		local angle = random:NextNumber(-halfArc, halfArc)
		local radius = arena.SpawnRadius + random:NextNumber(-5, 15)
		local height = random:NextNumber(2.5, 4)
		makeProp({
			Name = "Tombstone",
			Size = Vector3.new(2.2, height, 0.6),
			CFrame = CFrame.new(math.sin(angle) * radius, height / 2, -math.cos(angle) * radius)
				* CFrame.Angles(random:NextNumber(-0.15, 0.15), -angle, random:NextNumber(-0.15, 0.15)),
			Material = Enum.Material.Slate,
			Color = Props.vary(Color3.fromRGB(105, 108, 112), 0.1, random),
			Parent = map,
		})
	end

	-- Rocas sueltas
	for _ = 1, 45 do
		local position = randomRingPoint(40, 260)
		local size = random:NextNumber(2, 6)
		makePart({
			Name = "Rock",
			Size = Vector3.new(size * 1.3, size * 0.7, size),
			CFrame = CFrame.new(position + Vector3.new(0, size * 0.25, 0)) * CFrame.Angles(random:NextNumber(-0.3, 0.3), random:NextNumber(0, math.pi), random:NextNumber(-0.3, 0.3)),
			Material = Enum.Material.Slate,
			Color = Props.vary(Color3.fromRGB(96, 100, 104), 0.12, random),
			Parent = map,
		})
	end

	-- Bosque alrededor del claro
	for _ = 1, 150 do
		buildPine(map, randomRingPoint(225, 430), random:NextNumber(1, 1.8))
	end
	-- Algunos pinos sueltos a los lados y detrás del campamento
	for _ = 1, 40 do
		local position = randomRingPoint(95, 210)
		if position.Z > 0 or math.abs(position.X) > 120 then
			buildPine(map, position, random:NextNumber(0.9, 1.5))
		end
	end

	-- Montañas de bloques en el horizonte
	for index = 1, 16 do
		local angle = (index / 16) * math.pi * 2 + random:NextNumber(-0.1, 0.1)
		local radius = random:NextNumber(650, 800)
		local base = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local width = random:NextNumber(180, 260)
		local y = 0
		for step = 1, 3 do
			local layerWidth = width * (1 - (step - 1) * 0.3)
			local layerHeight = random:NextNumber(50, 80)
			makeProp({ Name = "Mountain", Size = Vector3.new(layerWidth, layerHeight, layerWidth), CFrame = CFrame.new(base + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Slate, Color = Props.vary(theme.Mountain, 0.08, random), CastShadow = false, Parent = map })
			y += layerHeight * 0.9
		end
	end

	-- Luciérnagas flotando sobre el campo
	local fireflies = makeProp({ Name = "Fireflies", Size = Vector3.new(260, 8, 200), Position = Vector3.new(0, 4, -40), Transparency = 1, Parent = map })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = 25
	emitter.Lifetime = NumberRange.new(5, 9)
	emitter.Speed = NumberRange.new(0.3, 1)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new(0.25)
	emitter.LightEmission = 1
	emitter.Color = ColorSequence.new(Color3.fromRGB(220, 255, 140))
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = fireflies
end

-- Busca hora y latitud para que la luna quede grande, de noche y justo
-- frente a la campana, por donde llegan los zombis.
local function aimMoon()
	local bestClock, bestLatitude, bestScore = 0, 0, -math.huge
	for latitude = -60, 60, 5 do
		Lighting.GeographicLatitude = latitude
		for clock = 0, 24, 0.25 do
			Lighting.ClockTime = clock
			if Lighting:GetSunDirection().Y < -0.2 then
				local score = Lighting:GetMoonDirection():Dot(MOON_DIRECTION)
				if score > bestScore then
					bestClock, bestLatitude, bestScore = clock, latitude, score
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

	Lighting.Brightness = 1.4
	Lighting.Ambient = theme.Ambient
	Lighting.OutdoorAmbient = theme.Ambient
	Lighting.EnvironmentDiffuseScale = 0.3
	Lighting.EnvironmentSpecularScale = 0.2

	local sky = Instance.new("Sky")
	sky.MoonAngularSize = 24
	sky.StarCount = 2500
	sky.Parent = Lighting

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.36
	atmosphere.Offset = 0.15
	atmosphere.Color = theme.Atmosphere
	atmosphere.Decay = theme.Decay
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.8
	atmosphere.Parent = Lighting

	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.TintColor = theme.Tint
	colorCorrection.Saturation = 0.15
	colorCorrection.Contrast = 0.12
	colorCorrection.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 1.4
	bloom.Parent = Lighting

	aimMoon()
end

function MapBuilder.build(): Folder
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	buildTerrain()
	local map = Instance.new("Folder")
	map.Name = "Map"
	buildScenery(map)
	buildTower(map)
	CampBuilder.build(map)
	map.Parent = workspace

	setupLighting()
	return map
end

return MapBuilder
