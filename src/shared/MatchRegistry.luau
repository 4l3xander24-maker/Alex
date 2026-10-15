-- Registro (MemoryStore) de las partidas en curso para poder reconectarse:
--   * El Lobby anota, para cada jugador que sale a una partida, el código del
--     servidor reservado donde juega.
--   * El servidor de la partida marca "sigo vivo" cada pocos segundos.
--   * Si alguien se desconecta y vuelve al Lobby, ahí le sale el botón para
--     volver a su partida (mientras el servidor siga vivo).
-- Todo va con pcall: sin MemoryStore (Studio sin acceso) simplemente no hay reconexión.
local MemoryStoreService = game:GetService("MemoryStoreService")

local PLAYER_TTL = 3 * 60 * 60 -- cuánto se recuerda a un jugador
local ALIVE_TTL = 100 -- sin latido en este tiempo = partida terminada

local MatchRegistry = {}

MatchRegistry.HeartbeatEvery = 30

local players: MemoryStoreHashMap? = nil
local alive: MemoryStoreHashMap? = nil
pcall(function()
	players = MemoryStoreService:GetHashMap("CM_ReconnectPlayers")
	alive = MemoryStoreService:GetHashMap("CM_ReconnectAlive")
end)

export type Record = { Code: string, Id: string }

function MatchRegistry.register(userIds: { number }, code: string, privateId: string)
	local map = players
	if not map then
		return
	end
	for _, userId in userIds do
		pcall(function()
			map:SetAsync(tostring(userId), { Code = code, Id = privateId }, PLAYER_TTL)
		end)
	end
	MatchRegistry.heartbeat(privateId)
end

function MatchRegistry.lookup(userId: number): Record?
	local map = players
	if not map then
		return nil
	end
	local ok, value = pcall(function()
		return map:GetAsync(tostring(userId))
	end)
	if ok and typeof(value) == "table" and value.Code and value.Id then
		return value :: Record
	end
	return nil
end

function MatchRegistry.clear(userId: number)
	local map = players
	if map then
		pcall(function()
			map:RemoveAsync(tostring(userId))
		end)
	end
end

function MatchRegistry.heartbeat(privateId: string)
	local map = alive
	if map then
		pcall(function()
			map:SetAsync(privateId, true, ALIVE_TTL)
		end)
	end
end

function MatchRegistry.finish(privateId: string)
	local map = alive
	if map then
		pcall(function()
			map:RemoveAsync(privateId)
		end)
	end
end

function MatchRegistry.isAlive(privateId: string): boolean
	local map = alive
	if not map then
		return false
	end
	local ok, value = pcall(function()
		return map:GetAsync(privateId)
	end)
	return ok and value == true
end

return MatchRegistry
