-- Misiones diarias (Config.DailyMissions) y racha de días (Config.DailyRules).
-- Cada día de juego (cambia a Config.DailyRules.ResetHourUtc) salen 3 misiones
-- del grupo, las mismas para todos. Cuentan bajas, jefes, partidas, niveles y
-- oleadas; al cumplir una se paga sola y avisa, y cumplir las 3 da un extra.
-- El avance vive en el perfil (Missions), por id de misión. Todo lo calcula el
-- servidor: el cliente no puede dar premios.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DailyDay = require(ReplicatedStorage.Shared.DailyDay)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)

local rules = Config.DailyRules

local DailyService = {}

-- Bajas de la partida en curso de cada jugador (para "bajas en una sola partida")
local matchKills: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local function currentDay(): number
	return DailyDay.gameDay(os.time(), rules.ResetHourUtc)
end

local function missionsOf(day: number)
	return DailyDay.pick(Config.DailyMissions, day, rules.MissionsPerDay)
end

-- Perfiles con el formato viejo (Daily, por fecha UTC): si lo guardado es de
-- hoy, se pasa su avance y lo ya cobrado, para no pagar dos veces lo mismo
local function migrateLegacy(data, missions)
	local legacy = data.Daily
	if type(legacy) ~= "table" or type(legacy.Day) ~= "string" or legacy.Day == "" then
		return
	end
	local now = os.time()
	-- Solo si es la fecha UTC en que empezó el día de juego actual: lo cobrado
	-- antes de la hora de cambio pertenece al día de juego anterior
	if legacy.Day ~= os.date("!%Y-%m-%d", now - rules.ResetHourUtc * 3600) then
		return
	end
	missions.Progress.DKills = legacy.Kills or 0
	missions.Progress.DBoss = legacy.BossKills or 0
	missions.Progress.DWaves = legacy.Waves or 0
	for id, claimed in legacy.Claimed or {} do
		if claimed == true then
			missions.Claimed[id] = true
		end
	end
	legacy.Day = ""
end

-- Devuelve las misiones de hoy; si cambió el día, reinicia el avance
local function today(data): any
	local day = currentDay()
	local missions = data.Missions
	if missions.Day ~= day then
		local first = missions.Day == 0
		missions.Day = day
		missions.Progress = {}
		missions.Claimed = {}
		missions.BonusClaimed = false
		missions.StartLevel = data.Level
		if first then
			migrateLegacy(data, missions)
		end
	end
	return missions
end

-- Cuánto lleva una misión (los niveles se cuentan desde que empezó el día)
local function progressOf(data, missions, mission): number
	if mission.Stat == "Levels" then
		return math.max(0, data.Level - missions.StartLevel)
	end
	return missions.Progress[mission.Id] or 0
end

local function check(player: Player, data)
	local missions = today(data)
	local changed = false
	local all = true
	for _, mission in missionsOf(missions.Day) do
		if mission.Stat == "Levels" then
			missions.Progress[mission.Id] = progressOf(data, missions, mission)
		end
		if not missions.Claimed[mission.Id] and (missions.Progress[mission.Id] or 0) >= mission.Goal then
			missions.Claimed[mission.Id] = true
			DataService.addCoins(player, mission.Reward)
			Remotes.Notify:FireClient(player, `📅 Misión diaria cumplida: {mission.Icon} {mission.Name} · +{mission.Reward} monedas`)
			changed = true
		end
		if not missions.Claimed[mission.Id] then
			all = false
		end
	end
	if all and not missions.BonusClaimed then
		missions.BonusClaimed = true
		DataService.addCoins(player, rules.AllBonus)
		Remotes.Notify:FireClient(player, `🎉 ¡Misiones del día completas! +{rules.AllBonus} monedas extra`)
		changed = true
	end
	if changed then
		DataService.changed(player, "Profile")
	end
end

-- Suma (o, con isBest, guarda el mejor valor) a las misiones de hoy que cuentan esa medida
local function record(data, stat: string, amount: number, isBest: boolean)
	local missions = today(data)
	for _, mission in missionsOf(missions.Day) do
		if mission.Stat == stat then
			local current = missions.Progress[mission.Id] or 0
			missions.Progress[mission.Id] = if isBest then math.max(current, amount) else current + amount
		end
	end
end

function DailyService.onKill(player: Player, isBoss: boolean)
	local data = DataService.get(player)
	if not data then
		return
	end
	record(data, "Kills", 1, false)
	if isBoss then
		record(data, "BossKills", 1, false)
	end
	local kills = (matchKills[player] or 0) + 1
	matchKills[player] = kills
	record(data, "MatchKills", kills, true)
	check(player, data)
end

-- Al terminar la partida: cuántas oleadas superó
function DailyService.onMatchEnd(player: Player, waves: number, finished: boolean?)
	matchKills[player] = nil
	local data = DataService.get(player)
	if not data then
		return
	end
	record(data, "Waves", waves, true)
	if waves >= 1 and finished then
		record(data, "Matches", 1, false)
	end
	check(player, data)
end

-- Al cargar el perfil: cuenta la racha (una vez por día de juego) y deja listas las misiones
function DailyService.onPlayerReady(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	today(data)
	-- Sin poder guardar no se paga la racha: se repetiría en cada entrada
	if not DataService.canSave(player) then
		return
	end
	local streak = data.Streak
	local count, changed = DailyDay.nextStreak(streak.LastDay, currentDay(), streak.Count)
	if not changed then
		return
	end
	streak.Count = count
	streak.LastDay = currentDay()
	local reward = Config.DailyRules.StreakRewards[DailyDay.cycleDay(count, #rules.StreakRewards)]
	DataService.addCoins(player, reward)
	DataService.changed(player, "Profile")
	task.spawn(function()
		DataService.saveNow(player)
		task.wait(3) -- para que el cliente ya esté escuchando los avisos
		if player.Parent then
			Remotes.Notify:FireClient(player, `🔥 Día {count} de racha: +{reward} monedas. ¡Vuelve mañana!`)
		end
	end)
end

-- Subir de nivel cuenta para las misiones de nivel
DataService.onChanged(function(player, reason)
	if reason ~= "Level" then
		return
	end
	local data = DataService.get(player)
	if data then
		check(player, data)
	end
end)

return DailyService
