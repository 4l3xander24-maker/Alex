-- Números de daño que saltan sobre los enemigos al pegarles, con letra
-- pixelada (como en Guns 'n Goblins). Blancos al pegar, amarillos al matar.
-- Se reciclan para no crear y borrar etiquetas todo el tiempo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DamageNumbers = {}

local MAX_NUMBERS = 40
local LIFE = 0.75
local RISE = 3.2
local MAX_DISTANCE = 140
local HIT_COLOR = Color3.fromRGB(255, 255, 255)
local KILL_COLOR = Color3.fromRGB(255, 220, 80)

type Number = { Gui: BillboardGui, Label: TextLabel, Start: number, Origin: Vector3, Drift: number, Active: boolean }

local pool: { Number } = {}
local active: { Number } = {}
local holder: Part

local function create(): Number
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = MAX_DISTANCE
	gui.Adornee = holder
	gui.Enabled = false
	gui.Parent = holder
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Config.PixelFont
	label.TextScaled = true
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 28)
	label.Parent = gui
	return { Gui = gui, Label = label, Start = 0, Origin = Vector3.zero, Drift = 0, Active = false }
end

-- Muestra `amount` sobre `position`. Los decimales se redondean a uno.
function DamageNumbers.show(position: Vector3, amount: number, killed: boolean)
	local camera = workspace.CurrentCamera
	if (camera.CFrame.Position - position).Magnitude > MAX_DISTANCE then
		return
	end
	local number = table.remove(pool)
	if not number then
		if #active >= MAX_NUMBERS then
			return
		end
		number = create()
	end
	local rounded = math.floor(amount * 10 + 0.5) / 10
	number.Label.Text = if rounded == math.floor(rounded) then tostring(math.floor(rounded)) else string.format("%.1f", rounded)
	number.Label.TextColor3 = if killed then KILL_COLOR else HIT_COLOR
	number.Start = os.clock()
	number.Origin = position
	number.Drift = math.random() * 2 - 1
	number.Active = true
	number.Gui.Size = if killed then UDim2.fromOffset(110, 48) else UDim2.fromOffset(90, 40)
	number.Gui.Enabled = true
	table.insert(active, number)
end

local function step()
	local now = os.clock()
	local index = 1
	while index <= #active do
		local number = active[index]
		local age = (now - number.Start) / LIFE
		if age >= 1 then
			number.Gui.Enabled = false
			number.Active = false
			table.insert(pool, number)
			active[index] = active[#active]
			active[#active] = nil
			continue
		end
		-- Salta rápido y frena, se corre un poco al costado y se desvanece al final
		local rise = (1 - (1 - age) * (1 - age)) * RISE
		number.Gui.StudsOffsetWorldSpace = number.Origin + Vector3.new(number.Drift * age * 1.5, rise, 0)
		local fade = if age > 0.6 then (age - 0.6) / 0.4 else 0
		number.Label.TextTransparency = fade
		number.Label.TextStrokeTransparency = fade
		index += 1
	end
end

function DamageNumbers.init()
	holder = Instance.new("Part")
	holder.Name = "DamageNumbers"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one * 0.1
	holder.CFrame = CFrame.new()
	holder.Parent = workspace
	RunService.RenderStepped:Connect(step)
end

return DamageNumbers
