-- Energía del cuchillo (el círculo blanco del HUD): cada tajo gasta un poco y
-- se recarga sola cuando dejas de atacar un ratito. Cliente y servidor usan
-- las mismas cuentas (Config.Weapons.Machete.Energy).
local Config = require(script.Parent.Config)

local MeleeEnergy = {}

export type State = { Value: number, Time: number, LastUse: number }

local function settings()
	return Config.Weapons.Machete.Energy
end

function MeleeEnergy.new(): State
	return { Value = 1, Time = 0, LastUse = -math.huge }
end

-- Energía en el momento `now` (0 a 1)
function MeleeEnergy.get(state: State, now: number): number
	local energy = settings()
	local regenStart = math.max(state.Time, state.LastUse + energy.Delay)
	if now <= regenStart then
		return state.Value
	end
	return math.min(1, state.Value + (now - regenStart) * energy.Regen)
end

-- Intenta gastar un tajo. `tolerance` (0 a 1) deja pasar un poco menos de lo
-- que cuesta, para el servidor (por el lag).
function MeleeEnergy.use(state: State, now: number, tolerance: number?): boolean
	local cost = settings().Cost
	local current = MeleeEnergy.get(state, now)
	if current < cost * (1 - (tolerance or 0)) - 1e-6 then
		return false
	end
	state.Value = math.max(0, current - cost)
	state.Time = now
	state.LastUse = now
	return true
end

-- true si alcanza para otro tajo
function MeleeEnergy.canUse(state: State, now: number): boolean
	return MeleeEnergy.get(state, now) >= settings().Cost - 1e-6
end

-- Recarga completa (al empezar la partida o al reaparecer)
function MeleeEnergy.refill(state: State)
	state.Value = 1
	state.Time = 0
	state.LastUse = -math.huge
end

return MeleeEnergy
