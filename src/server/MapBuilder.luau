-- Construye el mapa por código para que el juego funcione en un lugar vacío.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STONE = Color3.fromRGB(120, 120, 128)
local TORCH_COLOR = Color3.fromRGB(255, 150, 60)

local MapBuilder = {}

local function rangeList(from: number, to: number, step: number): { number }
	local list = {}
	for value = from, to, step do
		table.insert(list, value)
	end
	return list
end

local function makePart(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		part[key] = value
	end
	return part
end

function MapBuilder.build()
	for _, child in workspace:GetChildren() do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local arena = Config.Arena
	local width, height, depth = arena.CastleWidth, arena.CastleHeight, arena.CastleDepth

	local map = Instance.new("Folder")
	map.Name = "Map"

	makePart({
		Name = "Ground",
		Size = Vector3.new(arena.GroundSize, 2, arena.GroundSize),
		Position = Vector3.new(0, -1, 0),
		Material = Enum.Material.Grass,
		Color = Color3.fromRGB(62, 72, 50),
		Parent = map,
	})

	makePart({
		Name = "Graveyard",
		Size = Vector3.new(arena.SpawnHalfWidth * 2 + 10, 0.2, 24),
		Position = Vector3.new(0, 0.1, arena.SpawnZ - 4),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(52, 42, 36),
		CanCollide = false,
		Parent = map,
	})

	-- Lápidas detrás de la línea donde salen los zombis
	local random = Random.new(7)
	for x = -arena.SpawnHalfWidth, arena.SpawnHalfWidth, 8 do
		local height = random:NextNumber(2.5, 4)
		makePart({
			Name = "Tombstone",
			Size = Vector3.new(2.2, height, 0.6),
			CFrame = CFrame.new(x + random:NextNumber(-2, 2), height / 2, arena.SpawnZ - random:NextNumber(6, 14))
				* CFrame.Angles(random:NextNumber(-0.12, 0.12), 0, random:NextNumber(-0.12, 0.12)),
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(105, 105, 110),
			CanCollide = false,
			CanQuery = false,
			Parent = map,
		})
	end

	makePart({
		Name = "CastleWall",
		Size = Vector3.new(width, height, depth),
		Position = Vector3.new(0, height / 2, 0),
		Material = Enum.Material.Slate,
		Color = STONE,
		Parent = map,
	})

	makePart({
		Name = "Gate",
		Size = Vector3.new(14, 14, 1),
		Position = Vector3.new(0, 7, -depth / 2 - 0.5),
		Material = Enum.Material.WoodPlanks,
		Color = Color3.fromRGB(105, 70, 40),
		Parent = map,
	})

	for index, x in rangeList(-width / 2 + 2, width / 2 - 2, 6) do
		makePart({
			Name = "Merlon",
			-- Bajas (a la cintura) para que no tapen la vista al disparar
			Size = Vector3.new(3, 1.6, 1.5),
			Position = Vector3.new(x, height + 0.8, -depth / 2 + 0.75),
			Material = Enum.Material.Slate,
			Color = STONE,
			Parent = map,
		})
		if index % 3 == 1 then
			local torch = makePart({
				Name = "Torch",
				Size = Vector3.new(0.6, 1.2, 0.6),
				Position = Vector3.new(x, height + 2.2, -depth / 2 + 0.75),
				Material = Enum.Material.Neon,
				Color = TORCH_COLOR,
				CanCollide = false,
				CanQuery = false,
				Parent = map,
			})
			local light = Instance.new("PointLight")
			light.Color = TORCH_COLOR
			light.Range = 24
			light.Brightness = 2
			light.Parent = torch
		end
	end

	makePart({
		Name = "BackRail",
		Size = Vector3.new(width, 1.6, 1),
		Position = Vector3.new(0, height + 0.8, depth / 2 - 0.5),
		Material = Enum.Material.Slate,
		Color = STONE,
		Parent = map,
	})

	local towerHeight = height + 12
	for _, side in { -1, 1 } do
		makePart({
			Name = "Tower",
			Size = Vector3.new(14, towerHeight, 14),
			Position = Vector3.new(side * (width / 2 + 7), towerHeight / 2, 0),
			Material = Enum.Material.Slate,
			Color = STONE:Lerp(Color3.new(0, 0, 0), 0.15),
			Parent = map,
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "WallSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(16, 1, 6)
	spawn.Position = Vector3.new(0, height + 0.5, 3)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map

	map.Parent = workspace

	-- Noche con niebla: los zombis aparecen de la oscuridad
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(70, 70, 95)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 90, 120)
	Lighting.FogColor = Color3.fromRGB(25, 28, 38)
	Lighting.FogStart = 60
	Lighting.FogEnd = 260
end

return MapBuilder
