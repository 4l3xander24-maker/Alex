-- Menú de "¡Subiste de nivel!": 3 tarjetas para elegir una mejora.
-- Se elige con clic/toque o con las teclas 1, 2 y 3. El juego no se pausa.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local player = Players.LocalPlayer

local CARD_COLOR = Color3.fromRGB(28, 34, 36)
local CARD_BORDER = Color3.fromRGB(255, 210, 90)
local KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three }

local UpgradeMenu = {}

local gui: ScreenGui
local title: TextLabel
local cardHolder: Frame
local currentOptions: { any }? = nil

local function makeLabel(props): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextWrapped = true
	for key, value in props do
		label[key] = value
	end
	return label
end

local function hide()
	currentOptions = nil
	gui.Enabled = false
	for _, child in cardHolder:GetChildren() do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end
end

local function choose(index: number)
	local options = currentOptions
	if not options or not options[index] then
		return
	end
	Remotes.ChooseUpgrade:FireServer(options[index].Id)
	hide()
end

local function buildCard(index: number, option)
	local card = Instance.new("TextButton")
	card.LayoutOrder = index
	card.Size = UDim2.fromOffset(190, 230)
	card.BackgroundColor3 = CARD_COLOR
	card.BackgroundTransparency = 0.1
	card.Text = ""
	card.AutoButtonColor = true
	-- Modal libera el mouse en primera persona mientras el menú está abierto
	card.Modal = true
	card.Parent = cardHolder

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = CARD_BORDER
	stroke.Thickness = 2
	stroke.Parent = card

	makeLabel({ Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 60), Text = option.Icon, TextSize = 50, Parent = card })
	makeLabel({ Position = UDim2.fromOffset(10, 80), Size = UDim2.new(1, -20, 0, 44), Text = option.Name, TextSize = 19, Font = Enum.Font.GothamBlack, Parent = card })
	makeLabel({ Position = UDim2.fromOffset(12, 126), Size = UDim2.new(1, -24, 0, 60), Text = option.Description, TextSize = 14, TextColor3 = Color3.fromRGB(210, 220, 215), Parent = card })
	local footer = if UserInputService.TouchEnabled then "" else `[{index}]   `
	makeLabel({ Position = UDim2.new(0, 0, 1, -34), Size = UDim2.new(1, 0, 0, 24), Text = `{footer}Nv {option.Stacks}/{option.MaxStacks}`, TextSize = 13, TextColor3 = CARD_BORDER, Parent = card })

	card.Activated:Connect(function()
		choose(index)
	end)
end

local function show(level: number, options: { any })
	hide()
	currentOptions = options
	title.Text = `¡NIVEL {level}! Elige una mejora`
	for index, option in options do
		buildCard(index, option)
	end
	gui.Enabled = true
end

function UpgradeMenu.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "UpgradeMenu"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Enabled = false

	title = makeLabel({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -150),
		Size = UDim2.fromOffset(600, 40),
		TextSize = 30,
		Font = Enum.Font.GothamBlack,
		TextColor3 = CARD_BORDER,
		TextStrokeTransparency = 0.3,
		Parent = gui,
	})

	cardHolder = Instance.new("Frame")
	cardHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	cardHolder.Position = UDim2.new(0.5, 0, 0.5, 10)
	cardHolder.Size = UDim2.fromOffset(620, 230)
	cardHolder.BackgroundTransparency = 1
	cardHolder.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = cardHolder

	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.LevelUpOffer.OnClientEvent:Connect(function(level, options)
		if options then
			show(level, options)
		else
			hide()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not currentOptions then
			return
		end
		local index = table.find(KEYS, input.KeyCode)
		if index then
			choose(index)
		end
	end)
end

return UpgradeMenu
