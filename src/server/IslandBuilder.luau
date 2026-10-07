-- La tierra y el agua del mapa: al norte del canal el bosque (tierra firme
-- hasta el horizonte); al sur todo es mar, abajo de los acantilados, con dos
-- islas de pasto sobre columnas de roca: la principal (campana, castillo y
-- campamento) y la de la aldea (Config.Arena.Islands).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local ROCK = Color3.fromRGB(86, 90, 98)
local WATER = Color3.fromRGB(30, 80, 96)

local random = Random.new(53)

local IslandBuilder = {}

local arena = Config.Arena
local DEEP = arena.SeaLevel - 25 -- fondo del mar

-- Paredes naturales: rocas grandes y chicas que sobresalen a distintas
-- alturas (como acantilados de terreno de Roblox) y pasto que cuelga del borde
local function rockyEdge(terrain: Terrain, from: Vector3, to: Vector3)
	local offset = to - from
	local steps = math.max(1, math.floor(offset.Magnitude / 6))
	for index = 0, steps do
		local point = from + offset * (index / steps)
		for _ = 1, 3 do
			local position = Vector3.new(point.X + random:NextNumber(-4, 4), random:NextNumber(arena.SeaLevel - 4, -10), point.Z + random:NextNumber(-4, 4))
			terrain:FillBall(position, random:NextNumber(4, 9), Enum.Material.Rock)
		end
		-- Labio de pasto que sobresale arriba
		if random:NextNumber() < 0.6 then
			terrain:FillBall(Vector3.new(point.X + random:NextNumber(-2, 2), random:NextNumber(-3.5, -2), point.Z + random:NextNumber(-2, 2)), random:NextNumber(2.5, 4), Enum.Material.Grass)
		end
	end
end

-- Columna de roca con pasto arriba (y = 0) para un rectángulo o un círculo
local function fillBox(terrain: Terrain, center: Vector2, size: Vector2)
	local rockHeight = -8 - DEEP
	terrain:FillBlock(CFrame.new(center.X, DEEP + rockHeight / 2, center.Y), Vector3.new(size.X, rockHeight, size.Y), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(center.X, -4, center.Y), Vector3.new(size.X, 8, size.Y), Enum.Material.Grass)
	local hx, hz = size.X / 2, size.Y / 2
	local corners = {
		Vector3.new(center.X - hx, 0, center.Y - hz),
		Vector3.new(center.X + hx, 0, center.Y - hz),
		Vector3.new(center.X + hx, 0, center.Y + hz),
		Vector3.new(center.X - hx, 0, center.Y + hz),
	}
	for index = 1, 4 do
		rockyEdge(terrain, corners[index], corners[index % 4 + 1])
	end
end

local function fillDisk(terrain: Terrain, center: Vector2, radius: number)
	local rockHeight = -8 - DEEP
	terrain:FillCylinder(CFrame.new(center.X, DEEP + rockHeight / 2, center.Y), rockHeight, radius, Enum.Material.Rock)
	terrain:FillCylinder(CFrame.new(center.X, -4, center.Y), 8, radius, Enum.Material.Grass)
	local steps = math.floor(radius * 2 * math.pi / 9)
	for index = 1, steps do
		local angle = index / steps * math.pi * 2
		local point = Vector3.new(center.X + math.cos(angle) * radius, 0, center.Y + math.sin(angle) * radius)
		rockyEdge(terrain, point, point)
	end
end

-- Terreno de Roblox: mar, bosque al norte e islas
function IslandBuilder.buildTerrain(terrain: Terrain)
	local width = arena.GroundSize
	local half = width / 2
	local ravine = arena.Ravine

	-- El mar: todo el sur desde el canal, con fondo de arena y rocas que asoman
	local seaLength = half - ravine.ZMin
	local seaCenter = ravine.ZMin + seaLength / 2
	terrain:FillBlock(CFrame.new(0, DEEP - 5, seaCenter), Vector3.new(width, 10, seaLength), Enum.Material.Sand)
	terrain:FillBlock(CFrame.new(0, (DEEP + arena.SeaLevel) / 2, seaCenter), Vector3.new(width, arena.SeaLevel - DEEP, seaLength), Enum.Material.Water)
	for _ = 1, 60 do
		local position = Vector3.new(random:NextNumber(-half, half), arena.SeaLevel - random:NextNumber(2, 8), random:NextNumber(ravine.ZMin + 10, half))
		terrain:FillBall(position, random:NextNumber(4, 12), Enum.Material.Rock)
	end
	terrain.WaterColor = Color3.fromRGB(25, 70, 80)
	terrain.WaterTransparency = 0.35
	terrain.WaterReflectance = 0.6
	terrain.WaterWaveSize = 0.3
	terrain.WaterWaveSpeed = 10

	-- El bosque: pasto hasta el horizonte y un acantilado de roca sobre el canal
	local landLength = ravine.ZMin + half
	terrain:FillBlock(CFrame.new(0, -4, ravine.ZMin - landLength / 2), Vector3.new(width, 8, landLength), Enum.Material.Grass)
	local rockHeight = -8 - DEEP
	terrain:FillBlock(CFrame.new(0, DEEP + rockHeight / 2, ravine.ZMin - 20), Vector3.new(width, rockHeight, 40), Enum.Material.Rock)
	rockyEdge(terrain, Vector3.new(-half, 0, ravine.ZMin), Vector3.new(half, 0, ravine.ZMin))

	-- Las islas
	for _, island in arena.Islands do
		for _, box in island.Boxes do
			fillBox(terrain, box.Center, box.Size)
		end
		for _, disk in island.Disks do
			fillDisk(terrain, disk.Center, disk.Radius)
		end
	end
	-- La isla principal termina en el acantilado detrás del campamento
	local cut = 60
	terrain:FillBlock(CFrame.new(0, (arena.SeaLevel + 6) / 2, arena.CliffZ + cut / 2), Vector3.new(200, 6 - arena.SeaLevel, cut), Enum.Material.Air)
	rockyEdge(terrain, Vector3.new(-60, 0, arena.CliffZ), Vector3.new(60, 0, arena.CliffZ))
end

-- Estilo Voxel (sin terreno): mar plano y columnas de bloques de roca bajo las islas
function IslandBuilder.buildVoxel(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Islands"
	folder.Parent = map
	local width = arena.GroundSize
	local ravine = arena.Ravine
	local seaLength = width / 2 - ravine.ZMin
	makeProp({ Name = "Sea", Size = Vector3.new(width, 1, seaLength), Position = Vector3.new(0, arena.SeaLevel, ravine.ZMin + seaLength / 2), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.15, Parent = folder })
	local height = -arena.SeaLevel
	makePart({ Name = "NorthCliff", Size = Vector3.new(width, height, 8), Position = Vector3.new(0, arena.SeaLevel / 2 - 1, ravine.ZMin - 4), Material = Enum.Material.Rock, Color = ROCK, Parent = folder })
	for _, island in arena.Islands do
		for _, box in island.Boxes do
			makePart({ Name = "IslandRock", Size = Vector3.new(box.Size.X, height, box.Size.Y), Position = Vector3.new(box.Center.X, arena.SeaLevel / 2 - 1, box.Center.Y), Material = Enum.Material.Rock, Color = ROCK, Parent = folder })
		end
		for _, disk in island.Disks do
			-- Tres cuadrados girados hacen un círculo de bloques
			local side = disk.Radius * math.sqrt(2)
			for turn = 0, 2 do
				makePart({ Name = "IslandRock", Size = Vector3.new(side, height, side), CFrame = CFrame.new(disk.Center.X, arena.SeaLevel / 2 - 1, disk.Center.Y) * CFrame.Angles(0, turn * math.pi / 6, 0), Material = Enum.Material.Rock, Color = Props.vary(ROCK, 0.05, random), Parent = folder })
			end
		end
	end
end

return IslandBuilder
