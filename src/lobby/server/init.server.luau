-- Lobby: donde entra todo el mundo. Una plaza de piedra con salas (círculos
-- de runas). Te paras en una para unirte; cuando entra el primero corre la
-- cuenta (más corta si se llena) y el grupo se va a una partida privada en el
-- lugar Match (servidor reservado solo para ellos).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Props)

local makePart, makeProp = Props.makePart, Props.makeProp
local rooms = Config.Rooms
local STONE = Color3.fromRGB(120, 124, 122)
local GRASS = Color3.fromRGB(96, 116, 50)
local GOLD = Color3.fromRGB(255, 215, 100)
local PAD_RADIUS = 7
local random = Random.new(5)

type Room = {
	Index: number,
	Center: Vector3,
	Members: { Player },
	EndsAt: number?,
	Launching: boolean,
	Label: TextLabel,
	Ring: BasePart,
}

local roomList: { Room } = {}
local roomOf: { [Player]: Room } = {}

-- Aviso para cada cliente (lo muestra LobbyClient)
local status = Instance.new("RemoteEvent")
status.Name = "LobbyStatus"
status.Parent = ReplicatedStorage

local function buildPlaza(map: Instance)
	local terrain = workspace.Terrain
	terrain:Clear()
	terrain:SetMaterialColor(Enum.Material.Grass, GRASS)
	terrain:FillBlock(CFrame.new(0, -4, 0), Vector3.new(400, 8, 400), Enum.Material.Grass)
	pcall(function()
		(terrain :: any).Decoration = true
	end)
	-- Plaza redonda de piedra
	makePart({ Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 90, 90), CFrame = CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Cobblestone, Color = STONE, Parent = map })
	-- Muro de castillo de fondo con almenas
	for x = -45, 45, 6 do
		local height = random:NextNumber(10, 13)
		makePart({ Name = "Wall", Size = Vector3.new(6, height, 3), Position = Vector3.new(x, height / 2, -52), Material = Enum.Material.Slate, Color = Props.vary(STONE, 0.07, random), Parent = map })
		makeProp({ Name = "Merlon", Size = Vector3.new(2.4, 2, 3), Position = Vector3.new(x, height + 1, -52), Material = Enum.Material.Slate, Color = STONE, Parent = map })
	end
	for _, x in { -48, 48 } do
		makePart({ Name = "Tower", Shape = Enum.PartType.Cylinder, Size = Vector3.new(22, 10, 10), CFrame = CFrame.new(x, 11, -52) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = STONE, Parent = map })
		for index = 0, 5 do
			local width = 11 - index * 1.8
			makePart({ Name = "TowerRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, width, width), CFrame = CFrame.new(x, 22.8 + index * 1.6, -52) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.ClayRoofTiles, Color = Color3.fromRGB(128, 54, 40), Parent = map })
		end
	end
	-- Cartel con el nombre del juego
	local sign = makePart({ Name = "TitleSign", Size = Vector3.new(30, 6, 1), Position = Vector3.new(0, 18, -50.4), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(96, 62, 38), Parent = map })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.PixelsPerStud = 30
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Arcade
	title.TextScaled = true
	title.TextColor3 = GOLD
	title.Text = "CAMPANA MALDITA"
	title.Parent = gui
	-- Antorchas alrededor de la plaza
	for index = 0, 9 do
		local angle = index / 10 * math.pi * 2
		Props.torch(map, Vector3.new(math.cos(angle) * 43, 0, math.sin(angle) * 43))
	end
	-- Lugar donde se aparece: al centro
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 0.5, 18), Vector3.new(0, 0.5, -20))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Parent = map
end

local function buildRoom(map: Instance, index: number, center: Vector3): Room
	local model = Instance.new("Model")
	model.Name = "Room" .. index
	makePart({ Name = "Pad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, PAD_RADIUS * 2, PAD_RADIUS * 2), CFrame = CFrame.new(center + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate, Color = Color3.fromRGB(26, 28, 32), Parent = model })
	local ring = makeProp({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.45, PAD_RADIUS * 2 + 0.8, PAD_RADIUS * 2 + 0.8), CFrame = CFrame.new(center + Vector3.new(0, 0.66, 0)) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 200, 120), Parent = model })
	-- Arco de piedra detrás de la sala
	for _, side in { -1, 1 } do
		makePart({ Name = "ArchPost", Size = Vector3.new(1.6, 11, 1.6), Position = center + Vector3.new(side * 6, 5.5, -PAD_RADIUS - 1), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	end
	local top = makePart({ Name = "ArchTop", Size = Vector3.new(14, 1.6, 1.6), Position = center + Vector3.new(0, 11.8, -PAD_RADIUS - 1), Material = Enum.Material.Slate, Color = STONE, Parent = model })
	Props.banner(model, center + Vector3.new(0, 0, -PAD_RADIUS - 1.9), 0, Color3.fromRGB(40, 110, 60))

	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(260, 70)
	board.StudsOffset = Vector3.new(0, 3, 0)
	board.MaxDistance = 120
	board.Adornee = top
	board.Parent = model
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = board
	model.Parent = map
	return { Index = index, Center = center, Members = {}, EndsAt = nil, Launching = false, Label = label, Ring = ring }
end

local function refresh(room: Room)
	local count = #room.Members
	local text = `SALA {room.Index}\n👥 {count}/{rooms.MaxPlayers}`
	if room.Launching then
		text ..= "  ·  ¡Saliendo!"
	elseif room.EndsAt then
		text ..= `  ·  ⏳ {math.max(0, math.ceil(room.EndsAt - os.clock()))} s`
	else
		text ..= "  ·  Párate aquí"
	end
	room.Label.Text = text
	room.Ring.Color = if count >= rooms.MaxPlayers then Color3.fromRGB(230, 70, 60) elseif count > 0 then GOLD else Color3.fromRGB(80, 200, 120)
	for _, player in room.Members do
		status:FireClient(player, room.Index, count, if room.EndsAt then math.max(0, math.ceil(room.EndsAt - os.clock())) else nil)
	end
end

local function leave(player: Player)
	local room = roomOf[player]
	if not room or room.Launching then
		return
	end
	roomOf[player] = nil
	local index = table.find(room.Members, player)
	if index then
		table.remove(room.Members, index)
	end
	if #room.Members == 0 then
		room.EndsAt = nil
	end
	status:FireClient(player, nil)
	refresh(room)
end

local function join(player: Player, room: Room)
	if roomOf[player] == room or room.Launching or #room.Members >= rooms.MaxPlayers then
		return
	end
	leave(player)
	roomOf[player] = room
	table.insert(room.Members, player)
	if not room.EndsAt then
		room.EndsAt = os.clock() + rooms.Countdown
	end
	if #room.Members >= rooms.MaxPlayers then
		room.EndsAt = math.min(room.EndsAt :: number, os.clock() + rooms.FullCountdown)
	end
	refresh(room)
end

-- Se van todos los de la sala a una partida privada
local function launch(room: Room)
	room.Launching = true
	refresh(room)
	local members = table.clone(room.Members)
	local ok, err = pcall(function()
		if RunService:IsStudio() then
			error("En Studio no se puede teletransportar: publica y prueba desde Roblox")
		end
		local options = Instance.new("TeleportOptions")
		options.ShouldReserveServer = true
		options:SetTeleportData({ Room = room.Index, Players = #members })
		TeleportService:TeleportAsync(Config.Places.Match, members, options)
	end)
	if not ok then
		warn(`Sala {room.Index}: {err}`)
		for _, player in members do
			status:FireClient(player, room.Index, #members, nil, tostring(err))
		end
	end
	task.wait(if ok then 8 else 3)
	-- Quien no se fue (falló o se desconectó) vuelve a la plaza
	for _, player in members do
		roomOf[player] = nil
	end
	table.clear(room.Members)
	room.EndsAt = nil
	room.Launching = false
	refresh(room)
end

local map = Instance.new("Folder")
map.Name = "Map"
buildPlaza(map)
for index = 1, rooms.Count do
	local angle = (index - 1) / rooms.Count * math.pi - math.pi
	local center = Vector3.new(math.cos(angle) * 28, 0, math.sin(angle) * 22 - 12)
	table.insert(roomList, buildRoom(map, index, center))
end
map.Parent = workspace

Players.PlayerRemoving:Connect(function(player)
	leave(player)
end)

-- Cada cuarto de segundo: quién está parado en qué sala y las cuentas
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local inside: Room? = nil
			if root then
				for _, room in roomList do
					local offset = root.Position - room.Center
					if Vector3.new(offset.X, 0, offset.Z).Magnitude <= PAD_RADIUS and offset.Y < 8 then
						inside = room
						break
					end
				end
			end
			if inside then
				join(player, inside)
			elseif roomOf[player] then
				leave(player)
			end
		end
		for _, room in roomList do
			if room.EndsAt and not room.Launching then
				if os.clock() >= room.EndsAt and #room.Members > 0 then
					task.spawn(launch, room)
				else
					refresh(room)
				end
			end
		end
	end
end)

for _, room in roomList do
	refresh(room)
end
