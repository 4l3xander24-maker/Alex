-- SOLO PARA GRABAR. Secuencia automática de la Partida (sin escribir comandos):
--  8 s  tienda Armería (scroll) · 6 s Entrenamiento · menú de dificultad 7 s
--  luego oleada con fusil, minigun, ballesta y lanzallamas (9 s cada uno)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Profile = require(player:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Profile"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)

repeat
	task.wait(0.5)
until Profile.get() and Profile.get().Weapons.Crossbow

local function take(name: string, seconds: number)
	workspace:SetAttribute("Take", name)
	task.wait(seconds)
end

task.wait(6)
workspace:SetAttribute("Shop", "Armory")
take("shop", 7)
workspace:SetAttribute("Shop", "Trainer")
take("shop", 6)
take("shopclose", 1.5)
take("menu", 7)
workspace:SetAttribute("Diff", 4)
Remotes.SelectDifficulty:FireServer(4, {})
task.wait(14)
for _, weapon in { "Rifle", "Minigun", "Crossbow", "Flamethrower" } do
	workspace:SetAttribute("Weapon", weapon)
	take("fps", 9)
end
