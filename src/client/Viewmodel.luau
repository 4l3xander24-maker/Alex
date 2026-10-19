-- El arma y las manos que se ven en primera persona. Son piezas locales
-- pegadas a la cámara, con retroceso, balanceo al caminar, animación de
-- recarga, tajo del cuchillo y posición de apuntar. Cada arma tiene su propio
-- modelo de bloques, y cambia de color con cada mejora (Config.WeaponTiers).
-- El cuchillo se agarra como en Guns 'n Goblins: un guante grande de cuero
-- con tachas, el mango hacia abajo a la izquierda y la hoja hacia la derecha.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local player = Players.LocalPlayer

local GUNMETAL = Color3.fromRGB(48, 48, 54)
local STEEL = Color3.fromRGB(125, 128, 138)
local DARK = Color3.fromRGB(28, 28, 32)
local WOOD = Color3.fromRGB(150, 95, 50)
local OLIVE = Color3.fromRGB(90, 100, 60)
local SKIN = Color3.fromRGB(150, 105, 80)
local FLASH = Color3.fromRGB(255, 210, 90)
local LENS = Color3.fromRGB(120, 200, 255)
-- Hoja del cuchillo: un tono claro del color de mejora
local BLADE = Color3.fromRGB(200, 202, 206)
local EDGE = Color3.fromRGB(236, 240, 244)
local GLOVE = Color3.fromRGB(122, 86, 86)
local GLOVE_DARK = Color3.fromRGB(92, 62, 64)
local STUD = Color3.fromRGB(236, 234, 222)
local HANDLE = Color3.fromRGB(62, 42, 30)
local POMMEL = Color3.fromRGB(150, 152, 158)

local SWING_TIME = 0.28
local EQUIP_TIME = 0.38 -- el arma nueva sube desde abajo de la pantalla

local HIP_OFFSET = CFrame.new(1.05, -0.92, -2.1)
local AIM_OFFSET = CFrame.new(0, -0.55, -1.7)
local BASE_FOV = 80

type PieceSpec = { Size: Vector3, Offset: CFrame, Color: Color3, Neon: boolean?, Shape: Enum.PartType?, Material: Enum.Material? }
-- Arm reemplaza la mano derecha de siempre; sin LeftHand no hay mano izquierda;
-- Hip cambia dónde se ve el arma en la pantalla
type ModelSpec = { Pieces: { PieceSpec }, Muzzle: CFrame, LeftHand: Vector3?, Arm: { PieceSpec }?, Hip: CFrame? }

local function p(size: Vector3, offset: CFrame, color: Color3, neon: boolean?): PieceSpec
	return { Size = size, Offset = offset, Color = color, Neon = neon }
end

-- Piezas relativas al centro del arma (el cañón apunta hacia -Z).
-- Las piezas GUNMETAL y STEEL toman los colores del nivel de mejora.
local MODELS: { [string]: ModelSpec } = {
	Machete = (function(): ModelSpec
		-- Todo relativo al puño. `knife` apunta la hoja hacia la derecha y un poco
		-- adelante, con la punta levantada.
		local knife = CFrame.Angles(0, 0.25, 0) * CFrame.Angles(0, 0, 0.1)
		local forearm = CFrame.new(0.6, -0.55, 1.15) * CFrame.Angles(0.45, -0.5, 0)
		local fist = CFrame.Angles(0, 0, 0.25)
		local pieces = {
			-- Mango, pomo, guarda
			p(Vector3.new(1.1, 0.26, 0.26), knife * CFrame.new(-0.45, 0, 0), HANDLE),
			p(Vector3.new(0.32, 0.34, 0.34), knife * CFrame.new(-1.05, 0, 0), POMMEL),
			p(Vector3.new(0.2, 0.75, 0.36), knife * CFrame.new(0.5, 0, 0), GUNMETAL),
			-- Hoja ancha de cuchillo grande, con el lomo y el filo de otro tono
			p(Vector3.new(2.9, 0.62, 0.07), knife * CFrame.new(2.05, 0.05, 0), BLADE),
			p(Vector3.new(2.9, 0.12, 0.08), knife * CFrame.new(2.05, 0.34, 0), STEEL),
			p(Vector3.new(2.6, 0.1, 0.08), knife * CFrame.new(2.0, -0.22, 0), EDGE),
			p(Vector3.new(0.75, 0.46, 0.07), knife * CFrame.new(3.6, 0.13, 0) * CFrame.Angles(0, 0, 0.5), BLADE),
			p(Vector3.new(0.26, 0.18, 0.08), knife * CFrame.new(0.78, -0.21, 0), DARK),
		}
		local arm = {
			-- Puño de cuero con nudillos y pulgar
			p(Vector3.new(0.82, 0.78, 0.78), fist, GLOVE),
			p(Vector3.new(0.84, 0.26, 0.34), fist * CFrame.new(0, 0.3, -0.26), GLOVE_DARK),
			p(Vector3.new(0.32, 0.32, 0.5), fist * CFrame.new(-0.38, 0.22, -0.08), GLOVE),
			-- Antebrazo con el puño de la manga, hacia abajo a la derecha
			p(Vector3.new(0.78, 0.78, 2.3), forearm, GLOVE),
			p(Vector3.new(0.98, 0.98, 0.6), forearm * CFrame.new(0, 0, 1.0), GLOVE_DARK),
		}
		-- Tachas blancas sobre el guante
		for _, spot in { Vector3.new(-0.2, 0.4, 0.15), Vector3.new(0.2, 0.4, 0.15) } do
			table.insert(arm, p(Vector3.new(0.16, 0.05, 0.16), fist * CFrame.new(spot), STUD))
		end
		for _, z in { -0.7, 0, 0.7 } do
			for _, x in { -0.2, 0.2 } do
				table.insert(arm, p(Vector3.new(0.16, 0.05, 0.16), forearm * CFrame.new(x, 0.41, z), STUD))
			end
			table.insert(arm, p(Vector3.new(0.05, 0.16, 0.16), forearm * CFrame.new(0.41, 0, z), STUD))
		end
		return {
			Muzzle = knife * CFrame.new(3.8, 0, 0),
			Hip = CFrame.new(0.45, -1.4, -2.6),
			Arm = arm,
			Pieces = pieces,
		}
	end)(),
	Pistol = {
		Muzzle = CFrame.new(0, 0.1, -1.3),
		LeftHand = Vector3.new(-0.12, -0.32, 0.05),
		Pieces = {
			p(Vector3.new(0.34, 0.36, 1.5), CFrame.new(0, 0, 0), GUNMETAL),
			p(Vector3.new(0.36, 0.14, 1.45), CFrame.new(0, 0.24, -0.02), STEEL),
			p(Vector3.new(0.37, 0.15, 0.06), CFrame.new(0, 0.24, 0.4), DARK),
			p(Vector3.new(0.37, 0.15, 0.06), CFrame.new(0, 0.24, 0.52), DARK),
			p(Vector3.new(0.18, 0.18, 0.5), CFrame.new(0, 0.1, -0.95), GUNMETAL),
			p(Vector3.new(0.07, 0.12, 0.07), CFrame.new(0, 0.37, -0.62), DARK),
			p(Vector3.new(0.24, 0.12, 0.07), CFrame.new(0, 0.37, 0.62), DARK),
			p(Vector3.new(0.3, 0.7, 0.36), CFrame.new(0, -0.42, 0.42) * CFrame.Angles(-0.25, 0, 0), WOOD),
			p(Vector3.new(0.06, 0.22, 0.35), CFrame.new(0, -0.26, 0.05), DARK),
		},
	},
	Shotgun = {
		Muzzle = CFrame.new(0, 0.1, -2.55),
		LeftHand = Vector3.new(-0.05, -0.34, -1.0),
		Pieces = {
			p(Vector3.new(0.34, 0.4, 1.0), CFrame.new(0, 0, 0.3), GUNMETAL),
			p(Vector3.new(0.2, 0.2, 2.4), CFrame.new(0, 0.1, -1.3), DARK),
			p(Vector3.new(0.16, 0.16, 1.9), CFrame.new(0, -0.12, -1.05), GUNMETAL),
			p(Vector3.new(0.32, 0.3, 0.8), CFrame.new(0, -0.12, -1.0), WOOD),
			p(Vector3.new(0.3, 0.5, 1.3), CFrame.new(0, -0.22, 1.3) * CFrame.Angles(-0.18, 0, 0), WOOD),
			p(Vector3.new(0.06, 0.08, 0.06), CFrame.new(0, 0.24, -2.45), STEEL),
			p(Vector3.new(0.3, 0.6, 0.34), CFrame.new(0, -0.45, 0.6) * CFrame.Angles(-0.3, 0, 0), WOOD),
		},
	},
	Rifle = {
		Muzzle = CFrame.new(0, 0.05, -2.3),
		LeftHand = Vector3.new(-0.05, -0.32, -1.05),
		Pieces = {
			p(Vector3.new(0.32, 0.42, 1.7), CFrame.new(0, 0, 0.1), GUNMETAL),
			p(Vector3.new(0.36, 0.34, 0.9), CFrame.new(0, 0.02, -1.1), DARK),
			p(Vector3.new(0.12, 0.12, 0.7), CFrame.new(0, 0.05, -1.9), DARK),
			p(Vector3.new(0.24, 0.8, 0.36), CFrame.new(0, -0.55, -0.35) * CFrame.Angles(0.25, 0, 0), DARK),
			p(Vector3.new(0.3, 0.5, 1.1), CFrame.new(0, -0.1, 1.4), GUNMETAL),
			p(Vector3.new(0.14, 0.18, 0.5), CFrame.new(0, 0.32, -0.1), DARK),
			p(Vector3.new(0.2, 0.06, 1.2), CFrame.new(0, 0.24, -0.4), STEEL),
			p(Vector3.new(0.28, 0.65, 0.34), CFrame.new(0, -0.45, 0.55) * CFrame.Angles(-0.3, 0, 0), DARK),
		},
	},
	Sniper = {
		Muzzle = CFrame.new(0, 0.08, -2.75),
		LeftHand = Vector3.new(-0.05, -0.3, -0.8),
		Pieces = {
			p(Vector3.new(0.3, 0.36, 1.8), CFrame.new(0, 0, 0.2), WOOD),
			p(Vector3.new(0.12, 0.12, 2.0), CFrame.new(0, 0.08, -1.7), DARK),
			p(Vector3.new(0.26, 0.26, 1.3), CFrame.new(0, 0.42, -0.1), DARK),
			p(Vector3.new(0.2, 0.2, 0.05), CFrame.new(0, 0.42, -0.76), LENS, true),
			p(Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.25, -0.5), DARK),
			p(Vector3.new(0.1, 0.2, 0.1), CFrame.new(0, 0.25, 0.3), DARK),
			p(Vector3.new(0.3, 0.08, 0.08), CFrame.new(0.22, 0.1, 0.5), STEEL),
			p(Vector3.new(0.3, 0.55, 1.2), CFrame.new(0, -0.15, 1.5), WOOD),
			p(Vector3.new(0.28, 0.6, 0.34), CFrame.new(0, -0.42, 0.6) * CFrame.Angles(-0.3, 0, 0), WOOD),
		},
	},
	Minigun = {
		Muzzle = CFrame.new(0, -0.03, -2.4),
		LeftHand = Vector3.new(0, 0.62, 0.1),
		Pieces = {
			p(Vector3.new(0.6, 0.6, 1.3), CFrame.new(0, -0.05, 0.2), GUNMETAL),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(-0.14, 0.05, -1.4), DARK),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(0.14, 0.05, -1.4), DARK),
			p(Vector3.new(0.14, 0.14, 1.9), CFrame.new(0, -0.17, -1.4), DARK),
			p(Vector3.new(0.5, 0.5, 0.15), CFrame.new(0, -0.03, -2.2), STEEL),
			p(Vector3.new(0.5, 0.5, 0.15), CFrame.new(0, -0.03, -0.9), STEEL),
			p(Vector3.new(0.12, 0.3, 0.7), CFrame.new(0, 0.4, 0.1), DARK),
			p(Vector3.new(0.5, 0.55, 0.6), CFrame.new(-0.55, -0.25, 0.3), OLIVE),
			p(Vector3.new(0.3, 0.6, 0.34), CFrame.new(0, -0.55, 0.6) * CFrame.Angles(-0.3, 0, 0), DARK),
		},
	},
}

-- Mallas de la Creator Store (src/weapons → ReplicatedStorage.WeaponModels)
-- en lugar de las piezas de bloques. Todas vienen con el cañón a lo largo de Z.
-- Length: largo en studs; Center: dónde va el centro de la malla (mismo
-- espacio que las piezas de arriba); Turn: giro para que el cañón apunte a -Z
-- y quede parada (las del paquete de mosquetes vienen acostadas y al revés).
local MESH_WEAPONS = Config.UseStoreModels and not Config.Style.Blocky
local MUSKET_TURN = CFrame.Angles(0, math.pi, 0) * CFrame.Angles(0, 0, math.pi / 2)
local MESHES: { [string]: { Length: number, Center: CFrame, Turn: CFrame? } } = {
	Pistol = { Length = 2.3, Center = CFrame.new(0, -0.05, -0.7), Turn = MUSKET_TURN },
	Shotgun = { Length = 4.2, Center = CFrame.new(0, -0.05, -0.9), Turn = MUSKET_TURN },
	Rifle = { Length = 4.9, Center = CFrame.new(0, -0.05, -0.4), Turn = MUSKET_TURN },
	Sniper = { Length = 5.5, Center = CFrame.new(0, 0, -0.4), Turn = CFrame.Angles(0, math.pi, 0) },
	Minigun = { Length = 3, Center = CFrame.new(0.1, -0.45, -0.9), Turn = CFrame.Angles(0, math.pi, 0) },
	-- El alfanje sigue la hoja del cuchillo (hacia la derecha y un poco adelante)
	Machete = { Length = 3.8, Center = CFrame.Angles(0, 0.25, 0) * CFrame.Angles(0, 0, 0.1) * CFrame.new(1.3, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0), Turn = CFrame.Angles(0, math.pi, 0) },
}

-- Manos realistas: dedos con tres falanges que rodean el mango (derecha) y el
-- guardamanos (izquierda), pulgar, palma, muñeca, puño de cuero y manga. Se
-- arman con cilindros entre puntos; el tono de piel es el del personaje.
local CUFF = Color3.fromRGB(110, 84, 56)
local SLEEVE_CLOTH = Color3.fromRGB(78, 64, 50)
local handTone = SKIN

local function characterTone(): Color3
	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or character:FindFirstChild("Head"))
	return if hand and hand:IsA("BasePart") then hand.Color else SKIN
end

-- Cilindro entre dos puntos (los cilindros de Roblox van a lo largo de X)
local function link(a: Vector3, b: Vector3, thick: number, color: Color3, material: Enum.Material?): PieceSpec
	local direction = b - a
	local up = if math.abs(direction.Unit.Y) > 0.99 then Vector3.xAxis else Vector3.yAxis
	return { Size = Vector3.new(direction.Magnitude, thick, thick), Offset = CFrame.lookAt((a + b) / 2, b, up) * CFrame.Angles(0, math.pi / 2, 0), Color = color, Shape = Enum.PartType.Cylinder, Material = material or Enum.Material.SmoothPlastic }
end

local function ball(at: Vector3, size: number, color: Color3): PieceSpec
	return { Size = Vector3.one * size, Offset = CFrame.new(at), Color = color, Shape = Enum.PartType.Ball, Material = Enum.Material.SmoothPlastic }
end

-- Un dedo (o el pulgar): tramos entre puntos con nudillos redondos
local function chain(list: { PieceSpec }, points: { Vector3 }, thick: number, color: Color3)
	for index = 1, #points - 1 do
		table.insert(list, link(points[index], points[index + 1], thick, color))
	end
	for index = 2, #points - 1 do
		table.insert(list, ball(points[index], thick * 1.08, color))
	end
	table.insert(list, ball(points[#points], thick * 0.95, color))
end

-- Antebrazo: muñeca de piel, puño de cuero y manga de tela hacia la cámara
local function forearm(list: { PieceSpec }, wrist: Vector3, direction: Vector3)
	local d = direction.Unit
	table.insert(list, link(wrist, wrist + d * 0.5, 0.27, handTone))
	table.insert(list, link(wrist + d * 0.5, wrist + d * 0.74, 0.37, CUFF, Enum.Material.Leather))
	table.insert(list, link(wrist + d * 0.74, wrist + d * 3.4, 0.42, SLEEVE_CLOTH, Enum.Material.Fabric))
end

-- Mano derecha sobre el mango. grip: dónde está el centro del mango (el mango es
-- vertical en el eje Y de `grip`, el cañón hacia -Z).
local function realRightHand(grip: CFrame): { PieceSpec }
	local list: { PieceSpec } = {}
	local function at(x: number, y: number, z: number): Vector3
		return grip:PointToWorldSpace(Vector3.new(x, y, z))
	end
	local tone = handTone
	-- Palma y dorso de la mano
	table.insert(list, { Size = Vector3.new(0.15, 0.5, 0.34), Offset = grip * CFrame.new(0.27, 0.02, 0.06), Color = tone, Material = Enum.Material.SmoothPlastic })
	table.insert(list, { Size = Vector3.new(0.22, 0.47, 0.3), Offset = grip * CFrame.new(0.35, 0.03, 0.2) * CFrame.Angles(0, -0.12, 0), Color = tone, Material = Enum.Material.SmoothPlastic })
	-- Cuatro dedos que rodean el mango por delante
	local fingers = { { 0.17, 0.095 }, { 0.06, 0.1 }, { -0.05, 0.095 }, { -0.15, 0.085 } }
	for _, finger in fingers do
		local y = finger[1]
		chain(list, { at(0.24, y, 0.12), at(0.28, y, -0.06), at(0.14, y, -0.24), at(-0.07, y, -0.26), at(-0.2, y, -0.12) }, finger[2], tone)
	end
	-- Pulgar por detrás del mango
	chain(list, { at(0.26, 0.2, 0.2), at(0.02, 0.23, 0.2), at(-0.17, 0.2, 0.08), at(-0.23, 0.2, -0.08) }, 0.115, tone)
	forearm(list, at(0.38, 0.0, 0.32), Vector3.new(0.18, -0.42, 1))
	return list
end

-- Mano izquierda bajo el cañón. barrel: dónde queda el centro del guardamanos.
local function realLeftHand(barrel: Vector3): { PieceSpec }
	local list: { PieceSpec } = {}
	local c = barrel + Vector3.new(0, 0.3, 0)
	local function at(x: number, y: number, z: number): Vector3
		return c + Vector3.new(x, y, z)
	end
	local tone = handTone
	table.insert(list, { Size = Vector3.new(0.2, 0.26, 0.46), Offset = CFrame.new(at(-0.33, -0.13, 0.02)), Color = tone, Material = Enum.Material.SmoothPlastic })
	table.insert(list, { Size = Vector3.new(0.22, 0.22, 0.3), Offset = CFrame.new(at(-0.4, -0.17, 0.22)) * CFrame.Angles(0, 0.2, 0), Color = tone, Material = Enum.Material.SmoothPlastic })
	for _, z in { 0.14, 0.05, -0.04, -0.13 } do
		chain(list, { at(-0.3, -0.04, z), at(-0.24, -0.2, z), at(-0.02, -0.28, z), at(0.2, -0.19, z), at(0.27, 0.0, z) }, 0.09, tone)
	end
	chain(list, { at(-0.34, 0.08, 0.2), at(-0.22, 0.12, 0.05), at(-0.1, 0.13, -0.15), at(-0.04, 0.12, -0.3) }, 0.105, tone)
	forearm(list, at(-0.46, -0.2, 0.32), Vector3.new(-0.4, -0.45, 1))
	return list
end

-- Dónde se agarra cada arma con la mano derecha (centro y inclinación del mango)
local TILT = CFrame.Angles(-0.3, 0, 0)
local GRIPS: { [string]: CFrame } = {
	Pistol = CFrame.new(0, -0.42, 0.42) * CFrame.Angles(-0.25, 0, 0),
	Shotgun = CFrame.new(0, -0.45, 0.6) * TILT,
	Rifle = CFrame.new(0, -0.45, 0.55) * TILT,
	Sniper = CFrame.new(0, -0.4, 0.45) * TILT,
	Minigun = CFrame.new(0, -0.55, 0.6) * TILT,
	Crossbow = CFrame.new(0, -0.45, 0.55) * TILT,
	Flamethrower = CFrame.new(0, -0.45, 0.5) * TILT,
}


-- Armas nuevas, con más detalle: cilindros, metal, madera y lazos entre puntos
local function bolt(from: Vector3, to: Vector3, color: Color3): PieceSpec
	return link(from, to, 0.07, color, Enum.Material.Metal)
end

local WOOD_DARK = Color3.fromRGB(96, 60, 34)
local BRASS = Color3.fromRGB(190, 150, 70)
local RUBBER = Color3.fromRGB(30, 30, 34)

local function crossbowModel(): ModelSpec
	local pieces: { PieceSpec } = {}
	local function add(spec: PieceSpec)
		table.insert(pieces, spec)
	end
	local V = Vector3.new
	local wood = Enum.Material.Wood
	local metal = Enum.Material.Metal
	-- Culata de madera con almohadilla de goma, empuñadura y guardamonte
	add({ Size = V(0.3, 0.38, 1.7), Offset = CFrame.new(0, -0.08, 1.0) * CFrame.Angles(0.05, 0, 0), Color = WOOD, Material = wood })
	add({ Size = V(0.32, 0.58, 0.16), Offset = CFrame.new(0, -0.16, 1.92), Color = RUBBER })
	add({ Size = V(0.28, 0.62, 0.3), Offset = CFrame.new(0, -0.45, 0.55) * CFrame.Angles(-0.3, 0, 0), Color = WOOD_DARK, Material = wood })
	add(link(V(0, -0.2, -0.1), V(0, -0.55, 0.05), 0.05, DARK, metal))
	add(link(V(0, -0.55, 0.05), V(0, -0.52, 0.3), 0.05, DARK, metal))
	add({ Size = V(0.06, 0.24, 0.07), Offset = CFrame.new(0, -0.24, 0.15), Color = STEEL, Material = metal })
	-- Riel de metal con la ranura del virote, y el mecanismo de disparo
	add({ Size = V(0.26, 0.2, 2.5), Offset = CFrame.new(0, 0.14, -0.3), Color = GUNMETAL, Material = metal })
	add({ Size = V(0.1, 0.06, 2.3), Offset = CFrame.new(0, 0.27, -0.3), Color = DARK, Material = metal })
	add({ Size = V(0.34, 0.3, 0.5), Offset = CFrame.new(0, 0.05, 0.45), Color = STEEL, Material = metal })
	-- Arco (prod): bloque central y tres tramos por lado, curvados hacia atrás
	add({ Size = V(0.4, 0.3, 0.4), Offset = CFrame.new(0, 0.16, -1.3), Color = GUNMETAL, Material = metal })
	local tips = {}
	for _, side in { -1, 1 } do
		local p0 = V(side * 0.2, 0.16, -1.3)
		local p1 = V(side * 0.85, 0.16, -1.42)
		local p2 = V(side * 1.4, 0.16, -1.68)
		local p3 = V(side * 1.7, 0.16, -2.05)
		add(link(p0, p1, 0.2, DARK, wood))
		add(link(p1, p2, 0.16, DARK, wood))
		add(link(p2, p3, 0.12, DARK, wood))
		add(ball(p3, 0.16, STEEL))
		tips[side] = p3
	end
	-- Estribo en la punta y cuerda tensada hacia el seguro
	add({ Size = V(0.55, 0.06, 0.06), Offset = CFrame.new(0, 0.14, -1.98), Color = STEEL, Material = metal })
	for _, side in { -1, 1 } do
		add({ Size = V(0.06, 0.3, 0.06), Offset = CFrame.new(side * 0.27, 0.0, -1.98), Color = STEEL, Material = metal })
		add(link(tips[side], V(0, 0.28, -0.72), 0.035, Color3.fromRGB(226, 214, 180)))
	end
	-- Virote con punta de acero y plumas rojas
	add(bolt(V(0, 0.34, -1.95), V(0, 0.34, -0.75), Color3.fromRGB(150, 110, 70)))
	add({ Size = V(0.16, 0.16, 0.3), Offset = CFrame.new(0, 0.34, -2.1), Color = STEEL, Shape = Enum.PartType.Ball, Material = metal })
	add({ Size = V(0.04, 0.2, 0.3), Offset = CFrame.new(0, 0.34, -0.85), Color = Color3.fromRGB(200, 60, 50) })
	add({ Size = V(0.2, 0.04, 0.3), Offset = CFrame.new(0, 0.34, -0.85), Color = Color3.fromRGB(200, 60, 50) })
	-- Mira: poste adelante y alza atrás
	add({ Size = V(0.05, 0.12, 0.05), Offset = CFrame.new(0, 0.34, -1.1), Color = BRASS, Material = metal })
	add({ Size = V(0.2, 0.1, 0.05), Offset = CFrame.new(0, 0.36, -0.1), Color = BRASS, Material = metal })
	return { Hip = CFrame.new(0.8, -0.72, -2.3), Muzzle = CFrame.new(0, 0.34, -2.2), LeftHand = Vector3.new(-0.05, -0.12, -0.55), Pieces = pieces }
end

local function flamethrowerModel(): ModelSpec
	local pieces: { PieceSpec } = {}
	local function add(spec: PieceSpec)
		table.insert(pieces, spec)
	end
	local V = Vector3.new
	local metal = Enum.Material.Metal
	-- Cuerpo, culata corta y empuñadura con guardamonte
	add({ Size = V(0.38, 0.46, 1.1), Offset = CFrame.new(0, 0, 0.3), Color = GUNMETAL, Material = metal })
	add({ Size = V(0.3, 0.36, 0.5), Offset = CFrame.new(0, -0.05, 1.05), Color = DARK, Material = metal })
	add({ Size = V(0.3, 0.6, 0.34), Offset = CFrame.new(0, -0.45, 0.5) * CFrame.Angles(-0.3, 0, 0), Color = RUBBER })
	add(link(V(0, -0.22, 0.1), V(0, -0.6, 0.2), 0.05, DARK, metal))
	add(link(V(0, -0.6, 0.2), V(0, -0.55, 0.42), 0.05, DARK, metal))
	-- Tubo con camisa de refrigeración, aros y boquilla de latón
	add(link(V(0, 0.04, -0.2), V(0, 0.04, -2.2), 0.2, DARK, metal))
	add(link(V(0, 0.04, -0.6), V(0, 0.04, -1.75), 0.36, STEEL, metal))
	for _, z in { -0.7, -1.0, -1.3, -1.6 } do
		add(link(V(0, 0.04, z), V(0, 0.04, z - 0.07), 0.42, DARK, metal))
	end
	add(link(V(0, 0.04, -2.2), V(0, 0.04, -2.42), 0.32, BRASS, metal))
	add(link(V(0, 0.04, -2.42), V(0, 0.04, -2.48), 0.4, DARK, metal))
	-- Llama piloto
	add(link(V(0.12, 0.2, -1.9), V(0.12, 0.2, -2.38), 0.05, BRASS, metal))
	add({ Size = V(0.2, 0.26, 0.2), Offset = CFrame.new(0.12, 0.24, -2.45), Color = Color3.fromRGB(255, 150, 50), Shape = Enum.PartType.Ball, Neon = true })
	-- Depósito de combustible a un lado, con correas, tapa roja y manguera
	add({ Size = V(1.1, 0.46, 0.46), Offset = CFrame.new(0.5, -0.32, 0.95) * CFrame.Angles(0, math.pi / 2, 0), Color = OLIVE, Shape = Enum.PartType.Cylinder, Material = metal })
	for _, z in { 0.55, 0.95, 1.35 } do
		add({ Size = V(0.08, 0.5, 0.5), Offset = CFrame.new(0.5, -0.32, z) * CFrame.Angles(0, math.pi / 2, 0), Color = DARK, Shape = Enum.PartType.Cylinder, Material = metal })
	end
	add({ Size = V(0.22, 0.22, 0.22), Offset = CFrame.new(0.5, -0.32, 0.38), Color = Color3.fromRGB(200, 50, 40), Shape = Enum.PartType.Ball })
	add(link(V(0.46, -0.2, 0.38), V(0.2, -0.04, 0.12), 0.08, RUBBER))
	-- Manómetro en el cuerpo
	add({ Size = V(0.04, 0.24, 0.24), Offset = CFrame.new(0.2, 0.12, 0.2), Color = BRASS, Shape = Enum.PartType.Cylinder, Material = metal })
	return { Hip = CFrame.new(0.8, -0.72, -2.3), Muzzle = CFrame.new(0, 0.04, -2.55), LeftHand = Vector3.new(-0.05, -0.22, -1.1), Pieces = pieces }
end

MODELS.Crossbow = crossbowModel()
MODELS.Flamethrower = flamethrowerModel()

local Viewmodel = {}

-- Vista 3D del arma en mano (para la tienda cuando no hay malla): las mismas
-- piezas de bloques, con los colores de la skin si lleva una.
function Viewmodel.buildPreview(weaponId: string, skin: any?): Model
	local model = Instance.new("Model")
	local spec = MODELS[weaponId] or MODELS.Pistol
	for index, piece in spec.Pieces do
		local part = Instance.new("Part")
		part.Name = "Piece" .. index
		part.Size = piece.Size
		part.CFrame = piece.Offset
		part.Color = if skin and (piece.Color == GUNMETAL or piece.Color == STEEL) then skin.Main:Lerp(skin.Accent, 0.4) else piece.Color
		part.Material = if piece.Neon or (skin and skin.Glow and piece.Color == GUNMETAL) then Enum.Material.Neon else piece.Material or Enum.Material.SmoothPlastic
		if piece.Shape then
			part.Shape = piece.Shape
		end
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
	end
	return model
end

local folder = Instance.new("Folder")
folder.Name = "Viewmodel"

local parts: { BasePart } = {}
local meshModel: Model? = nil
local tierOutline: Highlight? = nil
local offsets: { CFrame } = {}
local cframes: { CFrame } = {}
local flashPart: Part
local flashLight: PointLight
local muzzleOffset = MODELS.Pistol.Muzzle
local hipOffset = HIP_OFFSET
local handStart = math.huge -- desde qué pieza empiezan las manos y brazos

local currentWeapon = ""
local currentLevel = -1
local isMelee = false
local swingStart = -1
local equipStart = -1
local recoil = 0
local reloadAlpha = 0
local aimAlpha = 0
local reloading = false
local aiming = false
local zoom = 1
local hideWhenAiming = false
local flashUntil = 0
local walkTime = 0
local muzzlePosition = Vector3.zero

local function newPart(spec: PieceSpec): Part
	local part = Instance.new("Part")
	part.Size = spec.Size
	part.Color = spec.Color
	part.Material = if spec.Neon then Enum.Material.Neon else spec.Material or Enum.Material.SmoothPlastic
	if spec.Shape then
		part.Shape = spec.Shape
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Cambia el modelo del arma. zoomFactor viene de Config.Weapons y tier de
-- Config.WeaponTiers según el nivel de mejora.
function Viewmodel.setWeapon(weaponId: string, zoomFactor: number, level: number, tier)
	if weaponId == currentWeapon and level == currentLevel then
		return
	end
	if weaponId ~= currentWeapon and currentWeapon ~= "" then
		equipStart = os.clock()
	end
	currentWeapon = weaponId
	currentLevel = level
	isMelee = weaponId == "Machete"
	zoom = zoomFactor
	-- Con mira telescópica se ve por el visor en vez del arma
	hideWhenAiming = zoomFactor >= 3

	for _, part in parts do
		if part ~= flashPart then
			part:Destroy()
		end
	end
	table.clear(parts)
	table.clear(offsets)
	table.clear(cframes)
	if meshModel then
		meshModel:Destroy()
		meshModel = nil
	end

	local model = MODELS[weaponId] or MODELS.Pistol
	muzzleOffset = model.Muzzle
	hipOffset = model.Hip or HIP_OFFSET
	local meshSpec = MESHES[weaponId]
	local meshFolder = ReplicatedStorage:FindFirstChild("WeaponModels")
	local source = MESH_WEAPONS and meshSpec and meshFolder and meshFolder:FindFirstChild(weaponId)
	-- Con malla de la tienda no van las piezas de bloques del arma (los brazos sí)
	local specs = if source then {} else table.clone(model.Pieces)
	-- Manos reales sobre el arma; el cuchillo conserva su guante con tachas
	handTone = characterTone()
	local arm = model.Arm or realRightHand(GRIPS[weaponId] or GRIPS.Pistol)
	handStart = #specs + 1
	table.move(arm, 1, #arm, #specs + 1, specs)
	if model.LeftHand then
		local left = realLeftHand(model.LeftHand)
		table.move(left, 1, #left, #specs + 1, specs)
	end
	for _, spec in specs do
		local part = newPart(spec)
		-- Color del nivel de mejora: cuerpo (Main) y detalles (Accent)
		if spec.Color == GUNMETAL then
			part.Color = tier.Main
		elseif spec.Color == STEEL then
			part.Color = tier.Accent
			if tier.Glow then
				part.Material = Enum.Material.Neon
			end
		elseif spec.Color == BLADE then
			part.Color = tier.Accent:Lerp(Color3.new(1, 1, 1), 0.55)
		end
		table.insert(parts, part)
		table.insert(offsets, spec.Offset)
	end

	if source and meshSpec then
		local mesh = source:Clone() :: Model
		local box, size = mesh:GetBoundingBox()
		mesh:ScaleTo(meshSpec.Length / size.Z)
		box = mesh:GetBoundingBox()
		local turn = meshSpec.Turn or CFrame.identity
		for _, descendant in mesh:GetDescendants() do
			if descendant:IsA("BasePart") then
				-- Skin de arma: el modelo toma el color de la skin
				if tier.Tint then
					-- Sin la textura original el color se ve entero
					if descendant:IsA("MeshPart") then
						descendant.TextureID = ""
					end
					for _, appearance in descendant:GetChildren() do
						if appearance:IsA("SurfaceAppearance") then
							appearance:Destroy()
						end
					end
					descendant.Color = tier.Main:Lerp(tier.Accent, 0.45)
					if tier.Glow then
						descendant.Material = Enum.Material.Neon
					end
				end
				descendant.Anchored = true
				descendant.CanCollide = false
				descendant.CanQuery = false
				descendant.CanTouch = false
				descendant.CastShadow = false
				table.insert(parts, descendant)
				table.insert(offsets, meshSpec.Center * turn * box:ToObjectSpace(descendant.CFrame))
			end
		end
		mesh.Parent = folder
		meshModel = mesh
		-- El nivel de mejora se ve como un contorno del color del nivel
		if level > 0 then
			local outline = tierOutline or Instance.new("Highlight")
			outline.FillTransparency = 1
			outline.OutlineColor = tier.Accent
			outline.OutlineTransparency = if tier.Glow then 0 else 0.35
			outline.DepthMode = Enum.HighlightDepthMode.Occluded
			outline.Adornee = mesh
			outline.Parent = folder
			tierOutline = outline
		elseif tierOutline then
			tierOutline.Adornee = nil
		end
	elseif tierOutline then
		tierOutline.Adornee = nil
	end
	table.insert(parts, flashPart)
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	aimAlpha += ((if aiming then 1 else 0) - aimAlpha) * math.min(1, dt * 14)
	camera.FieldOfView = BASE_FOV / (1 + (zoom - 1) * aimAlpha)

	-- En la cinemática de derrota no se ve el arma (GameOverCinematic)
	local visible = isAlive() and not (hideWhenAiming and aimAlpha > 0.9) and not player:GetAttribute("InCinematic")
	folder.Parent = if visible then camera else nil
	if not visible then
		return
	end

	recoil *= math.exp(-dt * 14)
	reloadAlpha += ((if reloading then 1 else 0) - reloadAlpha) * math.min(1, dt * 10)

	local humanoid = (player.Character :: Model):FindFirstChildOfClass("Humanoid")
	local moving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0.1
	if moving then
		walkTime += dt * (humanoid :: Humanoid).WalkSpeed / 16
	end
	local sway = 1 - aimAlpha * 0.8
	local bobX = if moving then math.sin(walkTime * 8) * 0.05 * sway else 0
	local bobY = if moving then math.abs(math.cos(walkTime * 8)) * 0.05 * sway else 0

	local base = hipOffset:Lerp(AIM_OFFSET, aimAlpha)
	-- Tajo del cuchillo: de la derecha hacia la izquierda, cruzando la pantalla
	local swing = CFrame.identity
	local swingAlpha = (os.clock() - swingStart) / SWING_TIME
	if swingAlpha >= 0 and swingAlpha <= 1 then
		local arc = math.sin(swingAlpha * math.pi)
		local sweep = swingAlpha * 2 - 1
		-- El puño avanza y gira: la hoja barre de la derecha hacia adelante a la izquierda
		swing = CFrame.new(-0.55 * sweep * arc - 0.2 * arc, 0.15 * arc, -0.6 * arc) * CFrame.Angles(-0.2 * arc, 1.1 * arc, 0.25 * sweep * arc)
	end
	-- Cambio de arma: sube desde abajo girando y frena al llegar
	local equip = CFrame.identity
	local equipAlpha = (os.clock() - equipStart) / EQUIP_TIME
	if equipAlpha >= 0 and equipAlpha < 1 then
		local down = (1 - equipAlpha) ^ 3
		equip = CFrame.new(0.25 * down, -1.6 * down, 0.4 * down) * CFrame.Angles(-1.1 * down, 0.35 * down, 0.6 * down)
	end
	local root = camera.CFrame
		* base
		* equip
		* swing
		* CFrame.new(bobX, bobY - 0.5 * reloadAlpha, recoil * 0.22)
		* CFrame.Angles(recoil * 0.15 * sway - 0.7 * reloadAlpha, 0, 0.5 * reloadAlpha)

	-- Ajuste fino de las manos (prueba en vivo: atributo HandShift del jugador)
	local tweak = player:GetAttribute("HandShift")
	local shift = if typeof(tweak) == "Vector3" then CFrame.new(tweak) else CFrame.identity
	for index, offset in offsets do
		cframes[index] = root * (if index >= handStart then shift * offset else offset)
	end
	local muzzle = root * muzzleOffset
	muzzlePosition = muzzle.Position
	cframes[#offsets + 1] = muzzle
	workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)

	local flashing = os.clock() < flashUntil and not isMelee
	flashPart.Transparency = if flashing then 0 else 1
	flashLight.Enabled = flashing
end

function Viewmodel.swing()
	swingStart = os.clock()
end

function Viewmodel.kick(strength: number?)
	recoil = math.min(recoil + (strength or 1), 1.8)
	flashUntil = os.clock() + 0.04
end

function Viewmodel.setReloading(value: boolean)
	reloading = value
end

function Viewmodel.setAiming(value: boolean)
	aiming = value
end

function Viewmodel.isScoped(): boolean
	return hideWhenAiming and aimAlpha > 0.9
end

function Viewmodel.getMuzzlePosition(): Vector3
	if folder.Parent then
		return muzzlePosition
	end
	-- Sin arma visible (mirando por el visor) la bala sale de la cámara
	return (workspace.CurrentCamera.CFrame * CFrame.new(0, -0.3, -1)).Position
end

function Viewmodel.init(weaponId: string, zoomFactor: number, tier)
	flashPart = newPart(p(Vector3.new(0.22, 0.22, 0.22), CFrame.identity, FLASH, true))
	flashPart.Transparency = 1
	flashLight = Instance.new("PointLight")
	flashLight.Color = FLASH
	flashLight.Range = 14
	flashLight.Brightness = 3
	flashLight.Enabled = false
	flashLight.Parent = flashPart

	Viewmodel.setWeapon(weaponId, zoomFactor, 0, tier)
	-- Después de que la cámara se mueve, para que el arma no tiemble
	RunService:BindToRenderStep("Viewmodel", Enum.RenderPriority.Camera.Value + 1, update)
end

return Viewmodel
