-- Logros (Config.Achievements): se revisan al terminar cada partida, dan
-- monedas una sola vez y avisan con un mensaje.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local AchievementService = {}

-- values: Kills (total), Wave (mejor), BossKills, Level, MatchKills (de esta partida)
function AchievementService.check(player: Player, values: { [string]: number })
	local data = DataService.get(player)
	if not data then
		return
	end
	local unlocked = false
	for _, achievement in Config.Achievements do
		if not data.Achievements[achievement.Id] and (values[achievement.Stat] or 0) >= achievement.Goal then
			data.Achievements[achievement.Id] = true
			DataService.addCoins(player, achievement.Reward)
			Remotes.Notify:FireClient(player, `🏆 Logro: {achievement.Icon} {achievement.Name} · +{achievement.Reward} monedas`)
			unlocked = true
		end
	end
	if unlocked then
		DataService.changed(player, "Profile")
	end
end

return AchievementService
