-- Interfaz del lobby: botón para invitar amigos, diálogo del guía que explica
-- el juego, aviso de la tienda de skins y música de fondo.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local GOLD = Color3.fromRGB(255, 215, 100)
local DARK = Color3.fromRGB(20, 24, 26)

-- Lo que cuenta el guía, una página por vez
local GUIDE_PAGES = {
	"¡Bienvenido, viajero! Esa campana maldita atrae a los muertos cada noche. Tu misión: proteger la campana del campamento todas las oleadas que puedas.",
	`Párate en un círculo de runas para entrar a una sala. Juegan de 1 a {Config.Rooms.MaxPlayers}: cuantos más sean, más zombis y más duros.`,
	"En la partida: dispara y acuchilla zombis, junta monedas y diamantes de experiencia, y compra armas, poderes y mascotas en el campamento.",
	"Si te caes al agua vuelves al círculo de runas, pero pierdes vida. Si la campana cae o caen todos, termina la partida… ¡y pueden votar para reintentar!",
	"Tu mejor oleada y tus zombis matados salen en los tableros de la plaza. ¡Trae a tus amigos y llega al primer puesto!",
}

local LobbyUi = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local dialog: Frame
local dialogText: TextLabel
local dialogButton: TextButton
local toast: TextLabel
local page = 0

local function corner(parent: Instance, radius: number)
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, radius)
	round.Parent = parent
end

local function stroke(parent: Instance, color: Color3)
	local line = Instance.new("UIStroke")
	line.Color = color
	line.Thickness = 2
	line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	line.Parent = parent
end

local function playSound(id: number, volume: number, looped: boolean?): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = `rbxassetid://{id}`
	sound.Volume = volume
	sound.Looped = looped == true
	sound.Parent = SoundService
	sound:Play()
	if not looped then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
	return sound
end

function LobbyUi.playJoin()
	playSound(Sounds.Rebuild.Id, 0.5)
end

local function showToast(text: string)
	toast.Text = text
	toast.Visible = true
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.15
	task.delay(3, function()
		if toast.Text == text then
			TweenService:Create(toast, TweenInfo.new(0.5), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end

local function showPage()
	dialogText.Text = GUIDE_PAGES[page]
	dialogButton.Text = if page < #GUIDE_PAGES then "Siguiente ▶" else "¡Entendido!"
end

local function openGuide()
	page = 1
	showPage()
	dialog.Visible = true
	playSound(Sounds.Equip.Id, 0.4)
end

local function invite()
	local ok, canInvite = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)
	if ok and canInvite then
		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	else
		showToast("No se pueden enviar invitaciones ahora (en Studio no funciona).")
	end
end

local function buildInviteButton()
	local button = Instance.new("TextButton")
	button.Name = "Invite"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.new(1, -16, 0, 60)
	button.Size = UDim2.fromOffset(190, 46)
	button.BackgroundColor3 = Color3.fromRGB(46, 140, 80)
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "➕ Invitar amigos"
	button.AutoButtonColor = true
	button.Parent = gui
	corner(button, 10)
	stroke(button, Color3.fromRGB(180, 255, 200))
	button.Activated:Connect(invite)
end

local function buildDialog()
	dialog = Instance.new("Frame")
	dialog.Name = "GuideDialog"
	dialog.AnchorPoint = Vector2.new(0.5, 1)
	dialog.Position = UDim2.new(0.5, 0, 1, -120)
	dialog.Size = UDim2.new(0.9, 0, 0, 150)
	dialog.BackgroundColor3 = DARK
	dialog.BackgroundTransparency = 0.08
	dialog.Visible = false
	dialog.Parent = gui
	corner(dialog, 12)
	stroke(dialog, GOLD)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 150)
	limit.Parent = dialog
	local name = Instance.new("TextLabel")
	name.Position = UDim2.fromOffset(16, 8)
	name.Size = UDim2.new(1, -60, 0, 24)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBlack
	name.TextSize = 18
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = GOLD
	name.Text = "Ermitaño Tobías"
	name.Parent = dialog
	dialogText = Instance.new("TextLabel")
	dialogText.Position = UDim2.fromOffset(16, 36)
	dialogText.Size = UDim2.new(1, -32, 1, -86)
	dialogText.BackgroundTransparency = 1
	dialogText.Font = Enum.Font.GothamMedium
	dialogText.TextScaled = true
	dialogText.TextWrapped = true
	dialogText.TextXAlignment = Enum.TextXAlignment.Left
	dialogText.TextYAlignment = Enum.TextYAlignment.Top
	dialogText.TextColor3 = Color3.new(1, 1, 1)
	dialogText.Parent = dialog
	local textLimit = Instance.new("UITextSizeConstraint")
	textLimit.MaxTextSize = 18
	textLimit.Parent = dialogText
	dialogButton = Instance.new("TextButton")
	dialogButton.AnchorPoint = Vector2.new(1, 1)
	dialogButton.Position = UDim2.new(1, -12, 1, -10)
	dialogButton.Size = UDim2.fromOffset(150, 36)
	dialogButton.BackgroundColor3 = GOLD
	dialogButton.Font = Enum.Font.GothamBlack
	dialogButton.TextSize = 16
	dialogButton.TextColor3 = DARK
	dialogButton.Parent = dialog
	corner(dialogButton, 8)
	dialogButton.Activated:Connect(function()
		if page < #GUIDE_PAGES then
			page += 1
			showPage()
		else
			dialog.Visible = false
		end
	end)
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 6)
	close.Size = UDim2.fromOffset(30, 30)
	close.BackgroundTransparency = 1
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 20
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.Parent = dialog
	close.Activated:Connect(function()
		dialog.Visible = false
	end)
end

local function buildToast()
	toast = Instance.new("TextLabel")
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 70)
	toast.Size = UDim2.fromOffset(420, 44)
	toast.BackgroundColor3 = DARK
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 17
	toast.TextWrapped = true
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 10)
end

function LobbyUi.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "LobbyUi"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	buildInviteButton()
	buildDialog()
	buildToast()

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt.Name == "GuidePrompt" then
			openGuide()
		elseif prompt.Name == "ShopPrompt" then
			showToast("🛒 La tienda de skins abre muy pronto. ¡Atento!")
		end
	end)

	playSound(Sounds.Music.Lobby.Id, Sounds.Music.Lobby.Volume, true)
	playSound(Sounds.Ambience.Id, Sounds.Ambience.Volume, true)
end

return LobbyUi
