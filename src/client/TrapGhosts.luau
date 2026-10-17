-- Fantasmas celestes de las trampas: cada lugar libre para una mina o una reja
-- (modelos "Ghost" que crea el servidor en workspace.Traps) se ve transparente
-- y celeste solo cuando te acercas, y solo en la preparación. Con la partida en
-- marcha desaparecen. Se hace con LocalTransparencyModifier: cada jugador ve los
-- suyos sin gastar red.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TrapGhosts = {}

local SHOW_DISTANCE = 32
local player = Players.LocalPlayer

local function setVisible(model: Model, visible: boolean)
	local want = if visible then 0 else 1
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.LocalTransparencyModifier ~= want then
			part.LocalTransparencyModifier = want
		elseif part:IsA("BillboardGui") and part.Enabled ~= visible then
			part.Enabled = visible
		end
	end
end

function TrapGhosts.init()
	local state = ReplicatedStorage:WaitForChild("GameState")
	task.spawn(function()
		while true do
			task.wait(0.2)
			local folder = workspace:FindFirstChild("Traps")
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if folder and root then
				local preparing = state:GetAttribute("State") == "Lobby"
				for _, model in folder:GetChildren() do
					if model:IsA("Model") and model:GetAttribute("Ghost") and model.PrimaryPart then
						local near = (model.PrimaryPart.Position - root.Position).Magnitude < SHOW_DISTANCE
						setVisible(model, preparing and near and model:GetAttribute("Empty") == true)
					end
				end
			end
		end
	end)
end

return TrapGhosts
