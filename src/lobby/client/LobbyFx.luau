-- Efectos del lobby que corren en cada cliente: viento que mece árboles,
-- estandartes y la campana, antorchas que parpadean, y hojas y luciérnagas
-- que se apagan en calidad baja (celulares modestos).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local FLICKER_TAG = "Flicker"
local LOW_QUALITY_LEVEL = 4
local SWAY_DISTANCE = 160
local SWAY_SPEED = 1.7
local UP = Vector3.new(0, 1, 0)

local LobbyFx = {}

type Swayer = { Part: BasePart, Base: CFrame, Pivot: Vector3, Amount: number, Seed: number }
local swayers: { Swayer } = {}
local lights: { PointLight } = {}
local emitters: { ParticleEmitter } = {}
local lowQuality = false
local baseWind = Config.Wind.Direction.Unit * Config.Wind.Speed
local gustLevel = 1

local function getQualityLevel(): number
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	if ok and level > 0 then
		return level
	end
	return if UserInputService.TouchEnabled then 3 else 7
end

local function applyQuality()
	lowQuality = getQualityLevel() <= LOW_QUALITY_LEVEL
	for _, emitter in emitters do
		emitter.Enabled = not lowQuality
	end
end

local function track(instance: Instance)
	if instance:IsA("ParticleEmitter") and instance.Name == "LeafEmitter" then
		table.insert(emitters, instance)
		instance.Enabled = not lowQuality
	elseif instance:IsA("BasePart") then
		local amount = instance:GetAttribute("Sway")
		local pivot = instance:GetAttribute("SwayPivot")
		if typeof(amount) == "number" and typeof(pivot) == "Vector3" then
			table.insert(swayers, { Part = instance, Base = instance.CFrame, Pivot = pivot, Amount = amount, Seed = pivot.X * 0.13 + pivot.Z * 0.07 })
		end
	end
end

local function updateSway(clock: number)
	local camera = workspace.CurrentCamera.CFrame.Position
	local axis = UP:Cross(Vector3.new(baseWind.X, 0, baseWind.Z).Unit)
	local parts, cframes = {}, {}
	for _, swayer in swayers do
		local offset = swayer.Pivot - camera
		if swayer.Part.Parent and offset.X * offset.X + offset.Z * offset.Z < SWAY_DISTANCE * SWAY_DISTANCE then
			local wave = math.sin(clock * SWAY_SPEED + swayer.Seed) * 0.5 + math.noise(clock * 0.6, swayer.Seed) * 0.5
			local lean = swayer.Amount * gustLevel * (0.55 + wave)
			table.insert(parts, swayer.Part)
			table.insert(cframes, CFrame.new(swayer.Pivot) * CFrame.fromAxisAngle(axis, lean) * CFrame.new(-swayer.Pivot) * swayer.Base)
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function flicker(clock: number)
	for index, light in lights do
		local base = light:GetAttribute("BaseBrightness") or 1
		light.Brightness = base * (0.82 + math.noise(clock * 7, index * 1.7) * 0.35)
	end
end

function LobbyFx.init()
	for _, light in CollectionService:GetTagged(FLICKER_TAG) do
		table.insert(lights, light)
	end
	CollectionService:GetInstanceAddedSignal(FLICKER_TAG):Connect(function(light)
		table.insert(lights, light)
	end)
	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		applyQuality()
		for _, descendant in map:GetDescendants() do
			track(descendant)
		end
		map.DescendantAdded:Connect(track)
	end)
	pcall(function()
		UserSettings():GetService("UserGameSettings"):GetPropertyChangedSignal("SavedQualityLevel"):Connect(applyQuality)
	end)

	local frame = 0
	RunService.RenderStepped:Connect(function()
		frame += 1
		local clock = os.clock()
		gustLevel = 1 + Config.Wind.Gusts * math.noise(clock * 0.15, 3.7)
		workspace.GlobalWind = baseWind * math.max(gustLevel, 0.2)
		if not lowQuality and frame % 2 == 0 then
			updateSway(clock)
			flicker(clock)
		end
	end)
end

return LobbyFx
