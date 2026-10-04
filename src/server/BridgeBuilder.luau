-- El barranco con el río y el puente de piedra (como en Guns 'n Goblins): es
-- el único paso del bosque a la campana. El puente tiene losas grandes con
-- musgo y pasto, muros bajos con postes de madera oscura, un pilar en el medio
-- que baja hasta el río y columnas con antorchas en las cuatro esquinas. Las
-- rejas de metal de los extremos solo aparecen si se compran (TrapService).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local STONE = Color3.fromRGB(118, 124, 120)
local DARK_STONE = Color3.fromRGB(78, 84, 86)
local MOSS = Color3.fromRGB(70, 120, 60)
local POST = Color3.fromRGB(40, 32, 26)
local WATER = Color3.fromRGB(30, 80, 96)

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(41)

local BridgeBuilder = {}

local ravine = Config.Arena.Ravine
local bridge = Config.Arena.Bridge
local OVERHANG = 5 -- cuánto se apoya el puente sobre cada orilla
local DECK = 1.5 -- grosor de las losas (arriba en y = 0)

local function zRange(): (number, number)
	return ravine.ZMin - OVERHANG, ravine.ZMax + OVERHANG
end

-- Cava el barranco en el terreno de Roblox: paredes de roca irregulares, fondo
-- de arena y el río. Va después de pintar los caminos para borrar lo que quedó encima.
function BridgeBuilder.carveTerrain(terrain: Terrain)
	local width = Config.Arena.GroundSize
	local depth = ravine.ZMax - ravine.ZMin
	local middle = (ravine.ZMin + ravine.ZMax) / 2
	-- Roca debajo del pasto a los dos lados, para que las paredes no queden huecas
	terrain:FillBlock(CFrame.new(0, (ravine.Bottom - 8) / 2 - 4, middle), Vector3.new(width, -ravine.Bottom, depth + 60), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(0, -4, middle), Vector3.new(width, 8, depth + 60), Enum.Material.Grass)
	-- El hueco
	terrain:FillBlock(CFrame.new(0, (ravine.Bottom + 4) / 2, middle), Vector3.new(width, 4 - ravine.Bottom, depth), Enum.Material.Air)
	-- Rocas que asoman de las paredes
	local half = width / 2
	for x = -half, half, 10 do
		for _, wallZ in { ravine.ZMin, ravine.ZMax } do
			local position = Vector3.new(x + random:NextNumber(-4, 4), random:NextNumber(ravine.Bottom + 4, -12), wallZ + random:NextNumber(-2, 2))
			terrain:FillBall(position, random:NextNumber(4, 8), Enum.Material.Rock)
		end
	end
	-- Fondo, río y piedras en el agua
	terrain:FillBlock(CFrame.new(0, ravine.Bottom - 2, middle), Vector3.new(width, 4, depth + 4), Enum.Material.Sand)
	local water = ravine.WaterLevel - ravine.Bottom
	terrain:FillBlock(CFrame.new(0, ravine.Bottom + water / 2, middle), Vector3.new(width, water, depth), Enum.Material.Water)
	for _ = 1, 60 do
		local position = Vector3.new(random:NextNumber(-half, half), ravine.Bottom + random:NextNumber(0, 4), middle + random:NextNumber(-depth / 2 + 3, depth / 2 - 3))
		terrain:FillBall(position, random:NextNumber(2, 5), Enum.Material.Rock)
	end
end

-- En estilo Voxel (sin terreno): paredes de bloques de roca y un río plano
function BridgeBuilder.buildVoxelRavine(map: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Ravine"
	folder.Parent = map
	local width = Config.Arena.GroundSize
	local depth = ravine.ZMax - ravine.ZMin
	local middle = (ravine.ZMin + ravine.ZMax) / 2
	local wallHeight = -ravine.Bottom
	for _, wallZ in { ravine.ZMin - 4, ravine.ZMax + 4 } do
		makePart({ Name = "RavineWall", Size = Vector3.new(width, wallHeight, 8), Position = Vector3.new(0, ravine.Bottom / 2 - 0.5, wallZ), Material = Enum.Material.Rock, Color = DARK_STONE, Parent = folder })
	end
	makePart({ Name = "Riverbed", Size = Vector3.new(width, 2, depth + 8), Position = Vector3.new(0, ravine.Bottom - 1, middle), Material = Enum.Material.Sand, Color = Color3.fromRGB(120, 110, 90), Parent = folder })
	makeProp({ Name = "River", Size = Vector3.new(width, 0.4, depth), Position = Vector3.new(0, ravine.WaterLevel, middle), Material = Enum.Material.Glass, Color = WATER, Transparency = 0.25, Parent = folder })
end

-- Columna de piedra en una esquina del puente, con antorcha arriba
local function cornerPillar(model: Model, position: Vector3)
	makePart({ Name = "BridgePillar", Size = Vector3.new(2.6, 4.6, 2.6), Position = position + Vector3.new(0, 2.3, 0), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = model })
	makePart({ Name = "PillarCap", Size = Vector3.new(3.2, 0.8, 3.2), Position = position + Vector3.new(0, 5, 0), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })
	if theme.Medieval then
		Props.torch(model, position + Vector3.new(0, 5.4, 0), 1.6)
	end
end

function BridgeBuilder.build(map: Instance)
	local model = Instance.new("Model")
	model.Name = "StoneBridge"
	local zStart, zEnd = zRange()
	local length = zEnd - zStart
	local middle = (zStart + zEnd) / 2
	local x0, width = bridge.X, bridge.Width

	-- Losas grandes en damero de tonos, cada una un poquito desnivelada
	local slab = 4
	for z = zStart, zEnd - 0.01, slab do
		local size = math.min(slab, zEnd - z)
		local offset = random:NextNumber(0, 1) < 0.5
		for x = -width / 2, width / 2 - 0.01, slab do
			local slabWidth = math.min(slab, width / 2 - x)
			local center = Vector3.new(x0 + x + slabWidth / 2, -DECK / 2 + random:NextNumber(-0.04, 0.06), z + size / 2 + (if offset then 0.05 else 0))
			makePart({ Name = "Flagstone", Size = Vector3.new(slabWidth - 0.08, DECK, size - 0.08), Position = center, Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.1, random), Parent = model })
			-- Musgo y pasto entre las losas
			local roll = random:NextNumber()
			if roll < 0.25 then
				makeProp({ Name = "Moss", Size = Vector3.new(random:NextNumber(0.6, 1.6), 0.08, random:NextNumber(0.6, 1.6)), Position = center + Vector3.new(random:NextNumber(-1.2, 1.2), DECK / 2 + 0.04, random:NextNumber(-1.2, 1.2)), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.15, random), CastShadow = false, Parent = model })
			elseif roll < 0.4 then
				local base = center + Vector3.new(random:NextNumber(-1.4, 1.4), DECK / 2, random:NextNumber(-1.4, 1.4))
				for blade = 1, 3 do
					local height = random:NextNumber(0.5, 1.1)
					local tuft = makeProp({ Name = "GrassTuft", Size = Vector3.new(0.22, height, 0.22), Position = base + Vector3.new(blade * 0.3 - 0.6, height / 2, random:NextNumber(-0.2, 0.2)), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.2, random), CastShadow = false, Parent = model })
					Props.sway(tuft, base, 0.25)
				end
			end
		end
	end
	-- Cuerpo del puente debajo de las losas
	makePart({ Name = "BridgeBody", Size = Vector3.new(width, 3, length), Position = Vector3.new(x0, -DECK - 1.5, middle), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })

	-- Pilar del medio hasta el río y arcos escalonados hacia cada orilla
	local pierThickness = 6
	local pierTop = -DECK - 3
	local pierHeight = pierTop - ravine.Bottom
	makePart({ Name = "BridgePier", Size = Vector3.new(width - 1, pierHeight, pierThickness), Position = Vector3.new(x0, ravine.Bottom + pierHeight / 2, middle), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = model })
	makePart({ Name = "PierCutwater", Size = Vector3.new(width + 1, 4, pierThickness + 2), Position = Vector3.new(x0, ravine.WaterLevel + 1, middle), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })
	local span = (ravine.ZMax - ravine.ZMin) / 2 - pierThickness / 2
	for _, direction in { -1, 1 } do
		-- Del pilar y de la orilla bajan escalones que dibujan el arco
		for step = 1, 3 do
			local stepLength = span * (0.32 - step * 0.07)
			local stepHeight = step * 2.2
			local y = pierTop - stepHeight / 2
			for _, fromPier in { true, false } do
				local z = if fromPier
					then middle + direction * (pierThickness / 2 + stepLength / 2)
					else (if direction > 0 then ravine.ZMax else ravine.ZMin) - direction * stepLength / 2
				makePart({ Name = "ArchStep", Size = Vector3.new(width - 1, stepHeight, stepLength), Position = Vector3.new(x0, y, z), Material = Enum.Material.Slate, Color = Props.vary(DARK_STONE, 0.06, random), Parent = model })
			end
		end
	end
	-- Apoyos de piedra en las orillas
	for _, wallZ in { ravine.ZMin, ravine.ZMax } do
		makePart({ Name = "Abutment", Size = Vector3.new(width + 6, 16, 3), Position = Vector3.new(x0, -DECK - 8, wallZ + (if wallZ == ravine.ZMin then -1.5 else 1.5)), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.06, random), Parent = model })
	end

	-- Muros bajos a los lados con postes de madera oscura
	local wallHeight, wallThickness = 2.2, 1.2
	for _, side in { -1, 1 } do
		local x = x0 + side * (width / 2 - wallThickness / 2)
		for z = zStart, zEnd - 0.01, 4 do
			local segment = math.min(4, zEnd - z)
			makePart({ Name = "Parapet", Size = Vector3.new(wallThickness, wallHeight, segment - 0.06), Position = Vector3.new(x, wallHeight / 2, z + segment / 2), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.08, random), Parent = model })
			makePart({ Name = "ParapetPost", Size = Vector3.new(0.7, wallHeight + 1.6, 0.7), Position = Vector3.new(x + side * 0.1, (wallHeight + 1.6) / 2, z), Material = Enum.Material.Wood, Color = POST, Parent = model })
		end
		-- Hiedra colgando del borde de afuera
		for _ = 1, 5 do
			local z = random:NextNumber(ravine.ZMin + 2, ravine.ZMax - 2)
			local drop = random:NextNumber(2, 6)
			makeProp({ Name = "Ivy", Size = Vector3.new(0.2, drop, random:NextNumber(1, 2.4)), Position = Vector3.new(x0 + side * (width / 2 + 0.1), -drop / 2 + 0.6, z), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.15, random), CastShadow = false, Parent = model })
		end
	end

	-- Columnas con antorcha en las cuatro esquinas
	for _, z in { zStart - 1.4, zEnd + 1.4 } do
		for _, side in { -1, 1 } do
			cornerPillar(model, Vector3.new(x0 + side * (width / 2 + 0.2), 0, z))
		end
	end

	model.Parent = map
end

return BridgeBuilder
