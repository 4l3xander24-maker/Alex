-- Cinemática de derrota: la cámara de todos vuela hacia la campana y la rodea
-- despacio mientras se derrumba. Franjas negras arriba y abajo, todo se tiñe
-- de rojo, la cámara tiembla con el golpe y aparece el título.
-- Al superar la meta de la dificultad sale en cambio el cartel de ¡VICTORIA!
-- (dorado, con fanfarria y destellos, como el de subir de nivel). Antes, al
-- caer el jefe final, un temblor dorado con su título (finalBossDown).
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Sfx = require(script.Parent.Sfx)

local FLY_TIME = 1.8 -- de donde estabas hasta la campana
local COLLAPSE_AT = 2.6 -- cuando el servidor la derrumba (igual que en WaveService)
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
local overlays = 0 -- carteles abiertos sin mover la cámara (victoria, jefe final)
local flash: Frame
local fade: Frame

local function tween(instance: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	local info = TweenInfo.new(seconds, style or Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local animation = TweenService:Create(instance, info, goal)
	animation:Play()
	return animation
end


-- Polvo, humo y brasas que estallan al derrumbarse la campana
local function collapseBurst(bell: Vector3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = bell + Vector3.new(0, 6, 0)
	anchor.Parent = workspace
	local function emitter(color: Color3, size: number, speed: number, lifetime: number, count: number, glow: number)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.Lifetime = NumberRange.new(lifetime * 0.6, lifetime)
		e.Speed = NumberRange.new(speed * 0.5, speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Color = ColorSequence.new(color)
		e.LightEmission = glow
		e.Acceleration = Vector3.new(0, if glow > 0 then 6 else 1, 0)
		e.Parent = anchor
		e:Emit(count)
	end
	emitter(Color3.fromRGB(120, 108, 96), 14, 40, 3.5, 60, 0) -- polvo
	emitter(Color3.fromRGB(60, 56, 52), 18, 22, 4.5, 30, 0) -- humo oscuro
	emitter(Color3.fromRGB(255, 150, 60), 1.4, 55, 2.5, 70, 1) -- brasas
	task.delay(6, function()
		anchor:Destroy()
	end)
end

local function play(reason: string?, bell: Vector3, duration: number)
	if playing then
		return
	end
	playing = true
	-- Sin arma en la mano ni botones mientras dura (Viewmodel, Hud y StoreUi lo miran)
	player:SetAttribute("InCinematic", true)
	local camera = workspace.CurrentCamera
	local startCFrame = camera.CFrame
	local focus = bell + Vector3.new(0, 11, 0)
	local startAngle = math.atan2(startCFrame.Position.X - bell.X, startCFrame.Position.Z - bell.Z)
	camera.CameraType = Enum.CameraType.Scriptable
	local startFov = camera.FieldOfView

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
	task.delay(1.3, function()
		Sfx.playAt("BellToll", bell)
	end)
	task.delay(COLLAPSE_AT, function()
		Sfx.playAt("Explosion", bell)
		Sfx.playAt("BellHit", bell)
		collapseBurst(bell)
		-- Destello blanco que se apaga
		flash.BackgroundTransparency = 0.2
		tween(flash, 1.2, { BackgroundTransparency = 1 })
		tween(title, 0.8, { TextTransparency = 0 })
		task.delay(0.6, function()
			tween(subtitle, 0.8, { TextTransparency = 0 })
		end)
	end)

	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local age = os.clock() - started
		local since = age - COLLAPSE_AT
		-- Vuela hacia la órbita y se va acercando despacio; tras el derrumbe se
		-- aleja y sube como una grúa para ver toda la ruina
		local approach = math.clamp(age / COLLAPSE_AT, 0, 1)
		local crane = math.clamp(since / 3, 0, 1)
		crane = crane * crane * (3 - 2 * crane)
		local radius = RADIUS - approach * 9 + crane * 22
		local height = HEIGHT - approach * 3 + crane * 14
		local angle = startAngle + age * (if since > 0 then 0.12 else 0.2)
		local target = focus - Vector3.new(0, crane * 4, 0)
		local orbit = CFrame.lookAt(bell + Vector3.new(math.sin(angle) * radius, height, math.cos(angle) * radius), target)
		local alpha = math.clamp(age / FLY_TIME, 0, 1)
		alpha = alpha * alpha * (3 - 2 * alpha)
		local cframe = startCFrame:Lerp(orbit, alpha)
		-- Cuadro cerrado al acercarse y un golpe de zoom al derrumbarse
		local fov = startFov + (52 - startFov) * alpha
		if since > 0 then
			fov = 52 - math.max(0, 1 - since / 0.35) * 14 + crane * 14
		end
		camera.FieldOfView = fov
		-- Retumbo creciente antes del derrumbe y temblor fuerte después
		local power = 0
		if since < 0 and age > 1.2 then
			power = (age - 1.2) / (COLLAPSE_AT - 1.2) * 0.25
		elseif since >= 0 and since < 1.4 then
			power = (1 - since / 1.4) * 1.1
		end
		if power > 0 then
			cframe *= CFrame.new(math.noise(age * 30, 1) * power, math.noise(age * 30, 2) * power, 0) * CFrame.Angles(0, 0, math.noise(age * 20, 3) * power * 0.03)
		end
		camera.CFrame = cframe
		if age >= duration then
			connection:Disconnect()
		end
	end)

	task.wait(duration - 0.9)
	tween(fade, 0.8, { BackgroundTransparency = 0 })
	task.wait(0.9)
	camera.FieldOfView = startFov
	tween(fade, 0.6, { BackgroundTransparency = 1 })
	tween(topBar, 0.5, { Size = UDim2.fromScale(1, 0) })
	tween(bottomBar, 0.5, { Size = UDim2.fromScale(1, 0) })
	tween(title, 0.4, { TextTransparency = 1 })
	tween(subtitle, 0.4, { TextTransparency = 1 })
	tween(grade, 1, { Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0 }).Completed:Connect(function()
		grade:Destroy()
	end)
	camera.CameraType = Enum.CameraType.Custom
	player:SetAttribute("InCinematic", false)
	task.wait(0.5)
	gui.Enabled = false
	playing = false
end

-- Muerte del jefe final (sin mover la cámara, para que se siga jugando): el
-- servidor pone a los zombis en cámara lenta, aquí el mundo se tiñe de dorado,
-- la cámara tiembla, estalla polvo y brasas donde cayó y sale el título.
local function finalBossDown(position: Vector3, duration: number)
	if playing then
		return
	end
	overlays += 1
	local info = Config.Enemies[Config.FinalBoss.Type]
	Sfx.play("BossRoar")
	Sfx.playAt("Explosion", position)
	Sfx.playAt("BellToll", position)
	task.delay(0.8, Sfx.playAt, "BossBell", position)
	collapseBurst(position)
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "FinalBossGrade"
	grade.Parent = Lighting
	tween(grade, 0.3, { Saturation = -0.35, TintColor = Color3.fromRGB(255, 220, 160), Contrast = 0.15 })

	gui.Enabled = true
	flash.BackgroundTransparency = 0.3
	tween(flash, 0.9, { BackgroundTransparency = 1 })
	title.Text = `¡EL {string.upper(info.DisplayName)} HA CAÍDO!`
	title.TextColor3 = Color3.fromRGB(255, 205, 90)
	subtitle.Text = "La maldición de la campana se rompe..."
	tween(title, 0.4, { TextTransparency = 0 })
	task.delay(0.4, function()
		tween(subtitle, 0.6, { TextTransparency = 0 })
	end)

	-- Temblor que se apaga (con CameraOffset: la cámara sigue siendo del jugador)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local started = os.clock()
	local connection
	connection = RunService.RenderStepped:Connect(function()
		local age = os.clock() - started
		local power = math.max(0, 1 - age / 1.6) * 1.4
		if humanoid then
			humanoid.CameraOffset = if power > 0 then Vector3.new(math.noise(age * 30, 1) * power, math.noise(age * 30, 2) * power, 0) else Vector3.zero
		end
		if power <= 0 then
			connection:Disconnect()
		end
	end)

	task.wait(math.max(duration - 0.4, 0.4))
	tween(grade, 0.8, { Saturation = 0, TintColor = Color3.new(1, 1, 1), Contrast = 0 }).Completed:Connect(function()
		grade:Destroy()
	end)
	-- Si mientras tanto empezó la cinemática de derrota, el título ya es suyo
	if not playing then
		tween(title, 0.4, { TextTransparency = 1 })
		tween(subtitle, 0.4, { TextTransparency = 1 })
		task.wait(0.45)
		if not playing then
			title.TextColor3 = Color3.fromRGB(255, 70, 60)
		end
	end
	overlays -= 1
	if not playing and overlays == 0 then
		gui.Enabled = false
	end
end

-- Destello de cuadraditos dorados que sube y se apaga
local function sparkle(parent: Frame)
	local size = math.random(6, 12)
	local square = Instance.new("Frame")
	square.BorderSizePixel = 0
	square.AnchorPoint = Vector2.new(0.5, 0.5)
	square.Position = UDim2.new(math.random(), 0, math.random() * 1.4 - 0.2, 0)
	square.Size = UDim2.fromOffset(size, size)
	square.BackgroundColor3 = if math.random() < 0.3 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 220, 110)
	square.Parent = parent
	local delay = math.random() * 1.2
	task.delay(delay, function()
		local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(square, info, { Position = square.Position - UDim2.fromOffset(0, 40), BackgroundTransparency = 1 }):Play()
	end)
	task.delay(delay + 1.3, function()
		square:Destroy()
	end)
end

-- Cartel de ¡VICTORIA! (sin mover la cámara): entra grande, rebota y se va
local function victory(bell: Vector3, duration: number)
	overlays += 1
	Sfx.play("LevelUp")
	Sfx.playAt("BellToll", bell)
	local state = ReplicatedStorage:FindFirstChild("GameState")
	local info = Config.Difficulties[(state and state:GetAttribute("Difficulty")) or 1] or Config.Difficulties[1]

	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.3)
	frame.Size = UDim2.fromOffset(760, 160)
	frame.Parent = gui
	-- En celulares angostos se achica para no cortarse a los lados
	local fit = math.min(1, (workspace.CurrentCamera.ViewportSize.X - 24) / 760)
	local big = Instance.new("TextLabel")
	big.BackgroundTransparency = 1
	big.Size = UDim2.new(1, 0, 0, 96)
	big.Font = Config.PixelFont
	big.TextScaled = true
	big.Text = "¡VICTORIA!"
	big.TextColor3 = Color3.new(1, 1, 1)
	big.Parent = frame
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Color3.fromRGB(255, 248, 210), Color3.fromRGB(255, 190, 60))
	gradient.Parent = big
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(70, 40, 10)
	stroke.Thickness = 5
	stroke.LineJoinMode = Enum.LineJoinMode.Miter
	stroke.Parent = big
	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.fromOffset(0, 104)
	detail.Size = UDim2.new(1, 0, 0, 32)
	detail.Font = Config.PixelFont
	detail.TextSize = 26
	detail.TextColor3 = Color3.new(1, 1, 1)
	detail.TextStrokeTransparency = 0
	detail.Text = `{info.Icon} ¡Superaron {info.Name}! La campana resistió`
	detail.Parent = frame

	gui.Enabled = true
	local scale = Instance.new("UIScale")
	scale.Scale = 1.6 * fit
	scale.Parent = frame
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = fit }):Play()
	gradient.Offset = Vector2.new(0, -0.6)
	TweenService:Create(gradient, TweenInfo.new(0.8, Enum.EasingStyle.Sine), { Offset = Vector2.new(0, 0) }):Play()
	for _ = 1, 34 do
		sparkle(frame)
	end

	task.wait(math.max(duration - 0.5, 0.5))
	local fadeInfo = TweenInfo.new(0.5)
	TweenService:Create(big, fadeInfo, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
	TweenService:Create(detail, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.wait(0.55)
	frame:Destroy()
	overlays -= 1
	if not playing and overlays == 0 then
		gui.Enabled = false
	end
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
	flash = Instance.new("Frame")
	flash.Size = UDim2.fromScale(1, 1)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.Parent = gui
	fade = flash:Clone()
	fade.BackgroundColor3 = Color3.new(0, 0, 0)
	fade.Parent = gui
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
		if reason == "Victory" then
			task.spawn(victory, bell, duration)
		elseif reason == "FinalBoss" then
			task.spawn(finalBossDown, bell, duration)
		else
			task.spawn(play, reason, bell, duration)
		end
	end)
end

return GameOverCinematic
