-- Tienda con Robux en la partida: botón arriba a la derecha (o tecla B) y la
-- oferta de Revivir cuando caes (con cuenta regresiva).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local RobuxShop = require(Shared.RobuxShop)

local GOLD = Color3.fromRGB(255, 215, 100)
local REVIVE = Config.Monetization.Products.Revive

local StoreUi = {}

local player = Players.LocalPlayer
local revivePanel: Frame
local reviveTimer: TextLabel
local reviveButton: TextButton
local offerId = 0

local function corner(parent: Instance, radius: number)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = parent
end

local function toggleShop()
	if RobuxShop.isOpen() then
		RobuxShop.close()
	else
		RobuxShop.open(true)
	end
end

local function showRevive(seconds: number)
	offerId += 1
	local id = offerId
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(REVIVE.Id, Enum.InfoType.Product)
	end)
	local price = if ok and info and info.PriceInRobux then ` R$ {info.PriceInRobux}` else ""
	reviveButton.Text = `💖 Revivir{price}`
	revivePanel.Visible = true
	local finish = os.clock() + seconds
	while id == offerId and os.clock() < finish do
		reviveTimer.Text = `Te quedan {math.ceil(finish - os.clock())} s para volver`
		task.wait(0.2)
	end
	if id == offerId then
		revivePanel.Visible = false
	end
end

function StoreUi.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "StoreUi"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local button = Instance.new("TextButton")
	button.Name = "ShopButton"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 84)
	button.Size = UDim2.fromOffset(130, 32)
	button.BackgroundColor3 = Color3.fromRGB(46, 140, 80)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = if UserInputService.TouchEnabled then "🛒 Tienda" else "🛒 Tienda [B]"
	if UserInputService.TouchEnabled then
		-- En celular, justo debajo de las monedas y la hora (más abajo van la
		-- munición y los botones de disparo), dentro del área segura del teléfono
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		button.Position = UDim2.new(1, -16, 0, 76)
		button.Size = UDim2.fromOffset(110, 30)
		button.TextSize = 14
	end
	button.Parent = gui
	corner(button, 8)
	button.Activated:Connect(toggleShop)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			toggleShop()
		end
	end)

	-- Oferta de revivir
	revivePanel = Instance.new("Frame")
	revivePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	revivePanel.Position = UDim2.fromScale(0.5, 0.62)
	revivePanel.Size = UDim2.fromOffset(320, 120)
	revivePanel.BackgroundColor3 = Color3.fromRGB(26, 18, 22)
	revivePanel.BackgroundTransparency = 0.1
	revivePanel.Visible = false
	revivePanel.Parent = gui
	corner(revivePanel, 12)
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 90, 110)
	border.Thickness = 2
	border.Parent = revivePanel
	reviveTimer = Instance.new("TextLabel")
	reviveTimer.Position = UDim2.fromOffset(0, 10)
	reviveTimer.Size = UDim2.new(1, 0, 0, 24)
	reviveTimer.BackgroundTransparency = 1
	reviveTimer.Font = Enum.Font.GothamBold
	reviveTimer.TextSize = 16
	reviveTimer.TextColor3 = Color3.new(1, 1, 1)
	reviveTimer.Parent = revivePanel
	reviveButton = Instance.new("TextButton")
	reviveButton.AnchorPoint = Vector2.new(0.5, 1)
	reviveButton.Position = UDim2.new(0.5, 0, 1, -14)
	reviveButton.Size = UDim2.fromOffset(240, 54)
	reviveButton.BackgroundColor3 = Color3.fromRGB(220, 60, 90)
	reviveButton.Font = Enum.Font.GothamBlack
	reviveButton.TextSize = 22
	reviveButton.TextColor3 = Color3.new(1, 1, 1)
	reviveButton.Modal = true
	reviveButton.Parent = revivePanel
	corner(reviveButton, 10)
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = reviveButton
	reviveButton.Activated:Connect(function()
		MarketplaceService:PromptProductPurchase(player, REVIVE.Id)
	end)

	-- Cayeron todos: cuenta y botón para que cualquiera pague y sigan todos
	local CONTINUE = Config.Monetization.Products.Continue
	local continuePanel = revivePanel:Clone()
	continuePanel.Name = "Continue"
	continuePanel.Size = UDim2.fromOffset(360, 140)
	continuePanel.Position = UDim2.fromScale(0.5, 0.55)
	continuePanel.Parent = gui
	local continueTimer = continuePanel:FindFirstChildOfClass("TextLabel") :: TextLabel
	continueTimer.Size = UDim2.new(1, -84, 0, 56)
	continueTimer.Position = UDim2.fromOffset(8, 8)
	-- Cuenta regresiva grande de 10 a 0
	local countdown = Instance.new("TextLabel")
	countdown.AnchorPoint = Vector2.new(1, 0)
	countdown.Position = UDim2.new(1, -14, 0, 4)
	countdown.Size = UDim2.fromOffset(64, 64)
	countdown.BackgroundColor3 = Color3.fromRGB(34, 20, 26)
	countdown.Font = Enum.Font.GothamBlack
	countdown.TextSize = 40
	countdown.TextColor3 = Color3.fromRGB(255, 215, 100)
	countdown.Text = "10"
	countdown.Parent = continuePanel
	corner(countdown, 32)
	local countStroke = Instance.new("UIStroke")
	countStroke.Color = Color3.fromRGB(255, 215, 100)
	countStroke.Thickness = 2
	countStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	countStroke.Parent = countdown
	continueTimer.TextWrapped = true
	local continueButton = continuePanel:FindFirstChildOfClass("TextButton") :: TextButton
	continueButton.AnchorPoint = Vector2.new(0, 1)
	continueButton.Position = UDim2.new(0, 16, 1, -14)
	continueButton.Size = UDim2.fromOffset(204, 54)
	continueButton.TextSize = 18
	continueButton.TextScaled = true
	local continueLimit = Instance.new("UITextSizeConstraint")
	continueLimit.MaxTextSize = 18
	continueLimit.Parent = continueButton
	continueButton.Activated:Connect(function()
		if CONTINUE.Id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, CONTINUE.Id)
		end
	end)
	-- Cancelar: no seguir (se acaba la partida cuando todos cancelan o se acaba la cuenta)
	local cancelled = false
	local continueCancel = Instance.new("TextButton")
	continueCancel.AnchorPoint = Vector2.new(1, 1)
	continueCancel.Position = UDim2.new(1, -16, 1, -14)
	continueCancel.Size = UDim2.fromOffset(110, 54)
	continueCancel.BackgroundColor3 = Color3.fromRGB(90, 92, 104)
	continueCancel.Font = Enum.Font.GothamBlack
	continueCancel.TextSize = 18
	continueCancel.TextColor3 = Color3.new(1, 1, 1)
	continueCancel.Text = "Cancelar"
	continueCancel.Modal = true
	continueCancel.Parent = continuePanel
	corner(continueCancel, 10)
	continueCancel.Activated:Connect(function()
		cancelled = true
		continuePanel.Visible = false
		Remotes.ContinueCancel:FireServer()
	end)
	local gameState = ReplicatedStorage:WaitForChild("GameState")
	local continuePrice = ""
	task.spawn(function()
		if CONTINUE.Id ~= 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(CONTINUE.Id, Enum.InfoType.Product)
			end)
			continuePrice = if ok and info and info.PriceInRobux then ` R$ {info.PriceInRobux}` else ""
		end
	end)
	-- Cámara súper lenta mientras se decide: la imagen se apaga y se enfría
	local slowGrade: ColorCorrectionEffect? = nil
	local slowOn = false
	local function setSlowmo(on: boolean)
		if on == slowOn then
			return
		end
		slowOn = on
		if not slowGrade then
			local grade = Instance.new("ColorCorrectionEffect")
			grade.Name = "SlowmoGrade"
			grade.Parent = game:GetService("Lighting")
			slowGrade = grade
		end
		local goal = if on then { Saturation = -0.55, Contrast = 0.15, Brightness = -0.08, TintColor = Color3.fromRGB(170, 195, 255) } else { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Color3.new(1, 1, 1) }
		game:GetService("TweenService"):Create(slowGrade :: ColorCorrectionEffect, TweenInfo.new(0.5), goal):Play()
	end
	task.spawn(function()
		while true do
			local endsAt = gameState:GetAttribute("ContinueEnds") or 0
			local left = endsAt - workspace:GetServerTimeNow()
			local show = left > 0 and not cancelled
			if left <= 0 then
				cancelled = false
			end
			continuePanel.Visible = show
			setSlowmo(left > 0)
			if show then
				revivePanel.Visible = false
				local team = #Players:GetPlayers() > 1
				local bell = gameState:GetAttribute("ContinueReason") == "Bell"
				local title = if bell then "🔔 ¡Cayó la campana!\n¿Revivirla y seguir?" elseif team then "💀 ¡Cayó todo tu equipo!\n¿Revivir a todos?" else "💀 ¡Caíste!\n¿Revivir y seguir?"
				continueTimer.Text = title
				countdown.Text = tostring(math.ceil(left))
				local action = if bell then "Seguir" elseif team then "Revivir a todos" else "Revivirme"
				continueButton.Text = if CONTINUE.Id == 0 then `💖 {action} (sin precio)` else `💖 {action}{continuePrice}`
			end
			task.wait(0.2)
		end
	end)

	player:GetAttributeChangedSignal("InCinematic"):Connect(function()
		button.Visible = not player:GetAttribute("InCinematic")
	end)

	Remotes.ReviveOffer.OnClientEvent:Connect(function(seconds)
		task.spawn(showRevive, seconds)
	end)
	-- Si revive (o empieza otra partida), se esconde la oferta
	player.CharacterAdded:Connect(function()
		offerId += 1
		revivePanel.Visible = false
	end)
end

return StoreUi
