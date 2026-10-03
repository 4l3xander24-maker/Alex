-- Detalles del mundo que corren solo en cada cliente:
--   * Gira las aspas del molino (no gasta red: cada jugador las mueve en su pantalla).
--   * Hace parpadear la luz de velas y antorchas (solo en calidad alta) y la
--     baja de día. Hace bailar los cubitos de la fogata en pixel art 3D.
--   * Corre el cielo (SkyFx): ciclo de día y noche, nubes y luciérnagas.
--   * Adapta los efectos a la calidad gráfica del jugador: en calidad baja o
--     en celulares apaga el desenfoque, los rayos de sol y baja las partículas.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SkyFx = require(script.Parent.SkyFx)

local BLADE_SPEED = 0.45 -- vueltas por segundo en radianes
local LOW_QUALITY_LEVEL = 4 -- calidad 1-4 de 10 = equipo modesto
local FLICKER_TAG = "Flicker"
local FLICKER_SPEED = 7

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
		end
	end
	local map = workspace:FindFirstChild("Map")
	local ambient = map and map:FindFirstChild("AmbientParticles")
	local emitter = ambient and ambient:FindFirstChild("AmbientEmitter")
	if emitter and emitter:IsA("ParticleEmitter") then
		ambientEmitter = emitter
		emitter.Enabled = not low
	end
	SkyFx.setReduced(low)
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
		end
		-- Con StreamingEnabled las piezas llegan de a poco
		map.DescendantAdded:Connect(function(descendant)
			trackFlame(descendant)
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

	local frame = 0
	RunService.RenderStepped:Connect(function(dt)
		frame += 1
		SkyFx.step(dt)
		local clock = os.clock()
		-- Cada 2 cuadros alcanza para que el fuego se vea vivo. En calidad baja
		-- no parpadea: solo se ajusta a la hora del día de vez en cuando.
		if not lowQuality and frame % 2 == 0 then
			flicker(clock)
			danceFlames(clock)
		elseif lowQuality and clock - lastDayDim > 1 then
			lastDayDim = clock
			flicker(clock)
			updateAmbient()
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
