-- Los dos puentes del mapa:
--   * El puente de piedra (como en Guns 'n Goblins), en diagonal sobre el
--     canal: el único paso del bosque a la isla principal. Losas grandes con
--     musgo y pasto, muros bajos con postes de madera oscura, un pilar en el
--     medio que baja hasta el mar y columnas con antorchas en las esquinas. Las
--     rejas de metal de los extremos solo aparecen si se compran (TrapService).
--   * El puente de madera a la aldea, ROTO: quedan los dos extremos y unas
--     tablas colgando. Cada jugador lo repara una vez con monedas
--     (VillageService); las tablas que faltan las pone su propio cliente.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local STONE = Color3.fromRGB(118, 124, 120)
local DARK_STONE = Color3.fromRGB(78, 84, 86)
local MOSS = Color3.fromRGB(70, 120, 60)
local POST = Color3.fromRGB(40, 32, 26)
local PLANK = Color3.fromRGB(122, 86, 54)
local ROPE = Color3.fromRGB(150, 120, 80)

local theme = Config.Themes[Config.Theme] or Config.Themes.Verde
local random = Random.new(41)

local BridgeBuilder = {}

local arena = Config.Arena
local DECK = 1.5 -- grosor de las losas (arriba en y = 0)

-- Marco del puente: -Z va de From a To, X lo cruza de lado a lado. El
-- extremo del bosque está ForestDrop más abajo: el puente es una rampa.
local function bridgeFrame(from: Vector3, to: Vector3): (CFrame, number)
	local drop = arena.ForestDrop or 0
	local flatFrom, flatTo = Vector3.new(from.X, -drop, from.Z), Vector3.new(to.X, 0, to.Z)
	return CFrame.lookAt((flatFrom + flatTo) / 2, flatTo), (Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
end

-- Mismo lugar, pero derecho (sin la inclinación de la rampa): torres y pilares
local function upright(frame: CFrame): CFrame
	local look = frame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z).Unit
	return CFrame.lookAt(frame.Position, frame.Position + flat)
end

-- Cuánto avanzó (desde el centro, hacia To) el puente cuando cruza esa Z
local function alongAtZ(from: Vector3, to: Vector3, z: number): number
	local length = (Vector3.new(to.X, 0, to.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude
	return ((z - from.Z) / (to.Z - from.Z) - 0.5) * length
end

-- Columna de piedra en una esquina del puente, con antorcha arriba
-- Torrecita de guardia en cada esquina: base ancha, cuerpo alto, almenas,
-- antorcha arriba y estandarte colgando hacia el camino
local function cornerPillar(model: Model, frame: CFrame, side: number)
	frame = upright(frame)
	local height = 10
	makePart({ Name = "PillarBase", Size = Vector3.new(4.6, 1.6, 4.6), CFrame = frame * CFrame.new(0, 0.8, 0), Material = Enum.Material.Cobblestone, Color = Props.vary(DARK_STONE, 0.06, random), Parent = model })
	makePart({ Name = "BridgePillar", Size = Vector3.new(3.8, height, 3.8), CFrame = frame * CFrame.new(0, height / 2, 0), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = model })
	makePart({ Name = "PillarCap", Size = Vector3.new(4.6, 0.8, 4.6), CFrame = frame * CFrame.new(0, height + 0.4, 0), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })
	for _, corner in { Vector3.new(-1.7, 0, -1.7), Vector3.new(1.7, 0, -1.7), Vector3.new(-1.7, 0, 1.7), Vector3.new(1.7, 0, 1.7) } do
		makeProp({ Name = "PillarMerlon", Size = Vector3.new(1.1, 1.3, 1.1), CFrame = frame * CFrame.new(corner + Vector3.new(0, height + 1.45, 0)), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	end
	local banner = makeProp({ Name = "PillarBanner", Size = Vector3.new(0.15, 4.2, 2.2), CFrame = frame * CFrame.new(-side * 1.98, height - 3, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 110, 60), Parent = model })
	Props.sway(banner, (frame * CFrame.new(-side * 1.98, height - 0.9, 0)).Position, 0.02)
	if theme.Medieval then
		Props.torch(model, (frame * CFrame.new(0, height + 0.8, 0)).Position, 1.6)
	end
end

function BridgeBuilder.build(map: Instance)
	local model = Instance.new("Model")
	model.Name = "StoneBridge"
	local bridge, ravine = arena.Bridge, arena.Ravine
	local frame, length = bridgeFrame(bridge.From, bridge.To)
	local width = bridge.Width
	local half = length / 2 + 1 -- un poco más largo para apoyarse en las orillas
	-- Punto del puente: x de lado a lado, y de altura, a hacia To
	local function at(x: number, y: number, a: number): CFrame
		return frame * CFrame.new(x, y, -a)
	end

	-- Losas grandes en damero de tonos, cada una un poquito desnivelada
	local slab = 4
	for a = -half, half - 0.01, slab do
		local size = math.min(slab, half - a)
		for x = -width / 2, width / 2 - 0.01, slab do
			local slabWidth = math.min(slab, width / 2 - x)
			local center = at(x + slabWidth / 2, -DECK / 2 + random:NextNumber(-0.04, 0.06), a + size / 2)
			makePart({ Name = "Flagstone", Size = Vector3.new(slabWidth - 0.08, DECK, size - 0.08), CFrame = center, Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.1, random), Parent = model })
			-- Musgo y pasto entre las losas
			local roll = random:NextNumber()
			if roll < 0.25 then
				makeProp({ Name = "Moss", Size = Vector3.new(random:NextNumber(0.6, 1.6), 0.08, random:NextNumber(0.6, 1.6)), CFrame = center * CFrame.new(random:NextNumber(-1.2, 1.2), DECK / 2 + 0.04, random:NextNumber(-1.2, 1.2)), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.15, random), CastShadow = false, Parent = model })
			elseif roll < 0.4 then
				local base = (center * CFrame.new(random:NextNumber(-1.4, 1.4), DECK / 2, random:NextNumber(-1.4, 1.4))).Position
				for blade = 1, 3 do
					local height = random:NextNumber(0.5, 1.1)
					local tuft = makeProp({ Name = "GrassTuft", Size = Vector3.new(0.22, height, 0.22), Position = base + Vector3.new(blade * 0.3 - 0.6, height / 2, random:NextNumber(-0.2, 0.2)), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.2, random), CastShadow = false, Parent = model })
					Props.sway(tuft, base, 0.25)
				end
			end
		end
	end
	-- Cuerpo del puente debajo de las losas
	makePart({ Name = "BridgeBody", Size = Vector3.new(width, 3, half * 2), CFrame = at(0, -DECK - 1.5, 0), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })

	-- Dónde cruza cada orilla del canal y el medio
	local farBank = alongAtZ(bridge.From, bridge.To, ravine.ZMin)
	local nearBank = alongAtZ(bridge.From, bridge.To, ravine.ZMax)
	local middle = (farBank + nearBank) / 2

	-- Pilar del medio hasta el mar y arcos escalonados hacia cada orilla
	local pierThickness = 6
	local pierTop = -DECK - 3
	local bottom = arena.SeaLevel - 6
	local pierHeight = pierTop - bottom
	makePart({ Name = "BridgePier", Size = Vector3.new(width - 1, pierHeight, pierThickness), CFrame = upright(at(0, bottom + pierHeight / 2, middle)), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, random), Parent = model })
	makePart({ Name = "PierCutwater", Size = Vector3.new(width + 1, 4, pierThickness + 2), CFrame = upright(at(0, arena.SeaLevel + 1, middle)), Material = Enum.Material.Slate, Color = DARK_STONE, Parent = model })
	local span = (nearBank - farBank) / 2 - pierThickness / 2
	for _, direction in { -1, 1 } do
		local bank = if direction > 0 then nearBank else farBank
		for step = 1, 3 do
			local stepLength = span * (0.32 - step * 0.07)
			local stepHeight = step * 2.2
			local y = pierTop - stepHeight / 2
			makePart({ Name = "ArchStep", Size = Vector3.new(width - 1, stepHeight, stepLength), CFrame = at(0, y, middle + direction * (pierThickness / 2 + stepLength / 2)), Material = Enum.Material.Slate, Color = Props.vary(DARK_STONE, 0.06, random), Parent = model })
			makePart({ Name = "ArchStep", Size = Vector3.new(width - 1, stepHeight, stepLength), CFrame = at(0, y, bank - direction * stepLength / 2), Material = Enum.Material.Slate, Color = Props.vary(DARK_STONE, 0.06, random), Parent = model })
		end
	end
	-- Apoyos de piedra en las orillas
	for _, bank in { farBank, nearBank } do
		makePart({ Name = "Abutment", Size = Vector3.new(width + 6, 16, 3), CFrame = upright(at(0, -DECK - 8, bank + (if bank == farBank then -1.5 else 1.5))), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.06, random), Parent = model })
	end

	-- Muros bajos a los lados con postes de madera oscura
	local wallHeight, wallThickness = 3, 1.4
	for _, side in { -1, 1 } do
		local x = side * (width / 2 - wallThickness / 2)
		for a = -half, half - 0.01, 4 do
			local segment = math.min(4, half - a)
			makePart({ Name = "Parapet", Size = Vector3.new(wallThickness, wallHeight, segment - 0.06), CFrame = at(x, wallHeight / 2, a + segment / 2), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.08, random), Parent = model })
			makePart({ Name = "ParapetPost", Size = Vector3.new(1.6, wallHeight + 0.8, 1.6), CFrame = at(x + side * 0.1, (wallHeight + 0.8) / 2, a), Material = Enum.Material.Slate, Color = Props.vary(DARK_STONE, 0.06, random), Parent = model })
			-- Almena sobre el muro, a la mitad de cada tramo
			if segment > 2 then
				makeProp({ Name = "ParapetMerlon", Size = Vector3.new(wallThickness, 1, 1.6), CFrame = at(x, wallHeight + 0.5, a + segment / 2), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.08, random), Parent = model })
			end
		end
		-- Hiedra colgando del borde de afuera
		for _ = 1, 5 do
			local drop = random:NextNumber(2, 6)
			makeProp({ Name = "Ivy", Size = Vector3.new(0.2, drop, random:NextNumber(1, 2.4)), CFrame = at(side * (width / 2 + 0.1), -drop / 2 + 0.6, random:NextNumber(farBank + 2, nearBank - 2)), Material = Enum.Material.LeafyGrass, Color = Props.vary(MOSS, 0.15, random), CastShadow = false, Parent = model })
		end
	end

	-- Columnas con antorcha en las cuatro esquinas
	for _, a in { -half - 1.4, half + 1.4 } do
		for _, side in { -1, 1 } do
			cornerPillar(model, at(side * (width / 2 + 1.2), 0, a), side)
		end
	end

	model.Parent = map
end

-- Puente de madera a la aldea. Construye los extremos (en el mapa) y devuelve
-- las tablas que faltan en una carpeta aparte: cada cliente las pone cuando su
-- jugador ya lo reparó. También devuelve dónde va el aviso para repararlo.
function BridgeBuilder.buildVillageBridge(map: Instance): (Folder, BasePart)
	local info = arena.VillageBridge
	local frame, length = bridgeFrame(info.From, info.To)
	local width = info.Width
	local function at(x: number, y: number, a: number): CFrame
		return frame * CFrame.new(x, y, -a)
	end
	local model = Instance.new("Model")
	model.Name = "VillageBridge"
	local missing = Instance.new("Folder")
	missing.Name = "VillageBridgePlanks"

	local stub = 7 -- lo que queda en pie de cada lado
	local plank = 1.2
	local half = length / 2 + 1
	for a = -half, half - 0.01, plank do
		local center = a + plank / 2
		local intact = center < -half + stub or center > half - stub
		local props = { Name = "Plank", Size = Vector3.new(width, 0.5, plank - 0.12), CFrame = at(0, -0.25, center) * CFrame.Angles(0, random:NextNumber(-0.03, 0.03), 0), Material = Enum.Material.WoodPlanks, Color = Props.vary(PLANK, 0.12, random) }
		if intact then
			props.Parent = model
			makePart(props)
		else
			props.Parent = missing
			makePart(props)
		end
	end
	-- Algunas tablas rotas colgando del borde de cada extremo
	for _, side in { -1, 1 } do
		local edge = side * (half - stub)
		for index = 1, 3 do
			local hang = makeProp({ Name = "BrokenPlank", Size = Vector3.new(random:NextNumber(1.5, width - 1), 0.4, plank - 0.12), CFrame = at(random:NextNumber(-1.5, 1.5), -1.2 * index, edge - side * 0.5) * CFrame.Angles(side * random:NextNumber(1.1, 1.4), random:NextNumber(-0.3, 0.3), 0), Material = Enum.Material.WoodPlanks, Color = Props.vary(PLANK, 0.15, random), Parent = model })
			hang:SetAttribute("Broken", true)
		end
	end
	-- Postes que bajan al agua y barandas de soga
	for a = -half, half, 6 do
		for _, x in { -width / 2, width / 2 } do
			local post = makePart({ Name = "BridgePost", Size = Vector3.new(0.7, 4, 0.7), CFrame = at(x, 1.2, a), Material = Enum.Material.Wood, Color = POST, Parent = model })
			local stands = math.abs(a) > half - stub - 1
			if not stands then
				-- Los del medio quedaron torcidos
				post.CFrame = post.CFrame * CFrame.Angles(random:NextNumber(-0.4, 0.4), 0, random:NextNumber(-0.5, 0.5))
			end
			makePart({ Name = "Pile", Size = Vector3.new(0.9, -arena.SeaLevel, 0.9), CFrame = at(x, arena.SeaLevel / 2 - 0.5, a), Material = Enum.Material.Wood, Color = POST, Parent = model })
		end
	end
	for _, x in { -width / 2, width / 2 } do
		for _, side in { -1, 1 } do
			local mid = side * (half - stub / 2)
			makeProp({ Name = "Rope", Size = Vector3.new(0.18, 0.18, stub), CFrame = at(x, 2.8, mid), Material = Enum.Material.Fabric, Color = ROPE, Parent = model })
			local rope = makeProp({ Name = "Rope", Size = Vector3.new(0.18, 0.18, half - stub), CFrame = at(x, 2.8, side * (half - stub) / 2), Material = Enum.Material.Fabric, Color = ROPE, Parent = missing })
			rope.CanCollide = false
		end
	end
	-- Letrero y aviso para repararlo, en el lado de la isla principal
	local anchor = makePart({ Name = "RepairSign", Size = Vector3.new(4.4, 2.2, 0.3), CFrame = at(-width / 2 - 2.6, 2.6, -half + 1.5) * CFrame.Angles(0, math.rad(25), 0), Material = Enum.Material.WoodPlanks, Color = PLANK, Parent = model })
	makePart({ Name = "SignPost", Size = Vector3.new(0.4, 2.6, 0.4), CFrame = anchor.CFrame * CFrame.new(0, -2.4, 0), Material = Enum.Material.Wood, Color = POST, Parent = model })
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 40
	surface.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Config.PixelFont
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 225, 140)
	label.Text = `ALDEA\nPuente roto · {info.Price} 🪙`
	label.Parent = surface

	model.Parent = map
	return missing, anchor
end

return BridgeBuilder
