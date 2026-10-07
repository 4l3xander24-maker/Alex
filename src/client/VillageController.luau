-- El puente a la aldea: el servidor lo deja roto y guarda aparte las tablas
-- que faltan. Cuando este jugador ya lo reparó, su cliente pone las tablas
-- (solo en su pantalla y solo para él: así lo cruza solo quien pagó), esconde
-- las tablas rotas y el aviso de "Reparar".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Profile = require(script.Parent.Profile)

local VillageController = {}

local repaired = false
local planks: Instance? = nil

local function applyTo(instance: Instance)
	if instance:IsA("BasePart") and instance:GetAttribute("Broken") then
		instance.Transparency = if repaired then 1 else 0
	elseif instance:IsA("ProximityPrompt") and instance.Name == "VillageRepairPrompt" then
		instance.Enabled = not repaired
	end
end

function VillageController.init()
	task.spawn(function()
		local source = ReplicatedStorage:WaitForChild("VillageBridgePlanks", 60)
		local map = workspace:WaitForChild("Map", 60)
		if not source or not map then
			return
		end
		local function refresh()
			if not Profile.isLoaded() then
				return
			end
			repaired = Profile.get().VillageBridge == true
			if repaired and not planks then
				local copy = source:Clone()
				copy.Name = "VillageBridgeRepaired"
				copy.Parent = workspace
				planks = copy
			end
			local bridge = map:FindFirstChild("VillageBridge")
			if bridge then
				for _, descendant in bridge:GetDescendants() do
					applyTo(descendant)
				end
			end
		end
		-- Con StreamingEnabled el puente puede llegar después
		map.DescendantAdded:Connect(function(descendant)
			if descendant:FindFirstAncestor("VillageBridge") then
				applyTo(descendant)
			end
		end)
		Profile.Changed:Connect(refresh)
		refresh()
	end)
end

return VillageController
