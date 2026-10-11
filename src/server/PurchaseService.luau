-- Compras con Robux dentro de la partida:
--   * Entrega los productos (bolsas de monedas y Revivir) con ProcessReceipt.
--     Cada compra se anota en el perfil para no entregarla dos veces.
--   * Bonos de los pases: Monedas x2 y VIP (+XP).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local PlayerService = require(script.Parent.PlayerService)
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

function PurchaseService.init()
	MarketplaceService.ProcessReceipt = processReceipt
	-- Al comprar VIP o Monedas x2 se avisa (el bono corre desde ya)
	StoreService.onPassBought(function(player, passId)
		for _, pass in monetization.Passes do
			if pass.Id == passId then
				Remotes.Notify:FireClient(player, `{pass.Icon} ¡{pass.Name} activado! {pass.Description}`)
			end
		end
	end)
end

return PurchaseService
