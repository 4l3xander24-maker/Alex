-- Lobby (cliente): cartel abajo que dice en qué sala estás y cuánto falta,
-- efectos del mundo (LobbyFx) y la interfaz (LobbyUi)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local LobbyFx = require(script.LobbyFx)
local LobbyUi = require(script.LobbyUi)

LobbyFx.init()
LobbyUi.init()
local status = ReplicatedStorage:WaitForChild("LobbyStatus")

local gui = Instance.new("ScreenGui")
gui.Name = "Lobby"
gui.ResetOnSpawn = false
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("TextLabel")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -40)
panel.Size = UDim2.new(0.9, 0, 0, 64)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(460, 64)
limit.Parent = panel
panel.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
panel.BackgroundTransparency = 0.15
panel.Font = Enum.Font.GothamBold
panel.TextSize = 18
panel.TextWrapped = true
panel.TextColor3 = Color3.new(1, 1, 1)
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 100)
stroke.Thickness = 2
stroke.Parent = panel

local IDLE = `Párate en una sala para jugar (1 a {Config.Rooms.MaxPlayers} jugadores).\nMás jugadores = más zombis.`
panel.Text = IDLE

-- Botón Cancelar: dentro de la sala no puedes caminar; esto te saca del círculo
local cancelEvent = ReplicatedStorage:WaitForChild("LobbyCancel")
local cancel = Instance.new("TextButton")
cancel.AnchorPoint = Vector2.new(0.5, 1)
cancel.Position = UDim2.new(0.5, 0, 1, -116)
cancel.Size = UDim2.fromOffset(190, 46)
cancel.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
cancel.Font = Enum.Font.GothamBlack
cancel.TextSize = 19
cancel.TextColor3 = Color3.new(1, 1, 1)
cancel.Text = "✖ CANCELAR"
cancel.Visible = false
cancel.Parent = gui
local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 10)
cancelCorner.Parent = cancel
local cancelStroke = Instance.new("UIStroke")
cancelStroke.Color = Color3.new(1, 1, 1)
cancelStroke.Thickness = 2
cancelStroke.Parent = cancel
cancel.Activated:Connect(function()
	cancelEvent:FireServer()
end)

local currentRoom = nil
status.OnClientEvent:Connect(function(room, count, seconds, problem)
	cancel.Visible = room ~= nil and not problem
	if room and room ~= currentRoom then
		LobbyUi.playJoin()
	end
	currentRoom = room
	if not room then
		panel.Text = IDLE
	elseif problem then
		panel.Text = `⚠️ {problem}`
	elseif seconds then
		panel.Text = `Sala {room} · 👥 {count}/{Config.Rooms.MaxPlayers}\nLa partida empieza en {seconds} s (sal del círculo para cancelar)`
	else
		panel.Text = `Sala {room} · 👥 {count}/{Config.Rooms.MaxPlayers}`
	end
end)
