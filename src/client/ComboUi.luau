-- Combo de bajas: cada baja tuya suma si pasa menos de COMBO_WINDOW desde la
-- anterior. Sale un número grande a la izquierda del centro que se agranda y
-- se va al soltar el ritmo. A 10, 25 y 50 bajas seguidas sale una frase.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ComboUi = {}

local COMBO_WINDOW = 2.2
local MILESTONES = { [10] = "¡RACHA!", [25] = "¡IMPARABLE!", [50] = "¡LEYENDA!" }

local player = Players.LocalPlayer
local label: TextLabel
local sub: TextLabel
local count = 0
local lastKill = 0

local function pulse()
	label.TextSize = 38
	TweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextSize = 30 }):Play()
end

-- Se llama con la id del que mató a cada zombi
function ComboUi.onKill(killerUserId: number)
	if killerUserId ~= player.UserId then
		return
	end
	local now = os.clock()
	count = if now - lastKill <= COMBO_WINDOW then count + 1 else 1
	lastKill = now
	if count >= 3 then
		label.Visible = true
		label.Text = `x{count}`
		pulse()
		local text = MILESTONES[count]
		if text then
			sub.Text = text
			sub.Visible = true
		end
	end
end

function ComboUi.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Combo"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.62)
	label.Size = UDim2.fromOffset(160, 44)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 30
	label.TextColor3 = Color3.fromRGB(255, 225, 120)
	label.TextStrokeTransparency = 0.7
	label.Visible = false
	label.Parent = gui

	sub = Instance.new("TextLabel")
	sub.AnchorPoint = Vector2.new(0.5, 0.5)
	sub.Position = UDim2.fromScale(0.5, 0.69)
	sub.Size = UDim2.fromOffset(200, 26)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBlack
	sub.TextSize = 20
	sub.TextColor3 = Color3.fromRGB(255, 140, 80)
	sub.TextStrokeTransparency = 0.7
	sub.Visible = false
	sub.Parent = gui

	RunService.Heartbeat:Connect(function()
		if label.Visible and os.clock() - lastKill > COMBO_WINDOW then
			label.Visible = false
			sub.Visible = false
			count = 0
		elseif sub.Visible and os.clock() - lastKill > 1.2 then
			sub.Visible = false
		end
	end)
end

return ComboUi
