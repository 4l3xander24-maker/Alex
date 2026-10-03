-- Detalles del mundo que corren solo en cada cliente:
--   * Gira las aspas del molino (no gasta red: cada jugador las mueve en su pantalla).
--   * Hace parpadear la luz de velas y antorchas (solo en calidad alta).
--   * Adapta los efectos a la calidad gráfica del jugador: en calidad baja o
--     en celulares apaga el desenfoque, los rayos de sol y baja las partículas.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
		emitter.Enabled = not low
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
		local base = light:GetAttribute("BaseBrightness") or 1
		local noise = math.noise(clock * FLICKER_SPEED, index * 1.7)
		light.Brightness = base * (0.82 + noise * 0.35)
		index += 1
	end
end

function WorldFx.init()
	for _, light in CollectionService:GetTagged(FLICKER_TAG) do
		trackFlicker(light)
	end
	CollectionService:GetInstanceAddedSignal(FLICKER_TAG):Connect(trackFlicker)

	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		findBlades()
		applyQuality()
		-- Con StreamingEnabled las piezas llegan de a poco
		map.DescendantAdded:Connect(function(descendant)
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
		-- Cada 2 cuadros alcanza para que el fuego se vea vivo
		if not lowQuality and frame % 2 == 0 then
			flicker(os.clock())
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
