-- Iconos dibujados con cuadros y esquinas redondas (sin imágenes subidas, así
-- se ven nítidos en cualquier pantalla): botones de línea blanca al estilo de
-- Call of Duty Mobile (disparar, recargar, cambiar de arma, saltar, mirilla,
-- correr, esquivar) e iconos de color para vida, XP, monedas y poderes.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HudIcons = {}

local WHITE = Color3.new(1, 1, 1)


-- Cuadro `w` x `h` (fracciones del tamaño) centrado en (x, y), girado `degrees`
local function bar(parent: Instance, size: number, x: number, y: number, w: number, h: number, degrees: number?, round: boolean?, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(x * size, y * size)
	frame.Size = UDim2.fromOffset(w * size, h * size)
	frame.Rotation = degrees or 0
	frame.BackgroundColor3 = color or WHITE
	frame.BorderSizePixel = 0
	frame.Parent = parent
	if round then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
	end
	return frame
end

-- Círculo lleno de `diameter` (fracción del tamaño)
local function disc(parent: Instance, size: number, x: number, y: number, diameter: number, color: Color3): Frame
	return bar(parent, size, x, y, diameter, diameter, 0, true, color)
end

-- Aro (solo el borde) de `diameter` con grosor `thickness`
local function ring(parent: Instance, size: number, x: number, y: number, diameter: number, thickness: number, color: Color3?): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(x * size, y * size)
	frame.Size = UDim2.fromOffset(diameter * size, diameter * size)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or WHITE
	stroke.Thickness = thickness * size
	stroke.Parent = frame
	return frame
end

-- Punta de flecha en (tipX, tipY) apuntando hacia `direction` (grados en pantalla, 0 = derecha)
local function arrowHead(parent: Instance, size: number, tipX: number, tipY: number, direction: number, length: number, thickness: number, color: Color3?)
	for _, side in { 135, 225 } do
		local angle = math.rad(direction + side)
		local centerX = tipX + math.cos(angle) * length / 2
		local centerY = tipY + math.sin(angle) * length / 2
		bar(parent, size, centerX, centerY, length, thickness, direction + side, true, color)
	end
end

-- Contenedor cuadrado centrado en el botón
local function holder(button: GuiObject, size: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = "Icon"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 2
	frame.Parent = button
	return frame
end

----------------------------------------------------------------------
-- Iconos blancos de la hoja (assets/hud_icons.png, hecha con
-- assets/make_icons.py): 4 columnas de 128 px
----------------------------------------------------------------------

local SHEET = "rbxassetid://127873720461078"
local CELL = 128
local CELLS = { Bullet = 0, Jump = 1, Reload = 2, Swap = 3, Scope = 4, Sprint = 5, Dash = 6, Crouch = 7 }

local function glyph(button: GuiObject, name: string, size: number): ImageLabel
	local index = CELLS[name]
	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromOffset(size, size)
	image.BackgroundTransparency = 1
	image.Image = SHEET
	image.ImageRectSize = Vector2.new(CELL, CELL)
	image.ImageRectOffset = Vector2.new((index % 4) * CELL, (index // 4) * CELL)
	image.ImageColor3 = WHITE
	image.ImageTransparency = 0.04
	image.ZIndex = 2
	image.Parent = button
	return image
end

-- Disparar: disco grande con un aro fino por dentro y la bala inclinada
function HudIcons.fire(button: GuiObject, size: number): ImageLabel
	local innerRing = Instance.new("Frame")
	innerRing.Name = "InnerRing"
	innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
	innerRing.Position = UDim2.fromScale(0.5, 0.5)
	innerRing.Size = UDim2.fromScale(0.74, 0.74)
	innerRing.BackgroundTransparency = 1
	innerRing.Parent = button
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = innerRing
	local stroke = Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Transparency = 0.55
	stroke.Thickness = 1.5
	stroke.Parent = innerRing
	return glyph(button, "Bullet", size)
end

function HudIcons.reload(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Reload", size)
end

function HudIcons.swap(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Swap", size)
end

function HudIcons.jump(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Jump", size)
end

function HudIcons.scope(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Scope", size)
end

function HudIcons.sprint(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Sprint", size)
end

function HudIcons.dash(button: GuiObject, size: number): ImageLabel
	return glyph(button, "Dash", size)
end

----------------------------------------------------------------------
-- Iconos de color
----------------------------------------------------------------------

-- Corazón (vida)
function HudIcons.heart(parent: GuiObject, size: number): Frame
	local icon = holder(parent, size)
	local red = Color3.fromRGB(240, 70, 85)
	disc(icon, size, 0.34, 0.36, 0.38, red)
	disc(icon, size, 0.66, 0.36, 0.38, red)
	bar(icon, size, 0.5, 0.56, 0.4, 0.4, 45, false, red)
	disc(icon, size, 0.3, 0.3, 0.1, Color3.fromRGB(255, 170, 175))
	return icon
end

-- Destello de cuatro puntas con diamante al centro (XP)
function HudIcons.star(parent: GuiObject, size: number, color: Color3?): Frame
	local icon = holder(parent, size)
	local tint = color or Color3.fromRGB(120, 210, 255)
	bar(icon, size, 0.5, 0.5, 0.18, 0.92, 0, true, tint)
	bar(icon, size, 0.5, 0.5, 0.92, 0.18, 0, true, tint)
	bar(icon, size, 0.5, 0.5, 0.16, 0.6, 45, true, tint)
	bar(icon, size, 0.5, 0.5, 0.16, 0.6, -45, true, tint)
	disc(icon, size, 0.5, 0.5, 0.2, WHITE)
	return icon
end

-- Moneda dorada
function HudIcons.coin(parent: GuiObject, size: number): Frame
	local icon = holder(parent, size)
	disc(icon, size, 0.5, 0.5, 0.92, Color3.fromRGB(214, 150, 40))
	disc(icon, size, 0.5, 0.5, 0.8, Color3.fromRGB(255, 208, 70))
	ring(icon, size, 0.5, 0.5, 0.56, 0.06, Color3.fromRGB(214, 150, 40))
	bar(icon, size, 0.5, 0.5, 0.08, 0.3, 0, true, Color3.fromRGB(214, 150, 40))
	disc(icon, size, 0.3, 0.3, 0.1, Color3.fromRGB(255, 245, 190))
	return icon
end

-- Granada
local function grenade(icon: Frame, size: number)
	disc(icon, size, 0.5, 0.6, 0.62, Color3.fromRGB(96, 138, 84))
	disc(icon, size, 0.38, 0.5, 0.14, Color3.fromRGB(150, 190, 130))
	bar(icon, size, 0.5, 0.26, 0.22, 0.14, 0, false, Color3.fromRGB(170, 170, 178))
	bar(icon, size, 0.66, 0.2, 0.34, 0.07, -25, true, Color3.fromRGB(200, 200, 208))
	ring(icon, size, 0.3, 0.22, 0.2, 0.05, Color3.fromRGB(230, 200, 90))
	bar(icon, size, 0.5, 0.6, 0.6, 0.035, 0, false, Color3.fromRGB(70, 100, 62))
end

-- Rayo (cadena eléctrica)
local function bolt(icon: Frame, size: number)
	local yellow = Color3.fromRGB(255, 226, 90)
	bar(icon, size, 0.56, 0.28, 0.5, 0.16, -60, true, yellow)
	bar(icon, size, 0.46, 0.52, 0.42, 0.14, 0, true, yellow)
	bar(icon, size, 0.42, 0.74, 0.5, 0.16, -60, true, yellow)
	arrowHead(icon, size, 0.3, 0.92, 120, 0.2, 0.12, yellow)
end

-- Campana
local function bell(icon: Frame, size: number)
	local gold = Color3.fromRGB(240, 190, 70)
	bar(icon, size, 0.5, 0.42, 0.56, 0.56, 0, true, gold)
	bar(icon, size, 0.5, 0.64, 0.56, 0.3, 0, false, gold)
	bar(icon, size, 0.5, 0.78, 0.72, 0.1, 0, true, Color3.fromRGB(214, 150, 40))
	disc(icon, size, 0.5, 0.9, 0.16, Color3.fromRGB(120, 80, 30))
	disc(icon, size, 0.5, 0.12, 0.1, Color3.fromRGB(214, 150, 40))
	bar(icon, size, 0.38, 0.4, 0.06, 0.26, 12, true, Color3.fromRGB(255, 235, 170))
end

-- Dibuja el ícono del poder; false si no hay dibujo (queda su emoji)
function HudIcons.power(name: string, parent: GuiObject, size: number): boolean
	local drawers = { Grenade = grenade, Chain = bolt, Bell = bell }
	local draw = drawers[name]
	if not draw then
		return false
	end
	draw(holder(parent, size), size)
	return true
end

----------------------------------------------------------------------
-- Estilo de botones
----------------------------------------------------------------------

-- Disco translúcido oscuro con un borde casi invisible (como Call of Duty Mobile)
function HudIcons.styleButton(button: GuiObject, strokeThickness: number?)
	button.BackgroundColor3 = Color3.fromRGB(26, 28, 32)
	button.BackgroundTransparency = 0.42
	local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Transparency = 0.72
	stroke.Thickness = strokeThickness or 1.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
end

-- El botón se encoge un poco mientras lo tocas
function HudIcons.bindPress(button: GuiObject)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local function set(value: number)
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = value }):Play()
	end
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			set(0.9)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			set(1)
		end
	end)
end

-- Para saber si hace falta (pantalla táctil)
function HudIcons.isTouch(): boolean
	return UserInputService.TouchEnabled
end

return HudIcons
