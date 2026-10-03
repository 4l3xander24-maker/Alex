-- Compras y mejoras de los NPC del campamento:
-- Armero (armas), Bruja (poderes), Veterano (estadísticas y talentos) e
-- Intendente (cartuchera y trampas).
-- Solo se puede comprar durante la preparación, antes de empezar la partida.
-- El cliente solo pide; el servidor revisa monedas, puntos y requisitos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GameState = require(script.Parent.GameState)
local TrapService = require(script.Parent.TrapService)

local NOT_ENOUGH = "No tienes suficientes monedas"
local CLOSED = "🔒 Las tiendas solo abren antes de la partida"
-- Acciones que se pueden hacer en cualquier momento
local ALWAYS_ALLOWED = { EquipWeapon = true }

local ShopService = {}

type Profile = Progression.Profile

local actions: { [string]: (Player, Profile, string) -> (boolean, string) } = {}

function actions.BuyWeapon(player, data, id)
	local weapon = Config.Weapons[id]
	if not weapon then
		return false, "Arma desconocida"
	end
	if data.Weapons[id] then
		return false, "Ya tienes esta arma"
	end
	if not DataService.spendCoins(player, weapon.Price) then
		return false, NOT_ENOUGH
	end
	data.Weapons[id] = 0
	data.Equipped = id
	return true, `¡Compraste {weapon.DisplayName}!`
end

function actions.UpgradeWeapon(player, data, id)
	local level = data.Weapons[id]
	if not level or not Config.Weapons[id] then
		return false, "Primero compra esta arma"
	end
	if level >= Config.WeaponUpgrade.MaxLevel then
		return false, "Esta arma ya está al máximo"
	end
	if not DataService.spendCoins(player, Progression.weaponUpgradeCost(id, level)) then
		return false, NOT_ENOUGH
	end
	data.Weapons[id] = level + 1
	return true, `{Config.Weapons[id].DisplayName} mejorada a nivel {level + 1}`
end

function actions.EquipWeapon(_player, data, id)
	if not data.Weapons[id] then
		return false, "No tienes esta arma"
	end
	data.Equipped = id
	return true, `Equipaste {Config.Weapons[id].DisplayName}`
end

function actions.BuyPower(player, data, id)
	local power = Config.Powers[id]
	if not power then
		return false, "Poder desconocido"
	end
	if data.Powers[id] then
		return false, "Ya tienes este poder"
	end
	if not DataService.spendCoins(player, power.Price) then
		return false, NOT_ENOUGH
	end
	data.Powers[id] = 1
	return true, `¡Aprendiste {power.DisplayName}! Úsalo con la tecla {power.Key.Name}`
end

function actions.UpgradePower(player, data, id)
	local power = Config.Powers[id]
	local level = data.Powers[id]
	if not power or not level then
		return false, "Primero compra este poder"
	end
	if level >= power.MaxLevel then
		return false, "Este poder ya está al máximo"
	end
	if not DataService.spendCoins(player, Progression.powerUpgradeCost(id, level)) then
		return false, NOT_ENOUGH
	end
	data.Powers[id] = level + 1
	return true, `{power.DisplayName} subió a nivel {level + 1}`
end

function actions.AddStat(_player, data, id)
	local info = Progression.getStatInfo(id)
	if not info then
		return false, "Mejora desconocida"
	end
	if data.StatPoints <= 0 then
		return false, "No tienes puntos. Sube de nivel terminando partidas"
	end
	local points = data.Stats[id] or 0
	if points >= info.Max then
		return false, `{info.Name} ya está al máximo`
	end
	data.Stats[id] = points + 1
	data.StatPoints -= 1
	return true, `{info.Name}: {Progression.describeStat(id, points + 1)}`
end

function actions.LearnTalent(_player, data, id)
	local info = Progression.getTalentInfo(id)
	if not info then
		return false, "Talento desconocido"
	end
	if data.Talents[id] then
		return false, "Ya conoces este talento"
	end
	if data.TalentPoints <= 0 then
		return false, `Ganas un talento cada {Config.Progression.TalentEvery} niveles`
	end
	data.Talents[id] = true
	data.TalentPoints -= 1
	return true, `¡Aprendiste {info.Name}!`
end

function actions.UpgradeStorage(player, data)
	local level = data.AmmoStorage or 0
	local cost = Progression.ammoStorageCost(level)
	if not cost then
		return false, "La cartuchera ya está al máximo"
	end
	if not DataService.spendCoins(player, cost) then
		return false, NOT_ENOUGH
	end
	data.AmmoStorage = level + 1
	return true, `Cartuchera nivel {level + 1}: puedes cargar más balas`
end

function actions.BuyMine(player)
	if not TrapService.canPlaceMine() then
		return false, "Ya están todas las minas puestas"
	end
	if not DataService.spendCoins(player, Config.Traps.Mine.Price) then
		return false, NOT_ENOUGH
	end
	TrapService.placeMine(player)
	return true, "🪤 Mina enterrada en el camino de los zombis"
end

function actions.BuyGate(player, _data, id)
	local slot = Config.Traps.Gate.Slots[id]
	if not slot then
		return false, "Reja desconocida"
	end
	if TrapService.hasGate(id) then
		return false, `La {slot.Name:lower()} ya está construida`
	end
	if not DataService.spendCoins(player, Config.Traps.Gate.Price) then
		return false, NOT_ENOUGH
	end
	TrapService.buildGate(id)
	return true, `🚧 {slot.Name} construida`
end

function ShopService.isOpen(): boolean
	return GameState.get("State") == "Lobby"
end

function ShopService.init()
	Remotes.ShopAction.OnServerInvoke = function(player: Player, action: any, id: any)
		if typeof(action) ~= "string" or typeof(id) ~= "string" or not actions[action] then
			return false, "Acción inválida"
		end
		local data = DataService.get(player)
		if not data then
			return false, "Tu perfil aún está cargando"
		end
		if not ALWAYS_ALLOWED[action] and not ShopService.isOpen() then
			return false, CLOSED
		end
		local ok, message = actions[action](player, data, id)
		if ok then
			DataService.changed(player, if action == "EquipWeapon" then "Equip" else "Shop")
		end
		return ok, message
	end

	-- Cambio rápido de arma con las teclas 1-5 (no pasa por la tienda)
	Remotes.EquipWeapon.OnServerEvent:Connect(function(player, id)
		local data = DataService.get(player)
		if data and typeof(id) == "string" and data.Weapons[id] and data.Equipped ~= id then
			data.Equipped = id
			DataService.changed(player, "Equip")
		end
	end)
end

return ShopService
