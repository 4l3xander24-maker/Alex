-- El campamento detrás de la campana: fogata, bancos, tiendas de campaña,
-- empalizada y los tres NPC (Armero, Bruja y Veterano) con sus puestos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local DARK_WOOD = Props.Colors.DarkWood
local WOOD = Props.Colors.Wood
local FIRE_COLOR = Color3.fromRGB(255, 140, 60)

local camp = Config.Arena.CampCenter
local random = Random.new(11)

local CampBuilder = {}

-- CFrame en `position` mirando hacia la fogata (su -Z apunta al fuego)
local function facingCamp(position: Vector3): CFrame
	return CFrame.lookAt(position, Vector3.new(camp.X, position.Y, camp.Z))
end

local function buildCampfire(map: Instance)
	local center = camp
	for index = 1, 10 do
		local angle = index / 10 * math.pi * 2
		makePart({ Name = "FireStone", Size = Vector3.new(1.2, 0.8, 1), CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * 2.6, 0.4, math.sin(angle) * 2.6)) * CFrame.Angles(0, -angle, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(90, 92, 96), Parent = map })
	end
	for _, yaw in { 0.4, -0.4 + math.pi / 2 } do
		makeProp({ Name = "FireLog", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 0.8, 0.8), CFrame = CFrame.new(center + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, yaw, 0.15), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end

	local holder = makeProp({ Name = "Campfire", Size = Vector3.new(2, 1, 2), Position = center + Vector3.new(0, 1, 0), Transparency = 1, Parent = map })
	local fire = Instance.new("Fire")
	fire.Size = 6
	fire.Heat = 12
	fire.Color = FIRE_COLOR
	fire.SecondaryColor = Color3.fromRGB(255, 210, 90)
	fire.Parent = holder
	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.08
	smoke.RiseVelocity = 5
	smoke.Size = 5
	smoke.Color = Color3.fromRGB(40, 40, 40)
	smoke.Parent = holder
	Props.light(holder, FIRE_COLOR, 40, 3, true)

	local embers = Instance.new("ParticleEmitter")
	embers.Rate = 12
	embers.Lifetime = NumberRange.new(1.5, 3)
	embers.Speed = NumberRange.new(4, 8)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Size = NumberSequence.new(0.18)
	embers.LightEmission = 1
	embers.Color = ColorSequence.new(Color3.fromRGB(255, 170, 70))
	embers.Acceleration = Vector3.new(0, -1, 0)
	embers.Parent = holder

	-- Bancos de troncos alrededor (dejando libre el lado de la campana)
	for _, angle in { 0, math.pi / 2, math.pi } do
		local offset = Vector3.new(math.cos(angle) * 8, 0.7, math.sin(angle) * 8)
		makePart({
			Name = "Bench",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(6, 1.4, 1.4),
			CFrame = CFrame.new(center + offset) * CFrame.Angles(0, -angle + math.pi / 2, 0),
			Material = Enum.Material.Wood,
			Color = WOOD,
			Parent = map,
		})
	end
end

local function buildTent(map: Instance, position: Vector3, color: Color3)
	local toCamp = Vector3.new(camp.X - position.X, 0, camp.Z - position.Z).Unit
	-- El +X local de la tienda (donde está la puerta) mira a la fogata
	local base = CFrame.new(position) * CFrame.Angles(0, math.atan2(-toCamp.Z, toCamp.X), 0)
	local length, height, halfWidth = 8, 5.5, 4
	for _, side in { -1, 1 } do
		makePart({
			Name = "Tent",
			Size = Vector3.new(length, height, halfWidth),
			CFrame = base * CFrame.new(0, height / 2, side * halfWidth / 2) * CFrame.Angles(0, if side > 0 then math.pi else 0, 0),
			Material = Enum.Material.Fabric,
			Color = color,
			Parent = map,
		}, "WedgePart")
	end
	makeProp({ Name = "TentDoor", Size = Vector3.new(0.1, height * 0.6, halfWidth * 0.7), CFrame = base * CFrame.new(length / 2 + 0.05, height * 0.3, 0), Color = Color3.fromRGB(30, 26, 22), Parent = map })
	Props.crate(map, base * CFrame.new(length / 2 + 1.5, 0, halfWidth + 1), 2)
end

local function buildPalisade(map: Instance)
	local radius = 52
	local step = 1.45 / radius
	local maxAngle = math.rad(135)
	local angle = -maxAngle
	while angle <= maxAngle do
		local height = random:NextNumber(8, 10)
		local position = camp + Vector3.new(math.sin(angle) * radius, height / 2, math.cos(angle) * radius)
		makePart({
			Name = "PalisadeLog",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(height, 1.5, 1.5),
			CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Material = Enum.Material.Wood,
			Color = Props.vary(DARK_WOOD, 0.12, random),
			Parent = map,
		})
		angle += step
	end
	for degrees = -120, 120, 40 do
		local direction = Vector3.new(math.sin(math.rad(degrees)), 0, math.cos(math.rad(degrees)))
		Props.lantern(map, camp + direction * (radius - 3))
	end
end

-- Personaje de bloques. `extras` agrega sombrero, delantal, barba, etc.
local function buildNpc(parent: Instance, info, cframe: CFrame)
	local model = Instance.new("Model")
	model.Name = info.Name

	local function piece(name: string, size: Vector3, offset: Vector3, color: Color3, material: Enum.Material?): BasePart
		return makePart({ Name = name, Size = size, CFrame = cframe * CFrame.new(offset), Color = color, Material = material or Enum.Material.SmoothPlastic, CanCollide = false, Parent = model })
	end

	piece("LeftLeg", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), info.Pants)
	piece("RightLeg", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), info.Pants)
	local torso = piece("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), info.Shirt)
	piece("LeftArm", Vector3.new(1, 1.5, 1), Vector3.new(-1.5, 3.25, 0), info.Shirt)
	piece("RightArm", Vector3.new(1, 1.5, 1), Vector3.new(1.5, 3.25, 0), info.Shirt)
	piece("LeftHand", Vector3.new(1, 0.5, 1), Vector3.new(-1.5, 2.25, 0), info.Skin)
	piece("RightHand", Vector3.new(1, 0.5, 1), Vector3.new(1.5, 2.25, 0), info.Skin)
	local head = piece("Head", Vector3.new(1.3, 1.3, 1.3), Vector3.new(0, 4.65, 0), info.Skin)
	for _, x in { -0.3, 0.3 } do
		piece("Eye", Vector3.new(0.22, 0.22, 0.05), Vector3.new(x, 4.75, -0.66), Color3.fromRGB(20, 20, 24))
	end
	info.Extras(piece)
	model.PrimaryPart = torso

	local tag = Instance.new("BillboardGui")
	tag.Size = UDim2.fromOffset(220, 54)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 70
	tag.LightInfluence = 0
	tag.Adornee = head
	tag.Parent = model
	for index, text in { info.Name, info.Role } do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.5, 0)
		label.Position = UDim2.fromScale(0, (index - 1) * 0.5)
		label.BackgroundTransparency = 1
		label.Font = if index == 1 then Enum.Font.GothamBlack else Enum.Font.GothamBold
		label.TextSize = if index == 1 then 22 else 16
		label.TextColor3 = if index == 1 then Color3.fromRGB(255, 215, 100) else Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.3
		label.Text = text
		label.Parent = tag
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = info.Action
	prompt.ObjectText = `{info.Name} · {info.Role}`
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Shop", info.Shop)
	prompt.Parent = torso

	model.Parent = parent
end

-- Postes y techo de tela de un puesto (en coordenadas locales del puesto)
local function buildCanopy(map: Instance, stall: CFrame, color: Color3)
	for _, corner in { Vector3.new(-4.5, 0, -3.5), Vector3.new(4.5, 0, -3.5), Vector3.new(-4.5, 0, 4.5), Vector3.new(4.5, 0, 4.5) } do
		makePart({ Name = "StallPost", Size = Vector3.new(0.6, 8.5, 0.6), CFrame = stall * CFrame.new(corner + Vector3.new(0, 4.25, 0)), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	makePart({ Name = "Canopy", Size = Vector3.new(10.5, 0.4, 9.6), CFrame = stall * CFrame.new(0, 8.6, 0.5) * CFrame.Angles(math.rad(-10), 0, 0), Material = Enum.Material.Fabric, Color = color, Parent = map })
end

local function buildArmory(map: Instance)
	local stall = facingCamp(camp + Vector3.new(-23, 0, 8))
	buildCanopy(map, stall, Color3.fromRGB(150, 50, 46))
	makePart({ Name = "Counter", Size = Vector3.new(8, 3.2, 2), CFrame = stall * CFrame.new(0, 1.6, -1.8), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	makePart({ Name = "Rack", Size = Vector3.new(9, 6.5, 0.5), CFrame = stall * CFrame.new(0, 3.6, 4), Material = Enum.Material.WoodPlanks, Color = DARK_WOOD, Parent = map })
	for row = 0, 2 do
		local y = 2 + row * 1.8
		makeProp({ Name = "RackGun", Size = Vector3.new(5, 0.45, 0.35), CFrame = stall * CFrame.new(-0.6, y, 3.6), Color = Color3.fromRGB(48, 48, 54), Material = Enum.Material.Metal, Parent = map })
		makeProp({ Name = "RackStock", Size = Vector3.new(1.6, 0.8, 0.36), CFrame = stall * CFrame.new(2.6, y - 0.2, 3.6), Color = Color3.fromRGB(150, 95, 50), Parent = map })
	end
	makeProp({ Name = "CounterGun", Size = Vector3.new(0.5, 0.4, 2.6), CFrame = stall * CFrame.new(-1.5, 3.4, -1.8) * CFrame.Angles(0, 0.4, 0), Color = Color3.fromRGB(48, 48, 54), Material = Enum.Material.Metal, Parent = map })
	Props.sign(map, stall * CFrame.new(0, 7.3, -3.6), "ARMERÍA", Color3.fromRGB(255, 215, 100))
	Props.crate(map, stall * CFrame.new(-6.5, 0, -1), 2.4)
	Props.crate(map, stall * CFrame.new(-6.3, 2.4, -1) * CFrame.Angles(0, 0.3, 0), 1.6)
	Props.barrel(map, (stall * CFrame.new(6.3, 0, 0)).Position)

	buildNpc(map, {
		Name = "Bruno",
		Role = "Armero",
		Action = "Comprar armas",
		Shop = "Armory",
		Skin = Color3.fromRGB(200, 150, 110),
		Shirt = Color3.fromRGB(90, 70, 50),
		Pants = Color3.fromRGB(50, 50, 60),
		Extras = function(piece)
			piece("Apron", Vector3.new(1.8, 2.6, 0.1), Vector3.new(0, 2.6, -0.55), Color3.fromRGB(60, 45, 35), Enum.Material.Fabric)
			piece("Cap", Vector3.new(1.4, 0.4, 1.4), Vector3.new(0, 5.45, 0), Color3.fromRGB(150, 50, 46), Enum.Material.Fabric)
			piece("CapBrim", Vector3.new(1.4, 0.15, 0.6), Vector3.new(0, 5.3, -0.9), Color3.fromRGB(150, 50, 46), Enum.Material.Fabric)
			piece("Beard", Vector3.new(1.1, 0.5, 0.15), Vector3.new(0, 4.2, -0.7), Color3.fromRGB(70, 45, 30))
		end,
	}, stall * CFrame.new(0, 0, 1.2))
end

local function buildMystic(map: Instance)
	local stall = facingCamp(camp + Vector3.new(23, 0, 8))
	buildCanopy(map, stall, Color3.fromRGB(90, 50, 130))

	local cauldron = stall * CFrame.new(0, 0, -2.6)
	makePart({ Name = "Cauldron", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 4, 4), CFrame = cauldron * CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 46), Parent = map })
	local potion = makeProp({ Name = "Potion", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 3.4, 3.4), CFrame = cauldron * CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Neon, Color = Color3.fromRGB(110, 255, 120), Parent = map })
	Props.light(potion, Color3.fromRGB(110, 255, 120), 18, 2)
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Rate = 8
	bubbles.Lifetime = NumberRange.new(1, 2)
	bubbles.Speed = NumberRange.new(1.5, 3)
	bubbles.Size = NumberSequence.new(0.3)
	bubbles.LightEmission = 1
	bubbles.Color = ColorSequence.new(Color3.fromRGB(140, 255, 140))
	bubbles.Parent = potion

	for row = 0, 1 do
		local y = 3 + row * 2
		makePart({ Name = "Shelf", Size = Vector3.new(8, 0.3, 1.4), CFrame = stall * CFrame.new(0, y, 4), Material = Enum.Material.WoodPlanks, Color = DARK_WOOD, Parent = map })
		for column = -3, 3, 1.2 do
			local color = Color3.fromHSV(random:NextNumber(0, 1), 0.7, 1)
			makeProp({ Name = "Bottle", Size = Vector3.new(0.5, 0.8, 0.5), CFrame = stall * CFrame.new(column, y + 0.55, 4), Material = Enum.Material.Neon, Color = color, Parent = map })
		end
	end
	Props.sign(map, stall * CFrame.new(0, 7.3, -3.6), "BRUJA", Color3.fromRGB(180, 140, 255))

	buildNpc(map, {
		Name = "Morgana",
		Role = "Bruja",
		Action = "Comprar poderes",
		Shop = "Mystic",
		Skin = Color3.fromRGB(150, 190, 140),
		Shirt = Color3.fromRGB(70, 40, 100),
		Pants = Color3.fromRGB(50, 30, 70),
		Extras = function(piece)
			piece("Robe", Vector3.new(2.2, 2.2, 1.2), Vector3.new(0, 1.1, 0), Color3.fromRGB(60, 34, 90), Enum.Material.Fabric)
			piece("HatBrim", Vector3.new(2.4, 0.2, 2.4), Vector3.new(0, 5.35, 0), Color3.fromRGB(30, 22, 40), Enum.Material.Fabric)
			piece("Hat", Vector3.new(1.4, 0.9, 1.4), Vector3.new(0, 5.9, 0), Color3.fromRGB(30, 22, 40), Enum.Material.Fabric)
			piece("HatTop", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0.1, 6.7, 0.1), Color3.fromRGB(30, 22, 40), Enum.Material.Fabric)
			piece("HatTip", Vector3.new(0.5, 0.7, 0.5), Vector3.new(0.3, 7.4, 0.3), Color3.fromRGB(30, 22, 40), Enum.Material.Fabric)
		end,
	}, stall * CFrame.new(0, 0, 1.2))
end

local function buildTrainer(map: Instance)
	local stall = facingCamp(camp + Vector3.new(0, 0, 26))
	buildCanopy(map, stall, Color3.fromRGB(50, 80, 130))

	-- Muñeco de entrenamiento
	local dummy = stall * CFrame.new(-4, 0, -2.5)
	makePart({ Name = "DummyPost", Size = Vector3.new(0.6, 5, 0.6), CFrame = dummy * CFrame.new(0, 2.5, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	makePart({ Name = "DummyBody", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.8, 1.8), CFrame = dummy * CFrame.new(0, 3.4, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Fabric, Color = Color3.fromRGB(200, 170, 90), Parent = map })
	makePart({ Name = "DummyHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.4, CFrame = dummy * CFrame.new(0, 5.3, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(200, 170, 90), Parent = map })

	-- Estandartes
	for _, side in { -1, 1 } do
		makePart({ Name = "BannerPole", Size = Vector3.new(0.4, 11, 0.4), CFrame = stall * CFrame.new(side * 6.5, 5.5, -3.5), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makeProp({ Name = "Banner", Size = Vector3.new(2.6, 4, 0.15), CFrame = stall * CFrame.new(side * 6.5 + side * -1.4, 8.6, -3.5), Material = Enum.Material.Fabric, Color = if side < 0 then Color3.fromRGB(150, 40, 40) else Color3.fromRGB(40, 80, 150), Parent = map })
	end
	makePart({ Name = "Table", Size = Vector3.new(4, 2.6, 2), CFrame = stall * CFrame.new(3, 1.3, -1.6), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	makeProp({ Name = "Book", Size = Vector3.new(1.4, 0.3, 1), CFrame = stall * CFrame.new(3, 2.75, -1.6) * CFrame.Angles(0, 0.3, 0), Color = Color3.fromRGB(120, 30, 30), Parent = map })
	Props.sign(map, stall * CFrame.new(0, 7.3, -3.6), "VETERANO", Color3.fromRGB(140, 200, 255))

	buildNpc(map, {
		Name = "Don Ramiro",
		Role = "Veterano",
		Action = "Entrenar (mejoras y talentos)",
		Shop = "Trainer",
		Skin = Color3.fromRGB(210, 165, 130),
		Shirt = Color3.fromRGB(110, 115, 125),
		Pants = Color3.fromRGB(60, 50, 40),
		Extras = function(piece)
			piece("ChestPlate", Vector3.new(2.1, 1.6, 1.15), Vector3.new(0, 3.3, 0), Color3.fromRGB(150, 155, 165), Enum.Material.Metal)
			piece("Helmet", Vector3.new(1.45, 0.6, 1.45), Vector3.new(0, 5.4, 0), Color3.fromRGB(150, 155, 165), Enum.Material.Metal)
			piece("Beard", Vector3.new(1.2, 0.8, 0.15), Vector3.new(0, 4.1, -0.7), Color3.fromRGB(235, 235, 235))
			piece("Belt", Vector3.new(2.05, 0.3, 1.05), Vector3.new(0, 2.15, 0), Color3.fromRGB(60, 40, 25))
		end,
	}, stall * CFrame.new(0, 0, 1.2))
end

function CampBuilder.build(map: Instance)
	buildCampfire(map)
	buildArmory(map)
	buildMystic(map)
	buildTrainer(map)
	buildPalisade(map)

	local tentColors = { Color3.fromRGB(196, 178, 140), Color3.fromRGB(120, 130, 90), Color3.fromRGB(150, 110, 80), Color3.fromRGB(196, 178, 140) }
	for index, offset in { Vector3.new(-36, 0, -12), Vector3.new(36, 0, -12), Vector3.new(-34, 0, 26), Vector3.new(34, 0, 26) } do
		buildTent(map, camp + offset, tentColors[index])
	end
	for _, offset in { Vector3.new(-12, 0, -14), Vector3.new(12, 0, -14), Vector3.new(-14, 0, 18), Vector3.new(14, 0, 18) } do
		Props.lantern(map, camp + offset)
	end
	Props.barrel(map, camp + Vector3.new(-30, 0, 8))
	Props.barrel(map, camp + Vector3.new(30, 0, 12))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CampSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 1, 6)
	spawn.CFrame = CFrame.new(camp + Vector3.new(0, 0.5, -12))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map
end

return CampBuilder
