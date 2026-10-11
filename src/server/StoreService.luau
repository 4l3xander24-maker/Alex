-- Pases (Game Passes) y skins. Lo usan el Lobby y la partida:
--   * Sabe qué pases tiene cada jugador (pregunta a Roblox una vez y se
--     actualiza cuando compra uno).
--   * Skins: se consiguen con un pase (Robux), con monedas o con las dos
--     formas. Las compradas con monedas y la elegida se guardan en un
--     DataStore aparte que comparten los dos lugares. Se ponen al personaje:
--     capa, borde, cuello, hombreras, sombrero y brillo.
--   * StoreAction (RemoteFunction): "List" para la tienda, "Equip" y
--     "BuyCoins" (solo en la partida, que es donde están las monedas).
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local monetization = Config.Monetization
local SKIN_STORE = "CampanaMaldita_Skins_v1"

local StoreService = {}

type SkinInfo = typeof(monetization.Skins[1])
-- Lo que se guarda de cada jugador
type SkinSave = { Equipped: string, Owned: { [string]: boolean } }

local skinById: { [string]: SkinInfo } = {}
for _, skin in monetization.Skins do
	skinById[skin.Id] = skin
end

local owned: { [Player]: { [number]: boolean } } = {}
local saves: { [Player]: SkinSave } = {}
local passListeners: { (Player, number) -> () } = {}
-- La partida lo cambia para cobrar en monedas; en el Lobby no hay monedas
local spendCoins: ((Player, number) -> boolean)? = nil
local refundCoins: ((Player, number) -> ())? = nil

local skinStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(SKIN_STORE)
	end)
	if ok then
		skinStore = result
	end
end

local function keyFor(player: Player): string
	return `skin_{player.UserId}`
end

local function saveOf(player: Player): SkinSave
	local save = saves[player]
	if not save then
		save = { Equipped = "", Owned = {} }
		saves[player] = save
	end
	return save
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

-- key: "StarterPack", "DoubleCoins" o "Vip"
function StoreService.hasPass(player: Player, key: string): boolean
	return StoreService.ownsPassId(player, passIdOf(key))
end

local function skinPassId(skin: SkinInfo): number
	local info = skin :: any
	return if info.Pass then passIdOf(info.Pass) else info.PassId or 0
end

function StoreService.ownsSkin(player: Player, skinId: string): boolean
	local skin = skinById[skinId]
	if not skin then
		return false
	end
	return saveOf(player).Owned[skinId] == true or StoreService.ownsPassId(player, skinPassId(skin))
end

type PieceMaker = (BasePart, string, Vector3, CFrame, Color3, Enum.Material, Enum.PartType?) -> BasePart

-- Sombrero sobre la cabeza
local function buildHat(kind: string, head: BasePart, info: any, piece: PieceMaker)
	local size = head.Size
	local w = math.min(size.X, size.Z * 1.2)
	local h = size.Y
	local top = h / 2
	if kind == "Hood" then
		piece(head, "HoodTop", Vector3.new(w + 0.3, 0.22, w + 0.3), CFrame.new(0, top + 0.08, 0.05), info.Cape, Enum.Material.Fabric)
		piece(head, "HoodBack", Vector3.new(w + 0.3, h + 0.2, 0.2), CFrame.new(0, 0, w / 2 + 0.12), info.Cape, Enum.Material.Fabric)
		for _, side in { -1, 1 } do
			piece(head, "HoodSide", Vector3.new(0.18, h + 0.1, w + 0.2), CFrame.new(side * (w / 2 + 0.12), 0, 0.08), info.Cape, Enum.Material.Fabric)
		end
	elseif kind == "Crown" then
		piece(head, "CrownBand", Vector3.new(0.3, w + 0.15, w + 0.15), CFrame.new(0, top + 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2), info.Trim, Enum.Material.Metal, Enum.PartType.Cylinder)
		for index = 0, 4 do
			local angle = index / 5 * math.pi * 2
			local spike = piece(head, "CrownSpike", Vector3.new(0.2, 0.45, 0.2), CFrame.new(math.cos(angle) * w / 2, top + 0.45, math.sin(angle) * w / 2), info.Trim, Enum.Material.Metal)
			if info.Glow then
				spike.Material = Enum.Material.Neon
			end
		end
	elseif kind == "Horns" then
		for _, side in { -1, 1 } do
			piece(head, "HornBase", Vector3.new(0.3, 0.6, 0.3), CFrame.new(side * w * 0.38, top + 0.15, 0) * CFrame.Angles(0, 0, math.rad(side * -35)), info.Cape, Enum.Material.SmoothPlastic)
			piece(head, "HornTip", Vector3.new(0.2, 0.55, 0.2), CFrame.new(side * w * 0.62, top + 0.55, 0) * CFrame.Angles(0, 0, math.rad(side * 10)), info.Trim, Enum.Material.Neon)
		end
	elseif kind == "Helmet" then
		piece(head, "HelmetCap", Vector3.new(w + 0.22, h * 0.55, w + 0.22), CFrame.new(0, top - h * 0.2, 0.02), info.Trim, Enum.Material.Metal)
		piece(head, "HelmetCrest", Vector3.new(0.16, 0.35, w + 0.1), CFrame.new(0, top + 0.2, 0), info.Cape, Enum.Material.Fabric)
		piece(head, "NoseGuard", Vector3.new(0.14, 0.5, 0.1), CFrame.new(0, 0, -(w / 2 + 0.12)), info.Trim, Enum.Material.Metal)
	elseif kind == "Brim" then
		piece(head, "HatBrim", Vector3.new(0.12, w * 1.9, w * 1.9), CFrame.new(0, top + 0.02, 0) * CFrame.Angles(0, 0, math.pi / 2), info.Cape, Enum.Material.Fabric, Enum.PartType.Cylinder)
		piece(head, "HatCrown", Vector3.new(0.6, w * 0.95, w * 0.95), CFrame.new(0, top + 0.32, 0) * CFrame.Angles(0, 0, math.pi / 2), info.Cape, Enum.Material.Fabric, Enum.PartType.Cylinder)
		piece(head, "HatBand", Vector3.new(0.14, w * 0.97, w * 0.97), CFrame.new(0, top + 0.12, 0) * CFrame.Angles(0, 0, math.pi / 2), info.Trim, Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
end

-- Quita la skin que tenga y le pone la elegida (si la tiene)
local function applySkin(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local old = character:FindFirstChild("Skin")
	if old then
		old:Destroy()
	end
	local skinId = saveOf(player).Equipped
	local skin = skinById[skinId]
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
	local function piece(base: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = shape or Enum.PartType.Block
		part.Size = size
		part.CFrame = base.CFrame * offset
		part.Color = color
		part.Material = material
		part.Massless = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = base
		weld.Part1 = part
		weld.Parent = part
		part.Parent = model
		return part
	end
	local top = torso.Size.Y / 2
	local back = torso.Size.Z / 2
	local width = torso.Size.X
	-- Capa: cuelga de los hombros por la espalda, un poco abierta abajo
	local capeHeight = top * 2 + 2
	piece(torso, "Cape", Vector3.new(width * 1.05, capeHeight, 0.12), CFrame.new(0, top - capeHeight / 2, back + 0.12) * CFrame.Angles(math.rad(-6), 0, 0), info.Cape, Enum.Material.Fabric)
	local trim = piece(torso, "CapeTrim", Vector3.new(width * 1.07, 0.25, 0.14), CFrame.new(0, top - capeHeight + 0.1, back + 0.22) * CFrame.Angles(math.rad(-6), 0, 0), info.Trim, Enum.Material.Fabric)
	piece(torso, "Collar", Vector3.new(width * 1.1, 0.3, torso.Size.Z + 0.2), CFrame.new(0, top + 0.05, 0.05), info.Trim, Enum.Material.Metal)
	if info.Armor then
		for _, side in { -1, 1 } do
			piece(torso, "Pauldron", Vector3.new(1.1, 0.6, 1.2), CFrame.new(side * (width / 2 + 0.35), top - 0.05, 0) * CFrame.Angles(0, 0, math.rad(side * -18)), info.Trim, Enum.Material.Metal)
		end
	end
	local head = character:FindFirstChild("Head") :: BasePart?
	if info.Hat and head then
		buildHat(info.Hat, head, info, piece)
	end
	if info.Glow then
		trim.Material = Enum.Material.Neon
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Rate = 6
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Speed = NumberRange.new(0.5, 1.2)
		sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		sparkles.Color = ColorSequence.new(info.Trim)
		sparkles.LightEmission = 1
		sparkles.Parent = trim
	end
	model.Parent = character
end

-- Guarda skins compradas con monedas y la elegida. Devuelve si se pudo.
local function persist(player: Player): boolean
	local store = skinStore
	if not store then
		return false
	end
	local save = saveOf(player)
	local ok = pcall(function()
		store:SetAsync(keyFor(player), { Equipped = save.Equipped, Owned = save.Owned }, { player.UserId })
	end)
	return ok
end

local function equip(player: Player, skinId: string)
	saveOf(player).Equipped = skinId
	applySkin(player)
	task.spawn(persist, player)
end

-- Compra con monedas (solo en la partida)
local function buyWithCoins(player: Player, skinId: string): (boolean, string)
	local skin = skinById[skinId] :: any
	if not skin or not skin.CoinPrice then
		return false, "Esa skin no se vende con monedas"
	end
	if StoreService.ownsSkin(player, skinId) then
		return false, "Ya la tienes"
	end
	local spend, refund = spendCoins, refundCoins
	if not spend or not refund then
		return false, "Con monedas se compra dentro de la partida (tienda 🛒 o tecla B)"
	end
	if not spend(player, skin.CoinPrice) then
		return false, `Te faltan monedas: cuesta {skin.CoinPrice}`
	end
	local save = saveOf(player)
	save.Owned[skinId] = true
	save.Equipped = skinId
	if not persist(player) and skinStore then
		-- No se pudo guardar: se devuelve todo para no perder las monedas
		save.Owned[skinId] = nil
		refund(player, skin.CoinPrice)
		return false, "No se pudo guardar la compra, intenta de nuevo"
	end
	applySkin(player)
	return true, `¡{skin.Name} es tuya!`
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
	return { Skins = skins, Passes = passes, Equipped = saveOf(player).Equipped, CanUseCoins = spendCoins ~= nil }
end

function StoreService.onPassBought(listener: (Player, number) -> ())
	table.insert(passListeners, listener)
end

-- La partida conecta su billetera para vender skins con monedas
function StoreService.setCoinWallet(spend: (Player, number) -> boolean, refund: (Player, number) -> ())
	spendCoins = spend
	refundCoins = refund
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
			equip(player, id)
			return true
		elseif action == "BuyCoins" and type(id) == "string" then
			return buyWithCoins(player, id)
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
		-- Si traía una skin, se la pone de una vez
		for _, skin in monetization.Skins do
			if skinPassId(skin) == passId then
				equip(player, skin.Id)
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
				return store:GetAsync(keyFor(player))
			end)
			if ok and type(value) == "table" then
				local save = saveOf(player)
				save.Equipped = if type(value.Equipped) == "string" then value.Equipped else ""
				if type(value.Owned) == "table" then
					for skinId, has in value.Owned do
						if skinById[skinId] and has == true then
							save.Owned[skinId] = true
						end
					end
				end
			elseif ok and type(value) == "string" then
				saveOf(player).Equipped = value -- formato viejo: solo la elegida
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
		saves[player] = nil
	end)
end

return StoreService
