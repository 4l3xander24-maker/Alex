-- Analíticas de Roblox (Creator Hub → Analytics). Solo en el servidor: lo usan
-- la Partida y el Lobby (lobby.project.json lo copia). Cada llamada va en su
-- propio hilo y protegida con pcall: si Roblox falla o tarda, el juego sigue
-- igual. Nunca se mandan datos personales (ni nombres ni textos escritos).
-- Explicación para el dueño en docs/analiticas.md.
local AnalyticsService = game:GetService("AnalyticsService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Analytics = {}

-- Embudo de bienvenida (Onboarding): una sola vez por jugador, en orden. Los
-- números son los mismos en el Lobby (1 a 3) y en la Partida (4 a 10).
Analytics.Step = {
	JoinedLobby = 1,
	EnteredRoom = 2,
	Teleport = 3,
	Arrived = 4,
	Started = 5,
	Wave1 = 6,
	Wave3 = 7,
	FirstPurchase = 8,
	FirstMatch = 9,
	FirstVictory = 10,
}
local STEP_NAMES = {
	"Entró al Lobby",
	"Entró a una sala",
	"Viaja a la partida",
	"Llegó a la partida",
	"Reconstruyó la campana",
	"Superó la oleada 1",
	"Superó la oleada 3",
	"Primera compra",
	"Terminó su primera partida",
	"Primera victoria",
}

-- Embudo de cada partida ("Partida"): se repite en cada partida, con su id
Analytics.MatchStep = {
	Started = 1,
	Wave3 = 2,
	Wave5 = 3,
	Boss = 4,
	Goal = 5,
	Victory = 6,
	Endless = 7,
}
local MATCH_FUNNEL = "Partida"
local MATCH_NAMES = {
	"Empezó",
	"Llegó a la oleada 3",
	"Llegó a la oleada 5",
	"Venció una oleada de jefe",
	"Llegó a la oleada meta",
	"Victoria",
	"Eligió seguir (sin fin)",
}

-- Monedas: de dónde salen (reason de DataService.addCoins) y qué tipo de
-- transacción es para Roblox. Lo que no está en la lista cuenta como Gameplay.
local CURRENCY = "Monedas"
local TYPE = Enum.AnalyticsEconomyTransactionType
local SOURCE_TYPES: { [string]: string } = {
	Zombi = TYPE.Gameplay.Name,
	Oleadas = TYPE.Gameplay.Name,
	Objetivo = TYPE.Gameplay.Name,
	JefeFinal = TYPE.Gameplay.Name,
	Dificultad = TYPE.Gameplay.Name,
	Conquista = TYPE.Gameplay.Name,
	Logro = TYPE.Gameplay.Name,
	Bestiario = TYPE.Gameplay.Name,
	Mision = TYPE.TimedReward.Name,
	Racha = TYPE.TimedReward.Name,
	Semanal = TYPE.TimedReward.Name,
	Pase = TYPE.TimedReward.Name,
	Codigo = TYPE.Onboarding.Name,
	Referido = TYPE.Onboarding.Name,
	Robux = TYPE.IAP.Name,
	PackInicial = TYPE.IAP.Name,
	ReembolsoRobux = TYPE.IAP.Name,
	Reembolso = TYPE.Shop.Name,
}
-- Gastos: la categoría es lo que va antes de "_" en el itemSku. Las trampas se
-- compran en el terreno (ContextualPurchase); lo demás, en las tiendas (Shop).
local SINK_TYPES: { [string]: string } = {
	Trampa = TYPE.ContextualPurchase.Name,
}
-- Las monedas por zombi se juntan y se mandan de a una vez (cada FLUSH_EVERY
-- segundos, al salir o antes de otro movimiento): un evento por baja pasaría
-- el límite de eventos por minuto de Roblox
local BATCHED = { Zombi = true }
local FLUSH_EVERY = 60

local FIELD_KEYS = {
	Enum.AnalyticsCustomFieldKeys.CustomField01.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField02.Name,
	Enum.AnalyticsCustomFieldKeys.CustomField03.Name,
}

local warned = false

-- Corre la llamada en su propio hilo; un error solo se avisa una vez
local function safe(call: () -> ())
	task.spawn(function()
		local ok, err = pcall(call)
		if not ok and not warned then
			warned = true
			warn(`Analíticas: {err}`)
		end
	end)
end

-- Hasta 3 campos propios (límite de Roblox), como texto "Nombre - valor"
local function fields(list: { string }?): { [string]: any }?
	if not list then
		return nil
	end
	local result = {}
	for index, value in list do
		local key = FIELD_KEYS[index]
		if key then
			result[key] = value
		end
	end
	return result
end

local onboarded: { [Player]: { [number]: boolean } } = {}
local matchLogged: { [Player]: { [number]: boolean } } = {}
local matchId = ""
-- Monedas por zombi todavía sin mandar: cantidad y saldo después de la última
local pending: { [Player]: { Amount: number, Balance: number, Reason: string } } = {}

-- Paso del embudo de bienvenida (Roblox además cuenta cada paso una sola vez)
function Analytics.onboarding(player: Player, step: number)
	local done = onboarded[player] or {}
	onboarded[player] = done
	if done[step] or not STEP_NAMES[step] then
		return
	end
	done[step] = true
	safe(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, STEP_NAMES[step])
	end)
end

-- Empieza una partida nueva: los pasos del embudo "Partida" van con este id
function Analytics.newMatch()
	matchId = HttpService:GenerateGUID(false)
	table.clear(matchLogged)
end

-- Paso del embudo de la partida en curso, para un jugador (una vez por partida)
function Analytics.matchStep(player: Player, step: number)
	if matchId == "" or not MATCH_NAMES[step] then
		return
	end
	local done = matchLogged[player] or {}
	matchLogged[player] = done
	if done[step] then
		return
	end
	done[step] = true
	local session = matchId
	safe(function()
		AnalyticsService:LogFunnelStepEvent(player, MATCH_FUNNEL, session, step, MATCH_NAMES[step])
	end)
end

-- El mismo paso para todos los jugadores presentes
function Analytics.matchStepAll(step: number)
	for _, player in Players:GetPlayers() do
		Analytics.matchStep(player, step)
	end
end

local function flush(player: Player)
	local batch = pending[player]
	if not batch then
		return
	end
	pending[player] = nil
	safe(function()
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Source, CURRENCY, batch.Amount, batch.Balance, SOURCE_TYPES[batch.Reason] or TYPE.Gameplay.Name, batch.Reason)
	end)
end

-- Entraron monedas. balance = saldo real después de sumarlas.
function Analytics.coinsIn(player: Player, amount: number, balance: number, reason: string)
	if amount <= 0 then
		return
	end
	if BATCHED[reason] then
		local batch = pending[player]
		if batch and batch.Reason == reason then
			batch.Amount += amount
			batch.Balance = balance
		else
			flush(player)
			pending[player] = { Amount = amount, Balance = balance, Reason = reason }
		end
		return
	end
	-- Lo juntado antes va primero, así los saldos quedan en orden
	flush(player)
	safe(function()
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Source, CURRENCY, amount, balance, SOURCE_TYPES[reason] or TYPE.Gameplay.Name, reason)
	end)
end

-- Salieron monedas. sku = "Categoría_Id" (p. ej. "Arma_Shotgun"); balance = saldo después
function Analytics.coinsOut(player: Player, amount: number, balance: number, sku: string)
	if amount <= 0 then
		return
	end
	flush(player)
	local category = string.match(sku, "^[^_]+") or sku
	safe(function()
		AnalyticsService:LogEconomyEvent(player, Enum.AnalyticsEconomyFlowType.Sink, CURRENCY, amount, balance, SINK_TYPES[category] or TYPE.Shop.Name, sku)
	end)
end

-- Evento propio de poco volumen. extra: hasta 3 textos "Nombre - valor"
function Analytics.custom(player: Player, name: string, value: number?, extra: { string }?)
	safe(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1, fields(extra))
	end)
end

Players.PlayerRemoving:Connect(function(player)
	flush(player)
	onboarded[player] = nil
	matchLogged[player] = nil
end)

task.spawn(function()
	while true do
		task.wait(FLUSH_EVERY)
		for player in pending do
			flush(player)
		end
	end
end)

return Analytics
