-- Los NPC trabajan en lo suyo: el Armero martilla, la Bruja revuelve el
-- caldero, el Veterano le pega al muñeco y el Intendente levanta cajas.
-- El servidor marca los brazos y la herramienta con el atributo Work
-- (CampBuilder); aquí cada cliente los gira sobre la línea de los hombros.
local RunService = game:GetService("RunService")

type Worker = { Part: BasePart, Base: CFrame, Pivot: Vector3, Axis: Vector3, Kind: string, Seed: number }

local NpcWork = {}

local UP = Vector3.new(0, 1, 0)
local MAX_DISTANCE = 150 -- lejos no se anima
local workers: { Worker } = {}

local function track(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local kind = instance:GetAttribute("Work")
	local pivot = instance:GetAttribute("WorkPivot")
	local axis = instance:GetAttribute("WorkAxis")
	if type(kind) == "string" and typeof(pivot) == "Vector3" and typeof(axis) == "Vector3" then
		table.insert(workers, {
			Part = instance,
			Base = instance.CFrame,
			Pivot = pivot,
			Axis = axis,
			Kind = kind,
			Seed = instance:GetAttribute("WorkSeed") or 0,
		})
	end
end

-- Ángulos (hacia adelante sobre el hombro y de costado) según el trabajo.
-- Negativo = el brazo sube hacia adelante.
local function pose(kind: string, clock: number): (number, number)
	if kind == "hammer" then
		-- Sube despacio y baja de golpe sobre el yunque
		local t = (clock * 1.3) % 1
		local lift = if t < 0.7 then t / 0.7 else 1 - (t - 0.7) / 0.3
		return -0.35 - 1.5 * lift, 0
	elseif kind == "stir" then
		-- Círculos dentro del caldero
		return -0.75 + 0.12 * math.sin(clock * 3), 0.35 * math.cos(clock * 3)
	elseif kind == "swing" then
		-- Levanta la espada y tira un tajo cruzado
		local t = (clock * 0.9) % 1
		if t < 0.55 then
			return -2.4 * (t / 0.55), 0.3 * (t / 0.55)
		end
		local hit = (t - 0.55) / 0.45
		return -2.4 + 2.7 * math.min(hit * 2.2, 1), 0.3 - 0.6 * math.min(hit * 2.2, 1)
	elseif kind == "lift" then
		-- Sube y baja la caja de munición
		return -0.6 - 0.55 * (0.5 + 0.5 * math.sin(clock * 2)), 0
	end
	return 0, 0
end

local function update()
	local clock = os.clock()
	local camera = workspace.CurrentCamera.CFrame.Position
	local parts, cframes = {}, {}
	local index = 1
	while index <= #workers do
		local worker = workers[index]
		if not worker.Part.Parent then
			-- Con StreamingEnabled la pieza pudo descargarse (vuelve a entrar como nueva)
			workers[index] = workers[#workers]
			workers[#workers] = nil
			continue
		end
		if (worker.Pivot - camera).Magnitude < MAX_DISTANCE then
			local forward, side = pose(worker.Kind, clock + worker.Seed)
			local around = CFrame.new(worker.Pivot) * CFrame.fromAxisAngle(UP, side) * CFrame.fromAxisAngle(worker.Axis, -forward) * CFrame.new(-worker.Pivot)
			table.insert(parts, worker.Part)
			table.insert(cframes, around * worker.Base)
		end
		index += 1
	end
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function NpcWork.init()
	task.spawn(function()
		local map = workspace:WaitForChild("Map")
		for _, descendant in map:GetDescendants() do
			track(descendant)
		end
		map.DescendantAdded:Connect(track)
	end)
	RunService.RenderStepped:Connect(update)
end

return NpcWork
