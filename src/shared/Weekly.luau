-- Reto semanal: cada semana (de lunes a lunes, hora UTC) cambia el modificador
-- de las oleadas y hay un ranking nuevo. Lo comparten el servidor de la partida
-- y el lobby, así los dos calculan la misma semana.
local Config = require(script.Parent.Config)

local DAY = 86400
local WEEK = 7 * DAY
local MONDAY_OFFSET = 4 * DAY -- el 1/1/1970 fue jueves: el lunes más cercano está 4 días después

local Weekly = {}

function Weekly.weekId(now: number?): number
	return ((now or os.time()) - MONDAY_OFFSET) // WEEK
end

-- El reto de esta semana (rota por la lista de Config.Weekly.Challenges)
function Weekly.current(now: number?): (any, number)
	local week = Weekly.weekId(now)
	local list = Config.Weekly.Challenges
	return list[week % #list + 1], week
end

function Weekly.secondsLeft(now: number?): number
	local t = now or os.time()
	return (Weekly.weekId(t) + 1) * WEEK + MONDAY_OFFSET - t
end

-- "3 d 4 h" o "5 h" para mostrar cuánto falta
function Weekly.timeLeftText(now: number?): string
	local seconds = Weekly.secondsLeft(now)
	local days = seconds // DAY
	local hours = (seconds % DAY) // 3600
	return if days > 0 then `{days} d {hours} h` else `{hours} h`
end

-- Puntos del ranking: más oleadas y más dificultad, más puntos
function Weekly.score(wave: number, difficultyId: number): number
	return math.floor(wave * (1 + (difficultyId - 1) * 0.5) * 10 + 0.5)
end

return Weekly
