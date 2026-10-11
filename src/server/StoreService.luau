-- Pases (Game Passes) y skins. Lo usan el Lobby y la partida:
--   * Sabe qué pases tiene cada jugador (pregunta a Roblox una vez y se
--     actualiza cuando compra uno).
--   * Guarda la skin elegida (DataStore aparte, la comparten los dos lugares)
--     y se la pone al personaje: capa, borde, hombreras y brillo.
--   * StoreAction (RemoteFunction): "List" para la tienda y "Equip".
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local monetization = Config.Monetization
local SKIN_STORE = "CampanaMaldita_Skins_v1"

local StoreService = {}

type SkinInfo = typeof(monetization.Skins[1])

local skinById: { [string]: SkinInfo } = {}
for _, skin in monetization.Skins do
	skinById[skin.Id] = skin
end

local owned: { [Player]: { [number]: boolean } } = {}
local equipped: { [Player]: string? } = {}
local passListeners: { (Player, number) -> () } = {}

local skinStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(SKIN_STORE)
	end)
	if ok then
		skinStore = result
	end
end

local function passIdOf(key: string): number
	local pass = (monetization.Passes :: any)[key]
	return if pass then pass.Id else 0
end

function StoreService.ownsPassId(player: Player, passId: number): boolean
	if passId == 0 then
		return false
	end
	local cache = owned[player]
	if not cache then
		cache = {}
		owned[player] = cache
	end
	if cache[passId] == nil then
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if not ok then
			return false -- se vuelve a preguntar la próxima vez
		end
		cache[passId] = result
	end
	return cache[passId] == true
end

-- key: "DoubleCoins" o "Vip"
function StoreService.hasPass(player: Player, key: string): boolean
	return StoreService.ownsPassId(player, passIdOf(key))
end

local function skinPassId(skin: SkinInfo): number
	local info = skin :: any
	return if info.Pass then passIdOf(info.Pass) else info.PassId or 0
end

function StoreService.ownsSkin(player: Player, skinId: string): boolean
	local skin = skinById[skinId]
	return skin ~= nil and StoreService.ownsPassId(player, skinPassId(skin))
end

-- Quita la skin que tenga y le pone la elegida (si la tiene comprada)
local function applySkin(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("Skin")
	if old then
		old:Destroy()
	end
	local skinId = equipped[player]
	local skin = skinId and skinById[skinId]
	if not skin or not StoreService.ownsSkin(player, skinId) then
		return
	end
	local torso = (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")) :: BasePart?
	if not torso then
		return
	end
	local info = skin :: any
	local model = Instance.new("Model")
	model.Name = "Skin"
	local top = torso.Size.Y / 2
	local back = torso.Size.Z / 2
	local width = torso.Size.X
	local function piece(name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape or Enum.PartType.Block
		part.Size = size
		part.CFrame = torso.CFrame * offset
		part.Color = color
		part.Material = material
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
		return part
	end
	-- Capa: cuelga de los hombros por la espalda, un poco abierta abajo
	local capeHeight = top * 2 + 2
	piece("Cape", Vector3.new(width * 1.05, capeHeight, 0.12), CFrame.new(0, top - capeHeight / 2, back + 0.12) * CFrame.Angles(math.rad(-6), 0, 0), info.Cape, Enum.Material.Fabric)
	piece("CapeTrim", Vector3.new(width * 1.07, 0.25, 0.14), CFrame.new(0, top - capeHeight + 0.1, back + 0.22) * CFrame.Angles(math.rad(-6), 0, 0), info.Trim, Enum.Material.Fabric)
	piece("Collar", Vector3.new(width * 1.1, 0.3, torso.Size.Z + 0.2), CFrame.new(0, top + 0.05, 0.05), info.Trim, Enum.Material.Metal)
	if info.Armor then
		for _, side in { -1, 1 } do
			piece("Pauldron", Vector3.new(1.1, 0.6, 1.2), CFrame.new(side * (width / 2 + 0.35), top - 0.05, 0) * CFrame.Angles(0, 0, math.rad(side * -18)), info.Trim, Enum.Material.Metal)
		end
	end
	if info.Glow then
		local cape = model:FindFirstChild("CapeTrim") :: BasePart
		cape.Material = Enum.Material.Neon
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Rate = 6
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Speed = NumberRange.new(0.5, 1.2)
		sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		sparkles.Color = ColorSequence.new(info.Trim)
		sparkles.LightEmission = 1
		sparkles.Parent = cape
	end
	model.Parent = character
end

local function saveEquipped(player: Player)
	local store = skinStore
	if not store then
		return
	end
	local value = equipped[player] or ""
	task.spawn(function()
		pcall(function()
			store:SetAsync(`skin_{player.UserId}`, value)
		end)
	end)
end

-- Lista para la tienda del cliente
local function list(player: Player)
	local skins = {}
	for _, skin in monetization.Skins do
		table.insert(skins, { Id = skin.Id, PassId = skinPassId(skin), Owned = StoreService.ownsSkin(player, skin.Id) })
	end
	local passes = {}
	for key, pass in monetization.Passes do
		passes[key] = { Id = pass.Id, Owned = StoreService.hasPass(player, key) }
	end
	return { Skins = skins, Passes = passes, Equipped = equipped[player] or "" }
end

function StoreService.onPassBought(listener: (Player, number) -> ())
	table.insert(passListeners, listener)
end

function StoreService.init()
	local remote = Instance.new("RemoteFunction")
	remote.Name = "StoreAction"
	remote.Parent = ReplicatedStorage
	remote.OnServerInvoke = function(player: Player, action: any, id: any)
		if action == "List" then
			return list(player)
		elseif action == "Equip" and type(id) == "string" then
			if id ~= "" and not StoreService.ownsSkin(player, id) then
				return false
			end
			equipped[player] = if id == "" then nil else id
			applySkin(player)
			saveEquipped(player)
			return true
		end
		return nil
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local cache = owned[player]
		if cache then
			cache[passId] = true
		end
		-- Si era una skin, se la pone de una vez
		for _, skin in monetization.Skins do
			if skinPassId(skin) == passId then
				equipped[player] = skin.Id
				applySkin(player)
				saveEquipped(player)
				break
			end
		end
		for _, listener in passListeners do
			task.spawn(listener, player, passId)
		end
	end)

	local function onPlayerAdded(player: Player)
		-- Pregunta los pases de una vez (después se usan sin esperar)
		for key in monetization.Passes do
			task.spawn(StoreService.hasPass, player, key)
		end
		local store = skinStore
		if store then
			local ok, value = pcall(function()
				return store:GetAsync(`skin_{player.UserId}`)
			end)
			if ok and type(value) == "string" and value ~= "" then
				equipped[player] = value
			end
		end
		player.CharacterAdded:Connect(function(character)
			if not character:WaitForChild("UpperTorso", 3) then
				character:WaitForChild("Torso", 3)
			end
			applySkin(player)
		end)
		if player.Character then
			applySkin(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
		equipped[player] = nil
	end)
end

return StoreService
