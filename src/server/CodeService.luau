-- Canje de códigos de regalo (GiftCodes). El cliente solo manda el texto; el
-- servidor revisa que exista, que no haya vencido y que no lo hayas usado, y
-- limita los intentos por jugador para que no se puedan adivinar a la fuerza.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Progression = require(ReplicatedStorage.Shared.Progression)
local DataService = require(script.Parent.DataService)
local GiftCodes = require(script.Parent.GiftCodes)

local MAX_LENGTH = 32

local CodeService = {}

local byCode: { [string]: any } = {}
for _, gift in GiftCodes.List do
	byCode[string.upper(gift.Code)] = gift
end

local skinIds: { [string]: boolean } = {}
for _, skin in Config.ObjectSkins do
	skinIds[skin.Id] = true
end

type Limit = { Last: number, Fails: number, LockedUntil: number }
local limits: { [Player]: Limit } = {}

-- Devuelve false con el motivo si el jugador va demasiado rápido o está bloqueado
local function allowed(player: Player): (boolean, string)
	local now = os.clock()
	local limit = limits[player]
	if not limit then
		limit = { Last = -1e9, Fails = 0, LockedUntil = 0 }
		limits[player] = limit
	end
	if now < limit.LockedUntil then
		return false, `⏳ Demasiados intentos. Espera {math.ceil(limit.LockedUntil - now)} s`
	end
	if now - limit.Last < GiftCodes.Cooldown then
		return false, "⏳ Espera un momento antes de probar otro código"
	end
	limit.Last = now
	return true, ""
end

-- Un intento fallido; al llegar a MaxFails seguidos se bloquea un rato
local function fail(player: Player, message: string): (boolean, string)
	local limit = limits[player]
	if limit then
		limit.Fails += 1
		if limit.Fails >= GiftCodes.MaxFails then
			limit.Fails = 0
			limit.LockedUntil = os.clock() + GiftCodes.Lockout
		end
	end
	return false, message
end

-- Canjea `text` para este jugador. Devuelve si salió bien y el mensaje para mostrar.
function CodeService.redeem(player: Player, data: Progression.Profile, text: any): (boolean, string)
	if typeof(text) ~= "string" then
		return false, "Código inválido"
	end
	local ok, reason = allowed(player)
	if not ok then
		return false, reason
	end
	-- Sin espacios de más y sin importar mayúsculas
	local key = string.upper(string.match(string.sub(text, 1, MAX_LENGTH), "^%s*(.-)%s*$") or "")
	if key == "" then
		return false, "Escribe un código"
	end
	local gift = byCode[key]
	if not gift then
		return fail(player, "❌ Ese código no existe")
	end
	if gift.Until and os.time() >= gift.Until then
		return fail(player, "⌛ Ese código ya venció")
	end
	if data.Codes[key] then
		return fail(player, "Ya canjeaste ese código")
	end
	-- Se marca antes de pagar (sin esperas de por medio): no se puede cobrar dos veces
	data.Codes[key] = true
	local coins = gift.Coins or 0
	DataService.addCoins(player, coins)
	local skin = gift.ObjectSkin
	local gotSkin = skin ~= nil and skinIds[skin] == true and not data.ObjectSkins[skin]
	if gotSkin then
		data.ObjectSkins[skin] = true
	end
	-- Un acierto limpia los fallos seguidos
	local limit = limits[player]
	if limit then
		limit.Fails = 0
	end
	-- Guarda ya: el código no debe volver a canjearse si el servidor se cae
	task.spawn(DataService.saveNow, player)
	return true, `🎁 ¡Código canjeado! +{coins} monedas{if gotSkin then " + una skin nueva" else ""}`
end

function CodeService.init()
	Players.PlayerRemoving:Connect(function(player)
		limits[player] = nil
	end)
end

return CodeService
