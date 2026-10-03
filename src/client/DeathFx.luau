-- Física sencilla para la muerte de los zombis, al estilo de los juegos
-- pixelados: las piezas del cuerpo salen disparadas (la cabeza vuela),
-- caen al suelo y revientan en cubitos de colores que rebotan y se achican.
-- Todo es local en cada cliente y tiene un tope de cubitos para no dar lag.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local DeathFx = {}

local MAX_CUBES = 260
local FLASH_TIME = 0.07
local GROUND = 0
local WHITE = Color3.new(1, 1, 1)

type Debris = {
	Part: BasePart,
	Position: Vector3,
	Rotation: CFrame,
	Velocity: Vector3,
	Spin: Vector3,
	Gravity: number,
	Age: number,
	Life: number,
	HalfHeight: number,
	IsCube: boolean,
	BaseSize: Vector3,
	Color: Color3,
	BurstColors: { Color3 }?,
	BurstCount: number,
	BurstSize: number,
	BurstSpeed: number,
	BurstOnGround: boolean,
	Flash: boolean,
}

type Splat = { Part: BasePart, Age: number, Life: number }

local folder: Folder
local debris: { Debris } = {}
local splats: { Splat } = {}
local pool: { BasePart } = {}
local cubeCount = 0
local random = Random.new()

local function takeCube(): BasePart
	local part = table.remove(pool)
	if part then
		part.Transparency = 0
		return part
	end
	local cube = Instance.new("Part")
	cube.Name = "DeathCube"
	cube.Anchored = true
	cube.CanCollide = false
	cube.CanQuery = false
	cube.CanTouch = false
	cube.CastShadow = false
	cube.Material = Enum.Material.SmoothPlastic
	cube.Parent = folder
	return cube
end

local function releaseCube(part: BasePart)
	part.Transparency = 1
	part.CFrame = CFrame.new(0, -500, 0)
	table.insert(pool, part)
end

function DeathFx.init(parent: Instance)
	folder = Instance.new("Folder")
	folder.Name = "DeathFx"
	folder.Parent = parent
end

-- Cubos que quedan libres antes de llegar al tope
function DeathFx.budget(): number
	return math.max(0, MAX_CUBES - cubeCount)
end

-- Una pieza del cuerpo que sale volando. Al acabar su vida (o al tocar el
-- suelo, si BurstOnGround) revienta en `burstCount` cubitos.
function DeathFx.addPiece(part: BasePart, cframe: CFrame, options: { [string]: any })
	table.insert(debris, {
		Part = part,
		Position = cframe.Position,
		Rotation = cframe.Rotation,
		Velocity = options.Velocity,
		Spin = options.Spin,
		Gravity = options.Gravity,
		Age = 0,
		Life = options.Life,
		HalfHeight = part.Size.Magnitude / 3,
		IsCube = false,
		BaseSize = part.Size,
		Color = part.Color,
		BurstColors = options.BurstColors,
		BurstCount = options.BurstCount or 0,
		BurstSize = options.BurstSize or 0.4,
		BurstSpeed = options.BurstSpeed or 10,
		BurstOnGround = options.BurstOnGround == true,
		Flash = options.Flash ~= false,
	})
	if options.Flash ~= false then
		part.Color = WHITE
	end
end

function DeathFx.addCube(position: Vector3, color: Color3, size: number, velocity: Vector3, gravity: number, life: number, glowing: boolean?)
	if cubeCount >= MAX_CUBES then
		return
	end
	cubeCount += 1
	local part = takeCube()
	part.Size = Vector3.one * size
	part.Color = color
	part.Material = if glowing then Enum.Material.Neon else Enum.Material.SmoothPlastic
	table.insert(debris, {
		Part = part,
		Position = position,
		Rotation = CFrame.Angles(random:NextNumber(0, 6), random:NextNumber(0, 6), 0),
		Velocity = velocity,
		Spin = Vector3.new(random:NextNumber(-8, 8), random:NextNumber(-8, 8), random:NextNumber(-8, 8)),
		Gravity = gravity,
		Age = 0,
		Life = life,
		HalfHeight = size / 2,
		IsCube = true,
		BaseSize = part.Size,
		Color = color,
		BurstColors = nil,
		BurstCount = 0,
		BurstSize = 0,
		BurstSpeed = 0,
		BurstOnGround = false,
		Flash = false,
	})
end

-- Mancha en el suelo que se desvanece
function DeathFx.splat(position: Vector3, radius: number, color: Color3, life: number)
	local part = Instance.new("Part")
	part.Name = "Splat"
	-- En pixel art 3D la mancha es cuadrada
	part.Shape = if Config.Style.Blocky then Enum.PartType.Block else Enum.PartType.Cylinder
	part.Size = Vector3.new(0.1, radius * 2, radius * 2)
	part.CFrame = CFrame.new(position.X, GROUND + 0.08, position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	table.insert(splats, { Part = part, Age = 0, Life = life })
end

local function burst(item: Debris)
	local colors = item.BurstColors
	if not colors or item.BurstCount <= 0 then
		return
	end
	for index = 1, item.BurstCount do
		local direction = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(0.2, 1.2), random:NextNumber(-1, 1)).Unit
		local speed = item.BurstSpeed * random:NextNumber(0.6, 1.3)
		local color = colors[(index - 1) % #colors + 1]
		DeathFx.addCube(item.Position, color, item.BurstSize * random:NextNumber(0.7, 1.2), direction * speed, item.Gravity, random:NextNumber(0.8, 1.3))
	end
end

-- Avanza la física y agrega las piezas que se movieron a las listas de BulkMoveTo
function DeathFx.step(dt: number, parts: { BasePart }, cframes: { CFrame })
	local index = 1
	while index <= #debris do
		local item = debris[index]
		item.Age += dt
		local landed = false

		item.Velocity -= Vector3.new(0, item.Gravity * dt, 0)
		local position = item.Position + item.Velocity * dt
		if position.Y < GROUND + item.HalfHeight then
			position = Vector3.new(position.X, GROUND + item.HalfHeight, position.Z)
			landed = item.Velocity.Y < 0
			-- Rebote corto y se frena al arrastrarse
			item.Velocity = Vector3.new(item.Velocity.X * 0.6, math.abs(item.Velocity.Y) * 0.3, item.Velocity.Z * 0.6)
			item.Spin *= 0.6
		end
		item.Position = position
		item.Rotation *= CFrame.Angles(item.Spin.X * dt, item.Spin.Y * dt, item.Spin.Z * dt)

		if item.Flash and item.Age >= FLASH_TIME then
			item.Flash = false
			item.Part.Color = item.Color
		end

		local done = item.Age >= item.Life or (landed and item.BurstOnGround)
		if done then
			if item.IsCube then
				cubeCount -= 1
				releaseCube(item.Part)
			else
				burst(item)
				item.Part:Destroy()
			end
			debris[index] = debris[#debris]
			debris[#debris] = nil
			continue
		end

		-- Los cubitos se achican al final de su vida
		if item.IsCube then
			local left = (item.Life - item.Age) / item.Life
			if left < 0.4 then
				item.Part.Size = item.BaseSize * math.max(left / 0.4, 0.05)
			end
		end
		table.insert(parts, item.Part)
		table.insert(cframes, CFrame.new(position) * item.Rotation)
		index += 1
	end

	local splatIndex = 1
	while splatIndex <= #splats do
		local splat = splats[splatIndex]
		splat.Age += dt
		if splat.Age >= splat.Life then
			splat.Part:Destroy()
			splats[splatIndex] = splats[#splats]
			splats[#splats] = nil
			continue
		end
		local fadeStart = splat.Life * 0.6
		if splat.Age > fadeStart then
			splat.Part.Transparency = (splat.Age - fadeStart) / (splat.Life - fadeStart)
		end
		splatIndex += 1
	end
end

function DeathFx.clear()
	for _, item in debris do
		if item.IsCube then
			releaseCube(item.Part)
		else
			item.Part:Destroy()
		end
	end
	table.clear(debris)
	cubeCount = 0
	for _, splat in splats do
		splat.Part:Destroy()
	end
	table.clear(splats)
end

return DeathFx
