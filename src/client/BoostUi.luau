-- Potenciadores: aviso al conseguir uno y una ficha con cuenta regresiva en
-- el centro de la pantalla mientras dura (Daño x2, Escudo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Notify = require(script.Parent.Notify)

local BoostUi = {}

local player = Players.LocalPlayer
local chips: { [string]: { Frame: Frame, Label: TextLabel, EndTime: number } } = {}
local holder: Frame

local function addChip(name: string, info, duration: number)
	local chip = chips[name]
	if chip then
		chip.EndTime = workspace:GetServerTimeNow() + duration
		return
	end
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(112, 34)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	frame.BackgroundTransparency = 0.2
	frame.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = info.Color
	stroke.Thickness = 2
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 16
	label.TextColor3 = info.Color
	label.Parent = frame
	chips[name] = { Frame = frame, Label = label, EndTime = workspace:GetServerTimeNow() + duration }
	
end

function BoostUi.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Boosts"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -150)
	holder.Size = UDim2.fromOffset(260, 34)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = holder

	Remotes.Boost.OnClientEvent:Connect(function(name: string, duration: number)
		local info = Config.Powerups.Types[name]
		if not info then
			return
		end
		Notify.show(`{info.Icon} ¡{info.Name}!`, info.Color)
		if duration > 0 then
			addChip(name, info, duration)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for name, chip in chips do
			local left = chip.EndTime - now
			if left <= 0 then
				chip.Frame:Destroy()
				chips[name] = nil
			else
				chip.Label.Text = `{Config.Powerups.Types[name].Icon} {math.ceil(left)}s`
			end
		end
	end)
end

return BoostUi
