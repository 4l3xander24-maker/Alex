-- Botón "Invitar amigos" de la partida: solo en la preparación (antes de
-- reconstruir la campana) y después del tutorial, para no tapar sus carteles.
-- Muestra cuántos amigos invitados ya terminaron su primera partida. El
-- premio lo decide el servidor (ReferralService); aquí solo se abre la
-- ventana de invitar de Roblox (Invite).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Invite = require(Shared.Invite)
local Notify = require(script.Parent.Notify)
local Profile = require(script.Parent.Profile)

local InviteUi = {}

local player = Players.LocalPlayer

function InviteUi.init()
	local touch = UserInputService.TouchEnabled
	local gameState = ReplicatedStorage:WaitForChild("GameState")
	local gui = Instance.new("ScreenGui")
	gui.Name = "InviteFriends"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	if touch then
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Celular: debajo de Logros y Pase (a la derecha de la fila de arriba).
	-- PC: a la izquierda del engranaje de opciones.
	local button = Instance.new("TextButton")
	button.Name = "Invite"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = if touch then UDim2.new(1, -132, 0, 112) else UDim2.new(1, -60, 0, 122)
	button.Size = if touch then UDim2.fromOffset(188, 34) else UDim2.fromOffset(170, 36)
	button.BackgroundColor3 = Color3.fromRGB(46, 140, 80)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = if touch then 12 else 13
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextWrapped = true
	button.Visible = false
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local rules = Config.Referral
	local function render()
		button.Text = `➕ Invitar amigos\n🎁 Amigos invitados: {player:GetAttribute("Referrals") or 0}/{rules.MaxFriends}`
		button.Visible = gameState:GetAttribute("State") == "Lobby" and Profile.isLoaded() and Profile.get().Tutorial == true and not player:GetAttribute("InCinematic")
	end

	button.Activated:Connect(function()
		if Invite.prompt(player) then
			Notify.show(`🎁 +{rules.InviterCoins} monedas por cada amigo nuevo que termine su primera partida (hasta {rules.MaxFriends})`)
		else
			Notify.show("No se pueden enviar invitaciones ahora (en Studio no funciona)")
		end
	end)
	gameState:GetAttributeChangedSignal("State"):Connect(render)
	player:GetAttributeChangedSignal("Referrals"):Connect(render)
	player:GetAttributeChangedSignal("InCinematic"):Connect(render)
	Profile.Changed:Connect(render)
	render()
end

return InviteUi
