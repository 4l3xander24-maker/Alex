-- Cinemática de derrota: la cámara de todos vuela hacia la campana y la rodea
-- despacio mientras se derrumba. Franjas negras arriba y abajo, todo se tiñe
-- de rojo, la cámara tiembla con el golpe y aparece el título.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared").Remotes)
local Sfx = require(script.Parent.Sfx)

local FLY_TIME = 1.2 -- de donde estabas hasta la campana
local COLLAPSE_AT = 1.4 -- cuando el servidor la derrumba
local RADIUS = 30
local HEIGHT = 13
local BAR_HEIGHT = 0.12 -- franjas negras (fracción de la pantalla)

local GameOverCinematic = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local topBar: Frame
local bottomBar: Frame
local title: TextLabel
local subtitle: TextLabel
local playing = false

local function tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local animation = TweenService:Create(instance, info, goal)
	animation:Play()
	return animation
end

local function play(reason: string?, bell: Vector3, duration: number)
	if playing then
		return
	end
	playing = true
	local camera = workspace.CurrentCamera
	local startCFrame = camera.CFrame
	local focus = bell + Vector3.new(0, 11, 0)
	local startAngle = math.atan2(startCFrame.Position.X - bell.X, startCFrame.Position.Z - bell.Z)
	camera.CameraType = Enum.CameraType.Scriptable

	-- Rojo y sin color
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "GameOverGrade"
	grade.Parent = Lighting
	tween(grade, 1.5, { Saturation = -0.6, TintColor = Color3.fromRGB(255, 150, 140), Contrast = 0.2 })

	gui.Enabled = true
	title.TextTransparency = 1
	subtitle.TextTransparency = 1
	title.Text = if reason == "Dead" then "TODOS CAYERON" else "LA CAMPANA HA CAÍDO"
	subtitle.Text = "Los muertos se adueñan del campamento..."
	tween(topBar, 0.6, { Size = UDim2.fromScale(1, BAR_HEIGHT) })
	tween(bottomBar, 0.6, { Size = UDim2.fromScale(1, BAR_HEIGHT) })

	Sfx.playAt("BellToll", bell)
	task.delay(COLLAPSE_AT, function()
		Sfx.playAt("Explosion", bell)
		Sfx.playAt("BellHit", bell)
		tween(title, 0.8, { TextTransparency = 0 })
		task.delay(0.6, function()
			tween(subtitle, 0.8, { TextTransparency = 0 })
		end)
	end)

	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local age = os.clock() - started
		-- Vuela hacia la órbita y la rodea despacio
		local angle = startAngle + age * 0.22
		local orbit = CFrame.lookAt(bell + Vector3.new(math.sin(angle) * RADIUS, HEIGHT - age * 0.8, math.cos(angle) * RADIUS), focus)
		local alpha = math.clamp(age / FLY_TIME, 0, 1)
		alpha = alpha * alpha * (3 - 2 * alpha)
		local cframe = startCFrame:Lerp(orbit, alpha)
		-- Temblor cuando se derrumba
		local shakeAge = age - COLLAPSE_AT
		if shakeAge > 0 and shakeAge < 0.9 then
			local power = (1 - shakeAge / 0.9) * 0.6
			cframe *= CFrame.new(math.noise(age * 30, 1) * power, math.noise(age * 30, 2) * power, 0)
		end
		camera.CFrame = cframe
		if age >= duration then
			connection:Disconnect()
		end
	end)

	task.wait(duration)
	tween(topBar, 0.5, { Size = UDim2.fromScale(1, 0) })
	tween(bottomBar, 0.5, { Size = UDim2.fromScale(1, 0) })
	tween(title, 0.4, { TextTransparency = 1 })
	tween(subtitle, 0.4, { TextTransparency = 1 })
	tween(grade, 1, { Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0 }).Completed:Connect(function()
		grade:Destroy()
	end)
	camera.CameraType = Enum.CameraType.Custom
	task.wait(0.5)
	gui.Enabled = false
	playing = false
end

local function bar(anchorY: number): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0, anchorY)
	frame.Position = UDim2.fromScale(0, anchorY)
	frame.Size = UDim2.fromScale(1, 0)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	return frame
end

function GameOverCinematic.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "GameOverCinematic"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20
	gui.Enabled = false
	topBar = bar(0)
	bottomBar = bar(1)
	title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.new(0.9, 0, 0, 70)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 70, 60)
	title.TextStrokeTransparency = 0.3
	title.Parent = gui
	subtitle = title:Clone()
	subtitle.Position = UDim2.fromScale(0.5, 0.52)
	subtitle.Size = UDim2.new(0.8, 0, 0, 30)
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextColor3 = Color3.new(1, 1, 1)
	subtitle.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	Remotes.GameOverCinematic.OnClientEvent:Connect(function(reason, bell, duration)
		task.spawn(play, reason, bell, duration)
	end)
end

return GameOverCinematic
