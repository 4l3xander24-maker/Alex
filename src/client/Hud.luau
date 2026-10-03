local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local player = Players.LocalPlayer

local HEALTH_FULL = Color3.fromRGB(80, 200, 90)
local HEALTH_EMPTY = Color3.fromRGB(220, 60, 50)
local XP_COLOR = Color3.fromRGB(120, 200, 255)
local CROSSHAIR_COLOR = Color3.new(1, 1, 1)
local HIT_COLOR = Color3.fromRGB(255, 70, 70)
local PANEL_COLOR = Color3.fromRGB(20, 24, 26)

export type Actions = {
	setTrigger: (boolean) -> (),
	reload: () -> (),
	usePower: (string) -> (),
	getAmmo: () -> (number, number, number?),
	getPowerLevel: (string) -> number,
	getCooldown: (string) -> (number, number),
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
		label[key] = value
	end
	return label
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

local function round(parent: Instance, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
end

local function buildCrosshair(parent: Instance)
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
		bar.Parent = parent
		table.insert(crosshairBars, bar)
	end
end

-- Botón que se mantiene presionado (disparar en celular). Seguimos el dedo
-- exacto que lo tocó para que no se quede trabado si el dedo se desliza fuera.
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

type PowerSlot = { Frame: GuiButton, Cooldown: Frame, Timer: TextLabel, Level: TextLabel }

local function buildPowerSlots(parent: Instance, actions: Actions): { [string]: PowerSlot }
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Position = UDim2.new(0, 16, 1, -16)
	bar.Size = UDim2.fromOffset(240, 72)
	bar.BackgroundTransparency = 1
	bar.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar

	local slots = {}
	for order, name in Config.PowerOrder do
		local power = Config.Powers[name]
		local slot = Instance.new("TextButton")
		slot.LayoutOrder = order
		slot.Size = UDim2.fromOffset(68, 68)
		slot.BackgroundColor3 = PANEL_COLOR
		slot.BackgroundTransparency = 0.2
		slot.Text = power.Icon
		slot.TextSize = 32
		slot.AutoButtonColor = false
		slot.ClipsDescendants = true
		slot.Visible = false
		slot.Parent = bar
		round(slot, UDim.new(0, 10))
		slot.Activated:Connect(function()
			actions.usePower(name)
		end)

		local cooldown = Instance.new("Frame")
		cooldown.AnchorPoint = Vector2.new(0, 1)
		cooldown.Position = UDim2.fromScale(0, 1)
		cooldown.BackgroundColor3 = Color3.new(0, 0, 0)
		cooldown.BackgroundTransparency = 0.35
		cooldown.BorderSizePixel = 0
		cooldown.Size = UDim2.fromScale(1, 0)
		cooldown.Parent = slot

		local timer = makeLabel({ Size = UDim2.fromScale(1, 1), TextSize = 22, ZIndex = 2, Parent = slot })
		makeLabel({
			Position = UDim2.fromOffset(4, 2),
			Size = UDim2.fromOffset(20, 16),
			Text = if UserInputService.TouchEnabled then "" else power.Key.Name,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
			Parent = slot,
		})
		local level = makeLabel({
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -4, 1, -2),
			Size = UDim2.fromOffset(40, 16),
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 2,
			Parent = slot,
		})
		slots[name] = { Frame = slot, Cooldown = cooldown, Timer = timer, Level = level }
	end
	return slots
end

function Hud.flashHitMarker()
	for _, bar in crosshairBars do
		bar.BackgroundColor3 = HIT_COLOR
		TweenService:Create(bar, TweenInfo.new(0.15), { BackgroundColor3 = CROSSHAIR_COLOR }):Play()
	end
end

function Hud.init(actions: Actions)
	local gameState = ReplicatedStorage:WaitForChild("GameState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Arriba: oleada, estado y vida de la campana
	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(360, 76)
	top.BackgroundTransparency = 1
	top.Parent = gui

	local waveLabel = makeLabel({ Size = UDim2.new(1, 0, 0, 30), TextSize = 28, Parent = top })
	local statusLabel = makeLabel({
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 22),
		TextSize = 18,
		Font = Enum.Font.GothamBold,
		Parent = top,
	})
	local _, bellFill, bellText = makeBar(top, UDim2.fromOffset(0, 56), UDim2.new(1, 0, 0, 18))

	local coinsLabel = makeLabel({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(180, 30),
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = gui,
	})

	-- Abajo al centro: nivel y barra de experiencia
	local xpPanel = Instance.new("Frame")
	xpPanel.AnchorPoint = Vector2.new(0.5, 1)
	xpPanel.Position = UDim2.new(0.5, 0, 1, -14)
	xpPanel.Size = UDim2.fromOffset(420, 34)
	xpPanel.BackgroundTransparency = 1
	xpPanel.Parent = gui
	local levelLabel = makeLabel({ Size = UDim2.new(1, 0, 0, 18), TextSize = 16, Parent = xpPanel })
	local _, xpFill, xpText = makeBar(xpPanel, UDim2.fromOffset(0, 20), UDim2.new(1, 0, 0, 12))
	xpFill.BackgroundColor3 = XP_COLOR
	xpText.TextSize = 10

	-- Abajo a la derecha: munición
	local ammoLabel = makeLabel({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -30),
		Size = UDim2.fromOffset(220, 44),
		TextSize = 40,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = gui,
	})
	local reloadBack, reloadFill = makeBar(gui, UDim2.new(1, -140, 1, -24), UDim2.fromOffset(120, 6))
	reloadFill.BackgroundColor3 = Color3.fromRGB(255, 220, 90)

	local powerSlots = buildPowerSlots(gui, actions)
	buildCrosshair(gui)

	if UserInputService.TouchEnabled then
		local fire = makeRoundButton(gui, "🔫", UDim2.new(1, -40, 1, -150), 110, Color3.fromRGB(220, 60, 50))
		bindHoldButton(fire, actions.setTrigger)
		local reload = makeRoundButton(gui, "🔄", UDim2.new(1, -160, 1, -170), 64, PANEL_COLOR)
		reload.Activated:Connect(actions.reload)
		ammoLabel.Position = UDim2.new(1, -20, 1, -270)
		reloadBack.Position = UDim2.new(1, -140, 1, -264)
	end

	local function refreshState()
		local state = gameState:GetAttribute("State")
		local wave = gameState:GetAttribute("Wave") or 0
		local isBossWave = wave > 0 and wave % Config.Waves.BossEvery == 0
		waveLabel.Text = if wave > 0 then `OLEADA {wave}{if isBossWave then " 💀" else ""}` else "PREPÁRATE"

		if state == "Intermission" then
			statusLabel.Text = `Siguiente oleada en {gameState:GetAttribute("Countdown")}`
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
	end

	local function refreshXp()
		local xp = player:GetAttribute("Xp") or 0
		local needed = player:GetAttribute("XpNeeded") or 1
		levelLabel.Text = `NIVEL {player:GetAttribute("Level") or 1}`
		xpFill.Size = UDim2.fromScale(math.clamp(xp / needed, 0, 1), 1)
		xpText.Text = `{xp} / {needed} XP`
	end

	gameState.AttributeChanged:Connect(refreshState)
	player.AttributeChanged:Connect(refreshXp)
	refreshState()
	refreshXp()

	task.spawn(function()
		local coins = player:WaitForChild("leaderstats"):WaitForChild("Monedas")
		local function updateCoins()
			coinsLabel.Text = `🪙 {coins.Value}`
		end
		coins.Changed:Connect(updateCoins)
		updateCoins()
	end)

	-- Lo que cambia cada frame: munición y enfriamiento de poderes
	RunService.RenderStepped:Connect(function()
		local ammo, magazine, reloadProgress = actions.getAmmo()
		ammoLabel.Text = if reloadProgress then "RECARGANDO" else `{ammo} / {magazine}`
		ammoLabel.TextSize = if reloadProgress then 24 else 40
		ammoLabel.TextColor3 = if ammo == 0 and not reloadProgress then HEALTH_EMPTY else Color3.new(1, 1, 1)
		reloadBack.Visible = reloadProgress ~= nil
		reloadFill.Size = UDim2.fromScale(reloadProgress or 0, 1)

		for name, slot in powerSlots do
			local level = actions.getPowerLevel(name)
			slot.Frame.Visible = level > 0
			if level > 0 then
				local remaining, total = actions.getCooldown(name)
				slot.Cooldown.Size = UDim2.fromScale(1, math.clamp(remaining / total, 0, 1))
				slot.Timer.Text = if remaining > 0 then tostring(math.ceil(remaining)) else ""
				slot.Level.Text = `Nv{level}`
			end
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
