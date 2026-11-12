-- Partida que viene del Lobby (servidor reservado): al terminar, todos
-- vuelven al Lobby. Si se entró directo a este lugar (o en Studio), la
-- partida se repite aquí mismo como siempre.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local MatchRegistry = require(ReplicatedStorage.Shared.MatchRegistry)
local DataService = require(script.Parent.DataService)

local LobbyReturn = {}

-- Grupo que mandó el Lobby (TeleportData de quienes llegan): cuántos son y
-- quiénes. La partida no empieza hasta que lleguen todos o pase PartyWait.
local partySize = 0
local partyIds: { [number]: boolean } = {}
local firstJoinAt: number? = nil -- hora del servidor en que entró el primero
local partyDone = false

local function readJoinData(player: Player)
	firstJoinAt = firstJoinAt or workspace:GetServerTimeNow()
	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)
	local data = if ok and typeof(joinData) == "table" then joinData.TeleportData else nil
	if typeof(data) ~= "table" then
		return -- Studio, entrada directa o reconexión: no trae datos del grupo
	end
	local maxPlayers = Config.Rooms.MaxPlayers
	if typeof(data.Players) == "number" and data.Players == data.Players then
		partySize = math.max(partySize, math.clamp(math.floor(data.Players), 1, maxPlayers))
	end
	if typeof(data.UserIds) == "table" then
		for index, userId in data.UserIds do
			if typeof(index) == "number" and index <= maxPlayers and typeof(userId) == "number" then
				partyIds[userId] = true
			end
		end
	end
end

-- Empieza a leer los datos del grupo de cada jugador que entra
function LobbyReturn.watchParty()
	Players.PlayerAdded:Connect(readJoinData)
	for _, player in Players:GetPlayers() do
		readJoinData(player)
	end
end

-- Cuántos del grupo ya llegaron con el perfil cargado, cuántos se esperan y a
-- qué hora del servidor se deja de esperar. Esperados 0 = ya no hay que esperar
-- (juegas solo, Studio, llegaron todos o se acabó el tiempo; no vuelve a esperar).
function LobbyReturn.partyStatus(): (number, number, number)
	if partyDone then
		return 0, 0, 0
	end
	local expected = partySize
	local arrived = 0
	if next(partyIds) then
		local listed = 0
		for userId in partyIds do
			listed += 1
			local player = Players:GetPlayerByUserId(userId)
			if player and DataService.isReady(player) then
				arrived += 1
			end
		end
		expected = math.max(expected, listed)
	else
		for _, player in Players:GetPlayers() do
			if DataService.isReady(player) then
				arrived += 1
			end
		end
	end
	local endsAt = (firstJoinAt or workspace:GetServerTimeNow()) + Config.Rooms.PartyWait
	if expected <= 1 or arrived >= expected or workspace:GetServerTimeNow() >= endsAt then
		partyDone = true
		return 0, 0, 0
	end
	return arrived, expected, endsAt
end

-- Jugadores que se van al Lobby a propósito (no cuentan como desconexión)
local leaving: { [Player]: boolean } = {}

function LobbyReturn.isLeaving(player: Player): boolean
	return leaving[player] == true
end

-- Mientras la partida siga viva marca "sigo aquí" para que los que se
-- desconectaron puedan volver (ver MatchRegistry)
function LobbyReturn.startHeartbeat()
	if not LobbyReturn.isRoomMatch() then
		return
	end
	local privateId = game.PrivateServerId
	MatchRegistry.heartbeat(privateId)
	task.spawn(function()
		while true do
			task.wait(MatchRegistry.HeartbeatEvery)
			MatchRegistry.heartbeat(privateId)
		end
	end)
	game:BindToClose(function()
		MatchRegistry.finish(privateId)
	end)
end

-- true si este servidor lo reservó el Lobby para una sala
function LobbyReturn.isRoomMatch(): boolean
	return not RunService:IsStudio() and Config.Places.Lobby ~= 0 and game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- Manda a estos jugadores al Lobby (reintenta si Roblox falla). false si no se pudo
function LobbyReturn.sendPlayers(players: { Player }): boolean
	if #players == 0 then
		return true
	end
	-- Van al Lobby a propósito: ya no tienen partida a la que reconectarse
	for _, player in players do
		leaving[player] = true
		MatchRegistry.clear(player.UserId)
	end
	for attempt = 1, 3 do
		-- Quien cerró el juego mientras tanto haría fallar el viaje de todos
		local present = {}
		for _, player in players do
			if player.Parent then
				table.insert(present, player)
			end
		end
		if #present == 0 then
			return true
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(Config.Places.Lobby, present)
		end)
		if ok then
			return true
		end
		warn(`No se pudo volver al Lobby (intento {attempt}): {err}`)
		task.wait(2)
	end
	-- Siguen aquí: si se desconectan, cuenta como desconexión
	for _, player in players do
		leaving[player] = nil
	end
	return false
end

-- Manda a todos al Lobby
function LobbyReturn.sendEveryone()
	LobbyReturn.sendPlayers(Players:GetPlayers())
end

return LobbyReturn
