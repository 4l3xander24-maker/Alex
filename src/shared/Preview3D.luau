-- Vista previa en 3D de cualquier artículo de las tiendas (armas, skins, minas,
-- rejas, campana, compañeros, rastros, trajes y efectos): el modelo gira solo
-- dentro de un ViewportFrame; al tocarlo se abre una vista grande que se puede
-- girar arrastrando. Solo para clientes (cada builder devuelve un Model nuevo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local _Config = require(script.Parent.Config)

local Preview3D = {}

local FOV = 35
local WHITE = Color3.new(1, 1, 1)

----------------------------------------------------------------------
-- Cómo se arma y se enmarca un modelo
----------------------------------------------------------------------

local function newPart(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = frame
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	if shape then
		part.Shape = shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

local function anchorAll(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

-- Pone un modelo en un ViewportFrame y devuelve una función que lo gira.
local function frameModel(viewport: ViewportFrame, model: Model, zoom: number?)
	anchorAll(model)
	model.Parent = viewport
	local center, size = model:GetBoundingBox()
	local extent = math.max(size.X, size.Y, size.Z)
	local distance = (extent / 2) / math.tan(math.rad(FOV / 2)) * 1.25 * (zoom or 0.72)
	local camera = Instance.new("Camera")
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(Vector3.new(0, extent * 0.18, distance), Vector3.zero)
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	local original = model:GetPivot()
	local offset = CFrame.new(-center.Position)
	return function(yaw: number, pitch: number?)
		model:PivotTo(CFrame.Angles(pitch or 0, yaw, 0) * offset * original)
	end
end

local function newViewport(parent: GuiObject): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(150, 150, 160)
	viewport.LightColor = Color3.fromRGB(255, 244, 228)
	viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
	viewport.ZIndex = 3
	viewport.Parent = parent
	return viewport
end

----------------------------------------------------------------------
-- Modelos
----------------------------------------------------------------------

-- Arma: la malla de la tienda de ReplicatedStorage.WeaponModels. skin = skin de arma.
function Preview3D.weapon(weaponId: string, skin: any?): Model
	local model = Instance.new("Model")
	local folder = ReplicatedStorage:FindFirstChild("WeaponModels")
	local source = folder and folder:FindFirstChild(weaponId)
	if source and source:IsA("Model") then
		local clone = source:Clone()
		for _, part in clone:GetDescendants() do
			if part:IsA("BasePart") and skin then
				if part:IsA("MeshPart") then
					part.TextureID = ""
				end
				part.Color = skin.Main:Lerp(skin.Accent, 0.45)
				if skin.Glow then
					part.Material = Enum.Material.Neon
				end
			end
		end
		clone.Parent = model
	else
		newPart(model, "Body", Vector3.new(0.5, 0.7, 3.2), CFrame.new(), Color3.fromRGB(70, 70, 76), Enum.Material.Metal)
		newPart(model, "Grip", Vector3.new(0.4, 1, 0.5), CFrame.new(0, -0.7, 0.9), Color3.fromRGB(110, 70, 40), Enum.Material.Wood)
	end
	return model
end

-- Mina (igual que la real): base, domo, púas y luz
function Preview3D.mine(skin: any?, level: number?): Model
	local model = Instance.new("Model")
	local lvl = level or 1
	local body = if skin then skin.Main else Color3.fromRGB(46, 50, 44)
	local dome = if skin then skin.Main:Lerp(WHITE, 0.15) else Color3.fromRGB(70, 76, 66)
	local spike = if skin then skin.Accent else Color3.fromRGB(120, 124, 128)
	local light = if skin then (skin.Light or skin.Accent) else Color3.fromRGB(255, 60, 50)
	local neon = skin ~= nil and skin.Premium == true
	newPart(model, "Plate", Vector3.new(0.5, 2.8, 2.8), CFrame.Angles(0, 0, math.pi / 2), body, if neon then Enum.Material.Neon else Enum.Material.Metal, Enum.PartType.Cylinder)
	newPart(model, "Dome", Vector3.new(1.6, 0.9, 1.6), CFrame.new(0, 0.35, 0), dome, if neon then Enum.Material.Neon else Enum.Material.Metal, Enum.PartType.Ball)
	for index = 1, 6 + lvl * 2 do
		local angle = index / (6 + lvl * 2) * math.pi * 2
		newPart(model, "Spike", Vector3.new(0.18, 0.7, 0.18), CFrame.new(math.cos(angle) * 1.2, 0.5, math.sin(angle) * 1.2) * CFrame.Angles(math.sin(angle) * 0.4, 0, -math.cos(angle) * 0.4), spike, Enum.Material.Metal)
	end
	newPart(model, "Light", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.85, 0), light, Enum.Material.Neon)
	return model
end

-- Reja: dos torres, dintel y rastrillo
function Preview3D.gate(skin: any?): Model
	local model = Instance.new("Model")
	local stone = if skin then skin.Main else Color3.fromRGB(120, 124, 122)
	local iron = if skin then skin.Accent else Color3.fromRGB(60, 62, 68)
	local glass = skin ~= nil and skin.Premium == true
	local towerMaterial = if glass then Enum.Material.Glass else Enum.Material.Slate
	for _, side in { -1, 1 } do
		newPart(model, "Tower", Vector3.new(3, 15, 3), CFrame.new(side * 9, 7.5, 0), stone, towerMaterial)
		newPart(model, "Merlon", Vector3.new(3, 1.4, 1.4), CFrame.new(side * 9, 15.7, 0), stone, towerMaterial)
	end
	newPart(model, "Lintel", Vector3.new(21, 4, 3), CFrame.new(0, 13, 0), stone, towerMaterial)
	for index = 0, 12 do
		newPart(model, "Bar", Vector3.new(0.3, 11, 0.3), CFrame.new(-6 + index, 5.5, 0), iron, if glass then Enum.Material.Neon else Enum.Material.Metal)
	end
	for _, y in { 2, 5, 8 } do
		newPart(model, "Rail", Vector3.new(13, 0.3, 0.3), CFrame.new(0, y, 0), iron, if glass then Enum.Material.Neon else Enum.Material.Metal)
	end
	if skin and skin.Fire then
		for _, x in { -4, 0, 4 } do
			newPart(model, "Flame", Vector3.new(1.6, 3, 1.6), CFrame.new(x, 3, 0.2), Color3.fromRGB(255, 140, 40), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	return model
end

-- Campana: travesaño con la campana colgando
function Preview3D.bell(skin: any?): Model
	local model = Instance.new("Model")
	local body = if skin then skin.Main else Color3.fromRGB(150, 104, 52)
	local trim = if skin then skin.Accent else Color3.fromRGB(214, 170, 80)
	local neon = skin ~= nil and skin.Premium == true
	local material = if neon then Enum.Material.Neon else Enum.Material.Metal
	newPart(model, "Beam", Vector3.new(7, 0.6, 0.6), CFrame.new(0, 5, 0), Color3.fromRGB(96, 62, 38), Enum.Material.Wood)
	for _, x in { -3, 3 } do
		newPart(model, "Post", Vector3.new(0.7, 6, 0.7), CFrame.new(x, 2.4, 0), Color3.fromRGB(96, 62, 38), Enum.Material.Wood)
	end
	newPart(model, "Crown", Vector3.new(0.5, 0.9, 0.9), CFrame.new(0, 4.2, 0) * CFrame.Angles(0, 0, math.pi / 2), body, material, Enum.PartType.Cylinder)
	newPart(model, "Dome", Vector3.new(2.3, 2.3, 2.3), CFrame.new(0, 3.4, 0), body, material, Enum.PartType.Ball)
	newPart(model, "Body", Vector3.new(2.2, 3.2, 3.2), CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, math.pi / 2), body, material, Enum.PartType.Cylinder)
	newPart(model, "Rim", Vector3.new(0.3, 4.1, 4.1), CFrame.new(0, 0.8, 0) * CFrame.Angles(0, 0, math.pi / 2), trim, Enum.Material.Metal, Enum.PartType.Cylinder)
	newPart(model, "Clapper", Vector3.new(0.9, 0.9, 0.9), CFrame.new(0, 0.5, 0), Color3.fromRGB(90, 50, 30), Enum.Material.Metal, Enum.PartType.Ball)
	if skin and skin.Fire then
		for _, x in { -1.2, 0, 1.2 } do
			newPart(model, "Flame", Vector3.new(0.9, 1.8, 0.9), CFrame.new(x, 5.7, 0), Color3.fromRGB(255, 140, 40), Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	return model
end

-- Rastro de balas: una línea brillante con destellos
function Preview3D.tracer(skin: any): Model
	local model = Instance.new("Model")
	local width = if skin.Premium then 0.5 else 0.25
	newPart(model, "Streak", Vector3.new(width, width, 9), CFrame.new(), skin.Main, Enum.Material.Neon)
	if skin.Premium then
		newPart(model, "Core", Vector3.new(0.18, 0.18, 9), CFrame.new(), skin.Accent, Enum.Material.Neon)
		for index = 1, 6 do
			newPart(model, "Spark", Vector3.one * 0.35, CFrame.new((index % 2 - 0.5) * 1.1, ((index * 7) % 5 - 2) * 0.3, -4 + index * 1.4), skin.Accent, Enum.Material.Neon, Enum.PartType.Ball)
		end
	end
	newPart(model, "Tip", Vector3.one * (width * 2), CFrame.new(0, 0, -4.6), skin.Accent, Enum.Material.Neon, Enum.PartType.Ball)
	return model
end

-- Fogata: troncos cruzados y llamas del color de la skin
function Preview3D.campfire(skin: any): Model
	local model = Instance.new("Model")
	for _, yaw in { 0.4, -0.4 + math.pi / 2 } do
		newPart(model, "Log", Vector3.new(4, 0.8, 0.8), CFrame.new(0, 0.4, 0) * CFrame.Angles(0, yaw, 0.15), Color3.fromRGB(86, 58, 36), Enum.Material.Wood, Enum.PartType.Cylinder)
	end
	for index, layer in { { 1.6, 1.4, skin.Main }, { 1.2, 1.2, skin.Main:Lerp(skin.Accent, 0.4) }, { 0.8, 1.0, skin.Accent:Lerp(skin.Main, 0.3) }, { 0.4, 0.8, skin.Accent } } do
		newPart(model, "Flame", Vector3.new(layer[1], layer[2], layer[1]), CFrame.new(0, 0.9 + index * 0.9, 0), layer[3], Enum.Material.Neon, Enum.PartType.Ball)
	end
	return model
end

-- Efecto al morir un zombi: un estallido de cubos
function Preview3D.deathFx(skin: any): Model
	local model = Instance.new("Model")
	model:SetAttribute("Burst", true)
	local colors = skin.Colors or { skin.Main, skin.Accent }
	local rng = Random.new(7)
	local material = if skin.Premium then Enum.Material.Neon else Enum.Material.SmoothPlastic
	local core = newPart(model, "Core", Vector3.one * 1.4, CFrame.new(), skin.Accent, Enum.Material.Neon, Enum.PartType.Ball)
	core:SetAttribute("Core", true)
	if skin.Column then
		newPart(model, "Column", Vector3.new(0.9, 9, 0.9), CFrame.new(), skin.Main, Enum.Material.Neon):SetAttribute("Column", true)
	end
	for index = 1, 34 do
		local direction = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1)).Unit
		local size = rng:NextNumber(0.35, if skin.Big then 1.3 else 0.8)
		local bit = newPart(model, "Bit", Vector3.one * size, CFrame.new(direction * 2), colors[(index - 1) % #colors + 1], material)
		bit:SetAttribute("Dir", direction * rng:NextNumber(2.2, 4.2))
		bit:SetAttribute("Rise", (skin.Rise or 10) / 10 * rng:NextNumber(0.6, 1.4))
		bit:SetAttribute("Spin", rng:NextNumber(-6, 6))
		bit:SetAttribute("Size", size)
	end
	return model
end

-- Reproduce en bucle el estallido de un efecto de muerte (las partículas no se
-- ven en un ViewportFrame, así que se mueven los cubos a mano)
local function animateBurst(model: Model, t: number)
	local cycle = (t % 2.4) / 2.4
	local out = 1 - (1 - math.min(cycle * 2.2, 1)) ^ 2
	local fade = math.clamp((cycle - 0.55) / 0.45, 0, 1)
	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		if part:GetAttribute("Core") then
			part.Size = Vector3.one * 1.4 * math.max(1 - cycle * 2, 0.01)
		elseif part:GetAttribute("Column") then
			local flash = math.clamp(1 - cycle * 3, 0, 1)
			part.Transparency = 1 - flash
			part.Size = Vector3.new(0.9 * flash + 0.01, 9, 0.9 * flash + 0.01)
		else
			local dir = part:GetAttribute("Dir")
			local rise = part:GetAttribute("Rise")
			local size = part:GetAttribute("Size")
			part.Position = dir * out + Vector3.new(0, rise * cycle * 2.2, 0)
			part.Orientation = Vector3.new(part:GetAttribute("Spin") * cycle * 60, part:GetAttribute("Spin") * cycle * 90, 0)
			part.Transparency = fade
			part.Size = Vector3.one * size * (1 - fade * 0.5)
		end
	end
end

-- Traje: tu personaje con la capa, hombreras y sombrero de la skin
function Preview3D.outfit(skin: any): Model
	local model = Instance.new("Model")
	local character = Players.LocalPlayer.Character
	if character then
		local wasArchivable = character.Archivable
		character.Archivable = true
		local clone = character:Clone()
		character.Archivable = wasArchivable
		if clone then
			for _, child in clone:GetDescendants() do
				if child:IsA("Script") or child:IsA("LocalScript") or child.Name == "Skin" then
					child:Destroy()
				end
			end
			clone.Parent = model
		end
	end
	local anchor = model:FindFirstChild("HumanoidRootPart", true) :: BasePart?
	local origin = if anchor then anchor.CFrame else CFrame.new()
	local material = if skin.Glow then Enum.Material.Neon else Enum.Material.Fabric
	newPart(model, "Cape", Vector3.new(2.4, 3.6, 0.2), origin * CFrame.new(0, 0.4, 0.7) * CFrame.Angles(-0.1, 0, 0), skin.Cape, material)
	newPart(model, "CapeTrim", Vector3.new(2.4, 0.3, 0.25), origin * CFrame.new(0, -1.3, 0.78), skin.Trim, Enum.Material.Metal)
	if skin.Armor then
		for _, side in { -1, 1 } do
			newPart(model, "Shoulder", Vector3.new(1.3, 0.6, 1.3), origin * CFrame.new(side * 1.5, 1.7, 0), skin.Trim, Enum.Material.Metal)
		end
	end
	local headTop = origin * CFrame.new(0, 2.7, 0)
	if skin.Hat == "Crown" then
		newPart(model, "Crown", Vector3.new(1.5, 0.5, 1.5), headTop, skin.Trim, Enum.Material.Metal)
		for index = 0, 4 do
			local angle = index / 5 * math.pi * 2
			newPart(model, "Spike", Vector3.new(0.25, 0.6, 0.25), headTop * CFrame.new(math.cos(angle) * 0.6, 0.5, math.sin(angle) * 0.6), skin.Trim, Enum.Material.Metal)
		end
	elseif skin.Hat == "Horns" then
		for _, side in { -1, 1 } do
			newPart(model, "Horn", Vector3.new(0.3, 1, 0.3), headTop * CFrame.new(side * 0.6, 0.3, 0) * CFrame.Angles(0, 0, side * -0.5), skin.Trim, Enum.Material.Neon)
		end
	elseif skin.Hat == "Helmet" then
		newPart(model, "Helmet", Vector3.new(1.6, 0.9, 1.6), headTop * CFrame.new(0, -0.15, 0), skin.Trim, Enum.Material.Metal)
		newPart(model, "Crest", Vector3.new(0.2, 0.5, 1.5), headTop * CFrame.new(0, 0.5, 0), skin.Cape, Enum.Material.Fabric)
	elseif skin.Hat == "Hood" then
		newPart(model, "Hood", Vector3.new(1.7, 1.5, 1.7), headTop * CFrame.new(0, -0.1, 0.15), skin.Cape, Enum.Material.Fabric)
	elseif skin.Hat == "Brim" then
		newPart(model, "Brim", Vector3.new(2.6, 0.15, 2.6), headTop, skin.Cape, Enum.Material.Fabric)
		newPart(model, "HatTop", Vector3.new(1.4, 0.8, 1.4), headTop * CFrame.new(0, 0.45, 0), skin.Cape, Enum.Material.Fabric)
	end
	return model
end

----------------------------------------------------------------------
-- Interfaz
----------------------------------------------------------------------

-- Vista chica que gira sola. builder crea un Model nuevo cada vez.
function Preview3D.attach(parent: GuiObject, builder: () -> Model, zoom: number?): ViewportFrame
	local viewport = newViewport(parent)
	local ok, model = pcall(builder)
	if not ok then
		warn(`Vista 3D: {model}`)
		viewport:Destroy()
		return newViewport(parent)
	end
	local burst = (model :: Model):GetAttribute("Burst") == true
	local rotate = frameModel(viewport, model :: Model, if burst then (zoom or 0.72) * 1.7 else zoom)
	if burst then
		rotate(0)
	end
	local started = os.clock() + math.random()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not viewport.Parent or not viewport:IsDescendantOf(game) then
			connection:Disconnect()
			return
		end
		-- Solo gira si se ve (las filas fuera de la ventana no gastan)
		if viewport.AbsoluteSize.Y > 0 then
			if burst then
				animateBurst(model :: Model, os.clock() - started)
			else
				rotate((os.clock() - started) * 0.9)
			end
		end
	end)
	return viewport
end

local bigGui: ScreenGui? = nil

-- Vista grande: se gira arrastrando y se cierra con el botón o tocando afuera
function Preview3D.openBig(title: string, subtitle: string, builder: () -> Model)
	if bigGui then
		bigGui:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Preview3D"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 40
	gui.IgnoreGuiInset = true
	bigGui = gui

	local shade = Instance.new("TextButton")
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.45
	shade.Text = ""
	shade.AutoButtonColor = false
	shade.Modal = true
	shade.Parent = gui

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(460, 440)
	panel.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 100)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = panel
	local scale = Instance.new("UIScale")
	scale.Scale = math.min(1, workspace.CurrentCamera.ViewportSize.X / 520, workspace.CurrentCamera.ViewportSize.Y / 500)
	scale.Parent = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.fromOffset(18, 10)
	titleLabel.Size = UDim2.new(1, -90, 0, 28)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextSize = 22
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 100)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.Parent = panel
	local subLabel = titleLabel:Clone()
	subLabel.Position = UDim2.fromOffset(18, 38)
	subLabel.Size = UDim2.new(1, -36, 0, 20)
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextSize = 14
	subLabel.TextColor3 = Color3.fromRGB(200, 205, 215)
	subLabel.Text = subtitle
	subLabel.Parent = panel

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 10)
	close.Size = UDim2.fromOffset(46, 36)
	close.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 18
	close.TextColor3 = WHITE
	close.Text = "X"
	close.Modal = true
	close.Parent = panel
	local closeCorner = corner:Clone()
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = close

	local stage = Instance.new("Frame")
	stage.Position = UDim2.fromOffset(14, 66)
	stage.Size = UDim2.new(1, -28, 1, -110)
	stage.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
	stage.Parent = panel
	local stageCorner = corner:Clone()
	stageCorner.CornerRadius = UDim.new(0, 10)
	stageCorner.Parent = stage
	local hint = Instance.new("TextLabel")
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -8)
	hint.Size = UDim2.new(1, -20, 0, 24)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 13
	hint.TextColor3 = Color3.fromRGB(170, 175, 190)
	hint.Text = "Arrastra para girarlo"
	hint.Parent = panel

	local viewport = newViewport(stage)
	local ok, model = pcall(builder)
	if not ok then
		gui:Destroy()
		return
	end
	local burst = (model :: Model):GetAttribute("Burst") == true
	local rotate = frameModel(viewport, model :: Model, if burst then 1.2 else 0.7)
	if burst then
		hint.Text = "Así se verá al eliminar un zombi"
		rotate(0)
	end
	local started = os.clock()
	local yaw, pitch = 0.6, 0.15
	local dragging = false
	local auto = true
	local connections: { RBXScriptConnection } = {}
	table.insert(connections, stage.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			auto = false
		end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			yaw += input.Delta.X * 0.012
			pitch = math.clamp(pitch + input.Delta.Y * 0.008, -0.7, 0.7)
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(connections, RunService.RenderStepped:Connect(function(dt)
		if auto then
			yaw += dt * 0.7
		end
		if burst then
			animateBurst(model :: Model, os.clock() - started)
		else
			rotate(yaw, pitch)
		end
	end))
	local function closeIt()
		for _, connection in connections do
			connection:Disconnect()
		end
		gui:Destroy()
		if bigGui == gui then
			bigGui = nil
		end
	end
	close.Activated:Connect(closeIt)
	shade.Activated:Connect(closeIt)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

return Preview3D
