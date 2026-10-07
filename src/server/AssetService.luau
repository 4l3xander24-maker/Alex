-- Aplica las imágenes subidas (src/shared/Assets.luau):
--   * Convierte cada id a id de imagen: si subiste un Decal, Roblox guarda la
--     imagen con otro id; InsertService nos da el correcto.
--   * Texturas pixeladas: crea un MaterialVariant por textura y lo pone en
--     lugar del material de Roblox en todo el mapa y el terreno.
--   * Publica los ids en ReplicatedStorage.ResolvedAssets para los clientes
--     (sprites de zombis y NPC).
-- Si Assets.luau está vacío no hace nada y el juego se ve con los modelos 3D.
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Assets)
local Config = require(ReplicatedStorage.Shared.Config)

local AssetService = {}

-- Qué material de Roblox reemplaza cada textura, y cada cuántos studs se repite
local TEXTURE_MATERIALS: { [string]: { Material: Enum.Material, Studs: number } } = {
	Grass = { Material = Enum.Material.Grass, Studs = 8 },
	Dirt = { Material = Enum.Material.Ground, Studs = 6 },
	Mud = { Material = Enum.Material.Mud, Studs = 8 },
	Cobblestone = { Material = Enum.Material.Cobblestone, Studs = 8 },
	StoneBricks = { Material = Enum.Material.Slate, Studs = 8 },
	Planks = { Material = Enum.Material.WoodPlanks, Studs = 6 },
	Bark = { Material = Enum.Material.Wood, Studs = 4 },
	Leaves = { Material = Enum.Material.LeafyGrass, Studs = 6 },
	Roof = { Material = Enum.Material.ClayRoofTiles, Studs = 6 },
	Plaster = { Material = Enum.Material.Plaster, Studs = 8 },
	Rock = { Material = Enum.Material.Rock, Studs = 12 },
	Sand = { Material = Enum.Material.Sand, Studs = 8 },
	Fabric = { Material = Enum.Material.Fabric, Studs = 3 },
}

local folder = Instance.new("Folder")
folder.Name = "ResolvedAssets"
folder.Parent = ReplicatedStorage

local cache: { [string]: string } = {}

-- Id de imagen listo para usar ("" si no hay)
function AssetService.resolve(id: string): string
	if id == "" then
		return ""
	end
	if cache[id] then
		return cache[id]
	end
	local number = tonumber(string.match(id, "%d+"))
	local resolved = id
	if number then
		-- Si es un Decal, adentro trae la imagen; si ya es imagen, LoadAsset falla y usamos el id tal cual
		local ok, model = pcall(function()
			return InsertService:LoadAsset(number)
		end)
		if ok and model then
			local decal = model:FindFirstChildWhichIsA("Decal", true)
			if decal and decal.Texture ~= "" then
				resolved = decal.Texture
			end
			model:Destroy()
		end
	end
	cache[id] = resolved
	return resolved
end

local function publish(key: string, id: string)
	local resolved = AssetService.resolve(id)
	if resolved ~= "" then
		folder:SetAttribute(key, resolved)
	end
end

local function setupTextures()
	for name, info in TEXTURE_MATERIALS do
		local id = AssetService.resolve(Assets.Textures[name] or "")
		if id ~= "" then
			local variant = Instance.new("MaterialVariant")
			variant.Name = "Pixel" .. name
			variant.BaseMaterial = info.Material
			variant.ColorMap = id
			variant.StudsPerTile = info.Studs
			variant.MaterialPattern = Enum.MaterialPattern.Regular
			variant.Parent = MaterialService
			-- Todas las piezas y el terreno con este material usan la textura pixelada
			MaterialService:SetBaseMaterialOverride(info.Material, variant.Name)
		end
	end
end

local function setupSky()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		return
	end
	local moon = AssetService.resolve(if Config.SkyTextures.Moon ~= "" then Config.SkyTextures.Moon else Assets.Sky.Moon)
	local sun = AssetService.resolve(if Config.SkyTextures.Sun ~= "" then Config.SkyTextures.Sun else Assets.Sky.Sun)
	if moon ~= "" then
		sky.MoonTextureId = moon
	end
	-- Los clientes cambian a la luna de sangre en las oleadas altas (SkyFx)
	publish("Sky.Moon", if moon ~= "" then moon else sky.MoonTextureId)
	publish("Sky.MoonRed", Assets.Sky.MoonRed or "")
	if sun ~= "" then
		sky.SunTextureId = sun
	end
end

-- NPC con sprite: se esconde el muñeco de bloques y se muestra la imagen
-- pixelada, siempre mirando a la cámara y sin suavizado
local function applyNpcSprites()
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end
	for _, model in map:GetDescendants() do
		local key = model:GetAttribute("SpriteKey")
		if not (model:IsA("Model") and type(key) == "string") then
			continue
		end
		local image = folder:GetAttribute(`NPC.{key}`)
		local torso = model.PrimaryPart
		if type(image) ~= "string" or not torso then
			continue
		end
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Transparency = 1
			end
		end
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "PixelSprite"
		billboard.Size = UDim2.fromScale(4.4, 6.2) -- en studs
		billboard.StudsOffset = Vector3.new(0, 0.1, 0)
		billboard.LightInfluence = 1
		billboard.MaxDistance = 250
		billboard.Adornee = torso
		billboard.Parent = model
		local label = Instance.new("ImageLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Image = image
		label.ResampleMode = Enum.ResamplerMode.Pixelated
		label.Parent = billboard
	end
end

-- Corre en segundo plano: LoadAsset espera a la red
function AssetService.init()
	task.spawn(function()
		if Config.Style.PixelTextures then
			setupTextures()
		end
		setupSky()
		for name, frames in Assets.Sprites do
			publish(`Sprite.{name}.1`, frames[1])
			publish(`Sprite.{name}.2`, frames[2])
		end
		for name, id in Assets.NPC do
			publish(`NPC.{name}`, id)
		end
		applyNpcSprites()
		folder:SetAttribute("Ready", true)
	end)
end

return AssetService
