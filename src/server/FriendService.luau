-- Bonus por jugar con amigos de Roblox (Config.Friends): cada amigo presente en
-- la partida suma monedas y XP de cuenta, hasta un tope. Solo el servidor lo
-- calcula; el cliente lo ve en el aviso y en el resumen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local GameState = require(script.Parent.GameState)

local FriendService = {}

-- Amistades ya comprobadas entre jugadores presentes: friends[a][userIdDeB] = true
local friends: { [Player]: { [number]: boolean } } = {}

-- Cuántos amigos suyos hay ahora en el servidor
function FriendService.count(player: Player): number
	local known = friends[player]
	local total = 0
	if known then
		for _, other in Players:GetPlayers() do
			if other ~= player and known[other.UserId] then
				total += 1
			end
		end
	end
	return total
end

-- Bonus de este jugador (0.2 = +20%)
function FriendService.bonus(player: Player): number
	local friend = Config.Friends
	return math.min(FriendService.count(player) * friend.BonusPerFriend, friend.MaxBonus)
end

-- Multiplicador para monedas y XP (se junta con los demás multiplicando)
function FriendService.multiplier(player: Player): number
	return 1 + FriendService.bonus(player)
end

local function percent(player: Player): number
	return math.floor(FriendService.bonus(player) * 100 + 0.5)
end

-- Estados en que la partida ya empezó (antes, el aviso sale al empezar)
local PLAYING = { Intermission = true, Wave = true, Victory = true }

local function tell(player: Player)
	local count = FriendService.count(player)
	if count > 0 and player.Parent then
		Remotes.Notify:FireClient(player, `🤝 Juegas con {count} amigo{if count > 1 then "s" else ""}: +{percent(player)}% de monedas y XP`)
	end
end

-- Publica el bonus como atributo (por si algún cliente quiere mostrarlo)
local function publish(player: Player)
	player:SetAttribute("FriendBonus", percent(player))
end

-- Al entrar alguien: se comprueba su amistad con cada jugador presente. La
-- consulta espera a Roblox y puede fallar: si falla, cuenta como "no amigo".
local function onJoined(player: Player)
	local known = friends[player] or {}
	friends[player] = known
	local changed: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and not known[other.UserId] then
			local ok, isFriend = pcall(function()
				return player:IsFriendsWithAsync(other.UserId)
			end)
			if ok and isFriend == true and player.Parent and other.Parent then
				known[other.UserId] = true
				friends[other] = friends[other] or {}
				friends[other][player.UserId] = true
				table.insert(changed, other)
			end
		end
	end
	if #changed > 0 then
		publish(player)
		local started = PLAYING[GameState.get("State")] == true
		if started then
			tell(player)
		end
		for _, other in changed do
			publish(other)
			if started then
				tell(other)
			end
		end
	end
end

-- Al empezar la partida: se avisa a cada uno cuántos amigos tiene con él
function FriendService.announce()
	for _, player in Players:GetPlayers() do
		publish(player)
		tell(player)
	end
end

function FriendService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onJoined, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onJoined, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		friends[player] = nil
		-- Si se va un amigo, baja el bonus de los demás (sin repetir el aviso)
		task.defer(function()
			for _, other in Players:GetPlayers() do
				if other ~= player then
					publish(other)
				end
			end
		end)
	end)
end

return FriendService
