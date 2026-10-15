-- Elegir dificultad al reconstruir la campana. Solo se ven las que tienes
-- abiertas y la siguiente con candado (al empezar: Fácil y Normal con candado).
-- Al superar las oleadas de una dificultad se abre la que sigue.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local GOLD = Color3.fromRGB(255, 215, 100)
local DARK = Color3.fromRGB(22, 24, 30)
local CARD = Color3.fromRGB(38, 40, 50)
local GREY = Color3.fromRGB(90, 92, 100)

local DifficultyUi = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local list: Frame

local function corner(parent: Instance, radius: number)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = parent
end

local function label(props: { [string]: any }): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		(text :: any)[key] = value
	end
	return text
end

local function close()
	gui.Enabled = false
end

local function card(index: number, info, locked: boolean, previous)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 78)
	frame.BackgroundColor3 = CARD
	frame.LayoutOrder = index
	frame.Parent = list
	corner(frame, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = if locked then GREY else info.Color
	stroke.Thickness = 2
	stroke.Parent = frame

	local badge = Instance.new("TextLabel")
	badge.Position = UDim2.fromOffset(10, 11)
	badge.Size = UDim2.fromOffset(56, 56)
	badge.BackgroundColor3 = if locked then Color3.fromRGB(60, 62, 70) else info.Color
	badge.BackgroundTransparency = if locked then 0 else 0.15
	badge.Font = Enum.Font.GothamBlack
	badge.TextSize = 30
	badge.Text = if locked then "🔒" else info.Icon
	badge.TextColor3 = Color3.new(1, 1, 1)
	badge.Parent = frame
	corner(badge, 10)

	label({ Position = UDim2.fromOffset(78, 10), Size = UDim2.new(1, -230, 0, 26), Text = info.Name, TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = if locked then Color3.fromRGB(150, 150, 160) else info.Color, Parent = frame })
	local description = if locked
		then `Supera {previous.Name}: llega a la oleada {previous.Goal}`
		else info.Description .. (if info.Coins > 1 then `  ·  Premios x{info.Coins}` else "")
	label({ Position = UDim2.fromOffset(78, 38), Size = UDim2.new(1, -230, 0, 34), Text = description, TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(200, 200, 210), Parent = frame })

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(120, 42)
	button.BackgroundColor3 = if locked then GREY else info.Color
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 17
	button.TextColor3 = if locked then Color3.fromRGB(190, 190, 200) else Color3.fromRGB(16, 20, 30)
	button.Text = if locked then "Bloqueada" else "¡Jugar!"
	button.AutoButtonColor = not locked
	button.Modal = true
	button.Parent = frame
	corner(button, 8)
	if not locked then
		button.Activated:Connect(function()
			Remotes.SelectDifficulty:FireServer(info.Id)
			close()
		end)
	end
end

local function open(unlocked: number)
	for _, child in list:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	local shown = math.min(unlocked + 1, #Config.Difficulties)
	for index = 1, shown do
		local info = Config.Difficulties[index]
		card(index, info, index > unlocked, Config.Difficulties[index - 1])
	end
	gui.Enabled = true
end

function DifficultyUi.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "Difficulty"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 14
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.new(0.92, 0, 0, 0)
	window.AutomaticSize = Enum.AutomaticSize.Y
	window.BackgroundColor3 = DARK
	window.Parent = gui
	corner(window, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(560, 640)
	limit.Parent = window
	local border = Instance.new("UIStroke")
	border.Color = GOLD
	border.Thickness = 2
	border.Parent = window
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 12)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = window
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = window

	local top = Instance.new("Frame")
	top.LayoutOrder = 0
	top.Size = UDim2.new(1, 0, 0, 38)
	top.BackgroundTransparency = 1
	top.Parent = window
	label({ Size = UDim2.new(1, -110, 1, 0), Text = "ELIGE LA DIFICULTAD", TextSize = 24, Font = Enum.Font.Arcade, TextColor3 = GOLD, Parent = top })
	local cancel = Instance.new("TextButton")
	cancel.AnchorPoint = Vector2.new(1, 0.5)
	cancel.Position = UDim2.new(1, 0, 0.5, 0)
	cancel.Size = UDim2.fromOffset(100, 34)
	cancel.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	cancel.Font = Enum.Font.GothamBlack
	cancel.TextSize = 15
	cancel.TextColor3 = Color3.new(1, 1, 1)
	cancel.Text = "Cancelar"
	-- Modal libera el mouse en primera persona mientras está abierta
	cancel.Modal = true
	cancel.Parent = top
	corner(cancel, 8)
	cancel.Activated:Connect(close)

	list = Instance.new("Frame")
	list.LayoutOrder = 1
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.BackgroundTransparency = 1
	list.Parent = window
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	Remotes.DifficultyMenu.OnClientEvent:Connect(open)
end

return DifficultyUi
