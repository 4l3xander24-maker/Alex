-- Modelo estático de un tipo de enemigo (para vistas 3D y pruebas): las mismas
-- piezas que EnemyRenderer, puestas sin animación.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local ZombieModels = require(script.Parent.ZombieModels)

local EnemyPreview = {}

function EnemyPreview.model(typeName: string): Model
	local info = Config.Enemies[typeName]
	local scale = info.Size.Y / 5
	local model = Instance.new("Model")
	for _, spec in ZombieModels.get(typeName, info) do
		local color, glows = ZombieModels.resolveColor(info, spec.Color)
		local part = Instance.new("Part")
		part.Name = spec.Name
		part.Size = spec.Size * scale
		part.Color = color
		part.Material = if glows then Enum.Material.Neon else spec.Material
		if spec.Shape then
			part.Shape = spec.Shape
		end
		if spec.Transparent then
			part.Transparency = 1
		end
		part.Anchored = true
		part.CanCollide = false
		part.CFrame = CFrame.new(spec.Pivot * scale) * CFrame.Angles(-spec.Tilt, 0, 0) * CFrame.new(spec.Hang * scale) * (spec.Turn or CFrame.identity)
		part.Parent = model
	end
	return model
end

return EnemyPreview
