-- Saca casas, árboles y adornos de la plantilla oficial "Studio Tour" de
-- Roblox (guardada como .rbxl) y los guarda en src/models como Feria<Nombre>.
-- También copia los materiales propios de la plantilla (yeso, tejas, piedra)
-- a src/materials, porque las casas los usan.
-- Uso: lune run tools/extract_feria.luau ruta/a/FERIA.rbxl
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local path = process.args[1]
assert(path, "Falta la ruta del .rbxl")
local game = roblox.deserializePlace(fs.readFile(path))

-- Nombre en la plantilla → nombre en el juego
local WANTED = {
	OB_Building_A = "FeriaHouseA",
	OB_Building_B = "FeriaHouseB",
	OB_Tree_a = "FeriaTree",
	OB_Bush_a = "FeriaBush",
	OB_Flowers_a = "FeriaFlowersA",
	OB_Flowers_b = "FeriaFlowersB",
	OB_Flowers_c = "FeriaFlowersC",
	OB_Fence_15_a = "FeriaFence",
	OB_Lantern_a = "FeriaLantern",
	OB_Well_a = "FeriaWell",
	OB_Barrel_a = "FeriaBarrel",
	OB_Crate_a = "FeriaCrate",
	OB_Wheelbarrow_a = "FeriaWheelbarrow",
	OB_Flowerbox = "FeriaFlowerbox",
}

-- Un modelo "simple": sin otros modelos adentro (algunos árboles traen ramas extra)
local function isSimple(model): boolean
	for _, child in model:GetChildren() do
		if child:IsA("Model") and model.Name == "OB_Tree_a" then
			return false
		end
	end
	return true
end

local saved = {}
for _, model in game:GetService("Workspace"):GetDescendants() do
	local name = model:IsA("Model") and WANTED[model.Name]
	if name and not saved[name] and isSimple(model) then
		local copy = model:Clone()
		-- Seguridad: nada de scripts, y sin luces ni sonidos que no pedimos
		for _, descendant in copy:GetDescendants() do
			if descendant:IsA("LuaSourceContainer") or descendant:IsA("TouchTransmitter") or descendant:IsA("Humanoid") or descendant:IsA("Sound") then
				descendant:Destroy()
			end
		end
		copy.Name = name
		local parts = 0
		for _, descendant in copy:GetDescendants() do
			if descendant:IsA("BasePart") then
				parts += 1
			end
		end
		fs.writeFile(`src/models/{name}.rbxm`, roblox.serializeModel({ copy }))
		saved[name] = true
		print(`{name}: {parts} piezas`)
	end
end
for original, name in WANTED do
	if not saved[name] then
		print(`No se encontró {original}`)
	end
end

-- Materiales de la plantilla que usan las casas y el pozo
local MATERIALS = { Plaster_A = true, ScaleShingles = true, StoneWall = true, Cobblestone_a = true }
for _, variant in game:GetService("MaterialService"):GetChildren() do
	if variant:IsA("MaterialVariant") and MATERIALS[variant.Name] then
		fs.writeFile(`src/materials/{variant.Name}.rbxm`, roblox.serializeModel({ variant }))
		print(`Material {variant.Name} ({variant.BaseMaterial.Name})`)
	end
end
