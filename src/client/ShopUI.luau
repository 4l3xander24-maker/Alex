-- Ventanas de los NPC del campamento. Se abren con el aviso "E" (o tocando
-- en celular) al acercarse:
--   Armero   → comprar, mejorar y equipar armas
--   Bruja    → comprar y mejorar poderes, y mascotas (vive en la aldea)
--   Veterano → gastar puntos de mejora y aprender talentos
--   Intendente → cartuchera (más balas) y trampas para la partida
-- Solo se puede comprar durante la preparación; equipar armas, siempre.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local Notify = require(script.Parent.Notify)
local Profile = require(script.Parent.Profile)
local RobuxShop = require(Shared.RobuxShop)
local Sfx = require(script.Parent.Sfx)
local WeaponController = require(script.Parent.WeaponController)

local player = Players.LocalPlayer

local GOLD = Color3.fromRGB(255, 215, 100)
local GREEN = Color3.fromRGB(110, 220, 120)
local RED = Color3.fromRGB(255, 110, 100)
local PANEL = Color3.fromRGB(24, 28, 30)
local ROW = Color3.fromRGB(34, 40, 42)
local MUTED = Color3.fromRGB(190, 200, 195)
local CLOSE_DISTANCE = 16

local TITLES = {
	Armory = { "🔫 ARMERÍA", "Bruno, el Armero" },
	Mystic = { "🔮 TIENDA DE LA BRUJA", "Morgana, la Bruja" },
	Trainer = { "🎖️ ENTRENAMIENTO", "Don Ramiro, el Veterano" },
	Quartermaster = { "🎒 INTENDENCIA", "Gustavo, el Intendente" },
	Captain = { "⚔️ COMPAÑEROS", "Capitán Rolando" },
	Tailor = { "🧵 SASTRERÍA", "Elena, la Sastre" },
}

local ShopUI = {}

local gui: ScreenGui
local title: TextLabel
local subtitle: TextLabel
local list: ScrollingFrame
local closedBanner: TextLabel
local gameState: Instance
local currentShop: string? = nil
local currentPrompt: ProximityPrompt? = nil
local order = 0

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
	text.TextWrapped = true
	for key, value in props do
		(text :: any)[key] = value
	end
	text.Parent = parent
	return text
end

local function nextOrder(): number
	order += 1
	return order
end

local function sectionHeader(text: string)
	label(list, { Size = UDim2.new(1, -10, 0, 30), Text = text, TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, LayoutOrder = nextOrder() })
end

local function runAction(action: string, id: string)
	task.spawn(function()
		local ok, message = Remotes.ShopAction:InvokeServer(action, id)
		if ok then
			Sfx.play("Coins")
		end
		Notify.show(message, if ok then GREEN else RED)
	end)
end

type ButtonSpec = { Text: string, Enabled: boolean, OnClick: (() -> ())? }

local function isOpen(): boolean
	return gameState:GetAttribute("State") == "Lobby"
end

-- Una fila: ícono, nombre, descripción y hasta dos botones a la derecha
local function row(icon: string, name: string, description: string, buttons: { ButtonSpec }, nameColor: Color3?, premium: boolean?)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -10, 0, 86)
	frame.BackgroundColor3 = if premium then Color3.fromRGB(52, 36, 78) else ROW
	frame.LayoutOrder = nextOrder()
	frame.Parent = list
	round(frame, 10)
	-- Premium (Robux): borde violeta y degradado dorado, para que resalten
	if premium then
		local glow = Instance.new("UIStroke")
		glow.Color = Color3.fromRGB(200, 120, 255)
		glow.Thickness = 2.5
		glow.Parent = frame
		local shine = Instance.new("UIGradient")
		shine.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 225, 150))
		shine.Rotation = 20
		shine.Parent = frame
	end

	label(frame, { Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(54, 86), Text = icon, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Center })
	label(frame, { Position = UDim2.fromOffset(70, 8), Size = UDim2.new(1, -330, 0, 24), Text = name, TextSize = 18, Font = Enum.Font.GothamBlack, TextColor3 = nameColor or Color3.new(1, 1, 1) })
	label(frame, { Position = UDim2.fromOffset(70, 32), Size = UDim2.new(1, -330, 0, 50), Text = description, TextSize = 13, TextColor3 = MUTED, TextYAlignment = Enum.TextYAlignment.Top })

	for index, spec in buttons do
		local button = Instance.new("TextButton")
		-- Fuera de la preparación solo funcionan equipar armas y llevar mascotas
		if not isOpen() and spec.Text ~= "Equipar" and spec.Text ~= "Llevar" and spec.Text ~= "Quitar" and string.sub(spec.Text, 1, 5) ~= "Robux" and string.sub(spec.Text, 1, 5) ~= "Abrir" then
			spec.Enabled = false
		end
		button.AnchorPoint = Vector2.new(1, 0.5)
		button.Position = UDim2.new(1, -10 - (index - 1) * 130, 0.5, 0)
		button.Size = UDim2.fromOffset(122, 40)
		button.BackgroundColor3 = if spec.Enabled then GOLD else Color3.fromRGB(70, 74, 76)
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 14
		button.TextColor3 = if spec.Enabled then Color3.fromRGB(30, 24, 10) else Color3.fromRGB(170, 170, 170)
		button.Text = spec.Text
		button.AutoButtonColor = spec.Enabled
		button.Parent = frame
		round(button, 8)
		if spec.Enabled and spec.OnClick then
			button.Activated:Connect(spec.OnClick)
		end
	end
end

local function renderArmory(data: Progression.Profile, coins: number)
	sectionHeader("Armas  ·  cambia de arma con las teclas 1-6  ·  cada mejora cambia su color")
	for slot, id in Config.WeaponOrder do
		local weapon = Config.Weapons[id]
		local level = data.Weapons[id]
		local stats = Progression.getWeaponStats(data, id, false)
		local description
		if stats.Melee then
			description = `Daño {string.format("%.1f", stats.Damage)} · {string.format("%.1f", stats.FireRate)} tajos/s · hasta {stats.MaxTargets} zombis por tajo · sin munición`
		else
			local pellets = if stats.Pellets > 1 then ` x{stats.Pellets}` else ""
			description = `Daño {string.format("%.1f", stats.Damage)}{pellets} · {string.format("%.1f", stats.FireRate)} disparos/s · Cargador {stats.Magazine} · Reserva {stats.StartReserve}/{stats.MaxReserve}`
		end
		local buttons: { ButtonSpec } = {}
		local name = weapon.DisplayName
		local nameColor = nil

		if level == nil then
			table.insert(buttons, { Text = `Comprar 💰{weapon.Price}`, Enabled = coins >= weapon.Price, OnClick = function()
				runAction("BuyWeapon", id)
			end })
		else
			local tier = Progression.weaponTier(level)
			name ..= `  ·  {tier.Name}`
			nameColor = if level > 0 then tier.Accent else nil
			description ..= `\nMejora Nv {level}/{Config.WeaponUpgrade.MaxLevel}  ·  tecla {slot}`
			if level < Config.WeaponUpgrade.MaxLevel then
				local cost = Progression.weaponUpgradeCost(id, level)
				local nextTier = Progression.weaponTier(level + 1)
				table.insert(buttons, { Text = `{nextTier.Name} 💰{cost}`, Enabled = coins >= cost, OnClick = function()
					runAction("UpgradeWeapon", id)
				end })
			else
				table.insert(buttons, { Text = "Máximo", Enabled = false })
			end
			local isEquipped = WeaponController.getEquipped() == id
			table.insert(buttons, { Text = if isEquipped then "Equipada" else "Equipar", Enabled = not isEquipped, OnClick = function()
				WeaponController.equip(id)
				ShopUI.render()
			end })
		end
		row(weapon.Icon, name, description, buttons, nameColor)
	end
end

local function renderQuartermaster(data: Progression.Profile, coins: number)
	local storage = Config.AmmoStorage
	local level = data.AmmoStorage or 0
	local multiplier = Progression.ammoStorageMultiplier(data)
	sectionHeader("Cartuchera  ·  más balas máximas y más balas al empezar")
	local cost = Progression.ammoStorageCost(level)
	local pistol = Progression.getWeaponStats(data, "Pistol", false)
	row("🎒", `Cartuchera  ·  Nv {level}/{storage.MaxLevel}`, `Ahora cargas x{string.format("%.2f", multiplier)} balas (pistola: {pistol.StartReserve} al empezar, máximo {pistol.MaxReserve}).\nCada nivel: +{math.floor(storage.PerLevel * 100)}% en todas las armas.`, {
		if cost
			then { Text = `Mejorar 💰{cost}`, Enabled = coins >= cost, OnClick = function()
				runAction("UpgradeStorage", "")
			end }
			else { Text = "Máximo", Enabled = false },
	})

	local armor = Config.Bell.Armor
	local armorLevel = data.BellArmor or 0
	local armorCost = Progression.bellArmorCost(armorLevel)
	sectionHeader("Campana  ·  más vida para la campana (queda guardado)")
	row("🔔", `Refuerzo de la campana  ·  Nv {armorLevel}/{armor.MaxLevel}`, `Vida de la campana: {Config.Bell.MaxHealth + armorLevel * armor.HealthPerLevel}. Cada nivel: +{armor.HealthPerLevel}.\nEn la partida cuenta el refuerzo más alto del servidor.`, {
		if armorCost
			then { Text = `Mejorar 💰{armorCost}`, Enabled = coins >= armorCost, OnClick = function()
				runAction("UpgradeBell", "")
			end }
			else { Text = "Máximo", Enabled = false },
	})

	sectionHeader("Trampas  ·  se colocan en el terreno")
	row("🪤", "Minas y rejas", `En la preparación, camina por el camino de los zombis: aparecen lugares celestes. Acércate y pulsa E para colocar una mina (💰{Config.Traps.Mine.Price}) o una reja (💰{Config.Traps.Gate.Price}). Acércate a las ya puestas para mejorarlas. Solo duran una partida.`, {})
end

local function renderMystic(data: Progression.Profile, coins: number)
	sectionHeader("Poderes")
	for _, id in Config.PowerOrder do
		local power = Config.Powers[id]
		local level = data.Powers[id]
		local description = `{power.Description}. Tecla {power.Key.Name}.`
		local buttons: { ButtonSpec } = {}
		if level == nil then
			table.insert(buttons, { Text = `Comprar 💰{power.Price}`, Enabled = coins >= power.Price, OnClick = function()
				runAction("BuyPower", id)
			end })
		else
			local stats = Progression.getPowerStats(data, id)
			description ..= `\nNv {level}/{power.MaxLevel} · espera {string.format("%.1f", stats.Cooldown)} s · siguiente: {power.LevelText}`
			if level < power.MaxLevel then
				local cost = Progression.powerUpgradeCost(id, level)
				table.insert(buttons, { Text = `Mejorar 💰{cost}`, Enabled = coins >= cost, OnClick = function()
					runAction("UpgradePower", id)
				end })
			else
				table.insert(buttons, { Text = "Máximo", Enabled = false })
			end
		end
		row(power.Icon, power.DisplayName, description, buttons)
	end

	-- Mascotas: se compran una vez y una te acompaña en las partidas
	sectionHeader("Mascotas  ·  te siguen y atacan solas durante las oleadas")
	for _, id in Config.PetOrder do
		local pet = Config.Pets[id]
		local description = `{pet.Description}. Daño {pet.Damage} · {pet.Rate} ataques/s · alcance {pet.Range}{if pet.Splash then ` · en área` else ""}.`
		local buttons: { ButtonSpec } = {}
		if not data.Pets[id] then
			table.insert(buttons, { Text = `Comprar 💰{pet.Price}`, Enabled = coins >= pet.Price, OnClick = function()
				runAction("BuyPet", id)
			end })
		elseif data.Pet == id then
			table.insert(buttons, { Text = "Quitar", Enabled = true, OnClick = function()
				runAction("EquipPet", "")
			end })
		else
			table.insert(buttons, { Text = "Llevar", Enabled = true, OnClick = function()
				runAction("EquipPet", id)
			end })
		end
		row(pet.Icon, pet.DisplayName .. (if data.Pet == id then "  ·  te acompaña" else ""), description, buttons, if data.Pet == id then GREEN else nil)
	end
end

-- Compra con Robux de un producto de Config.Monetization.Products
local function buyProduct(key: string)
	local product = Config.Monetization.Products[key]
	if not product or product.Id == 0 then
		Notify.show("Este producto llega pronto", RED)
		return
	end
	MarketplaceService:PromptProductPurchase(player, product.Id)
end

local function petButtons(data: Progression.Profile, coins: number, id: string): { ButtonSpec }
	local pet = Config.Pets[id]
	local buttons: { ButtonSpec } = {}
	if data.Pets[id] then
		if data.Pet == id then
			table.insert(buttons, { Text = "Quitar", Enabled = true, OnClick = function()
				runAction("EquipPet", "")
			end })
		else
			table.insert(buttons, { Text = "Llevar", Enabled = true, OnClick = function()
				runAction("EquipPet", id)
			end })
		end
	elseif pet.Product then
		table.insert(buttons, { Text = "Robux 💎", Enabled = true, OnClick = function()
			buyProduct(pet.Product)
		end })
	else
		table.insert(buttons, { Text = `Comprar 💰{pet.Price}`, Enabled = coins >= pet.Price, OnClick = function()
			runAction("BuyPet", id)
		end })
	end
	return buttons
end

local function renderCaptain(data: Progression.Profile, coins: number)
	sectionHeader("Compañeros  ·  pelean a tu lado (uno a la vez, junto a tu mascota)")
	for _, id in Config.CompanionOrder do
		local pet = Config.Pets[id]
		local description = `{pet.Description}. Daño {pet.Damage} · {pet.Rate} ataques/s · alcance {pet.Range}{if pet.Splash then " · en área" else ""}.`
		if pet.Product then
			description ..= "\n💎 Compañero especial: se compra con Robux."
		end
		row(pet.Icon, pet.DisplayName .. (if data.Pet == id then "  ·  te acompaña" else ""), description, petButtons(data, coins, id), if data.Pet == id then GREEN else nil)
	end
end

-- Skins de objetos (minas, rejas, campana): las de monedas son normales; las
-- Premium (Robux) salen con borde violeta, estrella y brillo dorado
local KIND_NAMES = { Mine = "Minas", Gate = "Rejas", Bell = "Campana", Pet = "Compañeros", Tracer = "Rastro de balas" }
local function renderObjectSkins(data: Progression.Profile, coins: number)
	for _, kind in { "Mine", "Gate", "Bell", "Pet", "Tracer" } do
		local equipped = data.ObjectSkinOn[kind]
		sectionHeader(`Skins de {KIND_NAMES[kind]:lower()}`)
		row("⬜", "Normal", "El aspecto de siempre.", { { Text = if equipped == "" then "Puesta" else "Poner", Enabled = equipped ~= "", OnClick = function()
			runAction("EquipObjectSkin", `{kind}:`)
		end } })
		for _, skin in Config.ObjectSkins do
			if skin.Kind == kind then
				local owned = data.ObjectSkins[skin.Id]
				local buttons: { ButtonSpec } = {}
				if owned then
					table.insert(buttons, { Text = if equipped == skin.Id then "Puesta" else "Poner", Enabled = equipped ~= skin.Id, OnClick = function()
						runAction("EquipObjectSkin", `{kind}:{skin.Id}`)
					end })
				elseif skin.Product then
					table.insert(buttons, { Text = "Robux 💎", Enabled = true, OnClick = function()
						buyProduct(skin.Product)
					end })
				else
					table.insert(buttons, { Text = `Comprar 💰{skin.CoinPrice}`, Enabled = coins >= skin.CoinPrice, OnClick = function()
						runAction("BuyObjectSkin", skin.Id)
					end })
				end
				local description = if skin.Premium then "★ PREMIUM: brilla y suelta chispas. Solo con Robux." else "Cambia el color. Se compra con monedas."
				row(skin.Icon, (if skin.Premium then "★ " else "") .. skin.Name, description, buttons, if skin.Premium then Color3.fromRGB(235, 190, 255) elseif equipped == skin.Id then GREEN else nil, skin.Premium)
			end
		end
	end
end

local function renderTailor(data: Progression.Profile, coins: number)
	sectionHeader("Trajes  ·  capas, armaduras y sombreros")
	row("🧥", "Trajes y capas", "Capas de viajero, de cazador, reales y más. Se pagan con monedas o Robux.", { { Text = "Abrir trajes", Enabled = true, OnClick = function()
		ShopUI.close()
		RobuxShop.open(true)
	end } })
	sectionHeader("Skins de armas  ·  cambian el color de todas tus armas")
	row("🔫", "Armas normales", "Quita la skin y usa el color de cada arma según su nivel.", { { Text = if data.WeaponSkin == "" then "Puesta" else "Quitar", Enabled = data.WeaponSkin ~= "", OnClick = function()
		runAction("EquipWeaponSkin", "")
	end } })
	for _, skin in Config.WeaponSkins do
		local owned = data.WeaponSkins[skin.Id]
		local buttons: { ButtonSpec } = {}
		if owned then
			table.insert(buttons, { Text = if data.WeaponSkin == skin.Id then "Puesta" else "Equipar", Enabled = data.WeaponSkin ~= skin.Id, OnClick = function()
				runAction("EquipWeaponSkin", skin.Id)
			end })
		else
			if skin.CoinPrice then
				table.insert(buttons, { Text = `Comprar 💰{skin.CoinPrice}`, Enabled = coins >= skin.CoinPrice, OnClick = function()
					runAction("BuyWeaponSkin", skin.Id)
				end })
			end
			if skin.Product then
				table.insert(buttons, { Text = "Robux 💎", Enabled = true, OnClick = function()
					buyProduct(skin.Product)
				end })
			end
		end
		row(skin.Icon, `Skin {skin.Name}`, if skin.Glow then "Brilla con luz propia." else "Color nuevo para tus armas.", buttons, if data.WeaponSkin == skin.Id then GREEN else nil)
	end
	renderObjectSkins(data, coins)
end

-- Veterano al estilo de Guns 'n Goblins: dos columnas en letra pixelada.
-- Izquierda las mejoras con barritas (cada barrita llena = puntos gastados),
-- derecha los talentos con su estado. Abajo, qué hace lo que señalas.
local PIP_ON = Color3.fromRGB(150, 205, 255)
local PIP_HALF = Color3.fromRGB(90, 130, 175)
local PIP_OFF = Color3.fromRGB(44, 52, 68)
local DIM = Color3.fromRGB(110, 120, 140)
local SKY = Color3.fromRGB(170, 195, 230)

local function pixelText(parent: Instance, props): TextLabel
	local text = label(parent, props)
	text.Font = Config.PixelFont
	text.TextWrapped = false
	text.TextStrokeTransparency = 0.4
	return text
end

local function pixelButton(parent: Instance, text: string, position: UDim2, size: UDim2, color: Color3, onClick: () -> (), border: Color3?): TextButton
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Config.PixelFont
	button.TextSize = 16
	button.TextColor3 = if border then Color3.new(1, 1, 1) else Color3.fromRGB(16, 20, 32)
	button.TextStrokeTransparency = if border then 0.3 else 1
	button.Text = text
	button.Parent = parent
	if border then
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = border
		stroke.Thickness = 2
		stroke.Parent = button
	end
	button.Activated:Connect(onClick)
	return button
end

local function renderTrainer(data: Progression.Profile)
	local nextTalent = (data.Level // Config.Progression.TalentEvery + 1) * Config.Progression.TalentEvery
	local rowHeight = 34
	local rows = math.max(#Config.Stats, #Config.Talents)
	local open = true -- los puntos se reparten siempre, también en plena partida

	local board = Instance.new("Frame")
	board.BackgroundTransparency = 1
	board.Size = UDim2.new(1, -10, 0, 48 + rows * rowHeight + 70)
	board.LayoutOrder = nextOrder()
	board.Parent = list

	-- Barra de abajo: qué hace lo que señalas
	local info = label(board, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundTransparency = 0.15,
		BackgroundColor3 = Color3.fromRGB(14, 16, 22),
		Text = "Señala una mejora o un talento para ver qué hace",
		TextSize = 14,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	round(info, 6)
	local function describe(target: GuiObject, text: string)
		target.MouseEnter:Connect(function()
			info.Text = text
		end)
	end

	pixelText(board, { Size = UDim2.new(0.5, -14, 0, 36), Text = `MEJORAS ..........  {data.StatPoints} 💎`, TextSize = 22, TextColor3 = SKY })
	pixelText(board, { Position = UDim2.new(0.5, 14, 0, 0), Size = UDim2.new(0.5, -14, 0, 36), Text = `💎 {data.TalentPoints}  .......... TALENTOS`, TextSize = 22, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right })

	for index, stat in Config.Stats do
		local points = data.Stats[stat.Id] or 0
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Position = UDim2.fromOffset(0, 48 + (index - 1) * rowHeight)
		line.Size = UDim2.new(0.5, -14, 0, rowHeight)
		line.Parent = board
		pixelText(line, { Size = UDim2.new(0, 160, 1, 0), Text = string.upper(stat.Name), TextSize = 18, TextColor3 = if points > 0 then Color3.new(1, 1, 1) else DIM })
		-- Barritas: hasta 10; si el máximo es 20, cada barrita vale 2 puntos
		local pips = math.min(stat.Max, 10)
		local per = stat.Max / pips
		for pip = 1, pips do
			local filled = points >= pip * per
			local halfFilled = not filled and points >= (pip - 0.5) * per
			local bar = Instance.new("Frame")
			bar.BorderSizePixel = 0
			bar.Position = UDim2.fromOffset(160 + (pip - 1) * 13, 8)
			bar.Size = UDim2.fromOffset(9, rowHeight - 16)
			bar.BackgroundColor3 = if filled then PIP_ON elseif halfFilled then PIP_HALF else PIP_OFF
			bar.Parent = line
		end
		local current = if points > 0 then Progression.describeStat(stat.Id, points) else "Sin puntos"
		local nextText = if points < stat.Max then `  ·  Con +1: {Progression.describeStat(stat.Id, points + 1)}` else "  ·  ¡Al máximo!"
		describe(line, `{stat.Icon} {stat.Name}: {current} ({points}/{stat.Max}){nextText}`)
		if open and data.StatPoints > 0 and points < stat.Max then
			describe(pixelButton(line, "+", UDim2.new(1, 0, 0.5, 0), UDim2.fromOffset(30, 26), PIP_ON, function()
				runAction("AddStat", stat.Id)
			end), `{stat.Icon} {stat.Name}: gasta 1 punto  ·  Con +1: {Progression.describeStat(stat.Id, points + 1)}`)
		end
	end

	for index, talent in Config.Talents do
		local learned = Progression.hasTalent(data, talent.Id)
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Position = UDim2.new(0.5, 14, 0, 48 + (index - 1) * rowHeight)
		line.Size = UDim2.new(0.5, -14, 0, rowHeight)
		line.Parent = board
		pixelText(line, { Size = UDim2.new(1, -120, 1, 0), Text = string.upper(talent.Name), TextSize = 18, TextColor3 = if learned then GOLD else Color3.new(1, 1, 1) })
		describe(line, `{talent.Icon} {talent.Name}: {talent.Description}`)
		if learned then
			pixelText(line, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 120, 1, 0), Text = "APRENDIDO", TextSize = 16, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right })
		elseif open and data.TalentPoints > 0 then
			describe(pixelButton(line, "APRENDER", UDim2.new(1, 0, 0.5, 0), UDim2.fromOffset(110, 26), Color3.fromRGB(200, 100, 30), function()
				runAction("LearnTalent", talent.Id)
			end, GOLD), `{talent.Icon} {talent.Name}: {talent.Description}`)
		else
			pixelText(line, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 120, 1, 0), Text = if data.TalentPoints > 0 then "CERRADO" else `NIVEL {nextTalent}`, TextSize = 16, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right })
		end
	end
end

function ShopUI.render()
	if not currentShop then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	order = 0

	local data = Profile.get()
	local coins = Profile.coins()
	local titles = TITLES[currentShop]
	title.Text = titles[1]
	local xpText = `Nivel {data.Level} · {data.Xp}/{Progression.xpNeeded(data.Level)} XP`
	subtitle.Text = `{titles[2]}   ·   💰 {coins}   ·   {xpText}`

	closedBanner.Visible = not isOpen() and currentShop ~= "Trainer"
	if currentShop == "Armory" then
		renderArmory(data, coins)
	elseif currentShop == "Mystic" then
		renderMystic(data, coins)
	elseif currentShop == "Quartermaster" then
		renderQuartermaster(data, coins)
	elseif currentShop == "Captain" then
		renderCaptain(data, coins)
	elseif currentShop == "Tailor" then
		renderTailor(data, coins)
	else
		renderTrainer(data)
	end
end

function ShopUI.open(shop: string, prompt: ProximityPrompt?)
	if not TITLES[shop] then
		return
	end
	currentShop = shop
	currentPrompt = prompt
	ShopUI.render()
	gui.Enabled = true
end

function ShopUI.close()
	currentShop = nil
	currentPrompt = nil
	gui.Enabled = false
end

function ShopUI.isOpen(): boolean
	return currentShop ~= nil
end

-- El aviso de reparar la campana solo lo ve quien tiene el talento
local function updateRepairPrompt()
	local map = workspace:FindFirstChild("Map")
	local prompt = map and map:FindFirstChild("RepairPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Enabled = Profile.hasTalent("Repair")
	end
end

function ShopUI.init()
	gameState = ReplicatedStorage:WaitForChild("GameState")
	gui = Instance.new("ScreenGui")
	gui.Name = "Shop"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 12
	gui.Enabled = false

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.9, 0, 0.8, 0)
	panel.BackgroundColor3 = PANEL
	panel.BackgroundTransparency = 0.04
	panel.Parent = gui
	round(panel, 14)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(760, 560)
	constraint.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Parent = panel

	title = label(panel, { Position = UDim2.fromOffset(20, 12), Size = UDim2.new(1, -80, 0, 34), TextSize = 26, Font = Enum.Font.GothamBlack, TextColor3 = GOLD })
	subtitle = label(panel, { Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -80, 0, 22), TextSize = 15, TextColor3 = MUTED })
	closedBanner = label(panel, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -64, 0, 18),
		Size = UDim2.fromOffset(300, 24),
		TextSize = 14,
		TextColor3 = RED,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "🔒 Cerrado: solo se compra antes de la partida",
		Visible = false,
	})

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -12, 0, 12)
	close.Size = UDim2.fromOffset(40, 40)
	close.BackgroundColor3 = Color3.fromRGB(70, 40, 40)
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 20
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	-- Modal libera el mouse en primera persona mientras la ventana está abierta
	close.Modal = true
	close.Parent = panel
	round(close, 8)
	close.Activated:Connect(ShopUI.close)

	list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(14, 80)
	list.Size = UDim2.new(1, -28, 1, -94)
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

	gui.Parent = player:WaitForChild("PlayerGui")

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local shop = prompt:GetAttribute("Shop")
		if typeof(shop) == "string" then
			ShopUI.open(shop, prompt)
		end
	end)

	Profile.Changed:Connect(function()
		ShopUI.render()
		updateRepairPrompt()
	end)
	player:GetAttributeChangedSignal("Coins"):Connect(ShopUI.render)
	-- Abre/cierra la tienda con el estado de la partida y muestra las trampas
	gameState.AttributeChanged:Connect(function(name)
		if name == "State" or name == "Mines" or string.sub(name, 1, 4) == "Gate" then
			ShopUI.render()
		end
	end)
	-- Con StreamingEnabled el aviso puede llegar después: lo revisamos cuando aparece
	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		updateRepairPrompt()
		map.DescendantAdded:Connect(function(descendant)
			if descendant.Name == "RepairPrompt" then
				updateRepairPrompt()
			end
		end)
	end)

	-- Se cierra sola si te alejas del NPC
	RunService.Heartbeat:Connect(function()
		if not currentPrompt then
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local anchor = currentPrompt.Parent
		if not root or not anchor or not anchor:IsA("BasePart") or ((root :: BasePart).Position - anchor.Position).Magnitude > CLOSE_DISTANCE then
			ShopUI.close()
		end
	end)
end

return ShopUI
