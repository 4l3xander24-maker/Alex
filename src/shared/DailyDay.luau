-- Cuentas del día de juego, sin depender de Roblox (se pueden probar solas).
-- El día cambia a la hora resetHour en UTC, no a medianoche. Lo usan
-- DailyService (servidor) y AchievementsUi (cliente), así ven las mismas misiones.
local DailyDay = {}

local SECONDS_PER_DAY = 86400

-- Número de día de juego de una marca de tiempo (os.time())
function DailyDay.gameDay(timestamp: number, resetHour: number): number
	return math.floor((timestamp - resetHour * 3600) / SECONDS_PER_DAY)
end

-- Elige `count` entradas de `pool` según el día: siempre las mismas para un día dado
function DailyDay.pick<T>(pool: { T }, day: number, count: number): { T }
	local order = {}
	for index = 1, #pool do
		order[index] = index
	end
	-- Generador Park-Miller (propio, para que cliente y servidor coincidan siempre)
	local state = (day * 7919 + 12345) % 2147483646 + 1
	local function nextValue(): number
		state = (state * 48271) % 2147483647
		return state
	end
	for _ = 1, 4 do
		nextValue()
	end
	local picked = {}
	for slot = 1, math.min(count, #pool) do
		local other = slot + nextValue() % (#pool - slot + 1)
		order[slot], order[other] = order[other], order[slot]
		table.insert(picked, pool[order[slot]])
	end
	return picked
end

-- Racha: cuántos días lleva tras entrar hoy. Devuelve la cuenta nueva y si cambió
-- (si ya entró hoy no cambia; si entró ayer sube uno; si faltó algún día vuelve a 1)
function DailyDay.nextStreak(lastDay: number, today: number, count: number): (number, boolean)
	if lastDay == today then
		return count, false
	elseif lastDay == today - 1 then
		return count + 1, true
	end
	return 1, true
end

-- Día del ciclo (1 a cycleLength) que le toca a una racha de `count` días
function DailyDay.cycleDay(count: number, cycleLength: number): number
	return (math.max(count, 1) - 1) % cycleLength + 1
end

return DailyDay
