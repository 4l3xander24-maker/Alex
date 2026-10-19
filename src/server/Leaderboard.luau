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

-- Salón de la fama: el primer jugador del mundo en superar cada dificultad.
-- Se guarda una sola vez por dificultad (el que llega después no lo cambia).
local HALL_STORE = "CampanaMaldita_Hall_v1"
export type HallRecord = { UserId: number, Name: string, At: number }

local function hallStore(): DataStore?
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(HALL_STORE)
	end)
	return if ok then store else nil
end

function Leaderboard.hallRead(difficultyId: number): HallRecord?
	local store = hallStore()
	if not store then
		return nil
	end
	local ok, result = pcall(function()
		return store:GetAsync(`Diff{difficultyId}`)
	end)
	return if ok and type(result) == "table" then result else nil
end

-- true si este jugador quedó como el primero (nadie lo había superado antes)
function Leaderboard.hallClaim(difficultyId: number, record: HallRecord): boolean
	local store = hallStore()
	if not store then
		return false
	end
	local won = false
	local ok, err = pcall(function()
		store:UpdateAsync(`Diff{difficultyId}`, function(old)
			if old ~= nil then
				return nil -- ya tenía dueño: se cancela
			end
			won = true
			return record
		end)
	end)
	if not ok then
		warn(`Salón de la fama: {err}`)
		return false
	end
	return won
end

-- Ranking semanal: se guarda el mejor puntaje de cada jugador en la semana
local function weeklyStore(weekId: number): OrderedDataStore?
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(`Weekly_v1_{weekId}`)
	end)
	return if ok then store else nil
end

function Leaderboard.weeklySubmit(weekId: number, userId: number, score: number)
	if userId <= 0 or score <= 0 then
		return
	end
	task.spawn(function()
		local store = weeklyStore(weekId)
		if not store then
			return
		end
		local ok, err = pcall(function()
			store:UpdateAsync(tostring(userId), function(old)
				if old == nil or score > old then
					return score
				end
				return nil
			end)
		end)
		if not ok then
			warn(`Ranking semanal: {err}`)
		end
	end)
end

function Leaderboard.weeklyTop(weekId: number, count: number): { Row }?
	local store = weeklyStore(weekId)
	if not store then
		return nil
	end
	local ok, result = pcall(function()
		local rows: { Row } = {}
		for _, entry in store:GetSortedAsync(false, count):GetCurrentPage() do
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
