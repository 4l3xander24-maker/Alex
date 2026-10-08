-- Cartel grande de "¡SUBISTE DE NIVEL!" (como el LEVEL UP! de Guns 'n Goblins):
-- letras pixeladas azules con borde oscuro que saltan, destellos de cuadraditos
-- alrededor y debajo lo que ganaste. Sale cuando sube el nivel de la cuenta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Profile = require(script.Parent.Profile)
local Sfx = require(script.Parent.Sfx)

local LevelUpFx = {}

local SHOW_TIME = 2.6
local SPARKLES = 26
local TITLE_TOP = Color3.fromRGB(235, 245, 255)
local TITLE_BOTTOM = Color3.fromRGB(120, 175, 255)
local OUTLINE = Color3.fromRGB(16, 26, 60)

local gui: ScreenGui
local lastLevel: number? = nil
local showing = 0

local function sparkle(parent: Frame)
	-- Cruz de 5 cuadraditos que aparece, flota y se apaga
	local size = math.random(6, 12)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.new(math.random(), 0, math.random() * 1.4 - 0.2, 0)
	holder.Size = UDim2.fromOffset(size * 3, size * 3)
	holder.Parent = parent
	local squares = {}
	for _, offset in { Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(2, 1), Vector2.new(1, 2) } do
		local square = Instance.new("Frame")
		square.BorderSizePixel = 0
		square.BackgroundColor3 = if offset == Vector2.new(1, 1) then Color3.new(1, 1, 1) else Color3.fromRGB(190, 225, 255)
		square.Size = UDim2.fromOffset(size, size)
		square.Position = UDim2.fromOffset(offset.X * size, offset.Y * size)
		square.Parent = holder
		table.insert(squares, square)
	end
	local delay = math.random() * 0.8
	task.delay(delay, function()
		local info = TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(holder, info, { Position = holder.Position - UDim2.fromOffset(0, 30) }):Play()
		for _, square in squares do
			TweenService:Create(square, info, { BackgroundTransparency = 1 }):Play()
		end
	end)
	task.delay(delay + 1.2, function()
		holder:Destroy()
	end)
end

function LevelUpFx.show(level: number, gained: number)
	Sfx.play("LevelUp")
	showing += 1
	local token = showing
	local banner = gui:FindFirstChild("Banner")
	if banner then
		banner:Destroy()
	end

	local frame = Instance.new("Frame")
	frame.Name = "Banner"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.3)
	frame.Size = UDim2.fromOffset(760, 160)
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 0, 96)
	title.Font = Config.PixelFont
	title.TextScaled = true
	title.Text = if gained > 1 then `¡SUBISTE {gained} NIVELES!` else "¡SUBISTE DE NIVEL!"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Parent = frame
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(TITLE_TOP, TITLE_BOTTOM)
	gradient.Parent = title
	local stroke = Instance.new("UIStroke")
	stroke.Color = OUTLINE
	stroke.Thickness = 5
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Parent = title

	local data = Profile.get()
	local talents = if data.TalentPoints > 0 then `  ·  {data.TalentPoints} talento(s)` else ""
	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.fromOffset(0, 104)
	detail.Size = UDim2.new(1, 0, 0, 32)
	detail.Font = Config.PixelFont
	detail.TextSize = 26
	detail.TextColor3 = Color3.fromRGB(255, 215, 100)
	detail.TextStrokeTransparency = 0
	detail.Text = `Nivel {level}  ·  {data.StatPoints} punto(s) de mejora{talents}`
	detail.Parent = frame

	-- Entra grande y rebota a su tamaño
	local scale = Instance.new("UIScale")
	scale.Scale = 1.6
	scale.Parent = frame
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	-- Brillo que baja por las letras
	gradient.Offset = Vector2.new(0, -0.6)
	TweenService:Create(gradient, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Offset = Vector2.new(0, 0) }):Play()

	for _ = 1, SPARKLES do
		sparkle(frame)
	end

	task.delay(SHOW_TIME, function()
		if token ~= showing or not frame.Parent then
			return
		end
		local fade = TweenInfo.new(0.5)
		TweenService:Create(title, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		TweenService:Create(detail, fade, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.delay(0.55, function()
			frame:Destroy()
		end)
	end)
end

function LevelUpFx.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "LevelUp"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20
	gui.IgnoreGuiInset = true
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	Profile.Changed:Connect(function()
		if not Profile.isLoaded() then
			return
		end
		local level = Profile.get().Level
		-- La primera vez solo se anota (no es subir de nivel, es cargar el perfil)
		if lastLevel and level > lastLevel then
			LevelUpFx.show(level, level - lastLevel)
		end
		lastLevel = level
	end)
end

return LevelUpFx
