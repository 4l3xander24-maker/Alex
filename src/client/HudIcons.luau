-- Iconos dibujados con cuadros y esquinas redondas (sin imágenes subidas, así
-- se ven nítidos en cualquier pantalla): botones de línea blanca al estilo de
-- Call of Duty Mobile (disparar, recargar, cambiar de arma, saltar, mirilla,
-- correr, esquivar) e iconos de color para vida, XP, monedas y poderes.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local HudIcons = {}

local WHITE = Color3.new(1, 1, 1)
local DARK = Color3.fromRGB(18, 22, 28)

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
-- Botones de línea blanca
----------------------------------------------------------------------

-- Bala de fusil apuntando arriba, con punta plateada y vaina dorada
function HudIcons.fire(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	local brass = Color3.fromRGB(255, 205, 90)
	local brassDark = Color3.fromRGB(214, 150, 50)
	-- Punta redondeada, cuerpo de la vaina, ranura y base con borde
	bar(icon, size, 0.5, 0.24, 0.24, 0.3, 0, true, Color3.fromRGB(235, 240, 248))
	bar(icon, size, 0.5, 0.41, 0.24, 0.12, 0, false, Color3.fromRGB(235, 240, 248))
	bar(icon, size, 0.5, 0.53, 0.24, 0.16, 0, false, brass)
	bar(icon, size, 0.5, 0.63, 0.24, 0.035, 0, false, DARK)
	bar(icon, size, 0.5, 0.74, 0.3, 0.2, 0, false, brass)
	bar(icon, size, 0.5, 0.855, 0.36, 0.06, 0, false, brassDark)
	bar(icon, size, 0.5, 0.74, 0.1, 0.1, 0, true, brassDark)
	-- Brillo
	bar(icon, size, 0.44, 0.28, 0.035, 0.18, 0, true, WHITE)
	return icon
end

-- Flecha circular (recargar)
function HudIcons.reload(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	local circle = ring(icon, size, 0.5, 0.52, 0.6, 0.09)
	-- Abre un hueco arriba a la derecha: el trazo se desvanece en esa esquina
	local stroke = circle:FindFirstChildOfClass("UIStroke") :: UIStroke
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 135
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.62, 0),
		NumberSequenceKeypoint.new(0.64, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = stroke
	local angle = math.rad(70)
	arrowHead(icon, size, 0.5 + math.cos(angle) * 0.3, 0.52 - math.sin(angle) * 0.3, 25, 0.22, 0.09)
	return icon
end

-- Dos flechas que se cruzan (cambiar de arma)
function HudIcons.swap(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	bar(icon, size, 0.46, 0.36, 0.52, 0.09, 0, true)
	arrowHead(icon, size, 0.8, 0.36, 0, 0.22, 0.09)
	bar(icon, size, 0.54, 0.64, 0.52, 0.09, 0, true)
	arrowHead(icon, size, 0.2, 0.64, 180, 0.22, 0.09)
	return icon
end

-- Dos flechas hacia arriba (saltar)
function HudIcons.jump(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	arrowHead(icon, size, 0.5, 0.24, 270, 0.4, 0.1)
	arrowHead(icon, size, 0.5, 0.52, 270, 0.4, 0.1)
	bar(icon, size, 0.5, 0.7, 0.1, 0.2, 0, true)
	return icon
end

-- Mirilla de francotirador (apuntar)
function HudIcons.scope(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	ring(icon, size, 0.5, 0.5, 0.56, 0.07)
	bar(icon, size, 0.5, 0.13, 0.07, 0.22)
	bar(icon, size, 0.5, 0.87, 0.07, 0.22)
	bar(icon, size, 0.13, 0.5, 0.22, 0.07)
	bar(icon, size, 0.87, 0.5, 0.22, 0.07)
	disc(icon, size, 0.5, 0.5, 0.1, WHITE)
	return icon
end

-- Dos flechas hacia adelante (correr)
function HudIcons.sprint(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	arrowHead(icon, size, 0.52, 0.5, 0, 0.34, 0.1)
	arrowHead(icon, size, 0.8, 0.5, 0, 0.34, 0.1)
	return icon
end

-- Líneas de velocidad (esquivar)
function HudIcons.dash(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	bar(icon, size, 0.46, 0.3, 0.5, 0.08, 0, true)
	bar(icon, size, 0.56, 0.5, 0.6, 0.08, 0, true)
	bar(icon, size, 0.42, 0.7, 0.4, 0.08, 0, true)
	arrowHead(icon, size, 0.9, 0.5, 0, 0.22, 0.08)
	return icon
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

-- Círculo de cristal oscuro con borde blanco fino y un aro interior
function HudIcons.styleButton(button: GuiObject, strokeThickness: number?)
	button.BackgroundColor3 = DARK
	button.BackgroundTransparency = 0.38
	local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Transparency = 0.2
	stroke.Thickness = strokeThickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
	-- Luz suave desde arriba
	local gloss = Instance.new("UIGradient")
	gloss.Rotation = 90
	gloss.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
	gloss.Parent = button
	-- Aro interior
	local inner = Instance.new("Frame")
	inner.Name = "InnerRing"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.fromScale(0.5, 0.5)
	inner.Size = UDim2.new(1, -12, 1, -12)
	inner.BackgroundTransparency = 1
	inner.ZIndex = 1
	inner.Parent = button
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = inner
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = WHITE
	innerStroke.Transparency = 0.82
	innerStroke.Thickness = 1
	innerStroke.Parent = inner
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

-- Joystick: cuatro flechitas en la base
function HudIcons.dpad(base: GuiObject, size: number)
	local icon = holder(base, size)
	arrowHead(icon, size, 0.5, 0.1, 270, 0.16, 0.05)
	arrowHead(icon, size, 0.5, 0.9, 90, 0.16, 0.05)
	arrowHead(icon, size, 0.1, 0.5, 180, 0.16, 0.05)
	arrowHead(icon, size, 0.9, 0.5, 0, 0.16, 0.05)
	for _, child in icon:GetChildren() do
		if child:IsA("Frame") then
			child.BackgroundTransparency = 0.45
		end
	end
end

return HudIcons
