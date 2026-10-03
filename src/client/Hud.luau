local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local HEALTH_FULL = Color3.fromRGB(80, 200, 90)
local HEALTH_EMPTY = Color3.fromRGB(220, 60, 50)
local CROSSHAIR_COLOR = Color3.new(1, 1, 1)
local HIT_COLOR = Color3.fromRGB(255, 70, 70)

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

local function buildFireButton(parent: Instance, setTrigger: (boolean) -> ())
	local button = Instance.new("TextButton")
	button.Name = "FireButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -40, 1, -150)
	button.Size = UDim2.fromOffset(110, 110)
	button.BackgroundColor3 = Color3.fromRGB(220, 60, 50)
	button.BackgroundTransparency = 0.25
	button.Text = "🔫"
	button.TextSize = 48
	button.AutoButtonColor = false
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	-- Seguimos el dedo exacto que tocó el botón, así no se queda disparando
	-- si el dedo se desliza fuera del botón antes de soltar.
	local activeTouch: InputObject? = nil
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and not activeTouch then
			activeTouch = input
			setTrigger(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == activeTouch then
			activeTouch = nil
			setTrigger(false)
		end
	end)
end

function Hud.flashHitMarker()
	for _, bar in crosshairBars do
		bar.BackgroundColor3 = HIT_COLOR
		TweenService:Create(bar, TweenInfo.new(0.15), { BackgroundColor3 = CROSSHAIR_COLOR }):Play()
	end
end

function Hud.init(setTrigger: (boolean) -> ())
	local gameState = ReplicatedStorage:WaitForChild("GameState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	local top = Instance.new("Frame")
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(340, 76)
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

	local healthBack = Instance.new("Frame")
	healthBack.Position = UDim2.fromOffset(0, 56)
	healthBack.Size = UDim2.new(1, 0, 0, 18)
	healthBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	healthBack.BorderSizePixel = 0
	healthBack.Parent = top

	local healthFill = Instance.new("Frame")
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack

	local healthText = makeLabel({ Size = UDim2.fromScale(1, 1), TextSize = 13, ZIndex = 2, Parent = healthBack })

	local goldLabel = makeLabel({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(160, 30),
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = gui,
	})

	buildCrosshair(gui)
	if UserInputService.TouchEnabled then
		buildFireButton(gui, setTrigger)
	end

	local function refresh()
		local state = gameState:GetAttribute("State")
		local wave = gameState:GetAttribute("Wave") or 0
		waveLabel.Text = if wave > 0 then `OLEADA {wave}` else "PREPÁRATE"

		if state == "Intermission" then
			statusLabel.Text = `Siguiente oleada en {gameState:GetAttribute("Countdown")}`
		elseif state == "Wave" then
			statusLabel.Text = `Zombis restantes: {gameState:GetAttribute("EnemiesLeft")}`
		elseif state == "GameOver" then
			statusLabel.Text = "¡LOS ZOMBIS TOMARON EL CASTILLO! Reiniciando..."
		else
			statusLabel.Text = "Esperando jugadores..."
		end

		local health = gameState:GetAttribute("CastleHealth") or 0
		local maxHealth = gameState:GetAttribute("CastleMaxHealth") or 1
		local ratio = math.clamp(health / maxHealth, 0, 1)
		healthFill.Size = UDim2.fromScale(ratio, 1)
		healthFill.BackgroundColor3 = HEALTH_EMPTY:Lerp(HEALTH_FULL, ratio)
		healthText.Text = `🏰 {health} / {maxHealth}`
	end

	gameState.AttributeChanged:Connect(refresh)
	refresh()

	task.spawn(function()
		local gold = player:WaitForChild("leaderstats"):WaitForChild("Oro")
		local function updateGold()
			goldLabel.Text = `💰 {gold.Value}`
		end
		gold.Changed:Connect(updateGold)
		updateGold()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return Hud
