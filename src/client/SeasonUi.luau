-- Pase de temporada (Config.SeasonPass): botón "Pase" junto a Logros (con el
-- número de premios para cobrar) y una pantalla con los 30 escalones en una
-- tira que se desliza de lado: arriba la fila Gratis, abajo la Premium. Pensada
-- primero para celular: tarjetas grandes y un botón por premio. El cliente solo
-- pide cobrar; el servidor revisa todo (SeasonService).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local Notify = require(script.Parent.Notify)
local Profile = require(script.Parent.Profile)

local GOLD = Color3.fromRGB(255, 215, 100)
local ICE = Color3.fromRGB(140, 210, 255)
local GREEN = Color3.fromRGB(110, 220, 120)
local MUTED = Color3.fromRGB(150, 160, 170)
local PANEL = Color3.fromRGB(20, 26, 34)
local CARD = Color3.fromRGB(32, 42, 54)
local PREMIUM_CARD = Color3.fromRGB(48, 36, 70)
local COLUMN_WIDTH = 104

local pass = Config.SeasonPass
local product = Config.Monetization.Products.SeasonPass

local SeasonUi = {}

local player = Players.LocalPlayer
local panel: Frame
local track: ScrollingFrame
local header: TextLabel
local timeLabel: TextLabel
local tierLabel: TextLabel
local xpLabel: TextLabel
local fill: Frame
local buyButton: TextButton
local badge: TextLabel
local price = ""
local busy = false

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
	for key, value in props do
		(text :: any)[key] = value
	end
	text.Parent = parent
	return text
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local line = Instance.new("UIStroke")
	line.Color = color
	line.Thickness = thickness
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = parent
end

-- Perfil con la XP de temporada al día (el servidor la publica como atributo
-- en plena partida, sin mandar el perfil entero)
local function profile(): Progression.Profile
	local data = Profile.get()
	local season = Progression.season(data)
	local live = player:GetAttribute("SeasonXp")
	if typeof(live) == "number" and live > season.Xp then
		season.Xp = live
	end
	return data
end

local function timeLeft(): string
	local left = pass.Ends - os.time()
	if left <= 0 then
		return "Temporada terminada: cobra lo que alcanzaste"
	end
	local days, hours = left // 86400, (left % 86400) // 3600
	return if days > 0 then `Termina en {days} d {hours} h` else `Termina en {hours} h {(left % 3600) // 60} min`
end

local function claim(trackName: string, tier: number)
	if busy then
		return
	end
	busy = true
	local ok, success, message = pcall(function()
		return Remotes.SeasonClaim:InvokeServer(trackName, tier)
	end)
	busy = false
	if ok then
		Notify.show(message, if success then GREEN else Color3.fromRGB(255, 110, 100))
	end
end

-- Una tarjeta de premio (fila Gratis o Premium) dentro de la columna del escalón
local function card(column: Frame, trackName: string, tier: number, data: Progression.Profile)
	local season = Progression.season(data)
	local reward = pass.Rewards[tier][trackName]
	local isPremium = trackName == "Premium"
	local reached = Progression.seasonTier(season.Xp) >= tier
	local claimed = season.Claimed[Progression.seasonKey(trackName, tier)] == true
	local locked = isPremium and not season.Premium
	local final = tier == #pass.Rewards

	-- Toda la tarjeta es el botón: un blanco grande para el dedo
	local frame = Instance.new("TextButton")
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.Position = if isPremium then UDim2.new(0, 0, 0.5, 10) else UDim2.fromOffset(0, 22)
	frame.Size = UDim2.new(1, 0, 0.5, -16)
	frame.BackgroundColor3 = if isPremium then PREMIUM_CARD else CARD
	frame.BackgroundTransparency = if reached then 0 else 0.35
	frame.Parent = column
	round(frame, 10)
	if final then
		stroke(frame, GOLD, 2)
	elseif claimed then
		stroke(frame, GREEN, 1.5)
	end

	local icon, text = Progression.seasonRewardText(reward)
	label(frame, { Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0.4, -3), Text = icon, TextScaled = true, TextTransparency = if reached then 0 else 0.4 })
	local name = label(frame, { Position = UDim2.new(0, 4, 0.4, 0), Size = UDim2.new(1, -8, 0.6, -24), Text = text, TextScaled = true, TextWrapped = true, TextColor3 = if final then GOLD elseif reached then Color3.new(1, 1, 1) else MUTED })
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 13
	limit.MinTextSize = 8
	limit.Parent = name

	local status = label(frame, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(1, -8, 0, 20), BackgroundTransparency = 0, TextSize = 12, Font = Enum.Font.GothamBlack })
	round(status, 6)
	if claimed then
		status.Text = "✅ Cobrado"
		status.BackgroundColor3 = Color3.fromRGB(34, 70, 40)
	elseif locked then
		status.Text = "🔒 Premium"
		status.BackgroundColor3 = Color3.fromRGB(70, 60, 90)
	elseif Progression.canClaimSeason(data, trackName, tier) then
		status.Text = "Cobrar"
		status.BackgroundColor3 = Color3.fromRGB(46, 150, 80)
		frame.AutoButtonColor = true
		frame.Activated:Connect(function()
			claim(trackName, tier)
		end)
	else
		status.Text = `Escalón {tier}`
		status.BackgroundColor3 = Color3.fromRGB(44, 50, 58)
		status.TextColor3 = MUTED
	end
end

local function render()
	local data = profile()
	local season = Progression.season(data)
	local tier = Progression.seasonTier(season.Xp)
	local total = #pass.Rewards
	header.Text = `{pass.Icon} PASE DE TEMPORADA · {pass.Name}`
	timeLabel.Text = timeLeft()
	tierLabel.Text = `Escalón {tier} / {total}`
	if tier >= total then
		xpLabel.Text = `{season.Xp} XP · ¡Pase completo!`
		fill.Size = UDim2.fromScale(1, 1)
	else
		local into = season.Xp - tier * pass.XpPerTier
		xpLabel.Text = `{into} / {pass.XpPerTier} XP para el escalón {tier + 1}`
		fill.Size = UDim2.fromScale(math.clamp(into / pass.XpPerTier, 0, 1), 1)
	end

	-- Botón de compra: apagado sin id ("Próximamente"), con Premium o con la temporada cerrada
	local open = Progression.seasonOpen(os.time())
	local canBuy = product.Id ~= 0 and open and not season.Premium
	buyButton.Text = if season.Premium then "✅ Premium activo" elseif not open then "Temporada terminada" elseif product.Id == 0 then "⭐ Desbloquear Premium · Próximamente" else `⭐ Desbloquear Premium{price}`
	buyButton.Active = canBuy
	buyButton.AutoButtonColor = canBuy
	buyButton.BackgroundColor3 = if canBuy then Color3.fromRGB(150, 90, 220) elseif season.Premium then Color3.fromRGB(34, 70, 40) else Color3.fromRGB(70, 72, 80)

	for _, child in track:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	for index = 1, total do
		local column = Instance.new("Frame")
		column.Size = UDim2.new(0, COLUMN_WIDTH, 1, -6)
		column.BackgroundTransparency = 1
		column.LayoutOrder = index
		column.Parent = track
		local reached = tier >= index
		label(column, { Size = UDim2.new(1, 0, 0, 20), Text = if index == total then `👑 {index}` else tostring(index), TextSize = 15, Font = Enum.Font.GothamBlack, TextColor3 = if reached then GOLD else MUTED })
		card(column, "Free", index, data)
		card(column, "Premium", index, data)
	end
end

local function updateBadge()
	local count = Progression.seasonClaimable(profile())
	badge.Visible = count > 0
	badge.Text = tostring(count)
end

function SeasonUi.toggle()
	panel.Visible = not panel.Visible
	if panel.Visible then
		render()
		-- Se abre mirando el escalón que sigue
		local tier = Progression.seasonTier(Progression.season(profile()).Xp)
		track.CanvasPosition = Vector2.new(math.max(0, (tier - 1) * (COLUMN_WIDTH + 8)), 0)
	end
end

function SeasonUi.init()
	local touch = UserInputService.TouchEnabled
	local gui = Instance.new("ScreenGui")
	gui.Name = "SeasonPass"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 11
	if touch then
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Botón a la izquierda de Logros
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = if touch then UDim2.new(1, -234, 0, 76) else UDim2.new(1, -280, 0, 84)
	button.Size = if touch then UDim2.fromOffset(86, 30) else UDim2.fromOffset(110, 32)
	button.BackgroundColor3 = Color3.fromRGB(50, 110, 180)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = if touch then 14 else 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = `{pass.Icon} Pase`
	button.Parent = gui
	round(button, 8)
	badge = label(button, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(220, 50, 60), Text = "", TextSize = 12, Font = Enum.Font.GothamBlack, Visible = false, ZIndex = 2 })
	round(badge, 10)

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.94, 0.9)
	panel.BackgroundColor3 = PANEL
	panel.Visible = false
	panel.Parent = gui
	round(panel, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(780, 480)
	limit.Parent = panel
	stroke(panel, ICE, 2)

	header = label(panel, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -84, 0, 22), Text = "", TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = ICE, TextXAlignment = Enum.TextXAlignment.Left })
	local headerLimit = Instance.new("UITextSizeConstraint")
	headerLimit.MaxTextSize = 22
	headerLimit.Parent = header
	timeLabel = label(panel, { Position = UDim2.fromOffset(14, 28), Size = UDim2.new(1, -84, 0, 16), Text = "", TextSize = 12, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left })
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 8)
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

	-- Escalón y barra de XP
	tierLabel = label(panel, { Position = UDim2.fromOffset(14, 44), Size = UDim2.fromOffset(130, 20), Text = "", TextSize = 16, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left })
	local back = Instance.new("Frame")
	back.Position = UDim2.fromOffset(146, 48)
	back.Size = UDim2.new(1, -160, 0, 12)
	back.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
	back.Parent = panel
	round(back, 6)
	fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = ICE
	fill.Parent = back
	round(fill, 6)
	xpLabel = label(panel, { Position = UDim2.fromOffset(146, 61), Size = UDim2.new(1, -160, 0, 14), Text = "", TextSize = 11, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left })

	-- El premio final, siempre a la vista
	local finalIcon, finalText = Progression.seasonRewardText(pass.Rewards[#pass.Rewards].Premium)
	local final = label(panel, { Position = UDim2.fromOffset(14, 76), Size = UDim2.new(1, -28, 0, 18), Text = `👑 Premio final Premium: {finalIcon} {finalText}`, TextScaled = true, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left })
	local finalLimit = Instance.new("UITextSizeConstraint")
	finalLimit.MaxTextSize = 14
	finalLimit.Parent = final

	-- Nombres de las filas a la izquierda y la tira de escalones
	-- (la columna de nombres usa las mismas medidas que las tarjetas, para que queden alineados)
	local side = Instance.new("Frame")
	side.Position = UDim2.fromOffset(8, 98)
	side.Size = UDim2.new(0, 58, 1, -160)
	side.BackgroundTransparency = 1
	side.Parent = panel
	label(side, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0.5, -16), Text = "GRATIS", TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = ICE })
	label(side, { Position = UDim2.new(0, 0, 0.5, 10), Size = UDim2.new(1, 0, 0.5, -16), Text = "⭐\nPREMIUM", TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = GOLD })
	track = Instance.new("ScrollingFrame")
	track.Position = UDim2.fromOffset(68, 98)
	track.Size = UDim2.new(1, -78, 1, -154)
	track.BackgroundTransparency = 1
	track.BorderSizePixel = 0
	track.ScrollBarThickness = 6
	track.ScrollingDirection = Enum.ScrollingDirection.X
	track.AutomaticCanvasSize = Enum.AutomaticSize.X
	track.CanvasSize = UDim2.new()
	track.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = track

	-- Abajo: cómo se gana XP y el botón del Premium
	label(panel, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -8), Size = UDim2.new(1, -270, 0, 40), Text = "XP de temporada: oleadas superadas peleando, bajas, jefes y misiones diarias.", TextSize = 11, TextWrapped = true, TextColor3 = MUTED, TextXAlignment = Enum.TextXAlignment.Left })
	buyButton = Instance.new("TextButton")
	buyButton.AnchorPoint = Vector2.new(1, 1)
	buyButton.Position = UDim2.new(1, -12, 1, -8)
	buyButton.Size = UDim2.fromOffset(244, 44)
	buyButton.Font = Enum.Font.GothamBlack
	buyButton.TextSize = 14
	buyButton.TextWrapped = true
	buyButton.TextColor3 = Color3.new(1, 1, 1)
	buyButton.Parent = panel
	round(buyButton, 10)
	buyButton.Activated:Connect(function()
		local season = Progression.season(Profile.get())
		if product.Id ~= 0 and not season.Premium and Progression.seasonOpen(os.time()) then
			MarketplaceService:PromptProductPurchase(player, product.Id)
		end
	end)
	if product.Id ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(product.Id, Enum.InfoType.Product)
			end)
			price = if ok and info and info.PriceInRobux then ` · R$ {info.PriceInRobux}` else ""
		end)
	end

	button.Activated:Connect(SeasonUi.toggle)
	Profile.Changed:Connect(function()
		updateBadge()
		if panel.Visible then
			render()
		end
	end)
	player:GetAttributeChangedSignal("SeasonXp"):Connect(function()
		updateBadge()
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
	updateBadge()
	-- La cuenta regresiva de la temporada, mientras está abierto
	task.spawn(function()
		while true do
			task.wait(30)
			if panel.Visible then
				timeLabel.Text = timeLeft()
			end
		end
	end)
end

return SeasonUi
