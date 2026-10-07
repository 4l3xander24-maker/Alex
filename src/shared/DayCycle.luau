-- Ciclo de día y noche. La hora sale del reloj del servidor, así que el
-- servidor y todos los clientes ven exactamente la misma hora sin mandarla
-- por la red.
local Config = require(script.Parent.Config)

local DayCycle = {}

local cycle = Config.DayCycle
local theme = Config.Themes[Config.Theme] or {}

-- Horas en que empieza y termina cada transición
local DUSK_START, NIGHT_START = 17, 19.5
local DAWN_START, DAY_START = 4.5, 7

-- true si el tema actual tiene paletas de día y de noche
function DayCycle.isEnabled(): boolean
	return cycle.Enabled and theme.Day ~= nil and theme.Dusk ~= nil
end

-- Hora del día (0 a 24) para un tiempo del servidor
function DayCycle.getClock(serverTime: number): number
	return (cycle.StartClock + (serverTime % cycle.Length) / cycle.Length * 24) % 24
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- 0 = pleno día, 1 = noche cerrada (con transiciones suaves al atardecer y al amanecer)
function DayCycle.getNightFactor(clock: number): number
	if clock >= DUSK_START and clock < NIGHT_START then
		return smooth((clock - DUSK_START) / (NIGHT_START - DUSK_START))
	elseif clock >= DAWN_START and clock < DAY_START then
		return 1 - smooth((clock - DAWN_START) / (DAY_START - DAWN_START))
	elseif clock >= DAY_START and clock < DUSK_START then
		return 0
	end
	return 1
end

-- Cuánto del color del atardecer hay (0 a 1): máximo a mitad de cada transición
function DayCycle.getDuskFactor(clock: number): number
	local night = DayCycle.getNightFactor(clock)
	return 1 - math.abs(night * 2 - 1)
end

-- Noche a esta hora del servidor (si el ciclo está apagado, según el tema)
function DayCycle.getNightFactorAt(serverTime: number): number
	if not DayCycle.isEnabled() then
		return if theme.Night then 1 else 0
	end
	return DayCycle.getNightFactor(DayCycle.getClock(serverTime))
end

function DayCycle.isNight(serverTime: number): boolean
	return DayCycle.getNightFactorAt(serverTime) >= 0.5
end

-- Texto de la hora para el HUD, por ejemplo "🌙 22:15"
function DayCycle.describe(clock: number): string
	local night = DayCycle.getNightFactor(clock)
	local icon = if night >= 0.85 then "🌙" elseif night > 0.15 then (if clock > 12 then "🌇" else "🌅") else "☀️"
	local hours = math.floor(clock)
	local minutes = math.floor((clock - hours) * 60)
	return string.format("%s %02d:%02d", icon, hours, minutes)
end

local Lighting = game:GetService("Lighting")

type Palette = {
	Brightness: number,
	Ambient: Color3,
	Atmosphere: Color3,
	Decay: Color3,
	Density: number,
	Haze: number,
	Tint: Color3,
}

local function lerpPalette(a: Palette, b: Palette, t: number): Palette
	return {
		Brightness = a.Brightness + (b.Brightness - a.Brightness) * t,
		Ambient = a.Ambient:Lerp(b.Ambient, t),
		Atmosphere = a.Atmosphere:Lerp(b.Atmosphere, t),
		Decay = a.Decay:Lerp(b.Decay, t),
		Density = a.Density + (b.Density - a.Density) * t,
		Haze = a.Haze + (b.Haze - a.Haze) * t,
		Tint = a.Tint:Lerp(b.Tint, t),
	}
end

-- Colores del cielo y la luz a esta hora: día → atardecer → noche
function DayCycle.getPalette(clock: number): Palette
	local night = DayCycle.getNightFactor(clock)
	local nightPalette = theme :: any
	if night < 0.5 then
		return lerpPalette(theme.Day, theme.Dusk, night * 2)
	end
	return lerpPalette(theme.Dusk, nightPalette, (night - 0.5) * 2)
end

-- Qué tan rojo está el cielo en esa oleada (0 = normal, 1 = luna de sangre)
function DayCycle.getRedness(wave: number): number
	local full = Config.DayCycle.BloodMoon.FullAtWave
	return math.clamp((wave - 1) / math.max(full - 1, 1), 0, 1)
end

-- Pone la hora y los colores en Lighting (lo usa el servidor al empezar y
-- cada cliente varias veces por segundo). `redness` tiñe todo de rojo.
function DayCycle.applyLighting(clock: number, redness: number?)
	local palette = DayCycle.getPalette(clock)
	local night = DayCycle.getNightFactor(clock)
	local red = redness or 0
	local blood = Config.DayCycle.BloodMoon
	Lighting.ClockTime = clock
	Lighting.Brightness = palette.Brightness
	Lighting.Ambient = palette.Ambient:Lerp(blood.Ambient, red * 0.7)
	Lighting.OutdoorAmbient = Lighting.Ambient
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Color = palette.Atmosphere:Lerp(blood.Atmosphere, red * 0.85)
		atmosphere.Decay = palette.Decay:Lerp(blood.Decay, red * 0.85)
		atmosphere.Density = palette.Density
		atmosphere.Haze = palette.Haze
		atmosphere.Glare = 0.2 + 0.3 * (1 - night)
	end
	local correction = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	if correction then
		correction.TintColor = palette.Tint:Lerp(blood.Tint, red * 0.8)
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		bloom.Intensity = 0.4 + 0.4 * night
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		local stars = if night > 0.6 then 3000 else 0
		if sky.StarCount ~= stars then
			sky.StarCount = stars
		end
	end
end

return DayCycle
