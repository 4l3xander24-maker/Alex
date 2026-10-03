-- Trampas que se compran al Intendente antes de la partida:
--   Minas: se entierran en el camino de los zombis y explotan cuando pasa uno.
--   Rejas: una cruzada en cada camino, cerca de la campana. Los zombis se
--          paran a golpearlas hasta romperlas; mientras tanto no avanzan.
-- Duran una sola partida.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Paths = require(Shared.Paths)
local Remotes = require(Shared.Remotes)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)
local Props = require(script.Parent.Props)

local mineConfig = Config.Traps.Mine
local gateConfig = Config.Traps.Gate
local IRON = Color3.fromRGB(60, 62, 68)
local STONE = Props.Colors.Stone
local makePart, makeProp = Props.makePart, Props.makeProp

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
-- Lista de rejas en pie, guardada para no crearla en cada consulta de los zombis
local barriers: { EnemyService.Barrier } = {}

local function refreshBarriers()
	barriers = {}
	for id, gate in gates do
		table.insert(barriers, { Id = id, A = gate.A, B = gate.B })
	end
end

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

-- Lugar de una mina sobre su camino
function TrapService.getMineSpot(index: number): Vector3
	local spot = mineConfig.Spots[index]
	local position = Paths.pointFromBell(spot[1], spot[2])
	return position
end

-- La reja cruza el camino de lado a lado
function TrapService.getGateSegment(id: string): (Vector3, Vector3)
	local slot = gateConfig.Slots[id]
	local center, direction = Paths.pointFromBell(slot.Path, slot.At)
	local side = Vector3.new(-direction.Z, 0, direction.X) * (slot.Width / 2)
	return center - side, center + side
end

-- Para EnemyService: tramos de reja que siguen en pie
function TrapService.getBarriers(): { EnemyService.Barrier }
	return barriers
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
	for index in mineConfig.Spots do
		if not mines[index] then
			local position = TrapService.getMineSpot(index)
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

-- Portón de piedra con rastrillo de hierro (como en Guns 'n Goblins): dos
-- torres de ladrillo, dintel con almenas, escalera, estandarte y farol
function TrapService.buildGate(id: string): boolean
	if gates[id] or not gateConfig.Slots[id] then
		return false
	end
	local a, b = TrapService.getGateSegment(id)
	local model = Instance.new("Model")
	model.Name = "Gate" .. id
	local offset = b - a
	local length = offset.Magnitude
	local frame = CFrame.lookAt(a, b) -- -Z va de A hacia B; X atraviesa el muro
	local thickness = 3
	local wallHeight = 9
	local opening = 6.5 -- alto del hueco del rastrillo

	-- Torres a los lados y dintel arriba (ladrillo de castillo)
	for _, along in { 0, length } do
		makePart({ Name = "GateTower", Size = Vector3.new(thickness, wallHeight, 3), CFrame = frame * CFrame.new(0, wallHeight / 2, -along + (if along == 0 then 1.5 else -1.5)), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, Random.new()), Parent = model })
	end
	makePart({ Name = "GateLintel", Size = Vector3.new(thickness, wallHeight - opening, length), CFrame = frame * CFrame.new(0, opening + (wallHeight - opening) / 2, -length / 2), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	for along = 1, length - 1, 2.6 do
		makeProp({ Name = "Merlon", Size = Vector3.new(thickness, 1.4, 1.4), CFrame = frame * CFrame.new(0, wallHeight + 0.7, -along), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	end

	-- Rastrillo: barrotes verticales con punta y travesaños
	local inner = length - 6
	local bars = math.max(2, math.floor(inner / 1.1))
	for index = 0, bars do
		local along = 3 + index * inner / bars
		Props.makePart({ Name = "Bar", Size = Vector3.new(0.3, opening, 0.3), CFrame = frame * CFrame.new(0, opening / 2, -along), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = model })
		makeProp({ Name = "Spike", Size = Vector3.new(0.35, 0.5, 0.35), CFrame = frame * CFrame.new(0, 0.1, -along) * CFrame.Angles(0, 0, math.rad(45)), Material = Enum.Material.Metal, Color = IRON, Parent = model })
	end
	for _, y in { 1.4, 2.9, 4.4, 5.9 } do
		Props.makePart({ Name = "Rail", Size = Vector3.new(0.3, 0.3, inner), CFrame = frame * CFrame.new(0, y, -length / 2), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = model })
	end

	-- Escalera apoyada en la torre de la izquierda
	local ladder = frame * CFrame.new(-thickness / 2 - 0.8, 0, -1.5) * CFrame.Angles(0, 0, math.rad(-12))
	for _, side in { -0.7, 0.7 } do
		makeProp({ Name = "LadderRail", Size = Vector3.new(0.25, wallHeight, 0.25), CFrame = ladder * CFrame.new(0, wallHeight / 2, side), Material = Enum.Material.Wood, Color = Props.Colors.Wood, Parent = model })
	end
	for y = 1, wallHeight - 1, 1.3 do
		makeProp({ Name = "LadderRung", Size = Vector3.new(0.2, 0.2, 1.4), CFrame = ladder * CFrame.new(0, y, 0), Material = Enum.Material.Wood, Color = Props.Colors.Wood, Parent = model })
	end

	-- Estandarte verde arriba y farol colgando al costado
	local top = frame * CFrame.new(0, wallHeight + 1.4, -length * 0.62)
	makeProp({ Name = "FlagPole", Size = Vector3.new(0.3, 5, 0.3), CFrame = top * CFrame.new(0, 2.5, 0), Material = Enum.Material.Wood, Color = Props.Colors.DarkWood, Parent = model })
	local hinge = (top * CFrame.new(0, 4.4, 0)).Position
	for _, piece in {
		makeProp({ Name = "Flag", Size = Vector3.new(0.12, 3.2, 1.8), CFrame = top * CFrame.new(-0.15, 2.8, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 110, 60), Parent = model }),
		makeProp({ Name = "FlagEmblem", Size = Vector3.new(0.14, 1, 0.8), CFrame = top * CFrame.new(-0.16, 2.9, 0), Material = Enum.Material.Fabric, Color = Color3.fromRGB(220, 200, 90), Parent = model }),
	} do
		Props.sway(piece, hinge, 0.15)
	end
	Props.hangingLantern(model, (frame * CFrame.new(-thickness - 1.5, 0, -length - 1.5)).Position, frame.RightVector * -1)

	-- Barra de vida flotando sobre la reja
	local anchor = Props.makeProp({ Name = "HealthAnchor", Size = Vector3.one * 0.2, Position = a:Lerp(b, 0.5) + Vector3.new(0, 12.5, 0), Transparency = 1, Parent = model })
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
	refreshBarriers()
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
	refreshBarriers()
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
	refreshBarriers()
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
