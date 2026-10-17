-- Ajustes: volumen de música y de efectos, y calidad gráfica (Auto, Baja, Alta).
-- Se guardan como atributos del jugador (Sfx y WorldFx los leen) y se acuerdan
-- con el perfil del jugador local en esta sesión.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local OptionsUi = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 215, 100)
local PANEL = Color3.fromRGB(24, 28, 30)

local function round(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function group(name: string): SoundGroup
	local found = SoundService:FindFirstChild(name)
	if not found then
		found = Instance.new("SoundGroup")
		found.Name = name
		found.Parent = SoundService
	end
	return found :: SoundGroup
end

-- Barra deslizable de 0 a 1
local function slider(parent: Instance, title: string, order: number, start: number, onChange: (number) -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = title
	label.Parent = row
	local back = Instance.new("TextButton")
	back.Position = UDim2.fromOffset(0, 28)
	back.Size = UDim2.new(1, 0, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(50, 56, 60)
	back.Text = ""
	back.AutoButtonColor = false
	back.Parent = row
	round(back, 7)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(start, 1)
	fill.BackgroundColor3 = GOLD
	fill.Parent = back
	round(fill, 7)
	local dragging = false
	local function set(x: number)
		local alpha = math.clamp((x - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		label.Text = `{title}: {math.floor(alpha * 100)}%`
		onChange(alpha)
	end
	label.Text = `{title}: {math.floor(start * 100)}%`
	back.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			set(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			set(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

function OptionsUi.init()
	local touch = UserInputService.TouchEnabled
	local gui = Instance.new("ScreenGui")
	gui.Name = "Options"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 11
	if touch then
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Botón del engranaje, debajo de la Tienda
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.AnchorPoint = if touch then Vector2.new(0, 0) else Vector2.new(1, 0)
	button.Position = if touch then UDim2.new(0, 74, 0, 154) else UDim2.new(1, -16, 0, 122)
	button.Size = if touch then UDim2.fromOffset(34, 30) else UDim2.fromOffset(38, 32)
	button.BackgroundColor3 = Color3.fromRGB(70, 74, 84)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "⚙"
	button.Parent = gui
	round(button, 8)

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(340, 300)
	panel.BackgroundColor3 = PANEL
	panel.Visible = false
	panel.Parent = gui
	round(panel, 14)
	local border = Instance.new("UIStroke")
	border.Color = GOLD
	border.Thickness = 2
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 22
	title.TextColor3 = GOLD
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "AJUSTES"
	title.LayoutOrder = 0
	title.Parent = panel

	slider(panel, "Música", 1, 1, function(value)
		group("MusicGroup").Volume = value
	end)
	slider(panel, "Efectos", 2, 1, function(value)
		group("SfxGroup").Volume = value
	end)

	-- Calidad gráfica
	local qualityLabel = Instance.new("TextLabel")
	qualityLabel.Size = UDim2.new(1, 0, 0, 20)
	qualityLabel.BackgroundTransparency = 1
	qualityLabel.Font = Enum.Font.GothamBold
	qualityLabel.TextSize = 15
	qualityLabel.TextColor3 = Color3.new(1, 1, 1)
	qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
	qualityLabel.Text = "Calidad gráfica"
	qualityLabel.LayoutOrder = 3
	qualityLabel.Parent = panel
	local qualityRow = Instance.new("Frame")
	qualityRow.Size = UDim2.new(1, 0, 0, 38)
	qualityRow.BackgroundTransparency = 1
	qualityRow.LayoutOrder = 4
	qualityRow.Parent = panel
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.Padding = UDim.new(0, 8)
	rowLayout.Parent = qualityRow
	local choices: { [string]: TextButton } = {}
	local function mark()
		local current = player:GetAttribute("QualityMode") or "Auto"
		for key, choice in choices do
			choice.BackgroundColor3 = if key == current then GOLD else Color3.fromRGB(60, 66, 70)
			choice.TextColor3 = if key == current then Color3.fromRGB(30, 24, 10) else Color3.new(1, 1, 1)
		end
	end
	for _, option in { { "Auto", "Automática" }, { "Low", "Baja" }, { "High", "Alta" } } do
		local choice = Instance.new("TextButton")
		choice.Size = UDim2.fromOffset(94, 36)
		choice.Font = Enum.Font.GothamBlack
		choice.TextSize = 14
		choice.Text = option[2]
		choice.Parent = qualityRow
		round(choice, 8)
		choice.Activated:Connect(function()
			player:SetAttribute("QualityMode", option[1])
			mark()
		end)
		choices[option[1]] = choice
	end
	mark()

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(1, 0, 0, 40)
	close.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 16
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "Cerrar"
	close.Modal = true -- libera el mouse en primera persona
	close.LayoutOrder = 5
	close.Parent = panel
	round(close, 8)
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	button.Activated:Connect(function()
		panel.Visible = not panel.Visible
	end)
end

return OptionsUi
