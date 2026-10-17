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
local status: TextLabel
local HAT_NAMES = { Hood = "capucha", Crown = "corona", Horns = "cuernos", Helmet = "yelmo", Brim = "sombrero" }

local function setStatus(text: string, good: boolean)
	if status then
		status.Text = text
		status.TextColor3 = if good then Color3.fromRGB(120, 230, 140) else Color3.fromRGB(255, 140, 120)
	end
end

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

type Button = { Text: string, Color: Color3, OnClick: (() -> ())? }

-- Tarjeta: muestra (color o ícono), nombre, descripción y uno o dos botones
local function card(order: number, swatch: Color3?, icon: string?, title: string, description: string, buttons: { Button }, exclusive: boolean?)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 74)
	frame.BackgroundColor3 = CARD
	frame.LayoutOrder = order
	frame.Parent = list
	corner(frame, 10)
	if exclusive then
		local line = Instance.new("UIStroke")
		line.Color = Color3.fromRGB(200, 120, 255)
		line.Thickness = 2
		line.Parent = frame
	end
	local preview = Instance.new("TextLabel")
	preview.Position = UDim2.fromOffset(10, 10)
	preview.Size = UDim2.fromOffset(54, 54)
	preview.BackgroundColor3 = swatch or Color3.fromRGB(60, 62, 74)
	preview.Text = icon or ""
	preview.TextSize = 30
	preview.Font = Enum.Font.GothamBlack
	preview.Parent = frame
	corner(preview, 8)
	local buttonsWidth = #buttons * 110 + 10
	local name = label({ Position = UDim2.fromOffset(74, 10), Size = UDim2.new(1, -84 - buttonsWidth, 0, 24), Text = title, TextSize = 18, TextScaled = true, Font = Enum.Font.GothamBlack, Parent = frame })
	local nameLimit = Instance.new("UITextSizeConstraint")
	nameLimit.MaxTextSize = 18
	nameLimit.Parent = name
	if exclusive then
		name.Text = `{title}  <font color="#C878FF">★ EXCLUSIVA</font>`
		name.RichText = true
	end
	label({ Position = UDim2.fromOffset(74, 34), Size = UDim2.new(1, -84 - buttonsWidth, 0, 32), Text = description, TextSize = 13, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(200, 200, 210), Parent = frame })
	for index, info in buttons do
		local button = Instance.new("TextButton")
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -10 - (#buttons - index) * 110, 0.5, 0)
		button.Size = UDim2.fromOffset(102, 40)
		button.BackgroundColor3 = info.Color
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 15
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Text = info.Text
		button.AutoButtonColor = info.OnClick ~= nil
		button.Parent = frame
		corner(button, 8)
		if info.OnClick then
			button.Activated:Connect(info.OnClick)
		end
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
		-- Skin de temporada que ya pasó: solo la ve quien la compró
		local expired = info.Until ~= nil and os.time() > info.Until
		if expired and not entry.Owned then
			continue
		end
		local parts = { "Capa" }
		if info.Armor then
			table.insert(parts, "hombreras")
		end
		if info.Hat then
			table.insert(parts, HAT_NAMES[info.Hat] or "sombrero")
		end
		if info.Glow then
			table.insert(parts, "brillo mágico")
		end
		local description = table.concat(parts, ", ")
		if info.Seasonal then
			description ..= `  ·  {info.Seasonal}`
		end
		local buttons: { Button } = {}
		if entry.Owned then
			local isOn = equippedId == skin.Id
			table.insert(buttons, { Text = if isOn then "Quitar" else "Equipar", Color = if isOn then GREY else GREEN, OnClick = function()
				remote:InvokeServer("Equip", if isOn then "" else skin.Id)
				refresh()
			end })
		elseif info.Pass then
			local pass = (monetization.Passes :: any)[info.Pass]
			description ..= `. Viene con: {pass.Name}`
			table.insert(buttons, { Text = if entry.PassId == 0 then "Pronto" else `Ver {pass.Name}`, Color = if entry.PassId == 0 then GREY else GOLD, OnClick = if entry.PassId == 0 then nil else function()
				MarketplaceService:PromptGamePassPurchase(player, entry.PassId)
			end })
		else
			if info.CoinPrice then
				table.insert(buttons, { Text = `💰 {info.CoinPrice}`, Color = Color3.fromRGB(190, 140, 30), OnClick = function()
					local ok, bought, message = pcall(function()
						return remote:InvokeServer("BuyCoins", skin.Id)
					end)
					setStatus(if ok then message or "" else "La tienda no responde", ok and bought == true)
					if ok and bought then
						refresh()
					end
				end })
			end
			if info.PassId then
				local robux = entry.PassId ~= 0
				table.insert(buttons, { Text = if robux then robuxText(priceOf(entry.PassId, Enum.InfoType.GamePass)) else "Pronto", Color = if robux then GOLD else GREY, OnClick = if robux then function()
					MarketplaceService:PromptGamePassPurchase(player, entry.PassId)
				end else nil })
			end
		end
		card(nextOrder(), skin.Cape, nil, skin.Name, description, buttons, info.Exclusive)
	end

	header("⭐ Pases (para siempre)", nextOrder())
	for _, key in monetization.PassOrder do
		local pass = (monetization.Passes :: any)[key]
		local entry = state.Passes[key]
		local button: Button
		if entry.Owned then
			button = { Text = "✔ Tuyo", Color = GREY }
		elseif pass.Id == 0 then
			button = { Text = "Pronto", Color = GREY }
		else
			button = { Text = robuxText(priceOf(pass.Id, Enum.InfoType.GamePass)), Color = GOLD, OnClick = function()
				MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			end }
		end
		card(nextOrder(), nil, pass.Icon, pass.Name, pass.Description, { button }, key == "StarterPack")
	end

	if showCoins then
		header("💰 Monedas", nextOrder())
		for _, key in { "CoinsSmall", "CoinsBig" } do
			local product = (monetization.Products :: any)[key]
			if product.Id == 0 then
				card(nextOrder(), nil, product.Icon, product.Name, product.Description, { { Text = "Pronto", Color = GREY } })
			else
				card(nextOrder(), nil, product.Icon, product.Name, product.Description, { { Text = robuxText(priceOf(product.Id, Enum.InfoType.Product)), Color = GOLD, OnClick = function()
					MarketplaceService:PromptProductPurchase(player, product.Id)
				end } })
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
	label({ Position = UDim2.fromOffset(18, 10), Size = UDim2.fromOffset(140, 36), Text = "TIENDA", TextSize = 28, Font = Enum.Font.Arcade, TextColor3 = GOLD, Parent = window })
	status = label({ Position = UDim2.fromOffset(160, 10), Size = UDim2.new(1, -220, 0, 36), Text = "", TextSize = 14, TextWrapped = true, Parent = window })
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
	setStatus("", true)
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
