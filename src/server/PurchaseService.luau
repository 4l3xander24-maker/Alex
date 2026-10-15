-- Compras con Robux dentro de la partida:
--   * Entrega los productos (bolsas de monedas y Revivir) con ProcessReceipt.
--     Cada compra se anota en el perfil para no entregarla dos veces.
--   * Bonos de los pases: Monedas x2, VIP (+XP) y lo del Pack Inicial
--     (se entrega una sola vez, aunque lo hayan comprado en el Lobby).
--   * Conecta las monedas del perfil a la tienda de skins.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)
local GameState = require(script.Parent.GameState)
local StoreService = require(script.Parent.StoreService)

local monetization = Config.Monetization
local MAX_RECEIPTS = 40

local PurchaseService = {}

local productKeyById: { [number]: string } = {}
for key, product in monetization.Products do
	if product.Id ~= 0 then
		productKeyById[product.Id] = key
	end
end

function PurchaseService.coinMultiplier(player: Player): number
	return if StoreService.hasPass(player, "DoubleCoins") then 2 else 1
end

function PurchaseService.xpMultiplier(player: Player): number
	return if StoreService.hasPass(player, "Vip") then 1 + monetization.VipXpBonus else 1
end

local function grant(player: Player, key: string)
	local product = (monetization.Products :: any)[key]
	if key == "Revive" then
		if PlayerService.revive(player) then
			Remotes.Notify:FireAllClients(`💖 {player.DisplayName} volvió a la pelea`)
		else
			-- Ya no se podía revivir (terminó la partida o ya estaba vivo)
			DataService.addCoins(player, monetization.ReviveRefund)
			Remotes.Notify:FireClient(player, `💖 No hacía falta revivir: te damos {monetization.ReviveRefund} monedas`)
		end
	elseif key == "Continue" then
		local count = PlayerService.reviveAll()
		-- Si había caído la campana, vuelve con la mitad de su vida
		local bellBack = GameState.isBellDestroyed()
		if bellBack then
			GameState.reviveBell(0.5)
		end
		if count > 0 or bellBack then
			Remotes.Notify:FireAllClients(`💖 ¡{player.DisplayName} pagó para seguir! La partida continúa`)
		else
			DataService.addCoins(player, monetization.ReviveRefund)
			Remotes.Notify:FireClient(player, `💖 Ya no se podía continuar: te damos {monetization.ReviveRefund} monedas`)
		end
	elseif product.Pet then
		local data = DataService.get(player)
		if data then
			data.Pets[product.Pet] = true
			data.Pet = product.Pet
			Remotes.Notify:FireClient(player, `{product.Icon} ¡{product.Name} ahora pelea a tu lado!`)
		end
	elseif product.WeaponSkin then
		local data = DataService.get(player)
		if data then
			data.WeaponSkins[product.WeaponSkin] = true
			data.WeaponSkin = product.WeaponSkin
			Remotes.Notify:FireClient(player, `{product.Icon} ¡{product.Name} puesta en tus armas!`)
		end
	elseif product.Coins then
		DataService.addCoins(player, product.Coins)
		Remotes.Notify:FireClient(player, `{product.Icon} +{product.Coins} monedas. ¡Gracias por tu compra!`)
	end
end

local function processReceipt(info): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local data = player and DataService.get(player)
	local key = productKeyById[info.ProductId]
	if not player or not data or not key then
		-- Roblox lo vuelve a intentar cuando el jugador entre de nuevo
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if table.find(data.Receipts, info.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local ok, err = pcall(grant, player, key)
	if not ok then
		warn(`Compra {key} de {player.Name}: {err}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(data.Receipts, info.PurchaseId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
	DataService.changed(player, "Shop")
	DataService.saveNow(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Pack Inicial: monedas y pistola mejorada, una sola vez por cuenta
local function grantStarterPack(player: Player)
	local data = DataService.get(player)
	if not data or data.StarterPack or not StoreService.hasPass(player, "StarterPack") then
		return
	end
	local pack = monetization.Passes.StarterPack
	data.StarterPack = true
	data.Coins += pack.Coins
	data.Weapons.Pistol = math.max(data.Weapons.Pistol or 0, pack.PistolLevel)
	DataService.changed(player, "Shop")
	DataService.saveNow(player)
	Remotes.Notify:FireClient(player, `{pack.Icon} ¡Pack Inicial! +{pack.Coins} monedas, pistola de Plata y la skin Pionero`)
end

-- Se llama cuando el perfil del jugador terminó de cargar
function PurchaseService.onPlayerReady(player: Player)
	task.spawn(grantStarterPack, player)
end

function PurchaseService.init()
	MarketplaceService.ProcessReceipt = processReceipt
	-- Skins con monedas: cobra del perfil y, si no se pudo guardar, devuelve
	StoreService.setCoinWallet(function(player, amount)
		if DataService.spendCoins(player, amount) then
			DataService.changed(player, "Shop")
			return true
		end
		return false
	end, function(player, amount)
		DataService.addCoins(player, amount)
		DataService.changed(player, "Shop")
	end)
	-- Al comprar un pase se avisa (el bono corre desde ya)
	StoreService.onPassBought(function(player, passId)
		for _, pass in monetization.Passes do
			if pass.Id == passId then
				Remotes.Notify:FireClient(player, `{pass.Icon} ¡{pass.Name} activado! {pass.Description}`)
			end
		end
		grantStarterPack(player)
	end)
end

return PurchaseService
