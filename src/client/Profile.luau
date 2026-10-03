-- Copia local del perfil del jugador (la manda el servidor). Las monedas
-- llegan aparte como atributo porque cambian con cada zombi.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)

local player = Players.LocalPlayer

local Profile = {}

local data: Progression.Profile? = nil
local changed = Instance.new("BindableEvent")

-- Se dispara con la razón del cambio: "Load", "Shop", "Equip" o "Level"
Profile.Changed = changed.Event

function Profile.get(): Progression.Profile
	return data or Progression.defaultProfile()
end

function Profile.isLoaded(): boolean
	return data ~= nil
end

function Profile.coins(): number
	return player:GetAttribute("Coins") or Profile.get().Coins
end

function Profile.hasTalent(id: string): boolean
	return Progression.hasTalent(Profile.get(), id)
end

function Profile.init()
	Remotes.ProfileUpdated.OnClientEvent:Connect(function(newData, reason)
		data = newData
		changed:Fire(reason)
	end)
end

return Profile
