-- Mascotas que vende la Bruja (Config.Pets). Cada jugador lleva una (la que
-- eligió en su perfil). Durante las oleadas atacan solas al zombi más cercano
-- que esté a su alcance desde el jugador; el daño crece con la oleada. Los
-- clientes las dibujan siguiendo a su dueño (PetRenderer) y ven cada ataque.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)

local TICK = 0.1

local PetService = {}

-- Cuándo puede volver a atacar la mascota de cada jugador
local nextAttack: { [Player]: number } = {}

-- El atributo "Pet" del jugador le dice a los clientes qué mascota dibujar
local function publish(player: Player)
	local data = DataService.get(player)
	local pet = data and data.Pet or ""
	if pet ~= "" and not Config.Pets[pet] then
		pet = ""
	end
	player:SetAttribute("Pet", pet)
end

local function attack(player: Player, petId: string, now: number, wave: number)
	local pet = Config.Pets[petId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local origin = (root :: BasePart).Position
	local time = workspace:GetServerTimeNow()
	local target = EnemyService.findNearest(origin, pet.Range, time, {})
	if not target then
		return
	end
	local position = EnemyService.getPosition(target, time)
	if not position then
		return
	end
	nextAttack[player] = now + 1 / pet.Rate
	local damage = pet.Damage * (1 + Config.Waves.HealthGrowth * math.max(wave - 1, 0))
	Remotes.PetAttack:FireAllClients(player, petId, position)
	if pet.Splash then
		for _, enemyId in EnemyService.getInRadius(position, pet.Splash, time) do
			EnemyService.damage(enemyId, damage, player)
		end
	else
		EnemyService.damage(target, damage, player)
	end
end

function PetService.init()
	DataService.onChanged(function(player)
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		nextAttack[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			if GameState.get("State") ~= "Wave" then
				continue
			end
			local now = os.clock()
			local wave = GameState.get("Wave") or 1
			for _, player in Players:GetPlayers() do
				local petId = player:GetAttribute("Pet")
				if typeof(petId) == "string" and petId ~= "" and now >= (nextAttack[player] or 0) then
					attack(player, petId, now, wave)
				end
			end
		end
	end)
end

-- Cuando carga el perfil
function PetService.onPlayerReady(player: Player)
	publish(player)
end

return PetService
