-- Estado de la partida. Se publica como atributos de ReplicatedStorage.GameState
-- para que el HUD de cada cliente lo lea.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local GameState = {}

local folder = Instance.new("Folder")
folder.Name = "GameState"

local castleHealth = Config.Castle.MaxHealth

function GameState.init()
	folder:SetAttribute("State", "Waiting")
	folder:SetAttribute("Wave", 0)
	folder:SetAttribute("Countdown", 0)
	folder:SetAttribute("EnemiesLeft", 0)
	folder:SetAttribute("CastleMaxHealth", Config.Castle.MaxHealth)
	folder:SetAttribute("CastleHealth", castleHealth)
	folder.Parent = ReplicatedStorage
end

function GameState.set(name: string, value: any)
	folder:SetAttribute(name, value)
end

function GameState.damageCastle(amount: number)
	if castleHealth <= 0 then
		return
	end
	castleHealth = math.max(0, castleHealth - amount)
	-- Solo replicamos cuando cambia el número entero que ve el jugador
	local shown = math.ceil(castleHealth)
	if shown ~= folder:GetAttribute("CastleHealth") then
		folder:SetAttribute("CastleHealth", shown)
	end
end

function GameState.isCastleDestroyed(): boolean
	return castleHealth <= 0
end

function GameState.resetCastle()
	castleHealth = Config.Castle.MaxHealth
	folder:SetAttribute("CastleHealth", castleHealth)
end

return GameState
