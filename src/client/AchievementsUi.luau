-- Pantalla de logros (Config.Achievements): botón "Logros" junto a la Tienda y
-- una lista con el progreso de cada uno, su premio y cuáles ya conseguiste.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Profile = require(script.Parent.Profile)

local GOLD = Color3.fromRGB(255, 215, 100)
local GREEN = Color3.fromRGB(110, 220, 120)
local PANEL = Color3.fromRGB(24, 28, 30)
local ROW = Color3.fromRGB(34, 40, 42)

local AchievementsUi = {}

local player = Players.LocalPlayer
local panel: Frame
local list: ScrollingFrame
local summary: TextLabel

local function round(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function label(parent: Instance, props): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextXAlignment = Enum.TextXAlignment.Left
	for key, value in props do
		(text :: any)[key] = value
	end
	text.Parent = parent
	return text
end

-- Cuánto llevas de cada medida (las de una sola partida no se guardan: nil)
local function progressOf(stat: string): number?
	local data = Profile.get()
	if stat == "Kills" then
		return data.TotalKills
	elseif stat == "Wave" then
		return data.BestWave
	elseif stat == "Level" then
		return data.Level
	end
	return nil
end

local function render()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local data = Profile.get()
	local done = 0
	for index, achievement in Config.Achievements do
		local unlocked = data.Achievements[achievement.Id] == true
		if unlocked then
			done += 1
		end
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 64)
		row.BackgroundColor3 = ROW
		row.LayoutOrder = index
		row.Parent = list
		round(row, 10)
		if unlocked then
			local stroke = Instance.new("UIStroke")
			stroke.Color = GREEN
			stroke.Thickness = 1.5
			stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			stroke.Parent = row
		end
		label(row, { Position = UDim2.fromOffset(8, 0), Size = UDim2.fromOffset(46, 64), Text = achievement.Icon, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = if unlocked then 0 else 0.5 })
		label(row, { Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -190, 0, 20), Text = achievement.Name, TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = if unlocked then GREEN else Color3.new(1, 1, 1) })
		label(row, { Position = UDim2.fromOffset(60, 28), Size = UDim2.new(1, -190, 0, 16), Text = achievement.Description, TextSize = 12, TextColor3 = Color3.fromRGB(190, 200, 195) })
		local progress = progressOf(achievement.Stat)
		-- Barra de progreso
		local back = Instance.new("Frame")
		back.Position = UDim2.fromOffset(60, 48)
		back.Size = UDim2.new(1, -190, 0, 6)
		back.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
		back.Parent = row
		round(back, 3)
		local ratio = if unlocked then 1 elseif progress then math.clamp(progress / achievement.Goal, 0, 1) else 0
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = if unlocked then GREEN else GOLD
		fill.Parent = back
		round(fill, 3)
		local status = if unlocked then "¡Conseguido!" elseif progress then `{math.min(progress, achievement.Goal)} / {achievement.Goal}` else "En una partida"
		label(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 12), Size = UDim2.fromOffset(110, 20), Text = status, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = if unlocked then GREEN else Color3.new(1, 1, 1) })
		label(row, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 34), Size = UDim2.fromOffset(110, 20), Text = `💰 {achievement.Reward}`, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = GOLD })
	end
	summary.Text = `{done} de {#Config.Achievements} logros`
end

function AchievementsUi.toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
	end
end

function AchievementsUi.init()
	local touch = UserInputService.TouchEnabled
	local gui = Instance.new("ScreenGui")
	gui.Name = "Achievements"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 11
	if touch then
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Botón a la izquierda de la Tienda
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = if touch then UDim2.new(1, -132, 0, 76) else UDim2.new(1, -154, 0, 84)
	button.Size = if touch then UDim2.fromOffset(96, 30) else UDim2.fromOffset(120, 32)
	button.BackgroundColor3 = Color3.fromRGB(150, 110, 30)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = if touch then 14 else 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "🏆 Logros"
	button.Parent = gui
	round(button, 8)

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.9, 0.85)
	panel.BackgroundColor3 = PANEL
	panel.Visible = false
	panel.Parent = gui
	round(panel, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(620, 520)
	limit.Parent = panel
	local border = Instance.new("UIStroke")
	border.Color = GOLD
	border.Thickness = 2
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = panel

	label(panel, { Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -90, 0, 30), Text = "🏆 LOGROS", TextSize = 24, Font = Enum.Font.GothamBlack, TextColor3 = GOLD })
	summary = label(panel, { Position = UDim2.fromOffset(18, 40), Size = UDim2.new(1, -90, 0, 20), Text = "", TextSize = 14, TextColor3 = Color3.fromRGB(190, 200, 195) })
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(52, 40)
	close.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 20
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.Modal = true -- libera el mouse en primera persona
	close.Parent = panel
	round(close, 8)
	close.Activated:Connect(function()
		panel.Visible = false
	end)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 70)
	list.Size = UDim2.new(1, -24, 1, -82)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	button.Activated:Connect(AchievementsUi.toggle)
	Profile.Changed:Connect(function()
		if panel.Visible then
			render()
		end
	end)
	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		button.Visible = not player:GetAttribute("InCinematic")
		if player:GetAttribute("InCinematic") then
			panel.Visible = false
		end
	end)
end

return AchievementsUi
