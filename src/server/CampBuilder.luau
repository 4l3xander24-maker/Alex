-- El campamento detrás de la campana, al borde del acantilado: fogata,
-- bancos, tiendas de campaña, empalizada, mirador sobre el mar y los cuatro
-- NPC (Armero, Bruja, Veterano e Intendente) con sus puestos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local ModelLibrary = require(script.Parent.ModelLibrary)
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
	if Props.voxel then
		-- Fuego de cubitos que se achican hacia arriba (WorldFx los hace bailar)
		for index, layer in { { 2.2, 1.2, FIRE_COLOR }, { 1.6, 1, Color3.fromRGB(255, 180, 70) }, { 1, 0.9, Color3.fromRGB(255, 225, 120) }, { 0.5, 0.6, Color3.fromRGB(255, 245, 190) } } do
			local flame = makeProp({ Name = "VoxelFlame", Size = Vector3.new(layer[1], layer[2], layer[1]), Position = center + Vector3.new(0, 0.7 + index * 0.9, 0), Material = Enum.Material.Neon, Color = layer[3], Parent = map })
			flame:SetAttribute("Dance", index)
		end
	else
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
	end
	Props.flickerLight(holder, FIRE_COLOR, 40, 3, true)

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

-- Cerca baja al borde del acantilado (con hueco para el mirador)
local function buildCliffFence(map: Instance, lookoutX: number)
	local z = Config.Arena.CliffZ - 3
	local posts = {}
	for x = -34, 34, 3.4 do
		if math.abs(x - lookoutX) > 3 then
			makePart({ Name = "FencePost", Size = Vector3.new(0.5, 3, 0.5), Position = Vector3.new(x, 1.5, z), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
			table.insert(posts, x)
		end
	end
	for index = 1, #posts - 1 do
		local a, b = posts[index], posts[index + 1]
		if b - a < 4 then
			for _, y in { 1.2, 2.5 } do
				makePart({ Name = "FenceRail", Size = Vector3.new(b - a, 0.3, 0.25), Position = Vector3.new((a + b) / 2, y, z), Material = Enum.Material.Wood, Color = WOOD, Parent = map })
			end
		end
	end
end

-- Mirador de madera que sobresale del acantilado, con un catalejo
local function buildLookout(map: Instance, x: number)
	local cliffZ = Config.Arena.CliffZ
	local length, width = 12, 6
	local centerZ = cliffZ - 3 + length / 2
	makePart({ Name = "LookoutDeck", Size = Vector3.new(width, 0.5, length), Position = Vector3.new(x, 0, centerZ), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	for _, side in { -1, 1 } do
		makePart({ Name = "LookoutRail", Size = Vector3.new(0.3, 0.3, length - 3), Position = Vector3.new(x + side * (width / 2 - 0.15), 2.4, centerZ + 1.5), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "LookoutBeam", Size = Vector3.new(0.6, 0.6, 14), CFrame = CFrame.new(x + side * 2, -5, cliffZ + 1) * CFrame.Angles(math.rad(-40), 0, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		for postZ = cliffZ, cliffZ + length - 3, 3 do
			makePart({ Name = "LookoutPost", Size = Vector3.new(0.4, 2.6, 0.4), Position = Vector3.new(x + side * (width / 2 - 0.15), 1.3, postZ), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		end
	end
	makePart({ Name = "LookoutRail", Size = Vector3.new(width, 0.3, 0.3), Position = Vector3.new(x, 2.4, centerZ + length / 2 - 0.15), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })

	-- Catalejo sobre un trípode apuntando al mar
	local spot = Vector3.new(x, 0.25, centerZ + length / 2 - 2)
	for index = 1, 3 do
		local angle = index / 3 * math.pi * 2
		makeProp({ Name = "Tripod", Size = Vector3.new(0.15, 2.6, 0.15), CFrame = CFrame.new(spot + Vector3.new(math.cos(angle) * 0.5, 1.2, math.sin(angle) * 0.5)) * CFrame.Angles(math.sin(angle) * 0.25, 0, -math.cos(angle) * 0.25), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	makeProp({ Name = "Telescope", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 0.45, 0.45), CFrame = CFrame.new(spot + Vector3.new(0, 2.6, 0.3)) * CFrame.Angles(0, math.pi / 2, math.rad(12)), Material = Enum.Material.Metal, Color = Color3.fromRGB(205, 165, 70), Parent = map })
	Props.lantern(map, Vector3.new(x - width / 2 - 1, 0, cliffZ - 4))
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

	-- Estilo realista: personaje de malla de la tienda (src/models/Npc<Tienda>)
	-- en lugar del muñeco de bloques, que queda invisible (lo usan el aviso de
	-- E y el cartel). Se para en `cframe` mirando hacia adelante, de 5.6 de alto.
	local mesh = ModelLibrary.clone(`Npc{info.Shop}`)
	local meshParts: { [string]: BasePart } = {}
	if mesh then
		local low, torsoPart = math.huge, nil
		local high = -math.huge
		for _, descendant in mesh:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				if descendant.Transparency < 1 then
					low = math.min(low, descendant.Position.Y - descendant.Size.Y / 2)
					high = math.max(high, descendant.Position.Y + descendant.Size.Y / 2)
				end
				if descendant.Parent == mesh or not descendant.Parent:IsA("Accessory") then
					meshParts[descendant.Name] = descendant
				end
			end
		end
		torsoPart = meshParts.UpperTorso or meshParts.Torso
		if torsoPart and high > low then
			local look = torsoPart.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z).Unit
			local base = Vector3.new(torsoPart.Position.X, low, torsoPart.Position.Z)
			mesh.WorldPivot = CFrame.lookAt(base, base + flat)
			mesh:ScaleTo(5.6 / (high - low))
			mesh:PivotTo(cframe)
			mesh.Name = "Body"
			-- La ropa clásica (Shirt/Pants) solo se dibuja con un Humanoid: uno
			-- quieto, sin física ni nombre encima
			local clothing = mesh:FindFirstChildWhichIsA("Shirt", true) or mesh:FindFirstChildWhichIsA("Pants", true)
			if clothing and clothing.Parent and not clothing.Parent:FindFirstChildOfClass("Humanoid") then
				local humanoid = Instance.new("Humanoid")
				humanoid.RigType = Enum.HumanoidRigType.R15
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
				humanoid.EvaluateStateMachine = false
				humanoid.RequiresNeck = false
				humanoid.BreakJointsOnDeath = false
				humanoid.Parent = clothing.Parent
			end
			mesh.Parent = model
			for _, part in model:GetChildren() do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
		else
			mesh:Destroy()
			mesh = nil
		end
	end

	-- Trabajo: la herramienta va en la mano derecha y cada cliente mueve los
	-- brazos (NpcWork). Todo gira sobre la línea de los hombros.
	local work = info.Work
	if work then
		local tagged = {}
		local pivot = (cframe * CFrame.new(0, 4, 0)).Position
		local tools = work.Tool(piece)
		if mesh then
			local names = { "RightUpperArm", "RightLowerArm", "RightHand" }
			if work.Kind == "lift" then
				table.move({ "LeftUpperArm", "LeftLowerArm", "LeftHand" }, 1, 3, #names + 1, names)
			end
			for _, name in names do
				table.insert(tagged, meshParts[name])
			end
			-- Hombros de la malla, y la herramienta movida a su mano
			local shoulder = meshParts.RightUpperArm
			if shoulder then
				local top = shoulder.Position + Vector3.new(0, shoulder.Size.Y / 2, 0)
				pivot = Vector3.new(cframe.Position.X, top.Y, cframe.Position.Z)
			end
			local hand = meshParts.RightHand
			local blockHand = (cframe * CFrame.new(1.5, 2.25, 0)).Position
			local delta = if hand then hand.Position - blockHand else Vector3.zero
			if work.Kind == "lift" and meshParts.LeftHand and hand then
				delta = (hand.Position + meshParts.LeftHand.Position) / 2 - (cframe * CFrame.new(0, 2.25, 0)).Position
			end
			for _, part in tools do
				part.CFrame += delta
				part.Transparency = 0
			end
		else
			local moving = { "RightArm", "RightHand" }
			if work.Kind == "lift" then
				table.insert(moving, "LeftArm")
				table.insert(moving, "LeftHand")
			end
			for _, name in moving do
				table.insert(tagged, model:FindFirstChild(name))
			end
		end
		for _, part in tools do
			table.insert(tagged, part)
		end
		local seed = random:NextNumber(0, 10) -- igual para todo el NPC: brazo y herramienta juntos
		for _, part in tagged do
			if part then
				part:SetAttribute("Work", work.Kind)
				part:SetAttribute("WorkPivot", pivot)
				part:SetAttribute("WorkAxis", cframe.RightVector)
				part:SetAttribute("WorkSeed", seed)
			end
		end
	end
	model.PrimaryPart = torso
	-- Si se subió su sprite pixelado, AssetService lo muestra en lugar del muñeco
	local spriteKeys = { Armory = "Armero", Mystic = "Bruja", Trainer = "Veterano", Quartermaster = "Intendente" }
	model:SetAttribute("SpriteKey", spriteKeys[info.Shop])

	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
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
	local upright = CFrame.Angles(0, 0, math.pi / 2)
	-- Postes redondos con pie de piedra
	for _, corner in { Vector3.new(-4.5, 0, -3.5), Vector3.new(4.5, 0, -3.5), Vector3.new(-4.5, 0, 4.5), Vector3.new(4.5, 0, 4.5) } do
		makePart({ Name = "StallPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8.5, 0.7, 0.7), CFrame = stall * CFrame.new(corner + Vector3.new(0, 4.25, 0)) * upright, Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makeProp({ Name = "PostFoot", Size = Vector3.new(1.1, 0.6, 1.1), CFrame = stall * CFrame.new(corner + Vector3.new(0, 0.3, 0)), Material = Enum.Material.Slate, Color = Props.Colors.Stone, Parent = map })
	end
	-- Vigas del techo
	for _, z in { -3.5, 4.5 } do
		makeProp({ Name = "StallBeam", Size = Vector3.new(9.8, 0.45, 0.45), CFrame = stall * CFrame.new(0, 8.3 - (z + 3.5) * 0.17, z), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	-- Toldo a rayas: franjas del color de la tienda y crema
	local tilt = CFrame.Angles(math.rad(-10), 0, 0)
	local stripes = 7
	for index = 0, stripes - 1 do
		local x = -5.25 + (index + 0.5) * 10.5 / stripes
		makePart({ Name = "Canopy", Size = Vector3.new(10.5 / stripes, 0.3, 9.6), CFrame = stall * CFrame.new(0, 8.6, 0.5) * tilt * CFrame.new(x, 0, 0), Material = Enum.Material.Fabric, Color = if index % 2 == 0 then color else Color3.fromRGB(232, 222, 196), Parent = map })
	end
	-- Faldón con picos colgando adelante
	for index = 0, 9 do
		local x = -4.75 + index * 1.05
		makeProp({ Name = "Valance", Size = Vector3.new(0.75, 0.75, 0.12), CFrame = stall * CFrame.new(0, 8.6, 0.5) * tilt * CFrame.new(x, -0.45, -4.85) * CFrame.Angles(0, 0, math.rad(45)), Material = Enum.Material.Fabric, Color = if index % 2 == 0 then color else Color3.fromRGB(232, 222, 196), Parent = map })
	end
end

-- Mostrador de tablas con tapa más ancha y marcos de madera oscura
local function buildCounter(map: Instance, stall: CFrame)
	makePart({ Name = "Counter", Size = Vector3.new(8, 3, 2), CFrame = stall * CFrame.new(0, 1.5, -1.8), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	makePart({ Name = "CounterTop", Size = Vector3.new(8.6, 0.3, 2.6), CFrame = stall * CFrame.new(0, 3.15, -1.85), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	for _, x in { -3.9, 0, 3.9 } do
		makeProp({ Name = "CounterFrame", Size = Vector3.new(0.35, 3, 0.2), CFrame = stall * CFrame.new(x, 1.5, -2.85), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	makeProp({ Name = "CounterKick", Size = Vector3.new(8.1, 0.4, 0.2), CFrame = stall * CFrame.new(0, 0.2, -2.85), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
end

local function buildArmory(map: Instance)
	local stall = facingCamp(camp + Vector3.new(-23, 0, 8))
	buildCanopy(map, stall, Color3.fromRGB(150, 50, 46))
	buildCounter(map, stall)
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

	-- Bruno trabaja afuera del puesto: martilla en el yunque junto a la fragua
	local smith = stall * CFrame.new(-1.5, 0, -6)
	local anvil = smith * CFrame.new(1.5, 0, -2.4)
	makePart({ Name = "AnvilBase", Size = Vector3.new(1.1, 1.5, 1.1), CFrame = anvil * CFrame.new(0, 0.75, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(45, 45, 50), Parent = map })
	local anvilTop = makePart({ Name = "AnvilTop", Size = Vector3.new(1.2, 0.6, 2.4), CFrame = anvil * CFrame.new(0, 1.8, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 66), Parent = map })
	local hot = makeProp({ Name = "HotIron", Size = Vector3.new(0.3, 0.2, 1.2), CFrame = anvil * CFrame.new(0, 2.2, -0.2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 40), Parent = map })
	Props.light(hot, Color3.fromRGB(255, 140, 60), 8, 1)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Rate = 10
	sparks.Lifetime = NumberRange.new(0.2, 0.5)
	sparks.Speed = NumberRange.new(4, 9)
	sparks.SpreadAngle = Vector2.new(70, 70)
	sparks.Acceleration = Vector3.new(0, -25, 0)
	sparks.Size = NumberSequence.new(0.12)
	sparks.LightEmission = 1
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 90, 30))
	sparks.Parent = anvilTop
	-- Fragua de piedra con brasas
	local forge = smith * CFrame.new(4.2, 0, -1)
	makePart({ Name = "Forge", Size = Vector3.new(2.6, 2.4, 2.6), CFrame = forge * CFrame.new(0, 1.2, 0), Material = Enum.Material.Cobblestone, Color = Props.Colors.Stone, Parent = map })
	local coals = makeProp({ Name = "Coals", Size = Vector3.new(1.9, 0.3, 1.9), CFrame = forge * CFrame.new(0, 2.5, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 90, 30), Parent = map })
	Props.light(coals, Color3.fromRGB(255, 120, 50), 14, 1.6)
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate = 4
	smoke.Lifetime = NumberRange.new(2, 3)
	smoke.Speed = NumberRange.new(2, 3)
	smoke.Size = NumberSequence.new(0.8, 2.4)
	smoke.Transparency = NumberSequence.new(0.6, 1)
	smoke.Color = ColorSequence.new(Color3.fromRGB(90, 90, 90))
	smoke.Parent = coals

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
		Work = {
			Kind = "hammer",
			Tool = function(piece)
				return {
					piece("HammerHandle", Vector3.new(0.22, 0.22, 1.6), Vector3.new(1.5, 2.15, -0.8), Color3.fromRGB(110, 75, 45), Enum.Material.Wood),
					piece("HammerHead", Vector3.new(0.5, 0.5, 0.9), Vector3.new(1.5, 2.15, -1.7) , Color3.fromRGB(70, 70, 78), Enum.Material.Metal),
				}
			end,
		},
	}, smith)
end

-- La Bruja vive en la aldea (su propia isla), mirando al puente de madera
local function buildMystic(map: Instance)
	local info = Config.Arena.MysticStall
	local stall = CFrame.lookAt(info.Position, info.LookAt)
	buildCanopy(map, stall, Color3.fromRGB(90, 50, 130))

	-- Morgana revuelve el caldero afuera del puesto
	local witch = stall * CFrame.new(-1.5, 0, -4.4)
	local cauldron = witch * CFrame.new(1.5, 0, -2.6)
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
		Work = {
			Kind = "stir",
			Tool = function(piece)
				return { piece("Ladle", Vector3.new(0.22, 3.2, 0.22), Vector3.new(1.5, 0.8, 0), Color3.fromRGB(90, 60, 40), Enum.Material.Wood) }
			end,
		},
	}, witch)
end

local function buildQuartermaster(map: Instance)
	local stall = facingCamp(camp + Vector3.new(-22, 0, -14))
	buildCanopy(map, stall, Color3.fromRGB(90, 100, 60))
	buildCounter(map, stall)

	-- Cajas de munición apiladas y minas sobre el mostrador
	local ammoColor = Color3.fromRGB(80, 90, 55)
	for index, offset in { Vector3.new(-3, 0, 3.4), Vector3.new(-1, 0, 3.4), Vector3.new(1, 0, 3.4), Vector3.new(3, 0, 3.4), Vector3.new(-2, 1.4, 3.4), Vector3.new(0, 1.4, 3.4), Vector3.new(2, 1.4, 3.4), Vector3.new(-1, 2.8, 3.4), Vector3.new(1, 2.8, 3.4) } do
		makePart({ Name = "AmmoBox", Size = Vector3.new(1.8, 1.3, 1.2), CFrame = stall * CFrame.new(offset + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, (index % 3 - 1) * 0.08, 0), Material = Enum.Material.Metal, Color = ammoColor, Parent = map })
		makeProp({ Name = "AmmoStripe", Size = Vector3.new(1.82, 0.2, 1.22), CFrame = stall * CFrame.new(offset + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, (index % 3 - 1) * 0.08, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(230, 190, 60), Parent = map })
	end
	for index = -1, 1 do
		makeProp({ Name = "DisplayMine", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.35, 1.4, 1.4), CFrame = stall * CFrame.new(index * 2, 3.38, -1.8) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 54, 46), Parent = map })
	end
	-- Un trozo de reja de muestra
	for index = 0, 4 do
		makeProp({ Name = "SampleBar", Size = Vector3.new(0.18, 3, 0.18), CFrame = stall * CFrame.new(5.6, 1.5, -1 + index * 0.7), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 62, 68), Parent = map })
	end
	Props.sign(map, stall * CFrame.new(0, 7.3, -3.6), "INTENDENCIA", Color3.fromRGB(200, 230, 120))

	-- Gustavo acomoda cajas de munición afuera del puesto
	local quartermaster = stall * CFrame.new(1.5, 0, -6)
	Props.crate(map, quartermaster * CFrame.new(-2.8, 0, -1.4), 1.8)
	Props.crate(map, quartermaster * CFrame.new(-2.7, 1.8, -1.3) * CFrame.Angles(0, 0.25, 0), 1.4)
	Props.crate(map, quartermaster * CFrame.new(2.8, 0, -0.8) * CFrame.Angles(0, -0.2, 0), 1.8)

	buildNpc(map, {
		Name = "Gustavo",
		Role = "Intendente",
		Action = "Munición y trampas",
		Shop = "Quartermaster",
		Skin = Color3.fromRGB(170, 120, 85),
		Shirt = Color3.fromRGB(85, 95, 55),
		Pants = Color3.fromRGB(60, 65, 45),
		Extras = function(piece)
			piece("Beret", Vector3.new(1.45, 0.35, 1.45), Vector3.new(0, 5.45, 0.05), Color3.fromRGB(60, 70, 40), Enum.Material.Fabric)
			piece("Bandolier", Vector3.new(0.4, 2.6, 0.12), Vector3.new(0, 3, -0.56), Color3.fromRGB(110, 80, 40), Enum.Material.Fabric)
			piece("Mustache", Vector3.new(0.9, 0.2, 0.1), Vector3.new(0, 4.35, -0.68), Color3.fromRGB(50, 35, 25))
			piece("Goggles", Vector3.new(1.35, 0.25, 0.1), Vector3.new(0, 4.78, -0.69), Color3.fromRGB(30, 30, 30))
		end,
		Work = {
			Kind = "lift",
			Tool = function(piece)
				return {
					piece("CarryBox", Vector3.new(2.4, 1.3, 1.4), Vector3.new(0, 2.3, -1), Color3.fromRGB(80, 90, 55), Enum.Material.Metal),
					piece("CarryStripe", Vector3.new(2.42, 0.2, 1.42), Vector3.new(0, 2.5, -1), Color3.fromRGB(230, 190, 60)),
				}
			end,
		},
	}, quartermaster)
end

local function buildTrainer(map: Instance)
	local stall = facingCamp(camp + Vector3.new(0, 0, 26))
	buildCanopy(map, stall, Color3.fromRGB(50, 80, 130))

	-- Don Ramiro entrena afuera del puesto: le pega con la espada al muñeco
	local veteran = stall * CFrame.new(-2, 0, -5)
	local dummy = veteran * CFrame.new(1.2, 0, -3.4)
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
		Work = {
			Kind = "swing",
			Tool = function(piece)
				return {
					piece("SwordGrip", Vector3.new(0.25, 0.25, 0.7), Vector3.new(1.5, 2.15, -0.35), Color3.fromRGB(70, 45, 30), Enum.Material.Wood),
					piece("SwordGuard", Vector3.new(0.9, 0.2, 0.2), Vector3.new(1.5, 2.15, -0.75), Color3.fromRGB(180, 150, 70), Enum.Material.Metal),
					piece("SwordBlade", Vector3.new(0.15, 0.32, 3), Vector3.new(1.5, 2.15, -2.3), Color3.fromRGB(200, 205, 215), Enum.Material.Metal),
				}
			end,
		},
	}, veteran)
end

-- Refugio de madera junto a la fogata (como en Guns 'n Goblins): techo de
-- tablas inclinado, pared de piedra al fondo, troncos para sentarse, cajas y un farol
local function buildShelter(map: Instance)
	local frame = facingCamp(camp + Vector3.new(19, 0, -17))
	local width, depth, front, back = 11, 7, 6.5, 4
	for _, x in { -width / 2, width / 2 } do
		makePart({ Name = "ShelterPost", Size = Vector3.new(0.7, front, 0.7), CFrame = frame * CFrame.new(x, front / 2, -depth / 2), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
		makePart({ Name = "ShelterPost", Size = Vector3.new(0.7, back, 0.7), CFrame = frame * CFrame.new(x, back / 2, depth / 2), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	-- Techo inclinado de tablas que sobresale adelante
	local rise = front - back
	local slope = math.sqrt(depth * depth + rise * rise) + 2
	makePart({ Name = "ShelterRoof", Size = Vector3.new(width + 2, 0.5, slope), CFrame = frame * CFrame.new(0, (front + back) / 2 + 0.3, -0.6) * CFrame.Angles(math.atan2(rise, depth), 0, 0), Material = Enum.Material.WoodPlanks, Color = WOOD, Parent = map })
	for x = -width / 2, width / 2, 2.2 do
		makeProp({ Name = "RoofBeam", Size = Vector3.new(0.35, 0.35, slope), CFrame = frame * CFrame.new(x, (front + back) / 2 + 0.65, -0.6) * CFrame.Angles(math.atan2(rise, depth), 0, 0), Material = Enum.Material.Wood, Color = DARK_WOOD, Parent = map })
	end
	-- Pared de piedra al fondo, a media altura
	makePart({ Name = "ShelterWall", Size = Vector3.new(width, 3, 1.2), CFrame = frame * CFrame.new(0, 1.5, depth / 2 + 0.2), Material = Enum.Material.Slate, Color = Props.Colors.Stone, Parent = map })
	-- Troncos, cajas y una olla
	for _, spot in { Vector3.new(-3, 0, 0.5), Vector3.new(3, 0, 0.5) } do
		makePart({ Name = "LogSeat", Size = Vector3.new(2.6, 1.1, 1.1), CFrame = frame * CFrame.new(spot + Vector3.new(0, 0.55, -4.5)), Material = Enum.Material.Wood, Color = WOOD, Parent = map })
	end
	Props.crate(map, frame * CFrame.new(-4, 0, 2), 1.8)
	Props.crate(map, frame * CFrame.new(-4.2, 1.8, 2.1) * CFrame.Angles(0, 0.3, 0), 1.2)
	Props.barrel(map, (frame * CFrame.new(4, 0, 2)).Position)
	Props.hangingLantern(map, (frame * CFrame.new(-width / 2 - 1.2, 0, -depth / 2)).Position, (frame.LookVector))
end

function CampBuilder.build(map: Instance)
	buildCampfire(map)
	buildShelter(map)
	buildArmory(map)
	buildMystic(map)
	buildTrainer(map)
	buildQuartermaster(map)
	-- Sin empalizada de madera alrededor del campamento
	local lookoutX = 20
	buildCliffFence(map, lookoutX)
	buildLookout(map, lookoutX)

	local tentColors = { Color3.fromRGB(196, 178, 140), Color3.fromRGB(120, 130, 90), Color3.fromRGB(150, 110, 80), Color3.fromRGB(196, 178, 140) }
	for index, offset in { Vector3.new(-36, 0, -12), Vector3.new(36, 0, -12), Vector3.new(-34, 0, 26), Vector3.new(34, 0, 26) } do
		buildTent(map, camp + offset, tentColors[index])
	end
	for _, offset in { Vector3.new(-12, 0, -14), Vector3.new(12, 0, -14), Vector3.new(-14, 0, 18), Vector3.new(14, 0, 18) } do
		Props.lantern(map, camp + offset)
	end
	Props.barrel(map, camp + Vector3.new(-30, 0, 8))
	Props.barrel(map, camp + Vector3.new(30, 0, 12))

	-- Noche medieval: velas junto a los puestos y la fogata
	if (Config.Themes[Config.Theme] or {}).Medieval then
		for _, offset in { Vector3.new(-17, 0, 3), Vector3.new(17, 0, 3), Vector3.new(-16, 0, -19), Vector3.new(-6, 0, 21), Vector3.new(6, 0, 21), Vector3.new(-5, 0, -6), Vector3.new(5, 0, 6) } do
			Props.candles(map, camp + offset, nil, true)
		end
	end

	-- Los jugadores aparecen en el círculo de runas (MapBuilder)
end

return CampBuilder
