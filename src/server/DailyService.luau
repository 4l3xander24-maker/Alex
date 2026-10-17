-- Misiones diarias (Config.DailyMissions): cuentan bajas, jefes y oleadas del
-- día (UTC). Al cumplir una se paga sola y avisa. El progreso vive en el perfil.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local DailyService = {}

-- Pone el día de hoy; si cambió, reinicia el progreso
local function today(data): any
	local day = os.date("!%Y-%m-%d") :: string
	local daily = data.Daily
	if daily.Day ~= day then
		daily.Day = day
		daily.Kills = 0
		daily.BossKills = 0
		daily.Waves = 0
		daily.Claimed = {}
	end
	return daily
end

local function check(player: Player, data)
	local daily = today(data)
	local changed = false
	for _, mission in Config.DailyMissions do
		if not daily.Claimed[mission.Id] and (daily[mission.Stat] or 0) >= mission.Goal then
			daily.Claimed[mission.Id] = true
			DataService.addCoins(player, mission.Reward)
			Remotes.Notify:FireClient(player, `📅 Misión diaria cumplida: {mission.Icon} {mission.Name} · +{mission.Reward} monedas`)
			changed = true
		end
	end
	if changed then
		DataService.changed(player, "Profile")
	end
end

function DailyService.onKill(player: Player, isBoss: boolean)
	local data = DataService.get(player)
	if not data then
		return
	end
	local daily = today(data)
	daily.Kills += 1
	if isBoss then
		daily.BossKills += 1
	end
	check(player, data)
end

-- Al terminar la partida: cuántas oleadas superó
function DailyService.onMatchEnd(player: Player, waves: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	local daily = today(data)
	daily.Waves = math.max(daily.Waves, waves)
	check(player, data)
end

return DailyService
