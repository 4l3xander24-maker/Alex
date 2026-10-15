-- Detalles con los modelos de la plantilla "Studio Tour" de Roblox
-- (src/models/Feria*) en el campamento y la aldea:
--   * Lomas de pasto para que el suelo no sea plano (fuera de los caminos).
--   * Árboles frondosos que se mecen con el viento y sueltan hojas.
--   * Arbustos y flores que también se mecen, y barriles, cajas y carretillas.
-- Se arma con el mapa ya en el workspace: así ve qué lugares están ocupados
-- y no pone nada encima de casas, puestos, carpas o caminos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MedievalBuilder = require(script.Parent.MedievalBuilder)
local ModelLibrary = require(script.Parent.ModelLibrary)
local Props = require(script.Parent.Props)

local random = Random.new(77)
local LEAVES = { Color3.fromRGB(120, 170, 60), Color3.fromRGB(150, 190, 70), Color3.fromRGB(96, 140, 50), Color3.fromRGB(200, 196, 90) }
local FLOWERS = { "FeriaFlowersA", "FeriaFlowersB", "FeriaFlowersC" }
local CLUTTER = { { "FeriaBarrel", { Height = 3 } }, { "FeriaCrate", { Height = 2.6 } }, { "FeriaWheelbarrow", { Footprint = 5 } } }
local TRIES = 60 -- intentos por cada cosa antes de rendirse

-- Zonas: centro, anillo donde se pone cada cosa y cuántas
local village = Config.Arena.Islands.Village.Disks[1]
local AREAS = {
	{
		Center = Config.Arena.CampCenter,
		Hills = { Count = 14, Inner = 36, Outer = 58 },
		Trees = { Count = 11, Inner = 38, Outer = 58 },
		Bushes = { Count = 12, Inner = 30, Outer = 54 },
		Flowers = { Count = 16, Inner = 20, Outer = 52 },
		Clutter = { Count = 5, Inner = 20, Outer = 44 },
	},
	{
		Center = Vector3.new(village.Center.X, 0, village.Center.Y),
		Hills = { Count = 11, Inner = 20, Outer = 48 },
		Trees = { Count = 14, Inner = 16, Outer = 48 },
		Bushes = { Count = 12, Inner = 12, Outer = 46 },
		Flowers = { Count = 18, Inner = 8, Outer = 44 },
		Clutter = { Count = 6, Inner = 10, Outer = 38 },
	},
}

local FeriaBuilder = {}

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Exclude
overlap.FilterDescendantsInstances = { workspace.Terrain }

local downRay = RaycastParams.new()
downRay.FilterType = Enum.RaycastFilterType.Include
downRay.FilterDescendantsInstances = { workspace.Terrain }

-- Punto al azar en el anillo de la zona
local function ringPoint(center: Vector3, inner: number, outer: number): Vector3
	local angle = random:NextNumber(0, math.pi * 2)
	local radius = math.sqrt(random:NextNumber(inner * inner, outer * outer))
	return center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

-- Libre de caminos, agua, castillo, campana y de cualquier pieza del mapa
local function isFree(position: Vector3, radius: number): boolean
	if not MedievalBuilder.isClear(position, radius) then
		return false
	end
	if (position - Config.Arena.Bell).Magnitude < 22 + radius then
		return false
	end
	-- Entre el círculo de runas y la campana no va nada: se tiene que ver
	local from, to = Config.Arena.SpawnCircle, Config.Arena.Bell
	local along = math.clamp((position - from):Dot(to - from) / (to - from).Magnitude ^ 2, 0, 1)
	if (position - from:Lerp(to, along)).Magnitude < 10 + radius then
		return false
	end
	local box = CFrame.new(position + Vector3.new(0, 7, 0))
	return #workspace:GetPartBoundsInBox(box, Vector3.new(radius * 2, 14, radius * 2), overlap) == 0
end

-- Altura del terreno en ese punto (las lomas lo suben)
local function groundAt(position: Vector3): Vector3
	local hit = workspace:Raycast(Vector3.new(position.X, 60, position.Z), Vector3.new(0, -120, 0), downRay)
	return Vector3.new(position.X, if hit then hit.Position.Y else 0, position.Z)
end

local function scatter(rule: { Count: number, Inner: number, Outer: number }, center: Vector3, radius: number, place: (Vector3) -> ())
	local placed, tries = 0, 0
	while placed < rule.Count and tries < rule.Count * TRIES do
		tries += 1
		local position = ringPoint(center, rule.Inner, rule.Outer)
		if isFree(position, radius) then
			place(groundAt(position))
			placed += 1
		end
	end
end

local function hill(position: Vector3)
	local radius = random:NextNumber(10, 18)
	-- Una bola de pasto medio enterrada: sube de 5 a 9 studs, con bordes suaves
	workspace.Terrain:FillBall(Vector3.new(position.X, -radius * 0.5, position.Z), radius, Enum.Material.Grass)
	-- A veces una loma más chica pegada, para que no sean todas redondas iguales
	if random:NextNumber() < 0.5 then
		local side = random:NextNumber(0, math.pi * 2)
		local small = radius * random:NextNumber(0.5, 0.7)
		local offset = Vector3.new(math.cos(side), 0, math.sin(side)) * radius * 0.5
		workspace.Terrain:FillBall(Vector3.new(position.X + offset.X, -small * 0.45, position.Z + offset.Z), small, Enum.Material.Grass)
	end
end

local function tree(map: Instance, position: Vector3)
	local height = random:NextNumber(22, 30)
	local model = ModelLibrary.place("FeriaTree", CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), { Height = height }, false, map)
	if not model then
		return
	end
	Props.swayTree(model, position, height, 0.8)
	Props.leafFall(map, position + Vector3.new(0, height * 0.6, 0), height * 0.6, LEAVES)
end

local function swayingModel(map: Instance, name: string, position: Vector3, size: { Height: number?, Footprint: number? }, amount: number)
	local model = ModelLibrary.place(name, CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), size, false, map)
	if model then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				Props.sway(part, position, amount)
			end
		end
	end
end

function FeriaBuilder.build(map: Instance)
	if not ModelLibrary.has("FeriaTree") then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "Feria"
	folder.Parent = map
	-- Primero las lomas (cambian la altura del suelo), después lo demás encima
	for _, area in AREAS do
		scatter(area.Hills, area.Center, 18, hill)
	end
	for _, area in AREAS do
		-- La copa es ancha: lejos del camino para no taparlo
		scatter(area.Trees, area.Center, 12, function(position)
			tree(folder, position)
		end)
		scatter(area.Bushes, area.Center, 3, function(position)
			swayingModel(folder, "FeriaBush", position, { Height = random:NextNumber(3.5, 5.5) }, 0.03)
		end)
		scatter(area.Flowers, area.Center, 1.5, function(position)
			swayingModel(folder, FLOWERS[random:NextInteger(1, #FLOWERS)], position, { Height = random:NextNumber(1.2, 1.8) }, 0.06)
		end)
		scatter(area.Clutter, area.Center, 2.5, function(position)
			local item = CLUTTER[random:NextInteger(1, #CLUTTER)]
			ModelLibrary.place(item[1], CFrame.new(position) * CFrame.Angles(0, random:NextNumber(0, math.pi * 2), 0), item[2], true, folder)
		end)
	end
end

return FeriaBuilder
