-- Talentos de movimiento: Correr (Shift), Doble salto y Esquivar (C).
-- Se aplican en el cliente porque Roblox le da al jugador el control
-- físico de su propio personaje.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Profile = require(script.Parent.Profile)

local talents = Config.TalentValues
local player = Players.LocalPlayer

local MovementController = {}

local sprintHeld = false
local sprinting = false
local doubleJumpUsed = false
local dashReadyAt = 0

local function getHumanoid(): Humanoid?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

function MovementController.isSprinting(): boolean
	return sprinting
end

function MovementController.setSprint(held: boolean)
	sprintHeld = held
end

function MovementController.dash()
	local humanoid = getHumanoid()
	local root = humanoid and (player.Character :: Model):FindFirstChild("HumanoidRootPart")
	if not root or not Profile.hasTalent("Dash") or os.clock() < dashReadyAt then
		return
	end
	dashReadyAt = os.clock() + talents.DashCooldown

	-- Hacia donde camina el jugador, o hacia donde mira si está quieto
	local direction = (humanoid :: Humanoid).MoveDirection
	if direction.Magnitude < 0.1 then
		local look = workspace.CurrentCamera.CFrame.LookVector
		direction = Vector3.new(look.X, 0, look.Z)
	end
	if direction.Magnitude < 0.01 then
		return
	end

	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VectorVelocity = direction.Unit * talents.DashSpeed
	velocity.Parent = root
	Debris:AddItem(velocity, talents.DashTime)
	Debris:AddItem(attachment, talents.DashTime)
end

-- Segundos que faltan para volver a esquivar
function MovementController.getDashCooldown(): number
	return math.max(0, dashReadyAt - os.clock())
end

local function update()
	local humanoid = getHumanoid()
	if not humanoid then
		sprinting = false
		return
	end
	local base = player:GetAttribute("BaseWalkSpeed") or Config.Player.WalkSpeed
	sprinting = sprintHeld and Profile.hasTalent("Sprint") and humanoid.MoveDirection.Magnitude > 0.1
	humanoid.WalkSpeed = if sprinting then base * talents.SprintMultiplier else base
end

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	doubleJumpUsed = false
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed then
			doubleJumpUsed = false
		end
	end)
end

function MovementController.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			sprintHeld = true
		elseif input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.ButtonB then
			MovementController.dash()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL3 then
			sprintHeld = false
		end
	end)

	-- Doble salto: un segundo salto mientras está en el aire
	UserInputService.JumpRequest:Connect(function()
		local humanoid = getHumanoid()
		if humanoid and not doubleJumpUsed and Profile.hasTalent("DoubleJump") and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			doubleJumpUsed = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
	RunService.RenderStepped:Connect(update)
end

return MovementController
