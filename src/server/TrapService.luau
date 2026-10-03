-- Trampas que se compran al Intendente antes de la partida:
--   Minas: se entierran en el camino de los zombis y explotan cuando pasa uno.
--   Rejas: dos tramos de reja frente a la campana. Los zombis se paran a
--          golpearlas hasta romperlas; mientras tanto no llegan a la campana.
-- Duran una sola partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)
local Props = require(script.Parent.Props)

local mineConfig = Config.Traps.Mine
local gateConfig = Config.Traps.Gate
local IRON = Color3.fromRGB(60, 62, 68)
local STONE = Props.Colors.Stone

type Mine = { Position: Vector3, Owner: Player, Model: Model }
type Gate = {
	Id: string,
	A: Vector3,
	B: Vector3,
	Health: number,
	Model: Model,
	Fill: Frame,
}

local TrapService = {}

local mines: { [number]: Mine } = {}
local gates: { [string]: Gate } = {}
local folder: Folder

local function publish()
	local count = 0
	for _ in mines do
		count += 1
	end
	GameState.set("Mines", count)
	GameState.set("MinesMax", #mineConfig.Spots)
	GameState.set("GateMax", gateConfig.Health)
	for id in gateConfig.Slots do
		local gate = gates[id]
		GameState.set("Gate" .. id, if gate then math.ceil(gate.Health) else 0)
	end
end

local function pointAt(angleDegrees: number, radius: number): Vector3
	local angle = math.rad(angleDegrees)
	return Vector3.new(math.sin(angle) * radius, 0, -math.cos(angle) * radius)
end

function TrapService.getGateSegment(id: string): (Vector3, Vector3)
	local slot = gateConfig.Slots[id]
	return pointAt(slot.From, gateConfig.Radius), pointAt(slot.To, gateConfig.Radius)
end

-- Para EnemyService: tramos de reja que siguen en pie
function TrapService.getBarriers(): { EnemyService.Barrier }
	local list = {}
	for id, gate in gates do
		table.insert(list, { Id = id, A = gate.A, B = gate.B })
	end
	return list
end

function TrapService.canPlaceMine(): boolean
	for index = 1, #mineConfig.Spots do
		if not mines[index] then
			return true
		end
	end
	return false
end

function TrapService.placeMine(owner: Player): boolean
	for index, spot in mineConfig.Spots do
		if not mines[index] then
			local position = pointAt(spot[1], spot[2])
			local model = Instance.new("Model")
			model.Name = "Mine"
			Props.makeProp({ Name = "Plate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 2.4, 2.4), CFrame = CFrame.new(position + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 54, 46), Parent = model })
			local light = Props.makeProp({ Name = "Light", Size = Vector3.new(0.3, 0.3, 0.3), Position = position + Vector3.new(0, 0.45, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 50), Parent = model })
			Props.light(light, Color3.fromRGB(255, 60, 50), 6, 1)
			model.Parent = folder
			mines[index] = { Position = position, Owner = owner, Model = model }
			publish()
			return true
		end
	end
	return false
end

function TrapService.hasGate(id: string): boolean
	return gates[id] ~= nil
end

function TrapService.buildGate(id: string): boolean
	if gates[id] or not gateConfig.Slots[id] then
		return false
	end
	local a, b = TrapService.getGateSegment(id)
	local model = Instance.new("Model")
	model.Name = "Gate" .. id
	local offset = b - a
	local length = offset.Magnitude
	local frame = CFrame.lookAt(a, b) -- -Z va de A hacia B

	for _, point in { a, b } do
		Props.makePart({ Name = "Pillar", Size = Vector3.new(1.6, 6.5, 1.6), Position = point + Vector3.new(0, 3.25, 0), Material = Enum.Material.Cobblestone, Color = STONE, Parent = model })
		Props.makeProp({ Name = "PillarCap", Size = Vector3.new(2, 0.5, 2), Position = point + Vector3.new(0, 6.75, 0), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	end
	for _, y in { 0.6, 4.8 } do
		Props.makePart({ Name = "Rail", Size = Vector3.new(0.3, 0.3, length), CFrame = frame * CFrame.new(0, y, -length / 2), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = model })
	end
	local bars = math.floor(length / 0.9)
	for index = 1, bars - 1 do
		local bar = Props.makePart({ Name = "Bar", Size = Vector3.new(0.22, 5.4, 0.22), CFrame = frame * CFrame.new(0, 2.7, -index * length / bars), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = model })
		-- Puntas arriba de cada barrote
		Props.makeProp({ Name = "Spike", Size = Vector3.new(0.3, 0.5, 0.3), CFrame = bar.CFrame * CFrame.new(0, 2.95, 0) * CFrame.Angles(0, math.rad(45), 0), Material = Enum.Material.Metal, Color = IRON, Parent = model })
	end

	-- Barra de vida flotando sobre la reja
	local anchor = Props.makeProp({ Name = "HealthAnchor", Size = Vector3.one * 0.2, Position = a:Lerp(b, 0.5) + Vector3.new(0, 7.5, 0), Transparency = 1, Parent = model })
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(120, 12)
	billboard.MaxDistance = 120
	billboard.Parent = anchor
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 24, 26)
	back.BorderSizePixel = 0
	back.Parent = billboard
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
	fill.BorderSizePixel = 0
	fill.Parent = back

	model.Parent = folder
	gates[id] = { Id = id, A = a, B = b, Health = gateConfig.Health, Model = model, Fill = fill }
	publish()
	return true
end

function TrapService.damageGate(id: string, amount: number)
	local gate = gates[id]
	if not gate then
		return
	end
	local before = math.ceil(gate.Health)
	gate.Health -= amount
	gate.Fill.Size = UDim2.fromScale(math.clamp(gate.Health / gateConfig.Health, 0, 1), 1)
	if gate.Health > 0 then
		if math.ceil(gate.Health) ~= before then
			GameState.set("Gate" .. id, math.ceil(gate.Health))
		end
		return
	end

	gates[id] = nil
	Remotes.PowerFx:FireAllClients("Explosion", gate.A:Lerp(gate.B, 0.5) + Vector3.new(0, 2, 0), 8)
	gate.Model:Destroy()
	publish()
	for _, player in Players:GetPlayers() do
		Remotes.Notify:FireClient(player, `🚧 ¡Rompieron la {gateConfig.Slots[id].Name:lower()}!`)
	end
	EnemyService.releaseBarrier(id, workspace:GetServerTimeNow())
end

-- Revisa si algún zombi pisó una mina
function TrapService.think(now: number, wave: number)
	for index, mine in mines do
		if #EnemyService.getInRadius(mine.Position, mineConfig.TriggerRadius, now) > 0 then
			mines[index] = nil
			mine.Model:Destroy()
			Remotes.PowerFx:FireAllClients("Mine", mine.Position, mineConfig.Radius)
			local damage = mineConfig.Damage * (1 + Config.Waves.HealthGrowth * math.max(wave - 1, 0))
			for _, enemyId in EnemyService.getInRadius(mine.Position, mineConfig.Radius, now) do
				EnemyService.damage(enemyId, damage, mine.Owner)
			end
			publish()
		end
	end
end

-- Quita todas las trampas (al volver a la preparación)
function TrapService.reset()
	for _, mine in mines do
		mine.Model:Destroy()
	end
	for _, gate in gates do
		gate.Model:Destroy()
	end
	table.clear(mines)
	table.clear(gates)
	publish()
end

function TrapService.init()
	folder = Instance.new("Folder")
	folder.Name = "Traps"
	folder.Parent = workspace
	EnemyService.setBarrierProvider(TrapService.getBarriers)
	publish()
end

return TrapService
