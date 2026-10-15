-- Potenciadores que sueltan los zombis. Se aplican al instante a todo el
-- equipo (sin recogerlos del suelo) y avisan con un mensaje y una ficha en
-- el HUD cuando duran un tiempo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local CombatService = require(script.Parent.CombatService)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)

local random = Random.new()
local settings = Config.Powerups

local PowerupService = {}

local function pick(): string
	local total = 0
	for _, info in settings.Types do
		total += info.Weight
	end
	local roll = random:NextNumber() * total
	for name, info in settings.Types do
		roll -= info.Weight
		if roll <= 0 then
			return name
		end
	end
	return "Ammo"
end

function PowerupService.apply(name: string, wave: number)
	local info = settings.Types[name]
	local now = workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		if name == "Ammo" then
			CombatService.refillAmmo(player)
		elseif name == "Heal" then
			PlayerService.heal(player, 1000)
		elseif name == "Damage" then
			player:SetAttribute("DamageBoostUntil", now + info.Duration)
		elseif name == "Shield" then
			player:SetAttribute("ShieldUntil", now + info.Duration)
		elseif name == "Coins" and DataService.get(player) then
			DataService.addCoins(player, info.Base + info.PerWave * wave)
		end
		Remotes.Boost:FireClient(player, name, info.Duration or 0)
	end
end

-- Llamar en cada baja: a veces suelta un potenciador
function PowerupService.onKill(isBoss: boolean, wave: number)
	local chance = if isBoss then settings.BossDropChance else settings.DropChance
	if random:NextNumber() < chance then
		PowerupService.apply(pick(), wave)
	end
end

return PowerupService
