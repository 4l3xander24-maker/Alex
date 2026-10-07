-- La aldea, en su propia isla:
--   * El puente de madera para llegar está roto. Cada jugador lo repara una vez
--     con monedas (queda guardado en su perfil); las tablas que faltan las pone
--     su propio cliente (VillageController), así solo lo cruza quien pagó.
--   * El molino: entre oleadas, quien está cerca come pan recién hecho y se cura.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local GameState = require(script.Parent.GameState)
local PlayerService = require(script.Parent.PlayerService)
local ShopService = require(script.Parent.ShopService)

local TICK = 0.5

local VillageService = {}

-- Quién ya recibió el aviso del pan en este descanso entre oleadas
local fed: { [Player]: boolean } = {}

local function bindRepairPrompt(prompt: ProximityPrompt)
	prompt.Triggered:Connect(function(player)
		local ok, message = ShopService.run(player, "RepairVillageBridge", "")
		Remotes.Notify:FireClient(player, message)
		if not ok then
			return
		end
		for _, other in Players:GetPlayers() do
			if other ~= player then
				Remotes.Notify:FireClient(other, `🔨 {player.DisplayName} reparó su puente a la aldea`)
			end
		end
	end)
end

-- Cura a los que están junto al molino durante el descanso entre oleadas
local function feed()
	local windmill = Config.Arena.Windmill
	if GameState.get("State") ~= "Intermission" then
		table.clear(fed)
		return
	end
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local offset = (root :: BasePart).Position - windmill.Position
			if Vector3.new(offset.X, 0, offset.Z).Magnitude <= windmill.Radius then
				PlayerService.heal(player, windmill.HealPerSecond * TICK)
				if not fed[player] then
					fed[player] = true
					Remotes.Notify:FireClient(player, "🍞 Pan caliente del molino: te curas mientras estés cerca")
				end
			end
		end
	end
end

function VillageService.init(map: Instance)
	local prompt = map:FindFirstChild("VillageRepairPrompt", true)
	if prompt and prompt:IsA("ProximityPrompt") then
		bindRepairPrompt(prompt)
	end
	Players.PlayerRemoving:Connect(function(player)
		fed[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			feed()
		end
	end)
end

return VillageService
