-- Conquistas: la primera vez que un jugador supera una dificultad gana monedas.
-- El primer jugador del mundo en superar Experto o más entra al Salón de la
-- fama (sin límite de tiempo) y gana título, monedas extra y, en Experto, un
-- rastro exclusivo. El lobby muestra el salón en un tablero.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataService = require(script.Parent.DataService)
local Leaderboard = require(script.Parent.Leaderboard)

local ConquestService = {}

local function claimFirst(player: Player, difficultyId: number)
	local conquest = Config.Conquest
	local info = Config.Difficulties[difficultyId]
	local record: Leaderboard.HallRecord = { UserId = player.UserId, Name = player.DisplayName, At = os.time() }
	if not Leaderboard.hallClaim(difficultyId, record) then
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	local title = conquest.FirstTitle[difficultyId]
	local bonus = conquest.FirstBonus[difficultyId] or 0
	if title then
		data.Titles[tostring(difficultyId)] = true
		data.Title = title
	end
	local skinId = conquest.FirstSkin[difficultyId]
	if skinId then
		data.ObjectSkins[skinId] = true
	end
	DataService.addCoins(player, bonus)
	DataService.changed(player, "Profile")
	DataService.saveNow(player)
	Remotes.Notify:FireAllClients(`👑 ¡{player.DisplayName} es el PRIMER jugador del mundo en superar {info.Icon} {info.Name}!`)
	Remotes.Notify:FireClient(player, `👑 Salón de la fama: título "{title}" y +{bonus} monedas{if skinId then " + rastro exclusivo" else ""}`)
end

-- Se llama cuando el equipo supera la dificultad `difficultyId`
function ConquestService.onCleared(difficultyId: number)
	local conquest = Config.Conquest
	local key = tostring(difficultyId)
	for _, player in Players:GetPlayers() do
		local data = DataService.get(player)
		if data and not data.Conquests[key] then
			data.Conquests[key] = true
			local reward = conquest.Rewards[difficultyId] or 0
			if reward > 0 then
				DataService.addCoins(player, reward)
				Remotes.Notify:FireClient(player, `🏅 Primera vez que superas {Config.Difficulties[difficultyId].Name}: +{reward} monedas`)
			end
			DataService.changed(player, "Profile")
			if difficultyId >= conquest.FirstFrom then
				task.spawn(claimFirst, player, difficultyId)
			end
		end
	end
end

return ConquestService
