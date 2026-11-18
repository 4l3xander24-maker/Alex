-- Invitar amigos con premio (Config.Referral). Cómo funciona:
--   1. El amigo entra con la invitación ("ref:<UserId>" en LaunchData). El
--      Lobby lo valida y lo pasa en TeleportData (RefBy); si entró directo a
--      la Partida, se lee aquí su LaunchData.
--   2. Al cargar su perfil: solo si nunca terminó una partida, no tenía
--      invitador y de verdad son amigos en Roblox, se anota ReferredBy.
--   3. Al terminar esa primera partida: él recibe WelcomeCoins y al invitador
--      se le suma un premio pendiente en el DataStore "Referidos" (clave =
--      UserId del invitador), que guarda la lista de invitados para no
--      contar dos veces al mismo y el tope de MaxFriends.
--   4. El invitador cobra lo pendiente al cargar su perfil en una partida
--      (o al momento, si está en este servidor).
-- En Studio sin acceso a DataStores no se anota ni se paga nada.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Invite = require(Shared.Invite)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)

local rules = Config.Referral

type Record = { Pending: number, Ids: { number } }

local ReferralService = {}

local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(rules.Store)
end)

local function keyOf(userId: number): string
	return tostring(userId)
end

-- Lo guardado, limpio (otra versión o datos rotos no rompen nada)
local function readRecord(old: any): Record
	local record: Record = { Pending = 0, Ids = {} }
	if type(old) == "table" then
		record.Pending = math.max(0, math.floor(tonumber(old.Pending) or 0))
		if type(old.Ids) == "table" then
			for _, id in old.Ids do
				if type(id) == "number" then
					table.insert(record.Ids, id)
				end
			end
		end
	end
	return record
end

local claiming: { [Player]: boolean } = {}

-- Cobra los premios pendientes de este invitador: primero se vacía lo
-- pendiente en el DataStore (atómico), después se suman las monedas y se guarda
local function claim(player: Player)
	local referrals = store
	if not referrals or claiming[player] or not DataService.canSave(player) then
		return
	end
	claiming[player] = true
	local taken, total = 0, 0
	local ok, err = pcall(function()
		referrals:UpdateAsync(keyOf(player.UserId), function(old)
			taken = 0
			if type(old) ~= "table" then
				return nil
			end
			local record = readRecord(old)
			total = #record.Ids
			if record.Pending <= 0 then
				return nil
			end
			taken = record.Pending
			record.Pending = 0
			return record, { player.UserId }
		end)
	end)
	claiming[player] = nil
	if not ok then
		warn(`Referidos de {player.Name}: {err}`)
		return
	end
	if player.Parent then
		player:SetAttribute("Referrals", total)
	end
	if taken <= 0 then
		return
	end
	if not DataService.get(player) then
		-- Se fue mientras tanto: lo cobrado vuelve a quedar pendiente
		pcall(function()
			referrals:UpdateAsync(keyOf(player.UserId), function(old)
				local record = readRecord(old)
				record.Pending += taken
				return record, { player.UserId }
			end)
		end)
		return
	end
	local coins = taken * rules.InviterCoins
	DataService.addCoins(player, coins, "Referido")
	DataService.changed(player, "Profile")
	DataService.saveNow(player)
	local friends = if taken == 1 then "Un amigo que invitaste terminó" else `{taken} amigos que invitaste terminaron`
	Remotes.Notify:FireClient(player, `🤝 {friends} su primera partida: +{coins} monedas (amigos invitados: {total}/{rules.MaxFriends})`)
end

-- Anota un premio pendiente para el invitador (si no llegó al tope y este
-- amigo no contó antes). Reintenta si Roblox falla.
local function credit(inviteeId: number, inviterId: number)
	local referrals = store
	if not referrals then
		return
	end
	local added = false
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			referrals:UpdateAsync(keyOf(inviterId), function(old)
				added = false
				local record = readRecord(old)
				if table.find(record.Ids, inviteeId) or #record.Ids >= rules.MaxFriends then
					return nil
				end
				table.insert(record.Ids, inviteeId)
				record.Pending += 1
				added = true
				return record, { inviterId }
			end)
		end)
		if ok then
			break
		end
		added = false
		warn(`Referidos (intento {attempt}): {err}`)
		task.wait(attempt * 2)
	end
	-- Si el invitador está en este servidor, cobra ya
	local inviter = Players:GetPlayerByUserId(inviterId)
	if added and inviter and DataService.get(inviter) then
		claim(inviter)
	end
end

-- Quién lo invitó según cómo entró: desde el Lobby (TeleportData.RefBy, en el
-- mismo orden que UserIds) o directo con la invitación (LaunchData)
local function inviterFromJoin(player: Player): number?
	local ok, joinData = pcall(function()
		return player:GetJoinData()
	end)
	if not ok or typeof(joinData) ~= "table" then
		return nil
	end
	local data: any = joinData.TeleportData
	if joinData.SourcePlaceId == Config.Places.Lobby and typeof(data) == "table" and typeof(data.UserIds) == "table" and typeof(data.RefBy) == "table" then
		local index = table.find(data.UserIds, player.UserId)
		local id = if index then data.RefBy[index] else nil
		if typeof(id) == "number" and id > 0 then
			return id
		end
	end
	return Invite.parse(joinData.LaunchData)
end

-- ¿Se le puede anotar un invitador? Solo antes de su primera partida terminada
local function canBeReferred(player: Player): boolean
	local data = DataService.get(player)
	return data ~= nil and data.ReferredBy == 0 and Progression.isNovice(data) and DataService.canSave(player)
end

local function checkInvitee(player: Player)
	if not store or not canBeReferred(player) then
		return
	end
	local inviterId = inviterFromJoin(player)
	-- Número entero, no él mismo y amigos de verdad (no se confía en lo que trae el viaje)
	if not inviterId or inviterId ~= math.floor(inviterId) or inviterId <= 0 or inviterId == player.UserId then
		return
	end
	local ok, isFriend = pcall(function()
		return player:IsFriendsWithAsync(inviterId)
	end)
	-- La consulta espera a Roblox: se revisa todo otra vez
	if not ok or isFriend ~= true or not player.Parent or not canBeReferred(player) then
		return
	end
	local data = DataService.get(player) :: Progression.Profile
	data.ReferredBy = inviterId
	Remotes.Notify:FireClient(player, `🤝 Te invitó un amigo: termina tu primera partida y ganan monedas los dos (+{rules.WelcomeCoins} para ti)`)
end

-- Se llama cuando el perfil del jugador terminó de cargar
function ReferralService.onPlayerReady(player: Player)
	player:SetAttribute("Referrals", 0)
	task.spawn(claim, player)
	task.spawn(checkInvitee, player)
end

-- Terminó su primera partida (MatchService.endMatch): premio de bienvenida y
-- premio pendiente para quien lo invitó
function ReferralService.onFirstMatch(player: Player)
	local data = DataService.get(player)
	local inviterId = if data then data.ReferredBy else 0
	if not data or type(inviterId) ~= "number" or inviterId <= 0 or inviterId == player.UserId then
		return
	end
	DataService.addCoins(player, rules.WelcomeCoins, "Referido")
	Remotes.Notify:FireClient(player, `🤝 ¡Terminaste tu primera partida con la invitación de un amigo! +{rules.WelcomeCoins} monedas`)
	task.spawn(credit, player.UserId, inviterId)
end

return ReferralService
