local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Profile = require(script.Parent.Profile)

local player = Players.LocalPlayer

local HEALTH_FULL = Color3.fromRGB(80, 200, 90)
local HEALTH_EMPTY = Color3.fromRGB(220, 60, 50)
local GOLD = Color3.fromRGB(255, 215, 100)
local XP_COLOR = Color3.fromRGB(120, 200, 255)
local CROSSHAIR_COLOR = Color3.new(1, 1, 1)
local HIT_COLOR = Color3.fromRGB(255, 70, 70)
local PANEL_COLOR = Color3.fromRGB(20, 24, 26)

export type Actions = {
	setTrigger: (boolean) -> (),
	setAiming: (boolean) -> (),
	reload: () -> (),
	cycleWeapon: () -> (),
	usePower: (string) -> (),
	setSprint: (boolean) -> (),
	dash: () -> (),
	getAmmo: () -> (number, number, number, number?, boolean),
	ammoGranted: RBXScriptSignal,
	getEquipped: () -> string,
	isAiming: () -> boolean,
	isScoped: () -> boolean,
	getCooldown: (string) -> (number, number),
	getDashCooldown: () -> number,
}

local Hud = {}

local crosshairBars: { Frame } = {}

local function makeLabel(props): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	for key, value in props do
		(label :: any)[key] = value
	end
	return label
end

local function round(parent: Instance, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

local function makeBar(parent: Instance, position: UDim2, size: UDim2): (Frame, Frame, TextLabel)
	local back = Instance.new("Frame")
	back.Position = position
	back.Size = size
	back.BackgroundColor3 = PANEL_COLOR
	back.BorderSizePixel = 0
	back.Parent = parent

	local fill = Instance.new("Frame")
	fill.BorderSizePixel = 0
	fill.Parent = back

	local text = makeLabel({ Size = UDim2.fromScale(1, 1), TextSize = 13, ZIndex = 2, Parent = back })
	return back, fill, text
end

local function buildCrosshair(parent: Instance): Frame
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromOffset(40, 40)
	holder.BackgroundTransparency = 1
	holder.Parent = parent
	local gap, length, thickness = 6, 8, 2
	local offsets = {
		{ Vector2.new(0, -(gap + length / 2)), Vector2.new(thickness, length) },
		{ Vector2.new(0, gap + length / 2), Vector2.new(thickness, length) },
		{ Vector2.new(-(gap + length / 2), 0), Vector2.new(length, thickness) },
		{ Vector2.new(gap + length / 2, 0), Vector2.new(length, thickness) },
	}
	for _, data in offsets do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, data[1].X, 0.5, data[1].Y)
		bar.Size = UDim2.fromOffset(data[2].X, data[2].Y)
		bar.BackgroundColor3 = CROSSHAIR_COLOR
		bar.BorderSizePixel = 0
		bar.Parent = holder
		table.insert(crosshairBars, bar)
	end
	return holder
end

-- Vista del visor del francotirador: todo negro menos un círculo
local function buildScope(parent: Instance): Frame
	local scope = Instance.new("Frame")
	scope.Size = UDim2.fromScale(1, 1)
	scope.BackgroundTransparency = 1
	scope.Visible = false
	scope.Parent = parent
	local circle = Instance.new("Frame")
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromScale(0.5, 0.5)
	circle.Size = UDim2.fromScale(0.8, 0.8)
	circle.SizeConstraint = Enum.SizeConstraint.RelativeYY
	circle.BackgroundTransparency = 1
	circle.Parent = scope
	round(circle, UDim.new(1, 0))
	local ring = Instance.new("UIStroke")
	ring.Thickness = 2000
	ring.Color = Color3.new(0, 0, 0)
	ring.Parent = circle
	for _, horizontal in { true, false } do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromScale(0.5, 0.5)
		line.Size = if horizontal then UDim2.new(1, 0, 0, 1) else UDim2.new(0, 1, 1, 0)
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BorderSizePixel = 0
		line.Parent = circle
	end
	return scope
end

-- Botón que se mantiene presionado en celular. Seguimos el dedo exacto que
-- lo tocó para que no se quede trabado si el dedo se desliza fuera.
local function bindHoldButton(button: GuiButton, setHeld: (boolean) -> ())
	local activeTouch: InputObject? = nil
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and not activeTouch then
			activeTouch = input
			setHeld(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == activeTouch then
			activeTouch = nil
			setHeld(false)
		end
	end)
end

local function makeRoundButton(parent: Instance, text: string, position: UDim2, size: number, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = position
	button.Size = UDim2.fromOffset(size, size)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.25
	button.Text = text
	button.TextSize = size * 0.42
	button.AutoButtonColor = false
	button.Parent = parent
	round(button, UDim.new(1, 0))
	return button
end

type Slot = { Frame: GuiButton, Cooldown: Frame, Timer: TextLabel, Level: TextLabel }

local function makeSlot(parent: Instance, order: number, icon: string, key: string): Slot
	local slot = Instance.new("TextButton")
	slot.LayoutOrder = order
	slot.Size = UDim2.fromOffset(62, 62)
	slot.BackgroundColor3 = PANEL_COLOR
	slot.BackgroundTransparency = 0.2
	slot.Text = icon
	slot.TextSize = 28
	slot.AutoButtonColor = false
	slot.ClipsDescendants = true
	slot.Visible = false
	slot.Parent = parent
	round(slot, UDim.new(0, 10))

	local cooldown = Instance.new("Frame")
	cooldown.AnchorPoint = Vector2.new(0, 1)
	cooldown.Position = UDim2.fromScale(0, 1)
	cooldown.BackgroundColor3 = Color3.new(0, 0, 0)
	cooldown.BackgroundTransparency = 0.35
	cooldown.BorderSizePixel = 0
	cooldown.Size = UDim2.fromScale(1, 0)
	cooldown.Parent = slot

	local timer = makeLabel({ Size = UDim2.fromScale(1, 1), TextSize = 20, ZIndex = 2, Parent = slot })
	makeLabel({ Position = UDim2.fromOffset(4, 2), Size = UDim2.fromOffset(30, 14), Text = if UserInputService.TouchEnabled then "" else key, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2, Parent = slot })
	local level = makeLabel({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -2), Size = UDim2.fromOffset(40, 14), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2, Parent = slot })
	return { Frame = slot, Cooldown = cooldown, Timer = timer, Level = level }
end

local function makeRow(parent: Instance, anchor: Vector2, position: UDim2, size: Vector2): Frame
	local bar = Instance.new("Frame")
	bar.AnchorPoint = anchor
	bar.Position = position
	bar.Size = UDim2.fromOffset(size.X, size.Y)
	bar.BackgroundTransparency = 1
	bar.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = if anchor.X > 0.5 then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar
	return bar
end

function Hud.flashHitMarker()
	for _, bar in crosshairBars do
		bar.BackgroundColor3 = HIT_COLOR
		TweenService:Create(bar, TweenInfo.new(0.15), { BackgroundColor3 = CROSSHAIR_COLOR }):Play()
	end
end

function Hud.init(actions: Actions)
	local gameState = ReplicatedStorage:WaitForChild("GameState")
	local touch = UserInputService.TouchEnabled

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local scope = buildScope(gui)
	local lowHealth = Instance.new("Frame")
	lowHealth.Size = UDim2.fromScale(1, 1)
	lowHealth.BackgroundColor3 = HEALTH_EMPTY
	lowHealth.BackgroundTransparency = 1
	lowHealth.Parent = gui

	-- Arriba: oleada, estado y vida de la campana
	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(380, 76)
	top.BackgroundTransparency = 1
	top.Parent = gui
	local waveLabel = makeLabel({ Size = UDim2.new(1, 0, 0, 30), TextSize = 28, Parent = top })
	local statusLabel = makeLabel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 30), Size = UDim2.fromOffset(640, 22), TextSize = 17, Font = Enum.Font.GothamBold, Parent = top })
	local _, bellFill, bellText = makeBar(top, UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 18))
	local trapLabel = makeLabel({ Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 0, 18), TextSize = 13, Font = Enum.Font.GothamBold, Parent = top })
	-- Vida del jefe (solo cuando hay uno vivo)
	local bossBack, bossFill, bossText = makeBar(top, UDim2.fromOffset(-60, 100), UDim2.new(1, 120, 0, 20))
	bossFill.BackgroundColor3 = Color3.fromRGB(170, 40, 60)
	bossText.TextSize = 14
	bossBack.Visible = false

	-- Arriba a la derecha: monedas, nivel de cuenta y XP de la partida
	local coinsLabel = makeLabel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 10), Size = UDim2.fromOffset(200, 30), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Right, Parent = gui })
	local levelLabel = makeLabel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 40), Size = UDim2.fromOffset(240, 20), TextSize = 15, TextColor3 = XP_COLOR, TextXAlignment = Enum.TextXAlignment.Right, Parent = gui })
	local matchLabel = makeLabel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 60), Size = UDim2.fromOffset(240, 18), TextSize = 13, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = gui })

	-- Abajo a la izquierda: vida del jugador y poderes
	local healthBack, healthFill, healthText = makeBar(gui, UDim2.new(0, 16, 1, -100), UDim2.fromOffset(220, 16))
	local powerRow = makeRow(gui, Vector2.new(0, 1), UDim2.new(0, 16, 1, -14), Vector2.new(320, 62))
	local powerSlots: { [string]: Slot } = {}
	for order, name in Config.PowerOrder do
		local power = Config.Powers[name]
		local slot = makeSlot(powerRow, order, power.Icon, power.Key.Name)
		slot.Frame.Activated:Connect(function()
			actions.usePower(name)
		end)
		powerSlots[name] = slot
	end
	local dashSlot = makeSlot(powerRow, 10, "💨", "C")
	dashSlot.Frame.Activated:Connect(actions.dash)

	-- Abajo a la derecha: armas y munición
	local weaponRow = makeRow(gui, Vector2.new(1, 1), UDim2.new(1, -16, 1, -82), Vector2.new(420, 34))
	local weaponSlots: { [string]: TextLabel } = {}
	for slotIndex, id in Config.WeaponOrder do
		local slot = makeLabel({
			LayoutOrder = slotIndex,
			Size = UDim2.fromOffset(60, 34),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = PANEL_COLOR,
			Text = if touch then Config.Weapons[id].Icon else `{slotIndex} {Config.Weapons[id].Icon}`,
			TextSize = 16,
			Visible = false,
			Parent = weaponRow,
		})
		round(slot, UDim.new(0, 8))
		local stroke = Instance.new("UIStroke")
		stroke.Color = GOLD
		stroke.Thickness = 2
		stroke.Parent = slot
		weaponSlots[id] = slot
	end
	local weaponName = makeLabel({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -54), Size = UDim2.fromOffset(260, 22), TextSize = 16, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right, Parent = gui })
	local ammoLabel = makeLabel({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -12), Size = UDim2.fromOffset(300, 42), TextSize = 38, TextXAlignment = Enum.TextXAlignment.Right, RichText = true, Parent = gui })
	local reloadBack, reloadFill = makeBar(gui, UDim2.new(1, -140, 1, -8), UDim2.fromOffset(120, 5))
	reloadFill.BackgroundColor3 = GOLD

	local crosshair = buildCrosshair(gui)

	local aimButton, sprintButton
	if touch then
		local fire = makeRoundButton(gui, "🔫", UDim2.new(1, -40, 1, -170), 110, Color3.fromRGB(220, 60, 50))
		bindHoldButton(fire, actions.setTrigger)
		local reload = makeRoundButton(gui, "🔄", UDim2.new(1, -165, 1, -190), 60, PANEL_COLOR)
		reload.Activated:Connect(actions.reload)
		local swap = makeRoundButton(gui, "🔁", UDim2.new(1, -165, 1, -260), 54, PANEL_COLOR)
		swap.Activated:Connect(actions.cycleWeapon)
		aimButton = makeRoundButton(gui, "🔭", UDim2.new(1, -60, 1, -290), 60, PANEL_COLOR)
		local aiming = false
		aimButton.Activated:Connect(function()
			aiming = not aiming
			actions.setAiming(aiming)
		end)
		sprintButton = makeRoundButton(gui, "🏃", UDim2.new(0, 250, 1, -110), 60, PANEL_COLOR)
		sprintButton.AnchorPoint = Vector2.new(0, 1)
		bindHoldButton(sprintButton, actions.setSprint)
		-- Arriba de los botones de disparo y apuntar para que no se encimen
		weaponRow.Position = UDim2.new(1, -16, 1, -370)
		weaponName.Position = UDim2.new(1, -20, 1, -402)
		healthBack.Position = UDim2.new(0, 16, 1, -100)
	end

	local function refreshState()
		local state = gameState:GetAttribute("State")
		local wave = gameState:GetAttribute("Wave") or 0
		local isBossWave = wave > 0 and wave % Config.Waves.BossEvery == 0
		waveLabel.Text = if wave > 0 then `OLEADA {wave}{if isBossWave then " 💀" else ""}` else "PREPÁRATE"

		local countdown = gameState:GetAttribute("Countdown") or 0
		if state == "Lobby" then
			waveLabel.Text = "PREPARACIÓN"
			statusLabel.Text = `Compra en el campamento · empieza en {countdown} s · toca la campana para empezar ya`
		elseif state == "Intermission" then
			statusLabel.Text = `Siguiente oleada en {countdown}`
		elseif state == "Wave" then
			statusLabel.Text = `Zombis restantes: {gameState:GetAttribute("EnemiesLeft")}`
		elseif state == "GameOver" then
			statusLabel.Text = "¡DESTRUYERON LA CAMPANA! Reiniciando..."
		else
			statusLabel.Text = "Esperando jugadores..."
		end

		local health = gameState:GetAttribute("BellHealth") or 0
		local maxHealth = gameState:GetAttribute("BellMaxHealth") or 1
		local ratio = math.clamp(health / maxHealth, 0, 1)
		bellFill.Size = UDim2.fromScale(ratio, 1)
		bellFill.BackgroundColor3 = HEALTH_EMPTY:Lerp(HEALTH_FULL, ratio)
		bellText.Text = `🔔 {health} / {maxHealth}`

		-- Trampas compradas para esta partida
		local parts = {}
		local mines = gameState:GetAttribute("Mines") or 0
		if mines > 0 then
			table.insert(parts, `🪤 {mines} minas`)
		end
		for _, id in Config.Traps.Gate.SlotOrder do
			local gateHealth = gameState:GetAttribute("Gate" .. id) or 0
			if gateHealth > 0 then
				table.insert(parts, `🚧 {Config.Traps.Gate.Slots[id].Short} {gateHealth}`)
			end
		end
		trapLabel.Text = table.concat(parts, "   ")

		local bossName = gameState:GetAttribute("BossName") or ""
		bossBack.Visible = bossName ~= "" and state == "Wave"
		if bossBack.Visible then
			local bossHealth = gameState:GetAttribute("BossHealth") or 0
			local bossMax = math.max(gameState:GetAttribute("BossMaxHealth") or 1, 1)
			bossFill.Size = UDim2.fromScale(math.clamp(bossHealth / bossMax, 0, 1), 1)
			bossText.Text = `{bossName}  ·  {bossHealth} / {bossMax}`
		end
	end

	local function refreshProfile()
		local data = Profile.get()
		coinsLabel.Text = `🪙 {Profile.coins()}`
		local points = data.StatPoints + data.TalentPoints
		levelLabel.Text = `⭐ Nivel {data.Level} · {data.Xp}/{Progression.xpNeeded(data.Level)} XP{if points > 0 then "  (¡puntos!)" else ""}`
		local matchXp = player:GetAttribute("MatchXp") or 0
		matchLabel.Text = if matchXp > 0 then `+{matchXp} XP al terminar la partida` else ""
		for id, slot in weaponSlots do
			local level = data.Weapons[id]
			slot.Visible = level ~= nil
			-- El número del arma toma el color de su nivel de mejora
			slot.TextColor3 = if level and level > 0 then Progression.weaponTier(level).Accent else Color3.new(1, 1, 1)
		end
		if aimButton then
			aimButton.Visible = Profile.hasTalent("Aim")
		end
		if sprintButton then
			sprintButton.Visible = Profile.hasTalent("Sprint")
		end
	end

	gameState.AttributeChanged:Connect(refreshState)
	player.AttributeChanged:Connect(refreshProfile)
	Profile.Changed:Connect(refreshProfile)
	refreshState()
	refreshProfile()

	-- Lo que cambia cada frame
	RunService.RenderStepped:Connect(function()
		local data = Profile.get()

		local ammo, _, reserve, reloadProgress, melee = actions.getAmmo()
		local empty = not melee and ammo == 0 and reserve == 0
		if melee then
			ammoLabel.Text = "🔪 ∞"
		elseif reloadProgress then
			ammoLabel.Text = "RECARGANDO"
		elseif empty then
			ammoLabel.Text = `SIN BALAS <font size="16">· usa el machete (1)</font>`
		else
			ammoLabel.Text = `{ammo} <font size="22" transparency="0.25">/ {reserve}</font>`
		end
		ammoLabel.TextSize = if reloadProgress or empty then 24 else 38
		ammoLabel.TextColor3 = if (ammo == 0 and not reloadProgress and not melee) then HEALTH_EMPTY else Color3.new(1, 1, 1)
		reloadBack.Visible = reloadProgress ~= nil
		reloadFill.Size = UDim2.fromScale(reloadProgress or 0, 1)

		local equipped = actions.getEquipped()
		local equippedLevel = data.Weapons[equipped] or 0
		local tier = Progression.weaponTier(equippedLevel)
		weaponName.Text = `{Config.Weapons[equipped].DisplayName}{if equippedLevel > 0 then `  ·  {tier.Name}` else ""}`
		weaponName.TextColor3 = if equippedLevel > 0 then tier.Accent else Color3.new(1, 1, 1)
		for id, slot in weaponSlots do
			local stroke = slot:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Enabled = id == equipped
			end
		end

		for name, slot in powerSlots do
			local level = data.Powers[name] or 0
			slot.Frame.Visible = level > 0
			if level > 0 then
				local remaining, total = actions.getCooldown(name)
				slot.Cooldown.Size = UDim2.fromScale(1, math.clamp(remaining / total, 0, 1))
				slot.Timer.Text = if remaining > 0 then tostring(math.ceil(remaining)) else ""
				slot.Level.Text = `Nv{level}`
			end
		end
		dashSlot.Frame.Visible = Progression.hasTalent(data, "Dash")
		local dashRemaining = actions.getDashCooldown()
		dashSlot.Cooldown.Size = UDim2.fromScale(1, math.clamp(dashRemaining / Config.TalentValues.DashCooldown, 0, 1))
		dashSlot.Timer.Text = if dashRemaining > 0 then tostring(math.ceil(dashRemaining)) else ""

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local health = humanoid and humanoid.Health or 0
		local maxHealth = humanoid and humanoid.MaxHealth or 100
		local ratio = math.clamp(health / maxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthFill.BackgroundColor3 = HEALTH_EMPTY:Lerp(HEALTH_FULL, ratio)
		healthText.Text = `❤️ {math.ceil(health)} / {math.floor(maxHealth)}`
		lowHealth.BackgroundTransparency = if ratio < 0.3 and health > 0 then 0.8 + math.sin(os.clock() * 6) * 0.08 else 1

		local scoped = actions.isScoped()
		scope.Visible = scoped
		crosshair.Visible = not scoped
	end)

	-- "+3" que sube junto a la munición cuando un zombi te da balas
	actions.ammoGranted:Connect(function(weaponId, amount)
		local popup = makeLabel({
			-- A la izquierda del número de balas, para no tapar el nombre del arma
			AnchorPoint = Vector2.new(1, 1),
			Position = ammoLabel.Position + UDim2.fromOffset(-170, -4),
			Size = UDim2.fromOffset(200, 24),
			TextSize = 20,
			TextColor3 = GOLD,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = `+{amount} {Config.Weapons[weaponId].Icon}`,
			Parent = gui,
		})
		local tween = TweenService:Create(popup, TweenInfo.new(0.9), { Position = popup.Position + UDim2.fromOffset(0, -30), TextTransparency = 1, TextStrokeTransparency = 1 })
		tween.Completed:Once(function()
			popup:Destroy()
		end)
		tween:Play()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
