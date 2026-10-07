-- Suelo, acantilado y mar en pixel art 3D (Config.ArtStyle = "Voxel").
-- En vez del terreno de Roblox, el campo es una cuadrícula de baldosas de
-- colores: pasto en varios tonos, caminos de tierra y piedra con bordes
-- escalonados, flores y matas de pasto de cubitos. Más allá de la
-- cuadrícula hay un piso liso del mismo color para que el horizonte no quede vacío.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Paths = require(ReplicatedStorage.Shared.Paths)
local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp

local TILE = 8 -- tamaño de cada baldosa
local HALF_WIDTH = 280 -- la cuadrícula va de -280 a 280 en X
local FAR_Z = -300 -- y desde el acantilado hasta aquí en Z
local BASE_SIZE = 2000
local FLOWER_COLORS = {
	Color3.fromRGB(230, 60, 60),
	Color3.fromRGB(250, 210, 60),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(170, 100, 220),
}

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(31)

local VoxelBuilder = {}

local function shade(color: Color3, amount: number): Color3
	return Color3.new(math.clamp(color.R * amount, 0, 1), math.clamp(color.G * amount, 0, 1), math.clamp(color.B * amount, 0, 1))
end

-- Qué hay en cada baldosa: pasto, camino de tierra, piedra o tierra del campamento
local function tileKind(center: Vector3): string
	local arena = Config.Arena
	if center.Magnitude < arena.TowerSize / 2 + 5 then
		return "Stone"
	end
	if math.abs(center.X) < 5 and center.Z > 0 and center.Z < arena.CampCenter.Z then
		return "Stone"
	end
	local campOffset = center - arena.CampCenter
	if Vector3.new(campOffset.X, 0, campOffset.Z).Magnitude < arena.CampRadius then
		return "Dirt"
	end
	-- Sobre el agua no hay baldosas
	if not Paths.isGround(center) then
		return "Chasm"
	end
	local width = Config.PathStyle.Width / 2 + 1
	if Paths.distanceToAny(center) < width then
		return "Dirt"
	end
	return "Grass"
end

local COLORS = {
	Grass = theme.Ground,
	Dirt = Color3.fromRGB(110, 84, 56),
	Stone = Color3.fromRGB(128, 124, 116),
}

-- Florecita o mata de pasto encima de una baldosa
local function decorate(ground: Instance, center: Vector3, top: number)
	local roll = random:NextNumber()
	local spot = center + Vector3.new(random:NextNumber(-2.5, 2.5), top, random:NextNumber(-2.5, 2.5))
	if roll < 0.04 then
		local stem = makeProp({ Name = "Stem", Size = Vector3.new(0.2, 0.8, 0.2), Position = spot + Vector3.new(0, 0.4, 0), Color = shade(theme.Ground, 0.8), CastShadow = false, Parent = ground })
		local flower = makeProp({ Name = "Flower", Size = Vector3.new(0.5, 0.4, 0.5), Position = spot + Vector3.new(0, 0.95, 0), Color = FLOWER_COLORS[random:NextInteger(1, #FLOWER_COLORS)], CastShadow = false, Parent = ground })
		Props.sway(stem, spot, 0.2)
		Props.sway(flower, spot, 0.2)
	elseif roll < 0.11 then
		for blade = 1, 3 do
			local height = random:NextNumber(0.6, 1.3)
			local base = spot + Vector3.new(blade * 0.35 - 0.7, 0, random:NextNumber(-0.3, 0.3))
			local tuft = makeProp({ Name = "GrassTuft", Size = Vector3.new(0.25, height, 0.25), Position = base + Vector3.new(0, height / 2, 0), Color = shade(theme.Ground, random:NextNumber(1.05, 1.3)), CastShadow = false, Parent = ground })
			Props.sway(tuft, base, 0.3)
		end
	end
end

local function buildTiles(map: Instance)
	local ground = Instance.new("Folder")
	ground.Name = "VoxelGround"
	ground.Parent = map
	local cliffZ = Config.Arena.CliffZ
	local z = cliffZ - TILE / 2
	local row = 0
	while z > FAR_Z do
		row += 1
		for column = 1, HALF_WIDTH * 2 / TILE do
			local x = -HALF_WIDTH + (column - 0.5) * TILE
			local center = Vector3.new(x, 0, z)
			local kind = tileKind(center)
			if kind == "Chasm" then
				continue
			end
			local color = COLORS[kind]
			-- Tonos al azar, y en la piedra un damero suave
			local amount = random:NextNumber(0.86, 1.12)
			if kind == "Stone" and (row + column) % 2 == 0 then
				amount *= 0.9
			end
			local top = 0
			if kind == "Grass" and random:NextNumber() < 0.12 then
				top = 0.3 -- algunas baldosas un poquito más altas
			end
			makePart({ Name = "Tile", Size = Vector3.new(TILE, 2 + top, TILE), Position = Vector3.new(x, (top - 2) / 2, z), Color = shade(color, amount), Parent = ground })
			if kind == "Grass" then
				decorate(ground, center, top)
			end
		end
		z -= TILE
	end
end

-- Piso liso bajo y alrededor de la cuadrícula hasta el horizonte (siempre cargado)
local function buildBase(map: Instance)
	local base = Instance.new("Model")
	base.Name = "GroundBase"
	base.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local cliffZ = Config.Arena.CliffZ
	-- Solo al norte (el bosque); al sur todo es mar con islas (IslandBuilder)
	local ravine = Config.Arena.Ravine
	for _, span in { { -BASE_SIZE / 2, ravine.ZMin } } do
		local length = span[2] - span[1]
		makePart({ Name = "Base", Size = Vector3.new(BASE_SIZE, 2, length), Position = Vector3.new(0, -1.05, (span[1] + span[2]) / 2), Color = shade(theme.Ground, 0.95), Parent = base })
	end

	-- Acantilado detrás del campamento: columnas de bloques de roca de distintos tonos
	local rock = Color3.fromRGB(96, 96, 104)
	local sea = Config.Arena.SeaLevel
	for x = -64, 48, 16 do
		local y = 0
		while y > sea - 6 do
			local height = random:NextNumber(8, 16)
			local depth = random:NextNumber(4, 9)
			makePart({ Name = "CliffRock", Size = Vector3.new(16, height, depth), Position = Vector3.new(x + 8, y - height / 2, cliffZ + depth / 2 - 1), Color = shade(rock, random:NextNumber(0.8, 1.15)), Parent = base })
			y -= height
		end
	end

	-- Espuma al pie del acantilado y rocas de cubos en el mar (el agua la pone IslandBuilder)
	for x = -60, 60, 6 do
		if random:NextNumber() < 0.6 then
			makeProp({ Name = "Foam", Size = Vector3.new(random:NextNumber(2, 5), 0.4, random:NextNumber(1, 2.5)), Position = Vector3.new(x, sea + 0.1, cliffZ + random:NextNumber(8, 11)), Color = Color3.fromRGB(225, 240, 245), CastShadow = false, Parent = base })
		end
	end
	for _ = 1, 25 do
		local size = random:NextNumber(4, 12)
		makePart({ Name = "SeaRock", Size = Vector3.new(size, size, size), Position = Vector3.new(random:NextNumber(-300, 300), sea + size * 0.2, cliffZ + random:NextNumber(20, 160)), Color = shade(rock, random:NextNumber(0.8, 1.1)), Parent = base })
	end
	base.Parent = map
end

function VoxelBuilder.build(map: Instance)
	workspace.Terrain:Clear()
	buildBase(map)
	buildTiles(map)
end

return VoxelBuilder
