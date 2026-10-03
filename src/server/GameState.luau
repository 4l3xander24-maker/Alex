-- Estado de la partida. Se publica como atributos de ReplicatedStorage.GameState
-- para que el HUD de cada cliente lo lea.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local GameState = {}

local folder = Instance.new("Folder")
folder.Name = "GameState"

local bellHealth = Config.Bell.MaxHealth

function GameState.init()
	folder:SetAttribute("State", "Waiting")
	folder:SetAttribute("Wave", 0)
	folder:SetAttribute("Countdown", 0)
	folder:SetAttribute("EnemiesLeft", 0)
	folder:SetAttribute("BellMaxHealth", Config.Bell.MaxHealth)
	folder:SetAttribute("BellHealth", bellHealth)
	folder.Parent = ReplicatedStorage
end

function GameState.set(name: string, value: any)
	folder:SetAttribute(name, value)
end

function GameState.get(name: string): any
	return folder:GetAttribute(name)
end

function GameState.damageBell(amount: number)
	if bellHealth <= 0 then
		return
	end
	bellHealth = math.max(0, bellHealth - amount)
	-- Solo replicamos cuando cambia el número entero que ve el jugador
	local shown = math.ceil(bellHealth)
	if shown ~= folder:GetAttribute("BellHealth") then
		folder:SetAttribute("BellHealth", shown)
	end
end

function GameState.repairBell(amount: number): boolean
	if bellHealth <= 0 or bellHealth >= Config.Bell.MaxHealth then
		return false
	end
	bellHealth = math.min(Config.Bell.MaxHealth, bellHealth + amount)
	folder:SetAttribute("BellHealth", math.ceil(bellHealth))
	return true
end

function GameState.isBellDestroyed(): boolean
	return bellHealth <= 0
end

function GameState.resetBell()
	bellHealth = Config.Bell.MaxHealth
	folder:SetAttribute("BellHealth", bellHealth)
end

return GameState
