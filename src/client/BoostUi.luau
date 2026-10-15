-- Potenciadores: fichas pequeñas en la esquina de arriba a la derecha, debajo de
-- la hora, para no tapar la vista. Los de duración (Daño x2, Escudo) muestran
-- la cuenta regresiva; los instantáneos (munición, curación, monedas) salen unos
-- segundos y se van.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Sfx = require(script.Parent.Sfx)

local BoostUi = {}

local INSTANT_TIME = 3

type Chip = { Frame: Frame, Label: TextLabel, EndTime: number, Timed: boolean }

local player = Players.LocalPlayer
local chips: { [string]: Chip } = {}
local holder: Frame

local function makeChip(name: string, info, endTime: number, timed: boolean)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(132, 24)
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	frame.BackgroundTransparency = 0.3
	frame.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = info.Color
	stroke.Thickness = 1.2
	stroke.Transparency = 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = frame
	chips[name] = { Frame = frame, Label = label, EndTime = endTime, Timed = timed }
end

function BoostUi.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Boosts"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 6
	gui.Parent = player:WaitForChild("PlayerGui")

	holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(1, 0)
	holder.Position = UDim2.new(1, -16, 0, if UserInputService.TouchEnabled then 76 else 92)
	holder.Size = UDim2.fromOffset(132, 120)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding = UDim.new(0, 4)
	layout.Parent = holder

	Remotes.Boost.OnClientEvent:Connect(function(name: string, duration: number)
		local info = Config.Powerups.Types[name]
		if not info then
			return
		end
		Sfx.play("Powerup")
		local timed = duration > 0
		local endTime = workspace:GetServerTimeNow() + (if timed then duration else INSTANT_TIME)
		local chip = chips[name]
		if chip then
			chip.EndTime = endTime
		else
			makeChip(name, info, endTime, timed)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		for name, chip in chips do
			local left = chip.EndTime - now
			local info = Config.Powerups.Types[name]
			if left <= 0 then
				chip.Frame:Destroy()
				chips[name] = nil
			elseif chip.Timed then
				chip.Label.Text = `{info.Icon} {info.Name} {math.ceil(left)}s`
			else
				chip.Label.Text = `{info.Icon} {info.Name}`
			end
		end
	end)
end

return BoostUi
