-- SOLO PARA GRABAR (footage_lobby.project.json). No se publica.
-- Takes (workspace attribute "Take"): "signs" recorre los letreros de las 10 salas,
-- "plaza" gira alrededor de la campana gigante, "enter" mete al jugador en la sala "Room".
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local take = "off"
local takeStart = os.clock()

local function roomSigns()
	local list = {}
	for _, part in workspace:GetDescendants() do
		if part.Name == "RoomSign" and part:IsA("BasePart") then
			local gui = part:FindFirstChildOfClass("SurfaceGui")
			local title = gui and gui:FindFirstChildWhichIsA("TextLabel")
			local index = title and tonumber(string.match(title.Text, "%d+"))
			if index then
				table.insert(list, { Index = index, Part = part })
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Index < b.Index
	end)
	return list
end

local function viewOf(sign: BasePart)
	local position = (sign.CFrame * CFrame.new(0, -2.5, -17)).Position
	return CFrame.lookAt(position, sign.Position + Vector3.new(0, -1, 0))
end

RunService:BindToRenderStep("LobbyFootage", Enum.RenderPriority.Camera.Value + 10, function()
	local age = os.clock() - takeStart
	if take == "signs" then
		camera.CameraType = Enum.CameraType.Scriptable
		local signs = roomSigns()
		if #signs == 0 then
			return
		end
		local step = 1.5
		local position = math.clamp(age / step, 0, #signs - 1)
		local i = math.floor(position)
		local k = position - i
		k = k * k * (3 - 2 * k)
		local a = viewOf(signs[i + 1].Part)
		local b = viewOf(signs[math.min(i + 2, #signs)].Part)
		camera.CFrame = a:Lerp(b, k)
	elseif take == "plaza" then
		camera.CameraType = Enum.CameraType.Scriptable
		local center = Vector3.new(0, 8, -6)
		local angle = math.rad(-95) + age * 0.16
		local position = center + Vector3.new(math.cos(angle) * 70, 20, math.sin(angle) * 70)
		camera.CFrame = CFrame.lookAt(position, center + Vector3.new(0, 4, 0))
	end
end)

workspace:GetAttributeChangedSignal("Take"):Connect(function()
	take = workspace:GetAttribute("Take") or "off"
	takeStart = os.clock()
	if take == "off" then
		camera.CameraType = Enum.CameraType.Custom
	elseif take == "enter" then
		camera.CameraType = Enum.CameraType.Custom
		local index = workspace:GetAttribute("Room") or 6
		for _, sign in roomSigns() do
			if sign.Index == index then
				local center = Vector3.new(0, 0, 0)
				local count = 0
				for _, wall in sign.Part.Parent:GetChildren() do
					if wall.Name == "RoomWall" and wall:IsA("BasePart") then
						center += Vector3.new(wall.Position.X, 0, wall.Position.Z)
						count += 1
					end
				end
				if count > 0 and player.Character then
					center /= count
					player.Character:PivotTo(CFrame.new(center.X, sign.Part.Position.Y - 6, center.Z))
				end
			end
		end
	end
end)
