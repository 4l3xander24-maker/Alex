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
local DataService = require(script.Parent.DataService)
local EnemyService = require(script.Parent.EnemyService)
local GameState = require(script.Parent.GameState)
local Props = require(script.Parent.Props)

local mineConfig = Config.Traps.Mine
local gateConfig = Config.Traps.Gate
local IRON = Color3.fromRGB(60, 62, 68)
local STONE = Props.Colors.Stone
local makePart, makeProp = Props.makePart, Props.makeProp

type Mine = { Position: Vector3, Owner: Player, Model: Model, Level: number }
type Gate = {
	Id: string,
	A: Vector3,
	B: Vector3,
	Health: number,
	MaxHealth: number,
	Level: number,
	Model: Model,
	Fill: Frame,
	Portcullis: Model,
	Open: number, -- 0 = cerrada, 1 = rastrillo arriba
	Lift: number,
	Base: CFrame,
	Burn: number, -- cuenta para el daño del fuego (nivel 3)
}

-- Lugar fijo donde se puede poner una trampa: aparece como un fantasma celeste
-- cuando te acercas (solo en la preparación). Al comprarla toma su lugar la real.
type Slot = { Kind: string, Key: string, Ghost: Model, Prompt: ProximityPrompt }

local TrapService = {}

local mines: { [number]: Mine } = {}
local gates: { [string]: Gate } = {}
local folder: Folder
local slots: { [string]: Slot } = {}
local lastThink = 0
local preparing = true -- hay preparación (se puede colocar y mejorar)
local CYAN = Color3.fromRGB(110, 225, 255)
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
	return position + Vector3.new(0, Paths.walkHeight(position), 0)
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

local refreshSlots: () -> () = function() end
local onUpgrade: ((Player, string, string) -> ())? = nil

-- Aviso "Mejorar" sobre el objeto ya colocado (solo se usa en la preparación)
local function attachUpgrade(kind: string, key: string, model: Model, anchor: BasePart?, distance: number)
	if not anchor then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = distance
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(function(player)
		if onUpgrade then
			onUpgrade(player, kind, key)
		end
	end)
	refreshSlots()
end

-- Mina con relieve: base de metal, anillo de púas y luz de color según el nivel
local LEVEL_COLORS = { Color3.fromRGB(255, 60, 50), Color3.fromRGB(255, 160, 40), Color3.fromRGB(190, 90, 255) }

local function buildMineModel(position: Vector3, level: number): Model
	local model = Instance.new("Model")
	model.Name = "Mine"
	local color = LEVEL_COLORS[math.min(level, #LEVEL_COLORS)]
	Props.makeProp({ Name = "Plate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 2.8, 2.8), CFrame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Metal, Color = Color3.fromRGB(46, 50, 44), Parent = model })
	Props.makeProp({ Name = "Dome", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 0.9, 1.6), Position = position + Vector3.new(0, 0.55, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 76, 66), Parent = model })
	for index = 1, 6 + level * 2 do
		local angle = index / (6 + level * 2) * math.pi * 2
		Props.makeProp({ Name = "Spike", Size = Vector3.new(0.18, 0.7, 0.18), CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.2, 0.7, math.sin(angle) * 1.2)) * CFrame.Angles(math.sin(angle) * 0.4, 0, -math.cos(angle) * 0.4), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 124, 128), Parent = model })
	end
	local light = Props.makeProp({ Name = "Light", Size = Vector3.new(0.4, 0.4, 0.4), Position = position + Vector3.new(0, 1.05, 0), Material = Enum.Material.Neon, Color = color, Parent = model })
	Props.light(light, color, 7 + level * 2, 1.2)
	return model
end

function TrapService.getMineLevel(index: number): number
	local mine = mines[index]
	return if mine then mine.Level else 0
end

function TrapService.placeMine(owner: Player, index: number): boolean
	if mines[index] or not mineConfig.Spots[index] then
		return false
	end
	local position = TrapService.getMineSpot(index)
	local model = buildMineModel(position, 1)
	model.Parent = folder
	mines[index] = { Position = position, Owner = owner, Model = model, Level = 1 }
	attachUpgrade("Mine", tostring(index), model, model:FindFirstChild("Plate") :: BasePart?, 9)
	publish()
	return true
end

-- Mejora una mina: más daño y más radio (la rehace con más púas y otro color)
function TrapService.upgradeMine(index: number): boolean
	local mine = mines[index]
	if not mine or mine.Level >= mineConfig.MaxLevel then
		return false
	end
	mine.Level += 1
	mine.Model:Destroy()
	mine.Model = buildMineModel(mine.Position, mine.Level)
	mine.Model.Parent = folder
	attachUpgrade("Mine", tostring(index), mine.Model, mine.Model:FindFirstChild("Plate") :: BasePart?, 9)
	publish()
	return true
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
	local lift = Vector3.new(0, Paths.walkHeight((a + b) / 2), 0)
	local frame = CFrame.lookAt(a + lift, b + lift) -- -Z va de A hacia B; X atraviesa el muro
	local thickness = 3
	local wallHeight = 15
	local opening = 11 -- alto del hueco del rastrillo

	-- Torres a los lados y dintel arriba (ladrillo de castillo)
	for _, along in { 0, length } do
		makePart({ Name = "GateTower", Size = Vector3.new(thickness, wallHeight, 3), CFrame = frame * CFrame.new(0, wallHeight / 2, -along + (if along == 0 then 1.5 else -1.5)), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.05, Random.new()), Parent = model })
	end
	makePart({ Name = "GateLintel", Size = Vector3.new(thickness, wallHeight - opening, length), CFrame = frame * CFrame.new(0, opening + (wallHeight - opening) / 2, -length / 2), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	for along = 1, length - 1, 2.6 do
		makeProp({ Name = "Merlon", Size = Vector3.new(thickness, 1.4, 1.4), CFrame = frame * CFrame.new(0, wallHeight + 0.7, -along), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	end

	-- Rastrillo: barrotes verticales con punta y travesaños
	local portcullis = Instance.new("Model")
	portcullis.Name = "Portcullis"
	local inner = length - 6
	local bars = math.max(2, math.floor(inner / 1.1))
	for index = 0, bars do
		local along = 3 + index * inner / bars
		Props.makePart({ Name = "Bar", Size = Vector3.new(0.3, opening, 0.3), CFrame = frame * CFrame.new(0, opening / 2, -along), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = portcullis })
		makeProp({ Name = "Spike", Size = Vector3.new(0.35, 0.5, 0.35), CFrame = frame * CFrame.new(0, 0.1, -along) * CFrame.Angles(0, 0, math.rad(45)), Material = Enum.Material.Metal, Color = IRON, Parent = portcullis })
	end
	for _, y in { 1.6, 3.8, 6, 8.2, 10.4 } do
		Props.makePart({ Name = "Rail", Size = Vector3.new(0.3, 0.3, inner), CFrame = frame * CFrame.new(0, y, -length / 2), Material = Enum.Material.Metal, Color = IRON, CanQuery = false, Parent = portcullis })
	end
	portcullis.Parent = model

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
	local anchor = Props.makeProp({ Name = "HealthAnchor", Size = Vector3.one * 0.2, Position = a:Lerp(b, 0.5) + lift + Vector3.new(0, 19, 0), Transparency = 1, Parent = model })
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

	local upgradeAnchor = Props.makeProp({ Name = "UpgradeAnchor", Size = Vector3.one * 0.4, Position = a:Lerp(b, 0.5) + lift + Vector3.new(0, 2, 0), Transparency = 1, Parent = model })
	model.Parent = folder
	gates[id] = { Id = id, A = a, B = b, Health = gateConfig.Health, MaxHealth = gateConfig.Health, Level = 1, Model = model, Fill = fill, Portcullis = portcullis, Open = 0, Lift = opening - 0.3, Base = portcullis:GetPivot(), Burn = 0 }
	refreshBarriers()
	attachUpgrade("Gate", id, model, upgradeAnchor, 16)
	publish()
	return true
end

-- Mejora una reja: más vida (queda llena) y tachones dorados en las torres
function TrapService.upgradeGate(id: string): boolean
	local gate = gates[id]
	if not gate or gate.Level >= gateConfig.MaxLevel then
		return false
	end
	gate.Level += 1
	gate.MaxHealth = gateConfig.Health * (1 + gateConfig.HealthPerLevel * (gate.Level - 1))
	gate.Health = gate.MaxHealth
	gate.Fill.Size = UDim2.fromScale(1, 1)
	local middle = gate.A:Lerp(gate.B, 0.5)
	local lift = Vector3.new(0, Paths.walkHeight(middle), 0)
	local frame = CFrame.lookAt(gate.A + lift, gate.B + lift)
	local length = (gate.B - gate.A).Magnitude
	for _, along in { 0, length } do
		for stud = 1, gate.Level do
			makeProp({ Name = "LevelStud", Shape = Enum.PartType.Ball, Size = Vector3.one * 0.7, CFrame = frame * CFrame.new(0, 2 + stud * 2, -along + (if along == 0 then 1.5 else -1.5)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 205, 80), Parent = gate.Model })
		end
	end
	-- Nivel 3: puerta de fuego. Llamas sobre los barrotes y quema a los zombis que la golpean
	if gate.Level >= 3 then
		for _, part in gate.Portcullis:GetChildren() do
			if part.Name == "Rail" and part:IsA("BasePart") and not part:FindFirstChildOfClass("Fire") then
				local fire = Instance.new("Fire")
				fire.Size = 5
				fire.Heat = 6
				fire.Parent = part
			end
		end
		Props.light(gate.Portcullis:FindFirstChildWhichIsA("BasePart") :: BasePart, Color3.fromRGB(255, 140, 50), 22, 2)
	end
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
	gate.Fill.Size = UDim2.fromScale(math.clamp(gate.Health / gate.MaxHealth, 0, 1), 1)
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
	-- Rejas: el rastrillo sube cuando un jugador se acerca y baja solo al irse
	local dt = now - lastThink
	lastThink = now
	for _, gate in gates do
		local middle = (gate.A + gate.B) / 2
		local near = false
		for _, other in Players:GetPlayers() do
			local root = other.Character and other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local offset = root.Position - middle
				if Vector3.new(offset.X, 0, offset.Z).Magnitude < 13 then
					near = true
					break
				end
			end
		end
		local target = if near then 1 else 0
		local before = gate.Open
		gate.Open = if target > before then math.min(1, before + dt * 1.6) else math.max(0, before - dt * 0.9)
		if gate.Open ~= before then
			gate.Portcullis:PivotTo(CFrame.new(0, gate.Open * gate.Lift, 0) * gate.Base)
			local solid = gate.Open < 0.5
			for _, part in gate.Portcullis:GetChildren() do
				if part:IsA("BasePart") then
					part.CanCollide = solid
				end
			end
		end
		-- Puerta de fuego (nivel 3): quema a los zombis pegados
		local owner = Players:GetPlayers()[1]
		if gate.Level >= 3 and owner then
			gate.Burn += dt
			if gate.Burn >= 0.5 then
				gate.Burn = 0
				for step = -gateConfig.Slots[gate.Id].Width / 2, gateConfig.Slots[gate.Id].Width / 2, 5 do
					local direction = (gate.B - gate.A).Unit
					for _, enemyId in EnemyService.getInRadius(middle + direction * step, 5, now) do
						EnemyService.damage(enemyId, gateConfig.FireDamage, owner)
					end
				end
			end
		end
	end
	for index, mine in mines do
		local touching = EnemyService.getInRadius(mine.Position, mineConfig.TriggerRadius, now)
		local armed = false
		if #touching > 0 then
			-- Salta con un grupo cerca, o con un zombi duro o un jefe pisándola
			armed = #EnemyService.getInRadius(mine.Position, mineConfig.Radius, now) >= mineConfig.MinTargets
			for _, enemyId in touching do
				local info = Config.Enemies[EnemyService.getType(enemyId) or ""]
				if info and (info.IsBoss or info.MaxHealth >= mineConfig.HeavyHealth) then
					armed = true
				end
			end
		end
		if armed then
			mines[index] = nil
			mine.Model:Destroy()
			Remotes.PowerFx:FireAllClients("Mine", mine.Position, mineConfig.Radius * (1 + mineConfig.RadiusPerLevel * (mine.Level - 1)))
			local damage = mineConfig.Damage * (1 + mineConfig.DamagePerLevel * (mine.Level - 1)) * (1 + Config.Waves.HealthGrowth * math.max(wave - 1, 0))
			local blast = mineConfig.Radius * (1 + mineConfig.RadiusPerLevel * (mine.Level - 1))
			for _, enemyId in EnemyService.getInRadius(mine.Position, blast, now) do
				EnemyService.damage(enemyId, damage, mine.Owner)
			end
			publish()
		end
	end
end

-- Entre oleadas las rejas en pie se reparan un poco. Devuelve cuántas.
function TrapService.healGates(fraction: number): number
	local healed = 0
	for id, gate in gates do
		if gate.Health < gate.MaxHealth then
			gate.Health = math.min(gate.MaxHealth, gate.Health + gate.MaxHealth * fraction)
			gate.Fill.Size = UDim2.fromScale(math.clamp(gate.Health / gate.MaxHealth, 0, 1), 1)
			healed += 1
		end
	end
	if healed > 0 then
		publish()
	end
	return healed
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
	refreshSlots()
end

-- Fantasma celeste de un lugar libre. Se ve solo cerca y en la preparación
-- (TrapGhosts, en el cliente); el aviso del servidor lo compra y coloca.
local function buildGhost(name: string, parts: { { Size: Vector3, Frame: CFrame, Shape: Enum.PartType? } }, label: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("Ghost", true)
	model:SetAttribute("Empty", true)
	for _, spec in parts do
		local ghost = Props.makeProp({ Name = "GhostPart", Shape = spec.Shape or Enum.PartType.Block, Size = spec.Size, CFrame = spec.Frame, Material = Enum.Material.SmoothPlastic, Color = CYAN, Transparency = 0.55, CastShadow = false, Parent = model })
		ghost.CanQuery = false
		ghost.CanTouch = false
		if not model.PrimaryPart then
			model.PrimaryPart = ghost
		end
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GhostLabel"
	billboard.Size = UDim2.fromOffset(190, 34)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.MaxDistance = 40
	billboard.AlwaysOnTop = true
	billboard.Adornee = model.PrimaryPart
	billboard.Parent = model
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextSize = 15
	text.TextColor3 = CYAN
	text.TextStrokeTransparency = 0.5
	text.Text = label
	text.Parent = billboard
	return model
end

local function buyAtSlot(player: Player, slot: Slot)
	if not preparing then
		return
	end
	if slot.Kind == "Mine" then
		local index = tonumber(slot.Key) :: number
		if mines[index] then
			return
		end
		if not DataService.spendCoins(player, mineConfig.Price) then
			Remotes.Notify:FireClient(player, `Te faltan monedas: la mina cuesta {mineConfig.Price} 💰`)
			return
		end
		DataService.changed(player, "Profile")
		TrapService.placeMine(player, index)
		Remotes.Notify:FireClient(player, "🪤 Mina colocada. Acércate a ella para mejorarla")
	else
		if gates[slot.Key] then
			return
		end
		if not DataService.spendCoins(player, gateConfig.Price) then
			Remotes.Notify:FireClient(player, `Te faltan monedas: la reja cuesta {gateConfig.Price} 💰`)
			return
		end
		DataService.changed(player, "Profile")
		TrapService.buildGate(slot.Key)
		Remotes.Notify:FireClient(player, `🚧 {gateConfig.Slots[slot.Key].Name} construida. Acércate a ella para mejorarla`)
	end
end

onUpgrade = function(player: Player, kind: string, key: string)
	if not preparing then
		return
	end
	if kind == "Mine" then
		local index = tonumber(key) :: number
		local mine = mines[index]
		if not mine or mine.Level >= mineConfig.MaxLevel then
			return
		end
		local price = mineConfig.UpgradePrice[mine.Level]
		if not DataService.spendCoins(player, price) then
			Remotes.Notify:FireClient(player, `Te faltan monedas: mejorar cuesta {price} 💰`)
			return
		end
		DataService.changed(player, "Profile")
		TrapService.upgradeMine(index)
		Remotes.Notify:FireClient(player, `🪤 Mina mejorada al nivel {mines[index].Level}`)
	else
		local gate = gates[key]
		if not gate or gate.Level >= gateConfig.MaxLevel then
			return
		end
		local price = gateConfig.UpgradePrice[gate.Level]
		if not DataService.spendCoins(player, price) then
			Remotes.Notify:FireClient(player, `Te faltan monedas: mejorar cuesta {price} 💰`)
			return
		end
		DataService.changed(player, "Profile")
		TrapService.upgradeGate(key)
		Remotes.Notify:FireClient(player, `🚧 Reja mejorada al nivel {gate.Level}`)
	end
end

-- Qué se puede tocar ahora: en la preparación los lugares libres (comprar) y los
-- objetos puestos (mejorar); con la partida en marcha, nada
refreshSlots = function()
	for _, slot in slots do
		local filled = if slot.Kind == "Mine" then mines[tonumber(slot.Key) :: number] ~= nil else gates[slot.Key] ~= nil
		slot.Ghost:SetAttribute("Empty", not filled)
		slot.Prompt.Enabled = preparing and not filled
		local model = if filled then (if slot.Kind == "Mine" then mines[tonumber(slot.Key) :: number].Model else gates[slot.Key].Model) else nil
		local upgrade = model and model:FindFirstChild("UpgradePrompt", true)
		if upgrade and upgrade:IsA("ProximityPrompt") then
			local level = if slot.Kind == "Mine" then mines[tonumber(slot.Key) :: number].Level else gates[slot.Key].Level
			local config = if slot.Kind == "Mine" then mineConfig else gateConfig
			local name = if slot.Kind == "Mine" then "mina" else "reja"
			if level >= config.MaxLevel then
				upgrade.ActionText = `Nivel máximo ({level}/{config.MaxLevel})`
				upgrade.Enabled = false
			else
				upgrade.ActionText = `Mejorar {name} a nivel {level + 1} (💰{config.UpgradePrice[level]})`
				upgrade.ObjectText = if slot.Kind == "Mine" then "Mina" else "Reja"
				upgrade.Enabled = preparing
			end
		end
	end
end

local function setupSlots()
	for index in mineConfig.Spots do
		local position = TrapService.getMineSpot(index)
		local ghost = buildGhost(`MineSlot{index}`, {
			{ Size = Vector3.new(0.5, 2.8, 2.8), Frame = CFrame.new(position + Vector3.new(0, 0.25, 0)) * CFrame.Angles(0, 0, math.pi / 2), Shape = Enum.PartType.Cylinder },
			{ Size = Vector3.new(1.6, 0.9, 1.6), Frame = CFrame.new(position + Vector3.new(0, 0.6, 0)), Shape = Enum.PartType.Ball },
		}, `Mina · {mineConfig.Price} monedas`)
		ghost.Parent = folder
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = `Colocar mina (💰{mineConfig.Price})`
		prompt.ObjectText = "Trampa"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.Parent = ghost.PrimaryPart
		local slot: Slot = { Kind = "Mine", Key = tostring(index), Ghost = ghost, Prompt = prompt }
		slots["Mine" .. index] = slot
		prompt.Triggered:Connect(function(player)
			buyAtSlot(player, slot)
		end)
	end
	for _, id in gateConfig.SlotOrder do
		local a, b = TrapService.getGateSegment(id)
		local middle = (a + b) / 2
		local lift = Vector3.new(0, Paths.walkHeight(middle), 0)
		local length = (b - a).Magnitude
		local frame = CFrame.lookAt(middle + lift, b + lift)
		local ghost = buildGhost(`GateSlot{id}`, {
			{ Size = Vector3.new(3, 15, 3), Frame = frame * CFrame.new(0, 7.5, length / 2 - 1.5) },
			{ Size = Vector3.new(3, 15, 3), Frame = frame * CFrame.new(0, 7.5, -length / 2 + 1.5) },
			{ Size = Vector3.new(3, 4, length), Frame = frame * CFrame.new(0, 13, 0) },
		}, `Reja: {gateConfig.Slots[id].Short} · {gateConfig.Price} monedas`)
		ghost.Parent = folder
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = `Construir reja (💰{gateConfig.Price})`
		prompt.ObjectText = gateConfig.Slots[id].Short
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 18
		prompt.RequiresLineOfSight = false
		prompt.Parent = ghost.PrimaryPart
		local slot: Slot = { Kind = "Gate", Key = id, Ghost = ghost, Prompt = prompt }
		slots["Gate" .. id] = slot
		prompt.Triggered:Connect(function(player)
			buyAtSlot(player, slot)
		end)
	end
	refreshSlots()
end

function TrapService.init()
	folder = Instance.new("Folder")
	folder.Name = "Traps"
	folder.Parent = workspace
	EnemyService.setBarrierProvider(TrapService.getBarriers)
	publish()
	setupSlots()
	-- Solo se coloca y mejora en la preparación ("Lobby"); al empezar la partida
	-- los fantasmas y los avisos desaparecen hasta que termine
	local state = ReplicatedStorage:WaitForChild("GameState")
	preparing = state:GetAttribute("State") == "Lobby"
	refreshSlots()
	state:GetAttributeChangedSignal("State"):Connect(function()
		preparing = state:GetAttribute("State") == "Lobby"
		refreshSlots()
	end)
end

return TrapService
