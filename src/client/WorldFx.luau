-- Detalles del mundo que corren solo en cada cliente:
--   * Gira las aspas del molino (no gasta red: cada jugador las mueve en su pantalla).
--   * Hace parpadear la luz de velas y antorchas (solo en calidad alta) y la
--     baja de día. Hace bailar los cubitos de la fogata en pixel art 3D.
--   * Corre el cielo (SkyFx): ciclo de día y noche, nubes y luciérnagas.
--   * Viento: ráfagas que mueven el pasto 3D del terreno, y árboles, arbustos,
--     matas y estandartes que se mecen (solo los cercanos y en calidad alta).
--   * Adapta los efectos a la calidad gráfica del jugador: en calidad baja o
--     en celulares apaga el desenfoque, los rayos de sol y baja las partículas.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SkyFx = require(script.Parent.SkyFx)

local BLADE_SPEED = 0.45 -- vueltas por segundo en radianes
local LOW_QUALITY_LEVEL = 4 -- calidad 1-4 de 10 = equipo modesto
local CULL_DISTANCE = 230 -- en equipos modestos, árboles y plantas más lejos que esto no se dibujan
local FLICKER_TAG = "Flicker"
local FLICKER_SPEED = 7
local SWAY_DISTANCE = 160 -- más lejos no se nota que se mueven
local SWAY_SPEED = 1.7
local UP = Vector3.new(0, 1, 0)

local WorldFx = {}

local blades: Model? = nil
local bladesPivot: CFrame? = nil
local bladeAngle = 0
local lowQuality = false
local flickerLights: { PointLight } = {}
local flames: { BasePart } = {}
local flameBase: { [BasePart]: CFrame } = {}
local lastDayDim = 0
local ambientEmitter: ParticleEmitter? = nil

type Swayer = { Part: BasePart, Base: CFrame, Pivot: Vector3, Amount: number, Seed: number, Hidden: boolean? }
local swayers: { Swayer } = {}
-- Hojas que caen de los árboles (se apagan en calidad baja)
local leafEmitters: { ParticleEmitter } = {}
local baseWind = Config.Wind.Direction.Unit * Config.Wind.Speed
local gustLevel = 1

local function findBlades()
	local map = workspace:FindFirstChild("Map")
	local model = map and map:FindFirstChild("WindmillBlades")
	if model and model:IsA("Model") and model.PrimaryPart then
		blades = model
		bladesPivot = model:GetPivot()
	end
end

-- Nivel de calidad gráfica que eligió el jugador (1 a 10). En "Automático"
-- Roblox no dice el nivel real, así que en celular asumimos uno bajo.
local function getQualityLevel(): number
	-- Ajuste manual del menú (Auto, Bajo o Alto)
	local override = Players.LocalPlayer:GetAttribute("QualityMode")
	if override == "Low" then
		return 1
	elseif override == "High" then
		return 10
	end
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	end)
	if ok and level > 0 then
		return level
	end
	return if UserInputService.TouchEnabled then 3 else 7
end

local function applyQuality()
	local low = getQualityLevel() <= LOW_QUALITY_LEVEL
	lowQuality = low
	for _, effect in Lighting:GetChildren() do
		if effect:IsA("DepthOfFieldEffect") or effect:IsA("SunRaysEffect") then
			effect.Enabled = not low
		elseif effect:IsA("BloomEffect") then
			effect.Size = if low then 16 else 30
			effect.Enabled = not low
		end
	end
	-- Equipos modestos: sin pasto 3D, sin sombras en tiempo real y sin lo lejano
	pcall(function()
		workspace.Terrain.Decoration = not low
	end)
	Lighting.GlobalShadows = not low
	if not low then
		for _, swayer in swayers do
			if swayer.Hidden then
				swayer.Part.LocalTransparencyModifier = 0
				swayer.Hidden = false
			end
		end
	end
	local map = workspace:FindFirstChild("Map")
	local ambient = map and map:FindFirstChild("AmbientParticles")
	local emitter = ambient and ambient:FindFirstChild("AmbientEmitter")
	if emitter and emitter:IsA("ParticleEmitter") then
		ambientEmitter = emitter
		emitter.Enabled = not low
	end
	-- Las hojas se ajustan solas en el bucle (updateLeaves)
	SkyFx.setReduced(low)
end

-- Calidad baja: oculta árboles y plantas lejanos (no se ven ni se dibujan)
local function cullFar()
	local camera = workspace.CurrentCamera.CFrame.Position
	local limit = CULL_DISTANCE * CULL_DISTANCE
	for _, swayer in swayers do
		local part = swayer.Part
		if part.Parent then
			local offset = swayer.Pivot - camera
			local far = offset.X * offset.X + offset.Z * offset.Z > limit
			if far ~= (swayer.Hidden == true) then
				swayer.Hidden = far
				part.LocalTransparencyModifier = if far then 1 else 0
			end
		end
	end
end

-- Las luciérnagas de partículas (estilo realista) solo salen de noche
local function updateAmbient()
	local emitter = ambientEmitter
	if emitter and emitter.Parent and emitter.LightEmission > 0 then
		local wanted = not lowQuality and SkyFx.getNightFactor() > 0.5
		if emitter.Enabled ~= wanted then
			emitter.Enabled = wanted
		end
	end
end

local function trackSway(instance: Instance)
	if instance:IsA("ParticleEmitter") and instance.Name == "LeafEmitter" then
		table.insert(leafEmitters, instance)
		instance.Enabled = false -- updateLeaves lo prende si está cerca
		return
	end
	if instance:IsA("BasePart") then
		local amount = instance:GetAttribute("Sway")
		local pivot = instance:GetAttribute("SwayPivot")
		if typeof(amount) == "number" and typeof(pivot) == "Vector3" then
			table.insert(swayers, {
				Part = instance,
				Base = instance.CFrame,
				Pivot = pivot,
				Amount = amount,
				Seed = pivot.X * 0.13 + pivot.Z * 0.07,
			})
		end
	end
end

-- Ráfagas: el viento sube y baja suave. El pasto 3D del terreno lo sigue solo.
local function updateWind(clock: number)
	gustLevel = 1 + Config.Wind.Gusts * math.noise(clock * 0.15, 3.7)
	workspace.GlobalWind = baseWind * math.max(gustLevel, 0.2)
end

-- Cada pieza gira un poquito alrededor de su base hacia donde sopla el viento
-- Hojas que caen: solo cerca de la cámara (hay cientos de árboles) y con más
-- fuerza en las ráfagas. En calidad baja, apagadas.
local LEAF_DISTANCE = 170
local function updateLeaves()
	local camera = workspace.CurrentCamera.CFrame.Position
	local index = 1
	while index <= #leafEmitters do
		local emitter = leafEmitters[index]
		local box = emitter.Parent
		if not box then
			leafEmitters[index] = leafEmitters[#leafEmitters]
			leafEmitters[#leafEmitters] = nil
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
	local direction = Vector3.new(baseWind.X, 0, baseWind.Z).Unit
	local windward = direction
	local axis = UP:Cross(direction) -- girar sobre este eje inclina la punta a favor del viento
	local parts, cframes = {}, {}
	local index = 1
	while index <= #swayers do
		local swayer = swayers[index]
		local part = swayer.Part
		if not part.Parent then
			-- Con StreamingEnabled la pieza pudo descargarse (vuelve a entrar como nueva)
			swayers[index] = swayers[#swayers]
			swayers[#swayers] = nil
			continue
		end
		local pivot = swayer.Pivot
		local offset = pivot - camera
		if offset.X * offset.X + offset.Z * offset.Z < swayRange * swayRange then
			local wave = math.sin(clock * SWAY_SPEED + swayer.Seed) * 0.5 + math.noise(clock * 0.6, swayer.Seed) * 0.5
			local lean = swayer.Amount * gustLevel * (0.55 + wave)
			table.insert(parts, part)
			table.insert(cframes, CFrame.new(pivot) * CFrame.fromAxisAngle(axis, lean) * CFrame.fromAxisAngle(windward, math.sin(clock * SWAY_SPEED * 2.3 + swayer.Seed * 1.7) * swayer.Amount * 0.35 * gustLevel) * CFrame.new(-pivot) * swayer.Base)
		end
		index += 1
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function trackFlame(instance: Instance)
	if instance:IsA("BasePart") and instance:GetAttribute("Dance") then
		table.insert(flames, instance)
		flameBase[instance] = instance.CFrame
	end
end

-- Los cubitos del fuego se mueven un poco y giran, como llamas pixeladas
local function danceFlames(clock: number)
	local parts, cframes = {}, {}
	for _, flame in flames do
		local base = flameBase[flame]
		if flame.Parent and base then
			local index = flame:GetAttribute("Dance") or 1
			local wobble = Vector3.new(math.noise(clock * 3, index) * 0.25, math.noise(index, clock * 4) * 0.3, math.noise(clock * 3, index + 7) * 0.25)
			table.insert(parts, flame)
			table.insert(cframes, base * CFrame.new(wobble) * CFrame.Angles(0, clock * (1 + index * 0.4), 0))
		end
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function trackFlicker(instance: Instance)
	if instance:IsA("PointLight") then
		table.insert(flickerLights, instance)
	end
end

-- Cada luz parpadea a su ritmo con ruido suave, como una llama
local function flicker(clock: number)
	local index = 1
	while index <= #flickerLights do
		local light = flickerLights[index]
		if not light.Parent then
			-- Con StreamingEnabled la luz pudo descargarse
			flickerLights[index] = flickerLights[#flickerLights]
			flickerLights[#flickerLights] = nil
			continue
		end
		local base = (light:GetAttribute("BaseBrightness") or 1) * SkyFx.getFireLevel()
		local noise = if lowQuality then 0 else math.noise(clock * FLICKER_SPEED, index * 1.7)
		light.Brightness = base * (0.82 + noise * 0.35)
		index += 1
	end
end

function WorldFx.init()
	SkyFx.init()
	for _, light in CollectionService:GetTagged(FLICKER_TAG) do
		trackFlicker(light)
	end
	CollectionService:GetInstanceAddedSignal(FLICKER_TAG):Connect(trackFlicker)

	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		findBlades()
		applyQuality()
		for _, descendant in map:GetDescendants() do
			trackFlame(descendant)
			trackSway(descendant)
		end
		-- Con StreamingEnabled las piezas llegan de a poco
		map.DescendantAdded:Connect(function(descendant)
			trackFlame(descendant)
			trackSway(descendant)
			if descendant.Name == "WindmillBlades" or descendant.Name == "AmbientEmitter" then
				task.defer(function()
					findBlades()
					applyQuality()
				end)
			end
		end)
	end)

	pcall(function()
		UserSettings():GetService("UserGameSettings"):GetPropertyChangedSignal("SavedQualityLevel"):Connect(applyQuality)
	end)
	Players.LocalPlayer:GetAttributeChangedSignal("QualityMode"):Connect(applyQuality)

	local frame = 0
	RunService.RenderStepped:Connect(function(dt)
		frame += 1
		SkyFx.step(dt)
		local clock = os.clock()
		-- Cada 2 cuadros alcanza para que el fuego se vea vivo. En calidad baja
		-- no parpadea: solo se ajusta a la hora del día de vez en cuando.
		updateWind(clock)
		if not lowQuality and frame % 2 == 0 then
			flicker(clock)
			danceFlames(clock)
			updateSway(clock)
		elseif lowQuality then
			-- Celular: los árboles se mecen igual, cada 3 cuadros
			if frame % 3 == 0 then
				updateSway(clock)
			end
			if clock - lastDayDim > 1 then
				lastDayDim = clock
				flicker(clock)
				updateAmbient()
			end
		end
		if frame % 20 == 0 then
			updateLeaves()
		end
		if lowQuality and frame % 45 == 0 then
			cullFar()
		end
		if frame % 30 == 0 then
			updateAmbient()
		end
		if not blades or not blades.Parent or not bladesPivot then
			return
		end
		bladeAngle = (bladeAngle + dt * BLADE_SPEED) % (math.pi * 2)
		-- El eje de las aspas es el X local del eje central
		blades:PivotTo((bladesPivot :: CFrame) * CFrame.Angles(bladeAngle, 0, 0))
	end)
end

return WorldFx
