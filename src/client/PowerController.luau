-- Poderes: lee las teclas, lleva el enfriamiento local y dibuja los efectos
-- que manda el servidor (para que todos los jugadores los vean).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Upgrades = require(Shared.Upgrades)
local Viewmodel = require(script.Parent.Viewmodel)

local EXPLOSION_COLOR = Color3.fromRGB(255, 140, 50)
local LIGHTNING_COLOR = Color3.fromRGB(140, 220, 255)
local BELL_COLOR = Color3.fromRGB(255, 215, 100)
local GRENADE_COLOR = Color3.fromRGB(60, 80, 50)

local player = Players.LocalPlayer

local PowerController = {}

local readyAt: { [string]: number } = {}
local totalCooldown: { [string]: number } = {}

local fxFolder = Instance.new("Folder")
fxFolder.Name = "PowerFx"
fxFolder.Parent = workspace

local function newFxPart(size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = fxFolder
	return part
end

local function fadeOut(part: BasePart, duration: number, goal: { [string]: any })
	goal.Transparency = 1
	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(part, duration)
end

local function flashLight(position: Vector3, color: Color3, range: number, duration: number)
	local holder = newFxPart(Vector3.one * 0.1, color)
	holder.Transparency = 1
	holder.Position = position
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = 4
	light.Parent = holder
	TweenService:Create(light, TweenInfo.new(duration), { Brightness = 0 }):Play()
	Debris:AddItem(holder, duration)
end

local function explosion(position: Vector3, radius: number)
	local ball = newFxPart(Vector3.one * 2, EXPLOSION_COLOR)
	ball.Shape = Enum.PartType.Ball
	ball.Position = position + Vector3.new(0, 1, 0)
	fadeOut(ball, 0.35, { Size = Vector3.one * radius * 2 })
	flashLight(position + Vector3.new(0, 3, 0), EXPLOSION_COLOR, radius * 3, 0.4)
end

local function grenadeFx(origin: Vector3, target: Vector3, radius: number, flightTime: number)
	local grenade = newFxPart(Vector3.one * 0.7, GRENADE_COLOR)
	grenade.Shape = Enum.PartType.Ball
	grenade.Material = Enum.Material.SmoothPlastic
	local start = os.clock()
	local arcHeight = math.max(6, (target - origin).Magnitude * 0.25)
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local alpha = math.min((os.clock() - start) / flightTime, 1)
		grenade.Position = origin:Lerp(target, alpha) + Vector3.new(0, math.sin(alpha * math.pi) * arcHeight, 0)
		if alpha >= 1 then
			connection:Disconnect()
			grenade:Destroy()
			explosion(target, radius)
		end
	end)
end

-- Rayo zigzagueante entre cada par de puntos
local function chainFx(points: { Vector3 })
	for index = 1, #points - 1 do
		local from, to = points[index], points[index + 1]
		local previous = from
		local segments = 6
		for step = 1, segments do
			local point = from:Lerp(to, step / segments)
			if step < segments then
				point += Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2.5
			end
			local length = (point - previous).Magnitude
			local bolt = newFxPart(Vector3.new(0.25, 0.25, length), LIGHTNING_COLOR)
			bolt.CFrame = CFrame.lookAt(previous, point) * CFrame.new(0, 0, -length / 2)
			fadeOut(bolt, 0.25, {})
			previous = point
		end
		flashLight(to, LIGHTNING_COLOR, 12, 0.25)
	end
end

local function bellFx(center: Vector3, radius: number)
	local ring = newFxPart(Vector3.new(0.4, 2, 2), BELL_COLOR)
	ring.Shape = Enum.PartType.Cylinder
	ring.Transparency = 0.3
	ring.CFrame = CFrame.new(center + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	fadeOut(ring, 0.6, { Size = Vector3.new(0.4, radius * 2, radius * 2) })

	local bell = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Bell")
	if bell then
		flashLight(bell:GetPivot().Position, BELL_COLOR, 40, 0.8)
	end
end

local fxHandlers = {
	Grenade = grenadeFx,
	Chain = chainFx,
	Bell = bellFx,
}

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

function PowerController.getLevel(name: string): number
	return player:GetAttribute("Power_" .. name) or 0
end

function PowerController.use(name: string)
	local level = PowerController.getLevel(name)
	if level < 1 or os.clock() < (readyAt[name] or 0) or not isAlive() then
		return
	end
	local stats = Upgrades.getPowerStats(name, level)
	readyAt[name] = os.clock() + stats.Cooldown
	totalCooldown[name] = stats.Cooldown

	local cameraCFrame = workspace.CurrentCamera.CFrame
	Remotes.UsePower:FireServer(name, cameraCFrame.Position, cameraCFrame.LookVector, workspace:GetServerTimeNow())
	Viewmodel.kick()
end

-- Segundos que faltan y duración total del enfriamiento
function PowerController.getCooldown(name: string): (number, number)
	local remaining = math.max(0, (readyAt[name] or 0) - os.clock())
	return remaining, totalCooldown[name] or 1
end

function PowerController.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		for name, power in Config.Powers do
			if input.KeyCode == power.Key then
				PowerController.use(name)
			end
		end
	end)

	player:GetAttributeChangedSignal("RunId"):Connect(function()
		table.clear(readyAt)
	end)

	Remotes.PowerFx.OnClientEvent:Connect(function(kind, ...)
		local handler = fxHandlers[kind]
		if handler then
			handler(...)
		end
	end)
end

return PowerController
