-- Iconos blancos de línea para los botones del celular (al estilo de Call of
-- Duty Mobile): bala, recargar, cambiar de arma, mirilla, correr y esquivar.
-- Están dibujados con cuadros y esquinas redondas, así no necesitan imágenes
-- y se ven nítidos en cualquier pantalla.
local HudIcons = {}

local WHITE = Color3.new(1, 1, 1)

-- Cuadro `w` x `h` (fracciones del tamaño) centrado en (x, y), girado `degrees`
local function bar(parent: Frame, size: number, x: number, y: number, w: number, h: number, degrees: number?, round: boolean?, color: Color3?): Frame
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

-- Aro (solo el borde) de `diameter` con grosor `thickness`
local function ring(parent: Frame, size: number, x: number, y: number, diameter: number, thickness: number): Frame
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
	stroke.Color = WHITE
	stroke.Thickness = thickness * size
	stroke.Parent = frame
	return frame
end

-- Punta de flecha en (tipX, tipY) apuntando hacia `direction` (grados en pantalla, 0 = derecha)
local function arrowHead(parent: Frame, size: number, tipX: number, tipY: number, direction: number, length: number, thickness: number)
	for _, side in { 135, 225 } do
		local angle = math.rad(direction + side)
		local centerX = tipX + math.cos(angle) * length / 2
		local centerY = tipY + math.sin(angle) * length / 2
		bar(parent, size, centerX, centerY, length, thickness, direction + side, true)
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

-- Bala de fusil apuntando arriba (botón de disparar)
function HudIcons.fire(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	-- Punta redondeada, cuerpo, aro de la vaina y base
	bar(icon, size, 0.5, 0.3, 0.26, 0.34, 0, true)
	bar(icon, size, 0.5, 0.5, 0.26, 0.26)
	bar(icon, size, 0.5, 0.66, 0.36, 0.07)
	bar(icon, size, 0.5, 0.78, 0.3, 0.15, 0, false)
	-- Ranura de la vaina (se ve el hueco entre cuerpo y base)
	bar(icon, size, 0.5, 0.715, 0.4, 0.025, 0, false, Color3.fromRGB(20, 24, 30))
	return icon
end

-- Flecha circular (recargar)
function HudIcons.reload(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	local circle = ring(icon, size, 0.5, 0.52, 0.6, 0.085)
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
	arrowHead(icon, size, 0.5 + math.cos(angle) * 0.3, 0.52 - math.sin(angle) * 0.3, 25, 0.2, 0.085)
	return icon
end

-- Dos flechas que se cruzan (cambiar de arma)
function HudIcons.swap(button: GuiObject, size: number): Frame
	local icon = holder(button, size)
	bar(icon, size, 0.46, 0.36, 0.52, 0.085, 0, true)
	arrowHead(icon, size, 0.8, 0.36, 0, 0.2, 0.085)
	bar(icon, size, 0.54, 0.64, 0.52, 0.085, 0, true)
	arrowHead(icon, size, 0.2, 0.64, 180, 0.2, 0.085)
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
	bar(icon, size, 0.5, 0.5, 0.1, 0.1, 0, true)
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

-- Estilo de botón: círculo oscuro semitransparente con borde blanco fino
function HudIcons.styleButton(button: GuiObject, strokeThickness: number?)
	button.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	button.BackgroundTransparency = 0.42
	local stroke = button:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	stroke.Color = WHITE
	stroke.Transparency = 0.25
	stroke.Thickness = strokeThickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button
end

return HudIcons
