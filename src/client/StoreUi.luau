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
	button.Position = UDim2.new(1, -16, 0, 104)
	button.Size = UDim2.fromOffset(130, 32)
	button.BackgroundColor3 = Color3.fromRGB(46, 140, 80)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = if UserInputService.TouchEnabled then "🛒 Tienda" else "🛒 Tienda [B]"
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
