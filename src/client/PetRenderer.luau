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
	Stunned: boolean?,
	SkinKey: any,
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
	elseif id == "Soldier" or id == "Archer" then
		local skin = Color3.fromRGB(224, 172, 140)
		local pants = Color3.fromRGB(46, 46, 56)
		local parts = {
			p(Vector3.new(0.4, 0.9, 0.4), Vector3.new(-0.22, -0.95, 0), pants),
			p(Vector3.new(0.4, 0.9, 0.4), Vector3.new(0.22, -0.95, 0), pants),
			p(Vector3.new(0.9, 1.0, 0.5), Vector3.new(0, 0, 0), color),
			p(Vector3.new(0.35, 0.9, 0.35), Vector3.new(-0.65, 0, 0), color),
			p(Vector3.new(0.35, 0.9, 0.35), Vector3.new(0.65, 0, -0.1), color),
			p(Vector3.new(0.6, 0.6, 0.6), Vector3.new(0, 0.8, 0), skin),
		}
		if id == "Soldier" then
			table.insert(parts, p(Vector3.new(0.7, 0.35, 0.7), Vector3.new(0, 1.2, 0), Color3.fromRGB(150, 154, 164)))
			table.insert(parts, p(Vector3.new(0.18, 0.18, 1.3), Vector3.new(0.65, 0.05, -0.8), Color3.fromRGB(40, 40, 46)))
			table.insert(parts, p(Vector3.new(0.2, 0.2, 0.1), Vector3.new(0.65, 0.05, -1.5), Color3.fromRGB(255, 200, 80), true))
		else
			table.insert(parts, p(Vector3.new(0.75, 0.4, 0.75), Vector3.new(0, 1.15, 0), Color3.fromRGB(40, 80, 40)))
			table.insert(parts, p(Vector3.new(0.14, 1.9, 0.14), Vector3.new(-0.7, 0.1, -0.5), Color3.fromRGB(110, 76, 46)))
			table.insert(parts, p(Vector3.new(0.05, 1.7, 0.05), Vector3.new(-0.7, 0.1, -0.52), Color3.fromRGB(235, 235, 225)))
		end
		return { Follow = Vector3.new(-2.8, -1.1, 1.8), Flying = false, Attack = if id == "Soldier" then Color3.fromRGB(255, 220, 120) else Color3.fromRGB(180, 255, 150), Parts = parts }
	elseif id == "Hound" then
		return {
			Follow = Vector3.new(2.6, -1.9, 1.8),
			Flying = false,
			Attack = WHITE,
			Parts = {
				p(Vector3.new(1.0, 0.9, 2.0), Vector3.zero, color),
				p(Vector3.new(0.9, 0.8, 0.9), Vector3.new(0, 0.45, -1.3), color),
				p(Vector3.new(0.5, 0.35, 0.5), Vector3.new(0, 0.3, -1.85), shade(color, 0.2)),
				p(Vector3.new(0.18, 0.15, 0.1), Vector3.new(0, 0.45, -2.1), BLACK),
				p(Vector3.new(0.22, 0.45, 0.2), Vector3.new(-0.3, 0.95, -1.2), shade(color, 0.3)),
				p(Vector3.new(0.22, 0.45, 0.2), Vector3.new(0.3, 0.95, -1.2), shade(color, 0.3)),
				p(Vector3.new(1.05, 0.25, 0.5), Vector3.new(0, 0.35, -1.0), Color3.fromRGB(190, 40, 40)),
				p(Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.3, -0.8, -0.6), color),
				p(Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.3, -0.8, -0.6), color),
				p(Vector3.new(0.3, 0.8, 0.3), Vector3.new(-0.3, -0.8, 0.6), color),
				p(Vector3.new(0.3, 0.8, 0.3), Vector3.new(0.3, -0.8, 0.6), color),
				p(Vector3.new(0.25, 0.25, 0.9), Vector3.new(0, 0.5, 1.3), shade(color, 0.1)),
			},
		}
	elseif id == "Golem" then
		local stone = shade(color, 0.1)
		return {
			Follow = Vector3.new(-3.2, -0.6, 2.2),
			Flying = false,
			Attack = Color3.fromRGB(210, 200, 170),
			Parts = {
				p(Vector3.new(0.9, 1.1, 0.9), Vector3.new(-0.55, -1.2, 0), stone),
				p(Vector3.new(0.9, 1.1, 0.9), Vector3.new(0.55, -1.2, 0), stone),
				p(Vector3.new(2.0, 1.9, 1.3), Vector3.new(0, 0, 0), color),
				p(Vector3.new(0.9, 1.9, 0.9), Vector3.new(-1.5, -0.1, 0), stone),
				p(Vector3.new(0.9, 1.9, 0.9), Vector3.new(1.5, -0.1, 0), stone),
				p(Vector3.new(1.1, 0.9, 1.0), Vector3.new(0, 1.4, -0.1), color),
				p(Vector3.new(0.22, 0.14, 0.05), Vector3.new(-0.25, 1.5, -0.6), Color3.fromRGB(110, 230, 255), true),
				p(Vector3.new(0.22, 0.14, 0.05), Vector3.new(0.25, 1.5, -0.6), Color3.fromRGB(110, 230, 255), true),
				p(Vector3.new(0.5, 0.5, 0.1), Vector3.new(0, 0.2, -0.7), Color3.fromRGB(110, 230, 255), true),
			},
		}
	elseif id == "Phoenix" then
		return {
			Follow = Vector3.new(2.8, 2.8, 1.0),
			Flying = true,
			Attack = Color3.fromRGB(255, 150, 40),
			Parts = {
				p(Vector3.new(0.9, 0.9, 1.5), Vector3.zero, color),
				p(Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 0.7, -0.9), Color3.fromRGB(255, 190, 60)),
				p(Vector3.new(0.2, 0.2, 0.4), Vector3.new(0, 0.6, -1.4), Color3.fromRGB(255, 220, 90), true),
				p(Vector3.new(0.14, 0.12, 0.05), Vector3.new(-0.2, 0.8, -1.26), BLACK),
				p(Vector3.new(0.14, 0.12, 0.05), Vector3.new(0.2, 0.8, -1.26), BLACK),
				p(Vector3.new(0.5, 0.3, 1.8), Vector3.new(0, 0.1, 1.4), Color3.fromRGB(255, 90, 30), true),
				p(Vector3.new(0.3, 0.2, 1.2), Vector3.new(0, 0.2, 2.2), Color3.fromRGB(255, 220, 90), true),
				p(Vector3.new(1.8, 0.12, 1.2), Vector3.new(-1.4, 0.4, 0), Color3.fromRGB(255, 110, 30), true, -1),
				p(Vector3.new(1.8, 0.12, 1.2), Vector3.new(1.4, 0.4, 0), Color3.fromRGB(255, 110, 30), true, 1),
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

local function skinById(skinId: any): any
	if typeof(skinId) ~= "string" or skinId == "" then
		return nil
	end
	for _, skin in Config.ObjectSkins do
		if skin.Id == skinId then
			return skin
		end
	end
	return nil
end

local function create(owner: Player, id: string): Render
	local spec = specFor(id)
	local skin = skinById(owner:GetAttribute("PetSkin"))
	local model = Instance.new("Model")
	model.Name = `Pet_{owner.Name}`
	local parts = {}
	for _, piece in spec.Parts do
		local part = Instance.new("Part")
		part.Size = piece.Size
		part.Color = piece.Color
		part.Material = if piece.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		-- Skin: tiñe el cuerpo; las Premium brillan (los ojos neón se quedan como son)
		if skin and not piece.Neon then
			part.Color = piece.Color:Lerp(skin.Main, 0.8)
			if skin.Premium then
				part.Material = Enum.Material.Neon
			end
		end
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Parent = model
		table.insert(parts, part)
	end
	if skin and skin.Premium and parts[1] then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Rate = 16
		sparks.Lifetime = NumberRange.new(0.6, 1.2)
		sparks.Speed = NumberRange.new(1, 3)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		sparks.LightEmission = 1
		sparks.Color = ColorSequence.new(skin.Accent)
		sparks.Parent = parts[1]
	end
	model.Parent = folder
	return {
		Model = model,
		Parts = parts,
		Specs = spec.Parts,
		Id = id,
		SkinKey = owner:GetAttribute("PetSkin"),
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
		if not valid or (render and (render.Id ~= id or render.SkinKey ~= owner:GetAttribute("PetSkin"))) then
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
		-- Aturdido: se ve apagado mientras no pelea
		local stunned = (owner:GetAttribute("PetStunUntil") or 0) > workspace:GetServerTimeNow()
		if stunned ~= render.Stunned then
			render.Stunned = stunned
			for _, part in render.Parts do
				part.Transparency = if stunned then 0.6 else 0
			end
		end
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

-- Modelo quieto del compañero (para la vista 3D de las tiendas)
function PetRenderer.buildPreview(id: string, skinId: string?): Model
	local spec = specFor(id)
	local skin = skinById(skinId)
	local model = Instance.new("Model")
	for _, piece in spec.Parts do
		local part = Instance.new("Part")
		part.Size = piece.Size
		part.Color = piece.Color
		part.Material = if piece.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
		if skin and not piece.Neon then
			part.Color = piece.Color:Lerp(skin.Main, 0.8)
			if skin.Premium then
				part.Material = Enum.Material.Neon
			end
		end
		part.CFrame = CFrame.new(piece.Offset)
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
	end
	return model
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
