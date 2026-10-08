-- Rombos de experiencia: cuando muere un zombi salta un rombo brillante que
-- gira, y después vuela hacia quien lo mató. Al llegarte a ti muestra "+N XP".
-- Es solo visual: la XP ya se cuenta en el servidor al matar (MatchService).
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Sfx = require(script.Parent.Sfx)

local COLOR = Color3.fromRGB(90, 255, 170)
local BOSS_COLOR = Color3.fromRGB(255, 210, 80)
local MAX_DROPS = 60 -- en una horda grande no se llena la pantalla
local POP_TIME = 0.45 -- salta y gira antes de volar
local FLY_TIME = 0.4
local MAX_DISTANCE = 120 -- si el que lo mató está más lejos, el rombo solo se desvanece
local SPIN_SPEED = 6

type Drop = { Part: BasePart, Start: Vector3, Born: number, Target: Player?, Boss: boolean, Amount: number }

local XpDrops = {}

local player = Players.LocalPlayer
local folder: Folder
local drops: { Drop } = {}
local random = Random.new()

local function targetPosition(target: Player): Vector3?
	local character = target.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return if root then root.Position else nil
end

local function popText(amount: number, boss: boolean)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 26)
	gui.StudsOffset = Vector3.new(random:NextNumber(-1.5, 1.5), 2.2, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Config.PixelFont
	label.TextSize = if boss then 24 else 18
	label.TextColor3 = if boss then BOSS_COLOR else COLOR
	label.TextStrokeTransparency = 0.2
	label.Text = `+{amount} XP`
	label.Parent = gui
	gui.Parent = folder
	Debris:AddItem(gui, 0.8)
end

local function finish(index: number, collected: boolean)
	local drop = drops[index]
	table.remove(drops, index)
	drop.Part:Destroy()
	if collected and drop.Target == player then
		popText(drop.Amount, drop.Boss)
		Sfx.play("XpPickup")
	end
end

local function update()
	local now = os.clock()
	for index = #drops, 1, -1 do
		local drop = drops[index]
		local age = now - drop.Born
		local spin = CFrame.Angles(0, age * SPIN_SPEED, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45))
		if age < POP_TIME then
			-- Salta hacia arriba con un rebote suave
			local t = age / POP_TIME
			local height = 2.5 * math.sin(t * math.pi * 0.5) + 1
			drop.Part.CFrame = CFrame.new(drop.Start + Vector3.new(0, height, 0)) * spin
			continue
		end
		local target = drop.Target and targetPosition(drop.Target)
		local from = drop.Start + Vector3.new(0, 3.5, 0)
		if not target or (target - from).Magnitude > MAX_DISTANCE then
			-- Nadie cerca: se apaga donde está
			drop.Part.Transparency = math.clamp((age - POP_TIME) / 0.4, 0, 1)
			drop.Part.CFrame = CFrame.new(from) * spin
			if age > POP_TIME + 0.4 then
				finish(index, false)
			end
			continue
		end
		-- Vuela hacia el jugador, cada vez más rápido
		local t = math.clamp((age - POP_TIME) / FLY_TIME, 0, 1)
		local eased = t * t
		local position = from:Lerp(target, eased) + Vector3.new(0, math.sin(t * math.pi) * 2, 0)
		drop.Part.CFrame = CFrame.new(position) * spin
		drop.Part.Size = Vector3.one * (if drop.Boss then 1.4 else 0.8) * (1 - eased * 0.5)
		if t >= 1 then
			finish(index, true)
		end
	end
end

-- Lo llama EnemyRenderer cuando muere un zombi
function XpDrops.spawn(position: Vector3, killerId: number, typeName: string)
	if #drops >= MAX_DROPS then
		finish(1, false)
	end
	local info = Config.Enemies[typeName]
	local boss = info ~= nil and info.IsBoss == true
	local part = Instance.new("Part")
	part.Name = "XpDiamond"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = if boss then BOSS_COLOR else COLOR
	part.Size = Vector3.one * (if boss then 1.4 else 0.8)
	part.CFrame = CFrame.new(position)
	local light = Instance.new("PointLight")
	light.Color = part.Color
	light.Range = if boss then 10 else 5
	light.Brightness = 1.2
	light.Parent = part
	part.Parent = folder
	table.insert(drops, {
		Part = part,
		Start = Vector3.new(position.X, position.Y, position.Z),
		Born = os.clock(),
		Target = Players:GetPlayerByUserId(killerId),
		Boss = boss,
		Amount = if boss then Config.Progression.XpPerBossKill else Config.Progression.XpPerKill,
	})
end

function XpDrops.init()
	folder = Instance.new("Folder")
	folder.Name = "XpDrops"
	folder.Parent = workspace
	RunService.RenderStepped:Connect(update)
end

return XpDrops
