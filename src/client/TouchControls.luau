-- Controles táctiles propios (celular): joystick flotante a la izquierda y
-- botón de saltar a la derecha, con el mismo estilo que los botones del HUD.
-- Reemplazan a los de Roblox (StarterPlayer.DevTouchMovementMode = Scriptable).
--   * El joystick aparece donde pones el dedo en la mitad izquierda de la
--     pantalla y vuelve a su sitio al soltar.
--   * La zona del joystick es un botón transparente: así Roblox sabe que ese
--     toque ya está usado y no gira la cámara.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local HudIcons = require(script.Parent.HudIcons)

local player = Players.LocalPlayer

local TouchControls = {}

local RADIUS = 56 -- cuánto se aleja el pulgar del centro para ir a toda velocidad
local DEADZONE = 0.14
local HOME = UDim2.new(0, 100, 1, -100)

local function circle(parent: Instance, diameter: number): Frame
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(diameter, diameter)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
	return frame
end

function TouchControls.init(actions: { jump: () -> () })
	if not UserInputService.TouchEnabled then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "TouchControls"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -1 -- debajo del HUD: sus botones reciben el toque primero
	gui.Parent = player:WaitForChild("PlayerGui")

	local root = Instance.new("Frame")
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent = gui

	-- Zona del joystick: mitad izquierda, de abajo hasta casi la mitad
	local zone = Instance.new("TextButton")
	zone.AnchorPoint = Vector2.new(0, 1)
	zone.Position = UDim2.fromScale(0, 1)
	zone.Size = UDim2.fromScale(0.45, 0.7)
	zone.BackgroundTransparency = 1
	zone.Text = ""
	zone.AutoButtonColor = false
	zone.Parent = root

	-- Base y pulgar
	local base = circle(zone, 128)
	base.Position = HOME
	HudIcons.styleButton(base)
	HudIcons.dpad(base, 106)
	local knob = circle(base, 54)
	knob.Position = UDim2.fromScale(0.5, 0.5)
	knob.BackgroundTransparency = 0.25
	knob.ZIndex = 3
	local knobRing = Instance.new("UIStroke")
	knobRing.Color = Color3.new(1, 1, 1)
	knobRing.Transparency = 0.1
	knobRing.Thickness = 2
	knobRing.Parent = knob
	local knobShade = Instance.new("UIGradient")
	knobShade.Rotation = 90
	knobShade.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 175, 185))
	knobShade.Parent = knob

	local active: InputObject? = nil
	local origin = Vector2.zero
	local move = Vector2.zero

	local function toLocal(position: Vector3): Vector2
		return Vector2.new(position.X, position.Y) - zone.AbsolutePosition
	end

	zone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and not active then
			active = input
			origin = toLocal(input.Position)
			base.Position = UDim2.fromOffset(origin.X, origin.Y)
			base.BackgroundTransparency = 0.2
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == active then
			local delta = toLocal(input.Position) - origin
			if delta.Magnitude > RADIUS then
				delta = delta.Unit * RADIUS
			end
			knob.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
			local amount = delta.Magnitude / RADIUS
			move = if amount < DEADZONE then Vector2.zero else delta / RADIUS
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input == active then
			active = nil
			move = Vector2.zero
			base.Position = HOME
			base.BackgroundTransparency = 0.38
			knob.Position = UDim2.fromScale(0.5, 0.5)
		end
	end)

	-- Botón de saltar (donde estaba el de Roblox, abajo a la derecha)
	local jump = Instance.new("TextButton")
	jump.AnchorPoint = Vector2.new(1, 1)
	jump.Position = UDim2.new(1, -24, 1, -28)
	jump.Size = UDim2.fromOffset(78, 78)
	jump.Text = ""
	jump.AutoButtonColor = false
	jump.Parent = root
	local jumpCorner = Instance.new("UICorner")
	jumpCorner.CornerRadius = UDim.new(1, 0)
	jumpCorner.Parent = jump
	HudIcons.styleButton(jump, 2.5)
	HudIcons.jump(jump, 44)
	HudIcons.bindPress(jump)
	jump.Activated:Connect(actions.jump)

	-- Cada cuadro le dice al personaje hacia dónde ir (según la cámara)
	local wasMoving = false
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end
		if move.Magnitude > 0 then
			wasMoving = true
			humanoid:Move(Vector3.new(move.X, 0, move.Y), true)
		elseif wasMoving then
			wasMoving = false
			humanoid:Move(Vector3.zero, true)
		end
	end)
end

return TouchControls
