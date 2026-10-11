-- Pantalla de fin de partida: oleadas, bajas, monedas y la XP de cuenta ganada.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local Profile = require(script.Parent.Profile)

local GOLD = Color3.fromRGB(255, 215, 100)
local AUTO_CLOSE = 14

local MatchSummary = {}

local gui: ScreenGui
local panel: Frame
local showCount = 0
local order = 0

-- UIListLayout ordena por LayoutOrder: numeramos cada elemento al crearlo
local function nextOrder(): number
	order += 1
	return order
end

local function makeLabel(parent: Instance, text: string, size: number, color: Color3?, height: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -40, 0, height or size + 10)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = size
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextWrapped = true
	label.Text = text
	label.LayoutOrder = nextOrder()
	label.Parent = parent
	return label
end

local function hide()
	gui.Enabled = false
end

local function show(summary)
	for _, child in panel:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
			child:Destroy()
		end
	end

	local gameState = game:GetService("ReplicatedStorage"):FindFirstChild("GameState")
	local dead = gameState ~= nil and gameState:GetAttribute("EndReason") == "Dead"
	makeLabel(panel, if dead then "¡CAÍSTE!" else "¡LA CAMPANA CAYÓ!", 32, Color3.fromRGB(255, 90, 80))
	makeLabel(panel, `Llegaste a la oleada {summary.Wave}`, 20)
	makeLabel(panel, `🌊 Oleadas superadas: {summary.Waves}     🧟 Bajas: {summary.Kills}     💀 Jefes: {summary.BossKills}`, 17, nil, 26)
	if summary.NewRecord then
		local beaten = if summary.PreviousBest > 0 then ` (antes {summary.PreviousBest})` else ""
		makeLabel(panel, `🏆 ¡NUEVO RÉCORD! {summary.BestWave} oleadas{beaten}`, 24, GOLD)
	elseif summary.BestWave and summary.BestWave > 0 then
		makeLabel(panel, `🏆 Tu récord: {summary.BestWave} oleadas`, 17)
	end
	makeLabel(panel, `🪙 +{summary.Coins} monedas`, 20, GOLD)
	makeLabel(panel, `⭐ +{summary.Xp} XP de cuenta`, 24, Color3.fromRGB(120, 200, 255))

	local data = Profile.get()
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -80, 0, 14)
	bar.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
	bar.BorderSizePixel = 0
	bar.LayoutOrder = nextOrder()
	bar.Parent = panel
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(math.clamp(data.Xp / Progression.xpNeeded(data.Level), 0, 1), 1)
	fill.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	makeLabel(panel, `Nivel {summary.Level}  ·  {data.Xp} / {Progression.xpNeeded(data.Level)} XP`, 15)

	if summary.Levels > 0 then
		makeLabel(panel, `🎉 ¡Subiste {summary.Levels} nivel{if summary.Levels > 1 then "es" else ""}!`, 24, GOLD)
	end
	if summary.StatPoints > 0 or summary.TalentPoints > 0 then
		makeLabel(panel, `Tienes {summary.StatPoints} punto(s) de mejora y {summary.TalentPoints} de talento. Gástalos con Don Ramiro, el Veterano.`, 16, nil, 44)
	end

	-- Votación: Reintentar o Volver al lobby (el lobby solo si vinieron de una sala)
	local state = ReplicatedStorage:FindFirstChild("GameState")
	local canLobby = state ~= nil and state:GetAttribute("VoteCanLobby") == true
	local row = Instance.new("Frame")
	row.Size = UDim2.fromOffset(440, 46)
	row.BackgroundTransparency = 1
	row.LayoutOrder = nextOrder()
	row.Parent = panel
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.Padding = UDim.new(0, 12)
	rowLayout.Parent = row
	local voteLabel = makeLabel(panel, "", 15, Color3.fromRGB(200, 200, 200), 22)
	local myVote: string? = nil
	local buttons: { [string]: TextButton } = {}
	local function makeButton(choice: string, text: string, color: Color3)
		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(200, 44)
		button.BackgroundColor3 = color
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 18
		button.TextColor3 = Color3.fromRGB(30, 24, 10)
		button.Text = text
		-- Modal libera el mouse en primera persona
		button.Modal = true
		button.Parent = row
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = button
		button.Activated:Connect(function()
			myVote = choice
			Remotes.Vote:FireServer(choice)
			for name, other in buttons do
				other.BackgroundTransparency = if name == choice then 0 else 0.55
			end
		end)
		buttons[choice] = button
	end
	makeButton("Retry", "🔄 Reintentar", GOLD)
	if canLobby then
		makeButton("Lobby", "🏰 Volver al lobby", Color3.fromRGB(150, 200, 255))
	end

	gui.Enabled = true
	showCount += 1
	local thisShow = showCount
	-- La cuenta y los votos se leen de GameState; al terminar la votación se cierra
	task.spawn(function()
		local seenVote = false
		local started = os.clock()
		while showCount == thisShow and gui.Enabled do
			local voting = state ~= nil and state:GetAttribute("Vote") == true
			if voting then
				seenVote = true
				local left = math.max(0, math.ceil((state:GetAttribute("VoteEnds") or 0) - workspace:GetServerTimeNow()))
				local counts = `🔄 {state:GetAttribute("VoteRetry") or 0}`
				if canLobby then
					counts ..= `   🏰 {state:GetAttribute("VoteLobby") or 0}`
				end
				voteLabel.Text = `{if myVote then "Votaste. " else "Elige: "}{counts}   ·   ⏳ {left} s`
			elseif seenVote or os.clock() - started > AUTO_CLOSE then
				hide()
				break
			end
			task.wait(0.2)
		end
	end)
end

function MatchSummary.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "MatchSummary"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 15
	gui.Enabled = false

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(560, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.fromRGB(24, 28, 30)
	panel.BackgroundTransparency = 0.08
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = GOLD
	stroke.Thickness = 2
	stroke.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 18)
	padding.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	Remotes.MatchSummary.OnClientEvent:Connect(function(summary)
		-- Esperamos el perfil actualizado (llega junto con la XP)
		task.wait(0.2)
		show(summary)
	end)
end

return MatchSummary
