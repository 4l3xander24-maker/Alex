-- Detalles del mundo que corren solo en cada cliente:
--   * Gira las aspas del molino (no gasta red: cada jugador las mueve en su pantalla).
--   * Adapta los efectos a la calidad gráfica del jugador: en calidad baja o
--     en celulares apaga el desenfoque, los rayos de sol y baja las partículas.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BLADE_SPEED = 0.45 -- vueltas por segundo en radianes
local LOW_QUALITY_LEVEL = 4 -- calidad 1-4 de 10 = equipo modesto

local WorldFx = {}

local blades: Model? = nil
local bladesPivot: CFrame? = nil
local bladeAngle = 0

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

function WorldFx.init()
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

	RunService.RenderStepped:Connect(function(dt)
		if not blades or not blades.Parent or not bladesPivot then
			return
		end
		bladeAngle = (bladeAngle + dt * BLADE_SPEED) % (math.pi * 2)
		-- El eje de las aspas es el X local del eje central
		blades:PivotTo((bladesPivot :: CFrame) * CFrame.Angles(bladeAngle, 0, 0))
	end)
end

return WorldFx
