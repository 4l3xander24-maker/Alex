-- Lleva la cuenta de cada jugador durante la partida (oleadas, bajas,
-- monedas). La XP de cuenta se da en el momento (cada zombi y cada oleada),
-- así se puede subir de nivel en plena partida; al terminar manda el resumen
-- con la tabla de todo el equipo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local AchievementService = require(script.Parent.AchievementService)
local DailyService = require(script.Parent.DailyService)
local DataService = require(script.Parent.DataService)
local Leaderboard = require(script.Parent.Leaderboard)
local StoreService = require(script.Parent.StoreService)
local GameState = require(script.Parent.GameState)

type MatchStats = {
	Kills: number,
	BossKills: number,
	Coins: number,
	Waves: number,
	Xp: number, -- XP ya entregada en esta partida
	XpExact: number, -- con decimales (el bono VIP), para no perder fracciones
	StartLevel: number,
}

-- Una fila de la tabla del equipo al final
export type TeamRow = { Name: string, UserId: number, Kills: number, BossKills: number, Coins: number, Xp: number, Waves: number }

local MatchService = {}

local stats: { [Player]: MatchStats } = {}

local function ensure(player: Player): MatchStats
	local entry = stats[player]
	if not entry then
		local data = DataService.get(player)
		entry = { Kills = 0, BossKills = 0, Coins = 0, Waves = 0, Xp = 0, XpExact = 0, StartLevel = if data then data.Level else 1 }
		stats[player] = entry
	end
	return entry
end

-- El HUD muestra cuánta XP llevas ganada en esta partida
local function publish(player: Player, entry: MatchStats)
	player:SetAttribute("MatchXp", entry.Xp)
	player:SetAttribute("MatchKills", entry.Kills)
end

-- Da XP de cuenta ya mismo (con el bono VIP). Si sube de nivel, el cliente
-- muestra el cartel de "¡SUBISTE DE NIVEL!" al instante.
local function grantXp(player: Player, entry: MatchStats, amount: number)
	-- Más difícil, más XP
	local difficulty = Config.Difficulties[GameState.get("Difficulty") or 1]
	amount *= if difficulty then difficulty.Xp else 1
	if StoreService.hasPass(player, "Vip") then
		amount *= 1 + Config.Monetization.VipXpBonus
	end
	entry.XpExact += amount
	local whole = math.floor(entry.XpExact) - entry.Xp
	if whole > 0 then
		entry.Xp += whole
		DataService.addXp(player, whole)
	end
	publish(player, entry)
end

function MatchService.onKill(player: Player, isBoss: boolean, coins: number)
	local entry = ensure(player)
	local progression = Config.Progression
	entry.Kills += 1
	entry.Coins += coins
	if isBoss then
		entry.BossKills += 1
	end
	grantXp(player, entry, progression.XpPerKill + (if isBoss then progression.XpPerBossKill else 0))
end

function MatchService.onWaveCleared()
	for _, player in Players:GetPlayers() do
		local entry = ensure(player)
		entry.Waves += 1
		grantXp(player, entry, Config.Progression.XpPerWave)
	end
end

local function teamRows(): { TeamRow }
	local rows: { TeamRow } = {}
	for player, entry in stats do
		table.insert(rows, { Name = player.DisplayName, UserId = player.UserId, Kills = entry.Kills, BossKills = entry.BossKills, Coins = entry.Coins, Xp = entry.Xp, Waves = entry.Waves })
	end
	table.sort(rows, function(a, b)
		return if a.Kills ~= b.Kills then a.Kills > b.Kills else a.Xp > b.Xp
	end)
	return rows
end

-- Cierra la partida de un jugador: récord, ranking y el resumen (si sigue
-- conectado). La XP ya se entregó durante la partida.
function MatchService.award(player: Player, wave: number, team: { TeamRow }?)
	local entry = stats[player]
	stats[player] = nil
	if not entry then
		return
	end
	local data = DataService.get(player)
	-- Aunque pierdas, ganas algo por cada oleada que superaste
	if data and entry.Waves > 0 then
		local info = Config.Difficulties[GameState.get("Difficulty") or 1]
		local consolation = math.floor(Config.Economy.ParticipationPerWave * entry.Waves * (info and info.Coins or 1))
		DataService.addCoins(player, consolation)
		entry.Coins += consolation
	end
	local previousBest = if data then data.BestWave else 0
	local newRecord = data ~= nil and entry.Waves > previousBest
	if data and newRecord then
		data.BestWave = entry.Waves
		DataService.changed(player, "Record")
	end
	-- Ranking global que se ve en el lobby
	if data then
		data.TotalKills += entry.Kills
		Leaderboard.submit(player.UserId, "BestWave", data.BestWave)
		Leaderboard.submit(player.UserId, "Kills", data.TotalKills)
		DailyService.onMatchEnd(player, entry.Waves)
		AchievementService.check(player, { Kills = data.TotalKills, Wave = data.BestWave, BossKills = entry.BossKills, Level = data.Level, MatchKills = entry.Kills })
	end
	if player.Parent and data then
		player:SetAttribute("MatchXp", 0)
		player:SetAttribute("MatchKills", 0)
		Remotes.MatchSummary:FireClient(player, {
			Wave = wave,
			Waves = entry.Waves,
			Kills = entry.Kills,
			BossKills = entry.BossKills,
			Coins = entry.Coins,
			Xp = entry.Xp,
			Levels = math.max(0, data.Level - entry.StartLevel),
			Level = data.Level,
			StatPoints = data.StatPoints,
			TalentPoints = data.TalentPoints,
			BestWave = data.BestWave,
			PreviousBest = previousBest,
			NewRecord = newRecord,
			Team = team or {},
		})
	end
end

function MatchService.endMatch(wave: number)
	-- Todos reciben el resumen (y la votación), aunque no hayan matado nada
	for _, player in Players:GetPlayers() do
		ensure(player)
	end
	local team = teamRows()
	for player in stats do
		MatchService.award(player, wave, team)
	end
end

return MatchService
