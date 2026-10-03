-- Construye el mapa por código para que el juego funcione en un lugar vacío:
-- un campanario en el centro de un claro, rodeado de bosque y montañas,
-- de noche, con niebla de color y una luna enorme.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STONE = Color3.fromRGB(110, 116, 118)
local WOOD = Color3.fromRGB(120, 80, 48)
local DARK_WOOD = Color3.fromRGB(74, 50, 32)
local BRASS = Color3.fromRGB(205, 165, 70)
local LANTERN = Color3.fromRGB(255, 170, 80)
local MOON_DIRECTION = Vector3.new(0, 0.42, -1).Unit

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(7)

local MapBuilder = {}

local function makePart(props, className: string?): BasePart
	local part = Instance.new(className or "Part") :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	return part
end

-- Decoración que no debe estorbar a los disparos ni a los jugadores
local function makeProp(props, className: string?): BasePart
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	return makePart(props, className)
end

local function vary(color: Color3, amount: number): Color3
	local factor = 1 + random:NextNumber(-amount, amount)
	return Color3.new(math.min(color.R * factor, 1), math.min(color.G * factor, 1), math.min(color.B * factor, 1))
end

local function addLantern(map: Instance, position: Vector3)
	makePart({ Name = "LanternPost", Size = Vector3.new(0.4, 4, 0.4), Position = position + Vector3.new(0, 2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	local lantern = makeProp({
		Name = "Lantern",
		Size = Vector3.new(0.9, 1.1, 0.9),
		Position = position + Vector3.new(0, 4.5, 0),
		Material = Enum.Material.Neon,
		Color = LANTERN,
		Parent = map,
	})
	local light = Instance.new("PointLight")
	light.Color = LANTERN
	light.Range = 22
	light.Brightness = 1.6
	light.Shadows = true
	light.Parent = lantern
end

local function buildTower(map: Instance)
	local arena = Config.Arena
	local size, height = arena.TowerSize, arena.TowerHeight

	makePart({ Name = "TowerBase", Size = Vector3.new(size, height, size), Position = Vector3.new(0, height / 2, 0), Material = Enum.Material.Slate, Color = STONE, Parent = map })
	makePart({ Name = "Deck", Size = Vector3.new(size - 1, 0.4, size - 1), Position = Vector3.new(0, height + 0.2, 0), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	local top = height + 0.4
	local edge = size / 2 - 0.5

	-- Baranda de madera
	for _, side in { -1, 1 } do
		makePart({ Name = "Rail", Size = Vector3.new(size, 0.4, 0.4), Position = Vector3.new(0, top + 2.2, side * edge), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "Rail", Size = Vector3.new(0.4, 0.4, size), Position = Vector3.new(side * edge, top + 2.2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	for offset = -edge, edge, 3 do
		for _, spot in { Vector3.new(offset, 0, -edge), Vector3.new(offset, 0, edge), Vector3.new(-edge, 0, offset), Vector3.new(edge, 0, offset) } do
			makePart({ Name = "Post", Size = Vector3.new(0.5, 2.4, 0.5), Position = spot + Vector3.new(0, top + 1.2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		end
	end
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		addLantern(map, corner * (edge - 0.6) + Vector3.new(0, top, 0))
	end

	-- Estructura que sostiene la campana
	local frameHeight = 12
	for _, corner in { Vector3.new(-1, 0, -1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, 1) } do
		makePart({ Name = "Pillar", Size = Vector3.new(1, frameHeight, 1), Position = corner * 3.5 + Vector3.new(0, top + frameHeight / 2, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	for _, side in { -1, 1 } do
		makePart({ Name = "Beam", Size = Vector3.new(8, 0.8, 1), Position = Vector3.new(0, top + frameHeight, side * 3.5), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "Beam", Size = Vector3.new(1, 0.8, 8), Position = Vector3.new(side * 3.5, top + frameHeight, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	local roofY = top + frameHeight + 1.9
	makePart({ Name = "Roof", Size = Vector3.new(9.5, 3, 5), CFrame = CFrame.new(0, roofY, -2.5), Material = Enum.Material.WoodPlanks, Color = DARK_WOOD, Parent = map }, "WedgePart")
	makePart({ Name = "Roof", Size = Vector3.new(9.5, 3, 5), CFrame = CFrame.new(0, roofY, 2.5) * CFrame.Angles(0, math.pi, 0), Material = Enum.Material.WoodPlanks, Color = DARK_WOOD, Parent = map }, "WedgePart")

	-- La campana
	local bell = Instance.new("Model")
	bell.Name = "Bell"
	local bellTop = top + frameHeight - 0.6
	makePart({ Name = "Yoke", Size = Vector3.new(3, 0.6, 1), Position = Vector3.new(0, bellTop, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = bell })
	local layers = {
		{ Size = 1.6, Height = 0.8 },
		{ Size = 2.6, Height = 1.6 },
		{ Size = 3.4, Height = 1.4 },
		{ Size = 4, Height = 0.5 },
	}
	local y = bellTop - 0.3
	for _, layer in layers do
		y -= layer.Height / 2
		makePart({ Name = "BellBody", Size = Vector3.new(layer.Size, layer.Height, layer.Size), Position = Vector3.new(0, y, 0), Material = Enum.Material.Metal, Color = BRASS, Parent = bell })
		y -= layer.Height / 2
	end
	makePart({ Name = "Clapper", Size = Vector3.new(0.6, 0.8, 0.6), Position = Vector3.new(0, y - 0.3, 0), Material = Enum.Material.Metal, Color = BRASS:Lerp(Color3.new(0, 0, 0), 0.4), Parent = bell })
	bell.Parent = map

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "TowerSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 1, 4)
	spawn.CFrame = CFrame.new(0, top + 0.5, -6)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map
end

local function buildPine(map: Instance, position: Vector3, scale: number)
	local tree = Instance.new("Model")
	tree.Name = "Pine"
	makeProp({ Name = "Trunk", Size = Vector3.new(1.4, 4, 1.4) * scale, Position = position + Vector3.new(0, 2 * scale, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = tree })
	local color = vary(theme.Tree, 0.15)
	local y = 4 * scale
	for index, width in { 9, 7, 5, 3 } do
		local layerHeight = (if index == 4 then 2.5 else 3.2) * scale
		makeProp({
			Name = "Leaves",
			Size = Vector3.new(width * scale, layerHeight, width * scale),
			CFrame = CFrame.new(position + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi / 2), 0),
			Material = Enum.Material.SmoothPlastic,
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

	makePart({ Name = "Ground", Size = Vector3.new(arena.GroundSize, 2, arena.GroundSize), Position = Vector3.new(0, -1, 0), Material = Enum.Material.Grass, Color = theme.Ground, Parent = map })

	for _ = 1, 30 do
		local position = randomRingPoint(20, 200)
		makeProp({ Name = "Dirt", Size = Vector3.new(random:NextNumber(6, 16), 0.1, random:NextNumber(6, 16)), CFrame = CFrame.new(position + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, random:NextNumber(0, math.pi), 0), Material = Enum.Material.Ground, Color = vary(theme.Ground:Lerp(Color3.fromRGB(70, 50, 35), 0.6), 0.1), Parent = map })
	end

	local grass = theme.Ground:Lerp(Color3.new(1, 1, 1), 0.15)
	for _ = 1, 350 do
		local position = randomRingPoint(14, 230)
		local height = random:NextNumber(0.4, 1)
		makeProp({ Name = "Grass", Size = Vector3.new(0.6, height, 0.25), Position = position + Vector3.new(0, height / 2, 0), Material = Enum.Material.SmoothPlastic, Color = vary(grass, 0.15), CastShadow = false, Parent = map })
	end

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
			Color = vary(Color3.fromRGB(105, 108, 112), 0.1),
			Parent = map,
		})
	end

	-- Bosque alrededor del claro
	for _ = 1, 140 do
		buildPine(map, randomRingPoint(225, 430), random:NextNumber(1, 1.8))
	end
	for _ = 1, 25 do
		local position = randomRingPoint(40, 200)
		if position.Z > 25 then -- solo detrás de la campana, para no tapar la horda
			buildPine(map, position, random:NextNumber(0.9, 1.4))
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
			makeProp({ Name = "Mountain", Size = Vector3.new(layerWidth, layerHeight, layerWidth), CFrame = CFrame.new(base + Vector3.new(0, y + layerHeight / 2, 0)) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Slate, Color = vary(theme.Mountain, 0.08), CastShadow = false, Parent = map })
			y += layerHeight * 0.9
		end
	end
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
	atmosphere.Density = 0.38
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

function MapBuilder.build()
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local map = Instance.new("Folder")
	map.Name = "Map"
	buildScenery(map)
	buildTower(map)
	map.Parent = workspace

	setupLighting()
end

return MapBuilder
