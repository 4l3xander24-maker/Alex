-- Insignias de Roblox (Config.Badges). Se dan solo desde el servidor, por hitos que
-- calcula el servidor; el cliente no puede pedirlas. Mientras el Id sea 0 la insignia
-- está apagada. Roblox ignora las repetidas, pero aquí se da cada una una sola vez por
-- jugador y sesión del servidor para no llamar de más.
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Insignias = {}

local idByKey: { [string]: number } = {}
for _, badge in Config.Badges do
	idByKey[badge.Key] = badge.Id
end

-- Claves ya pedidas a Roblox en esta sesión, por jugador
local given: { [Player]: { [string]: boolean } } = {}

function Insignias.award(player: Player, key: string)
	local id = idByKey[key]
	if not id or id == 0 or not player.Parent then
		return
	end
	local done = given[player]
	if not done then
		done = {}
		given[player] = done
	end
	if done[key] then
		return
	end
	done[key] = true
	task.spawn(function()
		local ok, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, id)
		end)
		if not ok then
			warn(`Insignia {key}: no se pudo dar ({err})`)
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	given[player] = nil
end)

return Insignias
