-- Dibuja las mascotas de todos los jugadores (Config.Pets): modelos chiquitos
-- de bloques que siguen a su dueño. Los que vuelan aletean junto a su hombro;
-- el lobo corre a sus pies. Cuando el servidor avisa un ataque (PetAttack),
-- la mascota se lanza hacia el zombi y se ve el golpe.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local MAX_DISTANCE = 220
local LUNGE_TIME = 0.25

type PartSpec = { Size: Vector3, Offset: Vector3, Color: Color3, Neon: boolean?, Wing: number? }
type PetSpec = { Parts: { PartSpec }, Follow: Vector3, Flying: boolean, Attack: Color3 }
type Render = {
	Model: Model,
	Parts: { BasePart },
	Specs: { PartSpec },
	Id: string,
	CFrame: CFrame,
	LungeStart: number,
	LungeTarget: Vector3,
	Phase: number,
}

local CREAM = Color3.fromRGB(236, 220, 170)
local BLACK = Color3.fromRGB(20, 20, 24)
local WHITE = Color3.fromRGB(240, 240, 236)

local function p(size: Vector3, offset: Vector3, color: Color3, neon: boolean?, wing: number?): PartSpec
	return { Size = size, Offset = offset, Color = color, Neon = neon, Wing = wing }
end

local function shade(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

-- Piezas de cada mascota (mirando hacia -Z). Wing = lado del ala que aletea.
local function buildSpec(id: string): PetSpec
	local color = Config.Pets[id].Color
	if id == "Bat" then
		return {
			Follow = Vector3.new(2.4, 2.2, 0.8),
			Flying = true,
			Attack = Color3.fromRGB(190, 120, 255),
			Parts = {
				p(Vector3.new(0.9, 0.8, 0.7), Vector3.zero, color),
				p(Vector3.new(0.8, 0.7, 0.6), Vector3.new(0, 0.65, -0.1), color),
				p(Vector3.new(0.2, 0.35, 0.15), Vector3.new(-0.25, 1.15, -0.1), color),
				p(Vector3.new(0.2, 0.35, 0.15), Vector3.new(0.25, 1.15, -0.1), color),
				p(Vector3.new(0.15, 0.12, 0.05), Vector3.new(-0.18, 0.72, -0.42), Color3.fromRGB(255, 60, 60), true),
				p(Vector3.new(0.15, 0.12, 0.05), Vector3.new(0.18, 0.72, -0.42), Color3.fromRGB(255, 60, 60), true),
				p(Vector3.new(1.3, 0.12, 0.8), Vector3.new(-1.05, 0.2, 0), shade(color, 0.3), false, -1),
				p(Vector3.new(1.3, 0.12, 0.8), Vector3.new(1.05, 0.2, 0), shade(color, 0.3), false, 1),
			},
		}
	elseif id == "Owl" then
		return {
			Follow = Vector3.new(-2.4, 2.4, 0.8),
			Flying = true,
			Attack = WHITE,
			Parts = {
				p(Vector3.new(1.2, 1.4, 1.1), Vector3.zero, color),
				p(Vector3.new(1.0, 1.0, 0.1), Vector3.new(0, -0.1, -0.56), CREAM),
				p(Vector3.new(1.1, 0.9, 1.0), Vector3.new(0, 1.1, 0), color),
				p(Vector3.new(0.42, 0.42, 0.05), Vector3.new(-0.26, 1.15, -0.52), WHITE),
				p(Vector3.new(0.42, 0.42, 0.05), Vector3.new(0.26, 1.15, -0.52), WHITE),
				p(Vector3.new(0.2, 0.2, 0.06), Vector3.new(-0.26, 1.15, -0.56), Color3.fromRGB(255, 200, 40), true),
				p(Vector3.new(0.2, 0.2, 0.06), Vector3.new(0.26, 1.15, -0.56), Color3.fromRGB(255, 200, 40), true),
				p(Vector3.new(0.2, 0.25, 0.2), Vector3.new(0, 0.92, -0.6), Color3.fromRGB(240, 150, 40)),
				p(Vector3.new(0.2, 0.35, 0.2), Vector3.new(-0.4, 1.7, 0), shade(color, 0.2)),
				p(Vector3.new(0.2, 0.35, 0.2), Vector3.new(0.4, 1.7, 0), shade(color, 0.2)),
				p(Vector3.new(0.3, 1.1, 0.9), Vector3.new(-0.75, 0, 0.05), shade(color, 0.25), false, -1),
				p(Vector3.new(0.3, 1.1, 0.9), Vector3.new(0.75, 0, 0.05), shade(color, 0.25), false, 1),
			},
		}
	elseif id == "Wolf" then
		return {
			Follow = Vector3.new(-2.6, -1.9, 1.6),
			Flying = false,
			Attack = WHITE,
			Parts = {
				p(Vector3.new(1.1, 1.0, 2.2), Vector3.zero, color),
				p(Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, 0.5, -1.4), color),
				p(Vector3.new(0.5, 0.4, 0.6), Vector3.new(0, 0.32, -2.0), shade(color, 0.15)),
				p(Vector3.new(0.18, 0.15, 0.1), Vector3.new(0, 0.5, -2.32), BLACK),
				p(Vector3.new(0.25, 0.4, 0.2), Vector3.new(-0.28, 1.05, -1.3), color),
				p(Vector3.new(0.25, 0.4, 0.2), Vector3.new(0.28, 1.05, -1.3), color),
				p(Vector3.new(0.14, 0.12, 0.05), Vector3.new(-0.22, 0.7, -1.86), Color3.fromRGB(255, 210, 60), true),
				p(Vector3.new(0.14, 0.12, 0.05), Vector3.new(0.22, 0.7, -1.86), Color3.fromRGB(255, 210, 60), true),
				p(Vector3.new(0.35, 0.8, 0.35), Vector3.new(-0.35, -0.85, -0.7), color),
				p(Vector3.new(0.35, 0.8, 0.35), Vector3.new(0.35, -0.85, -0.7), color),
				p(Vector3.new(0.35, 0.8, 0.35), Vector3.new(-0.35, -0.85, 0.7), color),
				p(Vector3.new(0.35, 0.8, 0.35), Vector3.new(0.35, -0.85, 0.7), color),
				p(Vector3.new(0.3, 0.3, 1.0), Vector3.new(0, 0.45, 1.5), shade(color, 0.1)),
			},
		}
	end
	-- Dragoncito
	return {
		Follow = Vector3.new(2.6, 2.6, 1.2),
		Flying = true,
		Attack = Color3.fromRGB(255, 140, 40),
		Parts = {
			p(Vector3.new(1.1, 1.0, 1.6), Vector3.zero, color),
			p(Vector3.new(0.9, 0.6, 0.1), Vector3.new(0, -0.1, -0.81), CREAM),
			p(Vector3.new(0.9, 0.8, 1.0), Vector3.new(0, 0.6, -1.1), color),
			p(Vector3.new(0.15, 0.4, 0.15), Vector3.new(-0.25, 1.15, -1.0), CREAM),
			p(Vector3.new(0.15, 0.4, 0.15), Vector3.new(0.25, 1.15, -1.0), CREAM),
			p(Vector3.new(0.15, 0.12, 0.05), Vector3.new(-0.22, 0.75, -1.62), Color3.fromRGB(255, 220, 60), true),
			p(Vector3.new(0.15, 0.12, 0.05), Vector3.new(0.22, 0.75, -1.62), Color3.fromRGB(255, 220, 60), true),
			p(Vector3.new(0.4, 0.4, 1.4), Vector3.new(0, 0.1, 1.3), color),
			p(Vector3.new(1.4, 0.12, 1.0), Vector3.new(-1.1, 0.5, 0.1), shade(color, 0.3), false, -1),
			p(Vector3.new(1.4, 0.12, 1.0), Vector3.new(1.1, 0.5, 0.1), shade(color, 0.3), false, 1),
		},
	}
end

local specCache: { [string]: PetSpec } = {}
local function specFor(id: string): PetSpec
	local spec = specCache[id]
	if not spec then
		spec = buildSpec(id)
		specCache[id] = spec
	end
	return spec
end

local PetRenderer = {}

local renders: { [Player]: Render } = {}
local folder: Folder

local function destroy(owner: Player)
	local render = renders[owner]
	if render then
		render.Model:Destroy()
		renders[owner] = nil
	end
end

local function create(owner: Player, id: string): Render
	local spec = specFor(id)
	local model = Instance.new("Model")
	model.Name = `Pet_{owner.Name}`
	local parts = {}
	for _, piece in spec.Parts do
		local part = Instance.new("Part")
		part.Size = piece.Size
		part.Color = piece.Color
		part.Material = if piece.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = model
		table.insert(parts, part)
	end
	model.Parent = folder
	return {
		Model = model,
		Parts = parts,
		Specs = spec.Parts,
		Id = id,
		CFrame = CFrame.new(),
		LungeStart = -1,
		LungeTarget = Vector3.zero,
		Phase = math.random() * 10,
	}
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local clock = os.clock()
	for _, owner in Players:GetPlayers() do
		local id = owner:GetAttribute("Pet")
		local character = owner.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local valid = typeof(id) == "string" and Config.Pets[id] ~= nil and root ~= nil and humanoid ~= nil and humanoid.Health > 0
		local render = renders[owner]
		if not valid or (render and render.Id ~= id) then
			destroy(owner)
			render = nil
		end
		if not valid or not root or (root.Position - camera.CFrame.Position).Magnitude > MAX_DISTANCE then
			if render then
				render.Model.Parent = nil
			end
			continue
		end
		if not render then
			render = create(owner, id :: string)
			render.CFrame = root.CFrame
			renders[owner] = render
		end
		render.Model.Parent = folder

		-- Sigue a su dueño suave, mirando hacia donde mira él
		local spec = specFor(render.Id)
		local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		local facing = if look.Magnitude > 0.01 then CFrame.lookAt(Vector3.zero, look.Unit) else CFrame.identity
		local bob = if spec.Flying then math.sin(clock * 3 + render.Phase) * 0.35 else math.abs(math.sin(clock * 8)) * 0.15 * math.min(1, root.AssemblyLinearVelocity.Magnitude / 8)
		local goal = CFrame.new(root.Position + facing:VectorToWorldSpace(spec.Follow) + Vector3.new(0, bob, 0)) * facing
		-- Se lanza hacia el zombi y vuelve
		local lunge = (clock - render.LungeStart) / LUNGE_TIME
		if lunge >= 0 and lunge <= 1 then
			local toward = render.LungeTarget - goal.Position
			local reach = math.min(toward.Magnitude, if spec.Flying then 4 else 5)
			if toward.Magnitude > 0.1 then
				goal = CFrame.lookAt(goal.Position + toward.Unit * reach * math.sin(lunge * math.pi), render.LungeTarget)
			end
		end
		render.CFrame = render.CFrame:Lerp(goal, 1 - math.exp(-dt * 10))

		local flap = math.sin(clock * (if render.Id == "Owl" then 9 else 16) + render.Phase) * 0.7
		local cframes = table.create(#render.Parts)
		for index, piece in render.Specs do
			if piece.Wing then
				local pivot = Vector3.new(piece.Wing * 0.4, piece.Offset.Y, piece.Offset.Z)
				cframes[index] = render.CFrame * CFrame.new(pivot) * CFrame.Angles(0, 0, piece.Wing * flap) * CFrame.new(piece.Offset - pivot)
			else
				cframes[index] = render.CFrame * CFrame.new(piece.Offset)
			end
		end
		workspace:BulkMoveTo(render.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Golpe de la mascota: raya del color de su ataque y un estallido de cubitos
local function onAttack(owner: Player, id: string, target: Vector3)
	local render = renders[owner]
	if not render or not render.Model.Parent then
		return
	end
	render.LungeStart = os.clock()
	render.LungeTarget = target
	local color = specFor(id).Attack
	local from = render.CFrame.Position
	local length = (target - from).Magnitude
	local streak = Instance.new("Part")
	streak.Anchored = true
	streak.CanCollide = false
	streak.CanQuery = false
	streak.CanTouch = false
	streak.Material = Enum.Material.Neon
	streak.Color = color
	streak.Size = Vector3.new(0.25, 0.25, length)
	streak.CFrame = CFrame.lookAt(from, target) * CFrame.new(0, 0, -length / 2)
	streak.Parent = folder
	TweenService:Create(streak, TweenInfo.new(0.2), { Transparency = 1, Size = Vector3.new(0.05, 0.05, length) }):Play()
	Debris:AddItem(streak, 0.25)
	local burstSize = if Config.Pets[id].Splash then Config.Pets[id].Splash * 2 else 2
	local burst = Instance.new("Part")
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.Material = Enum.Material.Neon
	burst.Color = color
	burst.Transparency = 0.3
	burst.Size = Vector3.one * 0.6
	burst.CFrame = CFrame.new(target) * CFrame.Angles(math.random() * 3, math.random() * 3, 0)
	burst.Parent = folder
	TweenService:Create(burst, TweenInfo.new(0.25), { Size = Vector3.one * burstSize, Transparency = 1 }):Play()
	Debris:AddItem(burst, 0.3)
end

function PetRenderer.init()
	folder = Instance.new("Folder")
	folder.Name = "Pets"
	folder.Parent = workspace
	Players.PlayerRemoving:Connect(destroy)
	Remotes.PetAttack.OnClientEvent:Connect(onAttack)
	RunService.RenderStepped:Connect(update)
end

return PetRenderer
