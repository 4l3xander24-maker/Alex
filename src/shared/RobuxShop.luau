-- Ventana de la tienda con Robux (solo cliente). La usan el Lobby y la
-- partida: skins, pases y, dentro de la partida, bolsas de monedas.
-- Los precios los lee de Roblox; lo que no tiene id todavía sale "Pronto".
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local monetization = Config.Monetization
local GOLD = Color3.fromRGB(255, 215, 100)
local DARK = Color3.fromRGB(22, 24, 30)
local CARD = Color3.fromRGB(38, 40, 50)
local GREEN = Color3.fromRGB(60, 170, 90)
local GREY = Color3.fromRGB(90, 92, 100)

local RobuxShop = {}

local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local list: ScrollingFrame
local showCoins = false
local prices: { [string]: number } = {}

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

-- Precio en Robux (se pide una vez a Roblox)
local function priceOf(id: number, infoType: Enum.InfoType): number?
	local key = `{infoType.Name}{id}`
	if prices[key] == nil then
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		prices[key] = if ok and info and info.PriceInRobux then info.PriceInRobux else -1
	end
	return if prices[key] > 0 then prices[key] else nil
end

local function header(text: string, order: number)
	label({ Size = UDim2.new(1, 0, 0, 30), Text = text, TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, LayoutOrder = order, Parent = list })
end

-- Tarjeta: muestra (color o ícono), nombre, descripción y botón
local function card(order: number, swatch: Color3?, icon: string?, title: string, description: string, buttonText: string, buttonColor: Color3, onClick: (() -> ())?)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 74)
	frame.BackgroundColor3 = CARD
	frame.LayoutOrder = order
	frame.Parent = list
	corner(frame, 10)
	local preview = Instance.new("TextLabel")
	preview.Position = UDim2.fromOffset(10, 10)
	preview.Size = UDim2.fromOffset(54, 54)
	preview.BackgroundColor3 = swatch or Color3.fromRGB(60, 62, 74)
	preview.Text = icon or ""
	preview.TextSize = 30
	preview.Font = Enum.Font.GothamBlack
	preview.Parent = frame
	corner(preview, 8)
	label({ Position = UDim2.fromOffset(74, 10), Size = UDim2.new(1, -210, 0, 24), Text = title, TextSize = 18, Font = Enum.Font.GothamBlack, Parent = frame })
	label({ Position = UDim2.fromOffset(74, 34), Size = UDim2.new(1, -210, 0, 32), Text = description, TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(200, 200, 210), Parent = frame })
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(120, 40)
	button.BackgroundColor3 = buttonColor
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 16
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = buttonText
	button.AutoButtonColor = onClick ~= nil
	button.Parent = frame
	corner(button, 8)
	if onClick then
		button.Activated:Connect(onClick)
	end
end

local function robuxText(price: number?): string
	return if price then ` R$ {price}` else "Comprar"
end

local function refresh()
	if not gui then
		return
	end
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	local remote = ReplicatedStorage:FindFirstChild("StoreAction") :: RemoteFunction?
	local ok, state = pcall(function()
		return remote and remote:InvokeServer("List")
	end)
	if not ok or not state then
		header("La tienda no está disponible ahora", 1)
		return
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	header("🧥 Skins (las ven todos)", nextOrder())
	local equippedId = state.Equipped
	for index, skin in monetization.Skins do
		local entry = state.Skins[index]
		local info = skin :: any
		local description = if info.Armor then "Capa con borde, hombreras de metal" else "Capa con borde y cuello"
		if info.Glow then
			description ..= " y brillo mágico"
		end
		if entry.Owned then
			local isOn = equippedId == skin.Id
			card(nextOrder(), skin.Cape, nil, skin.Name, description, if isOn then "Quitar" else "Equipar", if isOn then GREY else GREEN, function()
				remote:InvokeServer("Equip", if isOn then "" else skin.Id)
				refresh()
			end)
		elseif entry.PassId == 0 then
			card(nextOrder(), skin.Cape, nil, skin.Name, description, "Pronto", GREY, nil)
		elseif info.Pass then
			card(nextOrder(), skin.Cape, nil, skin.Name, description .. ". Viene con el pase VIP", "Ver VIP", GOLD, function()
				MarketplaceService:PromptGamePassPurchase(player, entry.PassId)
			end)
		else
			card(nextOrder(), skin.Cape, nil, skin.Name, description, robuxText(priceOf(entry.PassId, Enum.InfoType.GamePass)), GOLD, function()
				MarketplaceService:PromptGamePassPurchase(player, entry.PassId)
			end)
		end
	end

	header("⭐ Pases (para siempre)", nextOrder())
	for key, pass in monetization.Passes do
		local entry = state.Passes[key]
		if entry.Owned then
			card(nextOrder(), nil, pass.Icon, pass.Name, pass.Description, "✔ Tuyo", GREY, nil)
		elseif pass.Id == 0 then
			card(nextOrder(), nil, pass.Icon, pass.Name, pass.Description, "Pronto", GREY, nil)
		else
			card(nextOrder(), nil, pass.Icon, pass.Name, pass.Description, robuxText(priceOf(pass.Id, Enum.InfoType.GamePass)), GOLD, function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end)
		end
	end

	if showCoins then
		header("🪙 Monedas", nextOrder())
		for _, key in { "CoinsSmall", "CoinsBig" } do
			local product = (monetization.Products :: any)[key]
			if product.Id == 0 then
				card(nextOrder(), nil, product.Icon, product.Name, product.Description, "Pronto", GREY, nil)
			else
				card(nextOrder(), nil, product.Icon, product.Name, product.Description, robuxText(priceOf(product.Id, Enum.InfoType.Product)), GOLD, function()
					MarketplaceService:PromptProductPurchase(player, product.Id)
				end)
			end
		end
	end
end

local function build()
	local screen = Instance.new("ScreenGui")
	screen.Name = "RobuxShop"
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 30
	screen.Enabled = false
	local window = Instance.new("Frame")
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromScale(0.92, 0.84)
	window.BackgroundColor3 = DARK
	window.Parent = screen
	corner(window, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(560, 620)
	limit.Parent = window
	local border = Instance.new("UIStroke")
	border.Color = GOLD
	border.Thickness = 2
	border.Parent = window
	label({ Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -80, 0, 36), Text = "TIENDA", TextSize = 28, Font = Enum.Font.Arcade, TextColor3 = GOLD, Parent = window })
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 10)
	close.Size = UDim2.fromOffset(40, 36)
	close.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 18
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	-- Modal libera el mouse en primera persona mientras está abierta
	close.Modal = true
	close.Parent = window
	corner(close, 8)
	close.Activated:Connect(function()
		screen.Enabled = false
	end)
	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(12, 56)
	list.Size = UDim2.new(1, -24, 1, -68)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = window
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = list
	screen.Parent = player:WaitForChild("PlayerGui")
	gui = screen

	-- Después de comprar, se actualiza sola
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(_, _, purchased)
		if purchased and screen.Enabled then
			task.wait(0.5)
			refresh()
		end
	end)
end

-- withCoins: muestra las bolsas de monedas (solo en la partida)
function RobuxShop.open(withCoins: boolean)
	showCoins = withCoins
	if not gui then
		build()
	end
	local screen = gui :: ScreenGui
	screen.Enabled = true
	task.spawn(refresh)
end

function RobuxShop.isOpen(): boolean
	return gui ~= nil and (gui :: ScreenGui).Enabled
end

function RobuxShop.close()
	if gui then
		gui.Enabled = false
	end
end

return RobuxShop
