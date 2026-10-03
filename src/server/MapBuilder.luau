-- Construye el mapa por código para que el juego funcione en un lugar vacío.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local STONE = Color3.fromRGB(120, 120, 128)

local MapBuilder = {}

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
		Color = Color3.fromRGB(86, 125, 70),
		Parent = map,
	})

	makePart({
		Name = "GoblinSpawn",
		Size = Vector3.new(arena.SpawnHalfWidth * 2 + 10, 0.2, 12),
		Position = Vector3.new(0, 0.1, arena.SpawnZ),
		Material = Enum.Material.Ground,
		Color = Color3.fromRGB(90, 40, 40),
		CanCollide = false,
		Parent = map,
	})

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

	for x = -width / 2 + 2, width / 2 - 2, 6 do
		makePart({
			Name = "Merlon",
			Size = Vector3.new(3, 3, 1.5),
			Position = Vector3.new(x, height + 1.5, -depth / 2 + 0.75),
			Material = Enum.Material.Slate,
			Color = STONE,
			Parent = map,
		})
	end

	makePart({
		Name = "BackRail",
		Size = Vector3.new(width, 3, 1),
		Position = Vector3.new(0, height + 1.5, depth / 2 - 0.5),
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

	Lighting.ClockTime = 16.5
end

return MapBuilder
