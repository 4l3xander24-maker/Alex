-- Ranking global (OrderedDataStore): mejor oleada y bajas totales de cada
-- jugador. La partida sube los valores al terminar y el lobby muestra el top.
-- En Studio sin acceso a la API no hace nada (el lobby muestra la tabla vacía).
local DataStoreService = game:GetService("DataStoreService")

local Leaderboard = {}

local STORES = {
	BestWave = "Top_BestWave_v1",
	Kills = "Top_Kills_v1",
}

export type Row = { UserId: number, Value: number }

local cache: { [string]: OrderedDataStore } = {}

local function storeFor(stat: string): OrderedDataStore?
	if cache[stat] then
		return cache[stat]
	end
	local name = STORES[stat]
	if not name then
		return nil
	end
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(name)
	end)
	if ok then
		cache[stat] = store
		return store
	end
	return nil
end

-- Guarda el valor del jugador (en segundo plano, no frena la partida)
function Leaderboard.submit(userId: number, stat: string, value: number)
	if userId <= 0 or value <= 0 then
		return
	end
	task.spawn(function()
		local store = storeFor(stat)
		if not store then
			return
		end
		local ok, err = pcall(function()
			store:SetAsync(tostring(userId), math.floor(value))
		end)
		if not ok then
			warn(`Ranking {stat}: {err}`)
		end
	end)
end

-- Los `count` mejores, de mayor a menor. nil si no se pudo leer.
function Leaderboard.top(stat: string, count: number): { Row }?
	local store = storeFor(stat)
	if not store then
		return nil
	end
	local ok, result = pcall(function()
		local page = store:GetSortedAsync(false, count):GetCurrentPage()
		local rows: { Row } = {}
		for _, entry in page do
			local userId = tonumber(entry.key)
			if userId then
				table.insert(rows, { UserId = userId, Value = entry.value })
			end
		end
		return rows
	end)
	return if ok then result else nil
end

return Leaderboard
