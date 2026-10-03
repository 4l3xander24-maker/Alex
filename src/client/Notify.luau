-- Mensajes cortos arriba de la pantalla ("¡Compraste Escopeta!", etc.)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

local DURATION = 3
local MAX_VISIBLE = 4

local Notify = {}

local holder: Frame

function Notify.show(text: string, color: Color3?)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromOffset(520, 30)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
	label.BackgroundTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextSize = 17
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.Text = text
	label.LayoutOrder = math.floor(os.clock() * 1000)
	label.Parent = holder
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	local labels = {}
	for _, child in holder:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels > MAX_VISIBLE then
		table.sort(labels, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		labels[1]:Destroy()
	end

	task.delay(DURATION, function()
		if label.Parent then
			local tween = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 })
			tween.Completed:Once(function()
				label:Destroy()
			end)
			tween:Play()
		end
	end)
end

function Notify.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Notify"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20

	holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.Position = UDim2.new(0.5, 0, 0, 104)
	holder.Size = UDim2.fromOffset(520, 160)
	holder.BackgroundTransparency = 1
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = holder

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	Remotes.Notify.OnClientEvent:Connect(function(text)
		Notify.show(text)
	end)
end

return Notify
