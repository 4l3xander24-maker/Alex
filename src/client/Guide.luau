-- Guía para jugadores nuevos:
--  * En la preparación, flechas sobre los vendedores y la campana.
--  * La primera vez, un tutorial corto de 4 pasos (se guarda en el perfil).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local HudIcons = require(script.Parent.HudIcons)
local Profile = require(script.Parent.Profile)

local GOLD = Color3.fromRGB(255, 215, 100)
local WHITE = Color3.new(1, 1, 1)
local HIDE_DISTANCE = 20 -- ya está al lado (se ve el aviso de E): la flecha estorba
local BOB_SPEED = 3
local BOB_HEIGHT = 0.6
local HITS_TO_LEARN = 3
local POWERS_STEP_TIME = 10

local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local STEPS = {
	{
		Title = "Prepárate y empieza",
		Text = if touch
			then "Sigue las flechas doradas: compra armas con tus monedas y, cuando estés listo, mantén el aviso de la campana para reconstruirla."
			else "Sigue las flechas doradas: compra armas con tus monedas y, cuando estés listo, mantén E en la campana para reconstruirla.",
	},
	{
		Title = "¡Defiende la campana!",
		Text = if touch
			then "Los zombis vienen del bosque. Usa los botones para moverte, disparar, recargar y saltar."
			else "Los zombis vienen del bosque. Dispara con clic izquierdo, R recarga, 1 a 8 cambia de arma.",
	},
	{
		Title = "Más ayuda",
		Text = "La Bruja vende poderes y el Capitán compañeros que pelean contigo. Los zombis sueltan potenciadores: míralos arriba a la derecha.",
	},
}

type Marker = { Gui: BillboardGui, Arrow: TextLabel, Target: BasePart, IsBell: boolean }

local Guide = {}

local player = Players.LocalPlayer
local markers: { Marker } = {}
local active = false -- el tutorial está en curso
local step = 0
local hits = 0
local panel: Frame
local controls: Frame? = nil -- (celular) fila con los botones y para qué sirve cada uno
local panelTitle: TextLabel
local panelText: TextLabel

local function gameState(): string?
	local folder = ReplicatedStorage:FindFirstChild("GameState")
	return if folder then folder:GetAttribute("State") else nil
end

local function saveTutorialDone()
	task.spawn(function()
		Remotes.ShopAction:InvokeServer("FinishTutorial", "")
	end)
end

local function finishTutorial()
	if not active then
		return
	end
	active = false
	step = 0
	panel.Visible = false
	if controls then
		controls.Visible = false
	end
	saveTutorialDone()
end

local function setStep(newStep: number)
	if not active or newStep <= step then
		return
	end
	if newStep > #STEPS then
		finishTutorial()
		return
	end
	step = newStep
	panelTitle.Text = `TUTORIAL {step}/{#STEPS} · {STEPS[step].Title}`
	panelText.Text = STEPS[step].Text
	if controls then
		controls.Visible = step == 2 or step == 3
	end
	if step == #STEPS then
		task.delay(POWERS_STEP_TIME, function()
			if step == #STEPS then
				finishTutorial()
			end
		end)
	end
end

-- Paso actual según el estado de la partida (por si entra a la mitad)
local function syncStepWithState()
	local state = gameState()
	if state == "Intermission" or state == "Wave" then
		setStep(2)
	end
end

local function addMarker(target: BasePart, text: string, isBell: boolean)
	local gui = Instance.new("BillboardGui")
	gui.Name = "GuideMarker"
	gui.Size = UDim2.fromOffset(170, 64)
	gui.StudsOffset = Vector3.new(0, if isBell then 9 else 5, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = target
	gui.Enabled = false

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.new(1, 0, 0, 34)
	arrow.Position = UDim2.fromOffset(0, 26)
	arrow.BackgroundTransparency = 1
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextSize = 34
	arrow.Text = "▼"
	arrow.TextStrokeTransparency = 0.2
	arrow.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 24)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 16
	label.Text = text
	label.TextColor3 = WHITE
	label.TextStrokeTransparency = 0.2
	label.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
	table.insert(markers, { Gui = gui, Arrow = arrow, Target = target, IsBell = isBell })
end

local function onPrompt(prompt: Instance)
	if not prompt:IsA("ProximityPrompt") or not prompt.Parent or not prompt.Parent:IsA("BasePart") then
		return
	end
	for _, marker in markers do
		if marker.Target == prompt.Parent then
			return
		end
	end
	if prompt:GetAttribute("Shop") then
		-- Solo la flecha: el cartel del NPC ya dice quién es
		addMarker(prompt.Parent, "", false)
	elseif prompt.Name == "StartPrompt" then
		addMarker(prompt.Parent, "Reconstruir campana", true)
	end
end

local function updateMarkers()
	local lobby = gameState() == "Lobby"
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local bob = math.sin(os.clock() * BOB_SPEED) * BOB_HEIGHT
	for index = #markers, 1, -1 do
		local marker = markers[index]
		if not marker.Target.Parent then
			marker.Gui:Destroy()
			table.remove(markers, index)
			continue
		end
		local far = not root or (root.Position - marker.Target.Position).Magnitude > HIDE_DISTANCE
		marker.Gui.Enabled = lobby and far
		if marker.Gui.Enabled then
			-- Dorado lo que el tutorial pide ahora; si no hay tutorial, todo dorado
			local highlighted = not active or step == 1
			marker.Arrow.TextColor3 = if highlighted then GOLD else WHITE
			marker.Gui.StudsOffset = Vector3.new(0, (if marker.IsBell then 9 else 5) + bob, 0)
		end
	end
end

local function buildPanel()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Tutorial"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	panel = Instance.new("Frame")
	-- Arriba a la derecha, debajo del nivel y el reloj: no tapa los avisos del centro
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -12, 0, 128)
	panel.Size = UDim2.fromOffset(380, 104)
	panel.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui
	if touch then
		-- En celular, arriba al centro (debajo del aviso de la oleada): a la
		-- derecha están los botones de disparar y recargar
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		panel.AnchorPoint = Vector2.new(0.5, 0)
		panel.Position = UDim2.new(0.5, 0, 0, 74)
		panel.Size = UDim2.fromOffset(340, 112)
	end
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Parent = panel
	local maxSize = Instance.new("UISizeConstraint")
	maxSize.MaxSize = Vector2.new(380, 130)
	maxSize.Parent = panel

	panelTitle = Instance.new("TextLabel")
	panelTitle.Position = UDim2.fromOffset(14, 8)
	panelTitle.Size = UDim2.new(1, -90, 0, 22)
	panelTitle.BackgroundTransparency = 1
	panelTitle.Font = Enum.Font.GothamBlack
	panelTitle.TextSize = 16
	panelTitle.TextColor3 = GOLD
	panelTitle.TextXAlignment = Enum.TextXAlignment.Left
	panelTitle.Parent = panel

	panelText = Instance.new("TextLabel")
	panelText.Position = UDim2.fromOffset(14, 32)
	panelText.Size = UDim2.new(1, -28, 1, -40)
	panelText.BackgroundTransparency = 1
	panelText.Font = Enum.Font.GothamBold
	panelText.TextSize = 15
	panelText.TextColor3 = WHITE
	panelText.TextWrapped = true
	panelText.TextXAlignment = Enum.TextXAlignment.Left
	panelText.TextYAlignment = Enum.TextYAlignment.Top
	panelText.Parent = panel

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -10, 0, 8)
	skip.Size = UDim2.fromOffset(70, 22)
	skip.BackgroundColor3 = Color3.fromRGB(60, 64, 70)
	skip.Font = Enum.Font.GothamBold
	skip.TextSize = 13
	skip.TextColor3 = WHITE
	skip.Text = "Saltar"
	skip.Parent = panel
	local skipCorner = Instance.new("UICorner")
	skipCorner.CornerRadius = UDim.new(0, 6)
	skipCorner.Parent = skip
	skip.Activated:Connect(finishTutorial)

	-- Celular: los botones reales con su nombre, para aprender mirándolos
	if touch then
		controls = Instance.new("Frame")
		local row = controls :: Frame
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Position = UDim2.new(0.5, 0, 0, 194)
		row.Size = UDim2.fromOffset(340, 64)
		row.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
		row.BackgroundTransparency = 0.3
		row.Visible = false
		row.Parent = gui
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, 8)
		layout.Parent = row
		local items = {
			{ "Moverte", "stick" },
			{ "Disparar", "fire" },
			{ "Recargar", "reload" },
			{ "Cambiar", "swap" },
			{ "Saltar", "jump" },
		}
		for index, item in items do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromOffset(58, 58)
			cell.BackgroundTransparency = 1
			cell.LayoutOrder = index
			cell.Parent = row
			local disc = Instance.new("Frame")
			disc.AnchorPoint = Vector2.new(0.5, 0)
			disc.Position = UDim2.fromScale(0.5, 0)
			disc.Size = UDim2.fromOffset(38, 38)
			disc.Parent = cell
			local discCorner = Instance.new("UICorner")
			discCorner.CornerRadius = UDim.new(1, 0)
			discCorner.Parent = disc
			HudIcons.styleButton(disc, 1.2)
			local kind = item[2]
			if kind == "stick" then
				disc.BackgroundColor3 = Color3.fromRGB(70, 72, 76)
				local knob = Instance.new("Frame")
				knob.AnchorPoint = Vector2.new(0.5, 0.5)
				knob.Position = UDim2.fromScale(0.5, 0.5)
				knob.Size = UDim2.fromOffset(18, 18)
				knob.BackgroundColor3 = Color3.fromRGB(214, 214, 216)
				knob.Parent = disc
				local knobCorner = Instance.new("UICorner")
				knobCorner.CornerRadius = UDim.new(1, 0)
				knobCorner.Parent = knob
			elseif kind == "fire" then
				disc.BackgroundColor3 = Color3.fromRGB(40, 42, 46)
				HudIcons.fire(disc, 28)
			elseif kind == "reload" then
				HudIcons.reload(disc, 24)
			elseif kind == "swap" then
				HudIcons.swap(disc, 24)
			else
				HudIcons.jump(disc, 24)
			end
			local caption = Instance.new("TextLabel")
			caption.Position = UDim2.fromOffset(0, 40)
			caption.Size = UDim2.new(1, 0, 0, 16)
			caption.BackgroundTransparency = 1
			caption.Font = Enum.Font.GothamBold
			caption.TextSize = 12
			caption.TextColor3 = WHITE
			caption.Text = item[1]
			caption.Parent = cell
		end
	end
end

-- Lo llama el arma cada vez que le pega a un zombi
function Guide.onEnemyHit()
	if step == 2 then
		hits += 1
		if hits >= HITS_TO_LEARN then
			setStep(3)
		end
	end
end

local function startTutorialIfNew()
	local data = Profile.get()
	if data.Tutorial then
		return
	end
	-- Perfiles viejos (de antes del tutorial) que ya saben jugar: no lo ven
	if data.Level > 1 then
		saveTutorialDone()
		return
	end
	active = true
	step = 0
	hits = 0
	panel.Visible = true
	setStep(1)
	syncStepWithState()
end

function Guide.init()
	buildPanel()

	local map = workspace:WaitForChild("Map")
	for _, descendant in map:GetDescendants() do
		onPrompt(descendant)
	end
	map.DescendantAdded:Connect(onPrompt)
	RunService.RenderStepped:Connect(updateMarkers)

	-- Mientras se ve el aviso de E, el cartel con el nombre del NPC se oculta
	-- (el aviso ya dice quién es y qué vende)
	local function setTag(prompt: ProximityPrompt, visible: boolean)
		local npc = if prompt:GetAttribute("Shop") then prompt:FindFirstAncestorOfClass("Model") else nil
		local tag = npc and npc:FindFirstChild("NameTag")
		if tag and tag:IsA("BillboardGui") then
			tag.Enabled = visible
		end
	end
	ProximityPromptService.PromptShown:Connect(function(prompt)
		setTag(prompt, false)
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		setTag(prompt, true)
	end)

	ReplicatedStorage:WaitForChild("GameState"):GetAttributeChangedSignal("State"):Connect(syncStepWithState)

	if Profile.isLoaded() then
		startTutorialIfNew()
	else
		local connection
		connection = Profile.Changed:Connect(function()
			if Profile.isLoaded() then
				connection:Disconnect()
				startTutorialIfNew()
			end
		end)
	end
end

return Guide
