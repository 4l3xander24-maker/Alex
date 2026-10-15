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
panel.TextSize = 20
panel.TextWrapped = true
panel.TextColor3 = Color3.new(1, 1, 1)
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 215, 100)
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = panel

local IDLE = `Entra a un círculo verde para jugar (1 a {Config.Rooms.MaxPlayers} jugadores).\nMás jugadores = más zombis.`
panel.Text = IDLE

-- Botón Cancelar: dentro de la sala no puedes salir caminando; esto te saca del círculo
local cancelEvent = ReplicatedStorage:WaitForChild("LobbyCancel")
local cancel = Instance.new("TextButton")
cancel.AnchorPoint = Vector2.new(0.5, 1)
cancel.Position = UDim2.new(0.5, 0, 1, -116)
cancel.Size = UDim2.fromOffset(190, 46)
cancel.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
cancel.Font = Enum.Font.GothamBlack
cancel.TextSize = 19
cancel.TextColor3 = Color3.new(1, 1, 1)
cancel.Text = "CANCELAR"
cancel.Visible = false
cancel.Parent = gui
local cancelCorner = Instance.new("UICorner")
cancelCorner.CornerRadius = UDim.new(0, 10)
cancelCorner.Parent = cancel
local cancelStroke = Instance.new("UIStroke")
cancelStroke.Color = Color3.new(1, 1, 1)
cancelStroke.Thickness = 1.5
cancelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
cancelStroke.Parent = cancel
cancel.Activated:Connect(function()
	cancelEvent:FireServer()
end)

-- Reconectar: si te desconectaste de una partida en curso, aparece este botón
local reconnectOffer = ReplicatedStorage:WaitForChild("ReconnectOffer")
local reconnectGo = ReplicatedStorage:WaitForChild("ReconnectGo")
local reconnect = Instance.new("TextButton")
reconnect.AnchorPoint = Vector2.new(0.5, 0)
reconnect.Position = UDim2.new(0.5, 0, 0, 16)
reconnect.Size = UDim2.fromOffset(300, 52)
reconnect.BackgroundColor3 = Color3.fromRGB(46, 150, 86)
reconnect.Font = Enum.Font.GothamBlack
reconnect.TextSize = 18
reconnect.TextColor3 = Color3.new(1, 1, 1)
reconnect.Text = "VOLVER A MI PARTIDA"
reconnect.Visible = false
reconnect.Parent = gui
local reconnectCorner = Instance.new("UICorner")
reconnectCorner.CornerRadius = UDim.new(0, 12)
reconnectCorner.Parent = reconnect
local reconnectStroke = Instance.new("UIStroke")
reconnectStroke.Color = Color3.fromRGB(190, 255, 210)
reconnectStroke.Thickness = 1.5
reconnectStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
reconnectStroke.Parent = reconnect
reconnectOffer.OnClientEvent:Connect(function(available)
	reconnect.Visible = available == true
	reconnect.Text = "VOLVER A MI PARTIDA"
	if available ~= true then
		panel.Text = "Esa partida ya terminó."
	end
end)
reconnect.Activated:Connect(function()
	reconnect.Text = "Conectando..."
	reconnectGo:FireServer()
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
		panel.Text = `Aviso: {problem}`
	elseif seconds then
		panel.Text = `Sala {room}  ·  {count}/{Config.Rooms.MaxPlayers} jugadores\nLa partida empieza en {seconds} s. Pulsa Cancelar para salir.`
	else
		panel.Text = `Sala {room}  ·  {count}/{Config.Rooms.MaxPlayers} jugadores`
	end
end)
