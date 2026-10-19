-- Reto semanal (Config.Weekly + Shared.Weekly): el modificador de las oleadas
-- cambia cada semana, cada partida sube puntos al ranking de la semana y los 3
-- primeros de la semana pasada cobran su premio al entrar.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Weekly = require(ReplicatedStorage.Shared.Weekly)
local DataService = require(script.Parent.DataService)
local Leaderboard = require(script.Parent.Leaderboard)

local WeeklyService = {}

-- Al terminar una partida: sube el puntaje de cada jugador de la partida
function WeeklyService.submit(wave: number, difficultyId: number)
	local score = Weekly.score(wave, difficultyId)
	local _, week = Weekly.current()
	for _, player in Players:GetPlayers() do
		Leaderboard.weeklySubmit(week, player.UserId, score)
	end
end

-- Al cargar el perfil: si quedó entre los 3 primeros de la semana pasada, cobra
function WeeklyService.onPlayerReady(player: Player)
	local _, week = Weekly.current()
	local previous = week - 1
	local data = DataService.get(player)
	if not data or data.WeeklyClaimed >= previous then
		return
	end
	task.spawn(function()
		local rows = Leaderboard.weeklyTop(previous, #Config.Weekly.Prizes)
		if not rows then
			return -- sin conexión: se intenta la próxima vez
		end
		local current = DataService.get(player)
		if not current or current.WeeklyClaimed >= previous then
			return
		end
		current.WeeklyClaimed = previous
		for place, row in rows do
			if row.UserId == player.UserId then
				local prize = Config.Weekly.Prizes[place] or 0
				DataService.addCoins(player, prize)
				Remotes.Notify:FireClient(player, `🏅 Quedaste #{place} en el reto de la semana pasada: +{prize} monedas`)
				break
			end
		end
		DataService.changed(player, "Profile")
	end)
end

return WeeklyService
