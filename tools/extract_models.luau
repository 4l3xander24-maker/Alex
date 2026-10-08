-- Saca los modelos de ServerStorage.ImportedModels de un archivo .rbxl y los
-- guarda en src/models/<Nombre>.rbxm (Rojo los pone en ServerStorage.Models).
-- Uso: lune run tools/extract_models.luau ruta/al/lugar.rbxl
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local path = process.args[1]
assert(path, "Falta la ruta del .rbxl")
local game = roblox.deserializePlace(fs.readFile(path))
local folder = game:GetService("ServerStorage"):FindFirstChild("ImportedModels")
assert(folder, "No hay ServerStorage.ImportedModels en el lugar")

for _, model in folder:GetChildren() do
	-- Seguridad: ningún script de modelos de terceros entra al juego
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end
	local parts = 0
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			parts += 1
		end
	end
	fs.writeFile(`src/models/{model.Name}.rbxm`, roblox.serializeModel({ model }))
	print(`{model.Name}: {parts} piezas`)
end
