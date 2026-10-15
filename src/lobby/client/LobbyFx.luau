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
	-- Las hojas se ajustan solas en el bucle (updateLeaves)
end

local function track(instance: Instance)
	if instance:IsA("ParticleEmitter") and instance.Name == "LeafEmitter" then
		table.insert(emitters, instance)
		instance.Enabled = false -- updateLeaves lo prende si está cerca
	elseif instance:IsA("BasePart") then
		local amount = instance:GetAttribute("Sway")
		local pivot = instance:GetAttribute("SwayPivot")
		if typeof(amount) == "number" and typeof(pivot) == "Vector3" then
			table.insert(swayers, { Part = instance, Base = instance.CFrame, Pivot = pivot, Amount = amount, Seed = pivot.X * 0.13 + pivot.Z * 0.07 })
		end
	end
end

-- Hojas que caen: solo cerca de la cámara (hay cientos de árboles) y con más
-- fuerza en las ráfagas. En calidad baja, apagadas.
local LEAF_DISTANCE = 170
local function updateLeaves()
	local camera = workspace.CurrentCamera.CFrame.Position
	local index = 1
	while index <= #emitters do
		local emitter = emitters[index]
		local box = emitter.Parent
		if not box then
			emitters[index] = emitters[#emitters]
			emitters[#emitters] = nil
			continue
		end
		-- En calidad baja (celulares) caen solo las de los árboles más cercanos
		local range = if lowQuality then LEAF_DISTANCE * 0.45 else LEAF_DISTANCE
		local near = box:IsA("BasePart") and (box.Position - camera).Magnitude < range
		if emitter.Enabled ~= near then
			emitter.Enabled = near
		end
		if near then
			local base = emitter:GetAttribute("BaseRate") or emitter.Rate
			emitter.Rate = base * math.clamp(gustLevel * gustLevel, 0.4, 2.5) * (if lowQuality then 0.6 else 1)
		end
		index += 1
	end
end

local function updateSway(clock: number)
	local camera = workspace.CurrentCamera.CFrame.Position
	-- En calidad baja (celulares) igual se mecen, pero solo los cercanos
	local swayRange = if lowQuality then SWAY_DISTANCE * 0.5 else SWAY_DISTANCE
	local windward = Vector3.new(baseWind.X, 0, baseWind.Z).Unit
	local axis = UP:Cross(windward)
	local parts, cframes = {}, {}
	for _, swayer in swayers do
		local offset = swayer.Pivot - camera
		if swayer.Part.Parent and offset.X * offset.X + offset.Z * offset.Z < swayRange * swayRange then
			local wave = math.sin(clock * SWAY_SPEED + swayer.Seed) * 0.5 + math.noise(clock * 0.6, swayer.Seed) * 0.5
			local lean = swayer.Amount * gustLevel * (0.55 + wave)
			table.insert(parts, swayer.Part)
			table.insert(cframes, CFrame.new(swayer.Pivot) * CFrame.fromAxisAngle(axis, lean) * CFrame.fromAxisAngle(windward, math.sin(clock * SWAY_SPEED * 2.3 + swayer.Seed * 1.7) * swayer.Amount * 0.35 * gustLevel) * CFrame.new(-swayer.Pivot) * swayer.Base)
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
		if frame % 20 == 0 then
			updateLeaves()
		end
		if not lowQuality and frame % 2 == 0 then
			updateSway(clock)
			flicker(clock)
		elseif lowQuality and frame % 3 == 0 then
			updateSway(clock)
		end
	end)
end

return LobbyFx
