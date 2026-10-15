-- Pantalla de fin de partida: oleadas, bajas, monedas, la XP de cuenta ganada
-- y la tabla de todo el equipo. Si subiste de nivel, un botón abre el panel de
-- mejoras y talentos (y se abre solo al cerrar el resumen si quedan puntos).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local Profile = require(script.Parent.Profile)
local ShopUI = require(script.Parent.ShopUI)

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

-- Tabla del equipo: una fila por jugador, la tuya resaltada
local function teamTable(team)
	if #team == 0 then
		return
	end
	local me = Players.LocalPlayer.UserId
	local columns = { { "Jugador", 0.4 }, { "🧟", 0.14 }, { "💀", 0.12 }, { "💰", 0.17 }, { "⭐ XP", 0.17 } }
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -40, 0, 26 * (#team + 1) + 8)
	frame.BackgroundColor3 = Color3.fromRGB(14, 16, 18)
	frame.BackgroundTransparency = 0.2
	frame.LayoutOrder = nextOrder()
	frame.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	local function line(index: number, values: { string }, color: Color3, highlight: boolean)
		local x = 0
		if highlight then
			local back = Instance.new("Frame")
			back.Position = UDim2.fromOffset(4, 4 + index * 26)
			back.Size = UDim2.new(1, -8, 0, 24)
			back.BackgroundColor3 = GOLD
			back.BackgroundTransparency = 0.82
			back.BorderSizePixel = 0
			back.Parent = frame
		end
		for column, info in columns do
			local cell = Instance.new("TextLabel")
			cell.Position = UDim2.new(x, 10, 0, 4 + index * 26)
			cell.Size = UDim2.new(info[2], -10, 0, 24)
			cell.BackgroundTransparency = 1
			cell.Font = if index == 0 then Enum.Font.GothamBlack else Enum.Font.GothamBold
			cell.TextSize = 15
			cell.TextColor3 = color
			cell.TextXAlignment = if column == 1 then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			cell.TextTruncate = Enum.TextTruncate.AtEnd
			cell.Text = values[column]
			cell.ZIndex = 2
			cell.Parent = frame
			x += info[2]
		end
	end
	local header = {}
	for _, info in columns do
		table.insert(header, info[1])
	end
	line(0, header, Color3.fromRGB(180, 180, 190), false)
	for index, row in team do
		local medal = if index == 1 then "🥇 " elseif index == 2 then "🥈 " elseif index == 3 then "🥉 " else ""
		line(index, { medal .. row.Name, tostring(row.Kills), tostring(row.BossKills), tostring(row.Coins), tostring(row.Xp) }, Color3.new(1, 1, 1), row.UserId == me)
	end
end

-- Abre el panel de talentos encima; si la votación sigue, el resumen vuelve
-- al cerrarlo para poder votar
local function openTalents()
	local thisShow = showCount
	gui.Enabled = false
	ShopUI.open("Trainer")
	task.spawn(function()
		while ShopUI.isOpen() and showCount == thisShow do
			task.wait(0.2)
		end
		local state = ReplicatedStorage:FindFirstChild("GameState")
		if showCount == thisShow and state and state:GetAttribute("Vote") == true then
			gui.Enabled = true
		end
	end)
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
	makeLabel(panel, `💰 +{summary.Coins} monedas     ⭐ +{summary.Xp} XP de cuenta`, 20, GOLD)
	teamTable(summary.Team or {})

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
	local hasPoints = summary.StatPoints > 0 or summary.TalentPoints > 0
	if hasPoints then
		makeLabel(panel, `⭐ Tienes {summary.StatPoints} punto(s) de mejora y {summary.TalentPoints} de talento: al elegir Reintentar los repartes.`, 16, GOLD, 44)
	end

	-- Dos botones: Reintentar de nuevo o Volver al lobby. No hay cuenta
	-- regresiva: la partida sigue cuando todos eligieron.
	local state = ReplicatedStorage:FindFirstChild("GameState")
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
			if myVote then
				return -- ya eligió
			end
			myVote = choice
			Remotes.Vote:FireServer(choice)
			for name, other in buttons do
				other.BackgroundTransparency = if name == choice then 0 else 0.55
			end
			-- Al reintentar con puntos nuevos, sale el panel de habilidades
			local points = Profile.get()
			if choice == "Retry" and (points.StatPoints > 0 or points.TalentPoints > 0) then
				openTalents()
			end
		end)
		buttons[choice] = button
	end
	makeButton("Retry", "🔄 Reintentar de nuevo", GOLD)
	makeButton("Lobby", "🏰 Volver al lobby", Color3.fromRGB(150, 200, 255))

	gui.Enabled = true
	showCount += 1
	local thisShow = showCount
	-- Los votos se leen de GameState; al terminar la votación se cierra
	task.spawn(function()
		local seenVote = false
		local started = os.clock()
		while showCount == thisShow do
			local voting = state ~= nil and state:GetAttribute("Vote") == true
			if voting then
				seenVote = true
				local counts = `🔄 {state:GetAttribute("VoteRetry") or 0}   🏰 {state:GetAttribute("VoteLobby") or 0}`
				voteLabel.Text = `{if myVote then "Elegiste. Esperando a los demás… " else "Elige: "}{counts}`
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

	-- En pantallas bajas (celular acostado) el panel se achica para que entre
	local fit = Instance.new("UIScale")
	fit.Parent = panel
	local function refit()
		local height = workspace.CurrentCamera.ViewportSize.Y
		local needed = panel.AbsoluteSize.Y / math.max(fit.Scale, 0.01)
		fit.Scale = if needed > 0 then math.clamp((height - 24) / needed, 0.55, 1) else 1
	end
	panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refit)
	end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	Remotes.MatchSummary.OnClientEvent:Connect(function(summary)
		-- Esperamos el perfil actualizado (llega junto con la XP)
		task.wait(0.2)
		show(summary)
	end)
end

return MatchSummary
