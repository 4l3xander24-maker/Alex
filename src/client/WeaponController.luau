-- Disparo, munición (cargador y reserva), recarga, cambio de arma, apuntar y
-- tajos de machete. El cliente predice todo con las mismas reglas que el
-- servidor para que se sienta instantáneo; el servidor valida y decide el daño.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MeleeEnergy = require(Shared.MeleeEnergy)
local Progression = require(Shared.Progression)
local Remotes = require(Shared.Remotes)
local MovementController = require(script.Parent.MovementController)
local Notify = require(script.Parent.Notify)
local Profile = require(script.Parent.Profile)
local Viewmodel = require(script.Parent.Viewmodel)
local Sfx = require(script.Parent.Sfx)

local TRACER_COLOR = Color3.fromRGB(255, 220, 90)
local TRACER_TIME = 0.05
local SWITCH_DELAY = 0.3
local NUMBER_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight }
local AIM_ANGLE = math.rad(Config.ShootAssist.AimAngle)
local DRY_RESET = 0.6 -- si pasa esto sin intentar disparar, la cuenta para sacar el cuchillo empieza de nuevo

type RayHit = { Id: number, Distance: number, Position: Vector3 }
-- Consultas a los zombis que dibuja EnemyRenderer (llegan en init para no
-- tener un require circular)
export type EnemyQueries = {
	raycast: (Vector3, Vector3, number) -> RayHit?,
	nearestToAim: (Vector3, Vector3, number, number) -> RayHit?,
	anyInSwing: (Vector3, Vector3, number, number) -> boolean,
}

local player = Players.LocalPlayer
local random = Random.new()

local WeaponController = {}

local ammoGranted = Instance.new("BindableEvent")
-- Se dispara con (weaponId, cantidad) cuando un zombi te da balas
WeaponController.AmmoGranted = ammoGranted.Event

local equipped = "Pistol"
local ammo: { [string]: number } = {}
local reserve: { [string]: number } = {}
local triggerHeld = false
local triggerFromMouse = false -- con el mouse nunca se usa la ayuda de puntería
local aimHeld = false
local lastShot = 0
local reloading = false
local reloadWeapon = ""
local reloadStart = 0
local reloadEnd = 0
local enemies: EnemyQueries
local onEnemyHit: () -> ()
-- Intentos de disparar sin balas: desde cuándo y el último
local dryStart = 0
local lastDry = -math.huge
-- Energía del cuchillo: cada tajo gasta, se recarga sola
local energy = MeleeEnergy.new()

local function stats(weaponId: string?)
	return Progression.getWeaponStats(Profile.get(), weaponId or equipped, aimHeld and Profile.hasTalent("Aim"))
end

local function isMelee(weaponId: string?): boolean
	return Config.Weapons[weaponId or equipped].Melee == true
end

local function isAiming(): boolean
	return aimHeld and Profile.hasTalent("Aim") and not MovementController.isSprinting() and not isMelee()
end

local function isAlive(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function cancelReload()
	reloading = false
	Viewmodel.setReloading(false)
end

local function showWeapon()
	local data = Profile.get()
	local level = data.Weapons[equipped] or 0
	-- Una skin de arma (Sastre) manda sobre el color del nivel de mejora
	for index, skin in Config.WeaponSkins do
		if skin.Id == data.WeaponSkin and data.WeaponSkins[skin.Id] then
			Viewmodel.setWeapon(equipped, Config.Weapons[equipped].Zoom, 1000 + index, { Name = skin.Name, Main = skin.Main, Accent = skin.Accent, Glow = skin.Glow, Tint = true })
			return
		end
	end
	Viewmodel.setWeapon(equipped, Config.Weapons[equipped].Zoom, level, Progression.weaponTier(level))
end

local function tracerSkin(): any
	local id = Profile.get().ObjectSkinOn.Tracer
	if id == "" then
		return nil
	end
	for _, skin in Config.ObjectSkins do
		if skin.Id == id then
			return skin
		end
	end
	return nil
end

-- Lanzallamas: una llamarada corta que sale del cañón hacia donde apuntas. Un
-- solo emisor para todas: se ubica en el cañón y suelta su tanda (las llamas
-- ya lanzadas siguen solas aunque el emisor se mueva).
local flameHolder: BasePart? = nil
local flameEmitter: ParticleEmitter? = nil

local function flameBurst(from: Vector3, to: Vector3)
	local direction = to - from
	if direction.Magnitude < 0.1 then
		return
	end
	local holder, emitter = flameHolder, flameEmitter
	if not holder or not emitter or not holder.Parent then
		-- Primera vez (o la cámara se cambió y se llevó al emisor)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Transparency = 1
		part.Size = Vector3.one * 0.2
		local flames = Instance.new("ParticleEmitter")
		flames.Rate = 0
		flames.Lifetime = NumberRange.new(0.25, 0.45)
		flames.Speed = NumberRange.new(38, 52)
		flames.SpreadAngle = Vector2.new(9, 9)
		flames.EmissionDirection = Enum.NormalId.Front
		flames.LightEmission = 1
		flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 2.4) })
		flames.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
		flames.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 150)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 140, 40)), ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 40, 30)) })
		flames.Parent = part
		part.Parent = workspace.CurrentCamera
		holder, emitter = part, flames
		flameHolder, flameEmitter = part, flames
	end
	(holder :: BasePart).CFrame = CFrame.lookAt(from, to);
	(emitter :: ParticleEmitter):Emit(4)
end

-- Balas trazadoras recicladas: una pieza por bala que se esconde al terminar y
-- vuelve a la reserva (no se crea y se borra una pieza en cada disparo)
local MAX_TRACERS = 24 -- en reserva; si se pasan (escopeta a toda cadencia) se borran
local tracerPool: { BasePart } = {}
local tracerSparks: { [BasePart]: ParticleEmitter } = {}

local function takeTracer(): BasePart
	local tracer = table.remove(tracerPool)
	if not tracer then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		tracer = part
	end
	local taken = tracer :: BasePart
	taken.Transparency = 0
	taken.Parent = workspace.CurrentCamera
	return taken
end

local function releaseTracer(tracer: BasePart)
	local sparks = tracerSparks[tracer]
	if sparks then
		-- Las chispas se van con la bala, como cuando se borraba
		sparks.Enabled = false
		sparks:Clear()
	end
	if #tracerPool >= MAX_TRACERS or not tracer.Parent then
		tracerSparks[tracer] = nil
		tracer:Destroy()
		return
	end
	tracer.Transparency = 1
	table.insert(tracerPool, tracer)
end

local function drawTracer(from: Vector3, to: Vector3)
	local length = (to - from).Magnitude
	local skin = tracerSkin()
	local tracer = takeTracer()
	tracer.Color = if skin then skin.Main else TRACER_COLOR
	local width = if skin and skin.Premium then 0.16 else 0.06
	tracer.Size = Vector3.new(width, width, length)
	tracer.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -length / 2)
	-- Las Premium dejan un núcleo claro y chispas a lo largo de la bala
	if skin and skin.Premium then
		local core = takeTracer()
		core.Color = skin.Accent
		core.Size = Vector3.new(0.05, 0.05, length)
		core.CFrame = tracer.CFrame
		task.delay(TRACER_TIME, releaseTracer, core)
		local emitter = tracerSparks[tracer]
		if not emitter then
			local sparks = Instance.new("ParticleEmitter")
			sparks.Rate = 60
			sparks.Lifetime = NumberRange.new(0.3, 0.5)
			sparks.Speed = NumberRange.new(0.5, 1.5)
			sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
			sparks.LightEmission = 1
			sparks.Parent = tracer
			tracerSparks[tracer] = sparks
			emitter = sparks
		end
		local sparks = emitter :: ParticleEmitter
		sparks.Color = ColorSequence.new(skin.Accent)
		sparks.Enabled = true
	end
	task.delay(TRACER_TIME, releaseTracer, tracer)
end

local function applySpread(direction: Vector3, spread: number): Vector3
	if spread <= 0 then
		return direction
	end
	local rotation = CFrame.Angles(random:NextNumber(-spread, spread), random:NextNumber(-spread, spread), 0)
	return (CFrame.lookAt(Vector3.zero, direction) * rotation).LookVector
end

local function slash(weaponStats)
	local cameraCFrame = workspace.CurrentCamera.CFrame
	Remotes.Shoot:FireServer(cameraCFrame.Position, cameraCFrame.LookVector, workspace:GetServerTimeNow(), false)
	Viewmodel.swing()
	Sfx.weapon(equipped)

	-- Marca de golpe si hay algún zombi dentro del tajo (misma regla que el servidor)
	if enemies.anyInSwing(cameraCFrame.Position, cameraCFrame.LookVector, weaponStats.Range, Config.Weapons[equipped].Arc or 0) then
		onEnemyHit()
	end
end

-- Raycast contra el mundo (paredes, suelo), sin el personaje propio
local function worldRaycast(origin: Vector3, direction: Vector3, distance: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character :: Instance }
	return workspace:Raycast(origin, direction * distance, params)
end

-- Hacia dónde sale el tiro y si va a dar en un zombi (para el disparo
-- automático). Con la ayuda de puntería, si la mira no toca a ningún zombi
-- pero uno queda a pocos grados, el tiro va hacia su cuerpo. Nunca con el mouse.
local function aimAt(origin: Vector3, direction: Vector3, range: number): (Vector3, boolean)
	local direct = enemies.raycast(origin, direction, range)
	if direct then
		return direction, worldRaycast(origin, direction, direct.Distance) == nil
	end
	local assist = player:GetAttribute("AimAssist") == true and not (triggerHeld and triggerFromMouse)
	if not assist then
		return direction, false
	end
	local near = enemies.nearestToAim(origin, direction, range, AIM_ANGLE)
	if not near then
		return direction, false
	end
	local toward = near.Position - origin
	if toward.Magnitude < 0.1 or worldRaycast(origin, toward.Unit, toward.Magnitude) then
		return direction, false
	end
	return toward.Unit, true
end

local function fire(weaponStats, direction: Vector3)
	local origin = workspace.CurrentCamera.CFrame.Position
	Remotes.Shoot:FireServer(origin, direction, workspace:GetServerTimeNow(), isAiming())
	Sfx.weapon(equipped)
	Viewmodel.kick(if weaponStats.Pellets > 1 or weaponStats.Damage > 5 then 1.6 else 1)

	-- Lo visual es local; el daño lo decide el servidor. Cada perdigón termina
	-- en lo que esté más cerca: una pared o un zombi.
	local hitEnemy = false
	for _ = 1, weaponStats.Pellets do
		local pelletDirection = applySpread(direction, weaponStats.Spread)
		local result = worldRaycast(origin, pelletDirection, weaponStats.Range)
		local hitPoint = if result then result.Position else origin + pelletDirection * weaponStats.Range
		local enemyHit = enemies.raycast(origin, pelletDirection, if result then result.Distance else weaponStats.Range)
		if enemyHit then
			hitPoint = enemyHit.Position
			hitEnemy = true
		end
		if Config.Weapons[equipped].Flame then
			flameBurst(Viewmodel.getMuzzlePosition(), hitPoint)
		else
			drawTracer(Viewmodel.getMuzzlePosition(), hitPoint)
		end
	end
	if hitEnemy then
		onEnemyHit()
	end
end

function WeaponController.equip(weaponId: string)
	if weaponId == equipped or not Profile.get().Weapons[weaponId] then
		return
	end
	cancelReload()
	equipped = weaponId
	-- Pequeña pausa al cambiar de arma (y respeta la cadencia del arma nueva)
	lastShot = math.max(lastShot, os.clock() + SWITCH_DELAY - 1 / stats().FireRate)
	showWeapon()
	Sfx.play("Equip")
	Remotes.EquipWeapon:FireServer(weaponId)
end

function WeaponController.cycle()
	local owned = {}
	for _, id in Config.WeaponOrder do
		if Profile.get().Weapons[id] then
			table.insert(owned, id)
		end
	end
	local index = table.find(owned, equipped) or 0
	WeaponController.equip(owned[index % #owned + 1])
end

function WeaponController.reload()
	if reloading or isMelee() or not isAlive() then
		return
	end
	if (ammo[equipped] or 0) >= stats().Magazine or (reserve[equipped] or 0) <= 0 then
		return
	end
	reloading = true
	reloadWeapon = equipped
	reloadStart = os.clock()
	reloadEnd = reloadStart + stats().ReloadTime
	Remotes.Reload:FireServer()
	Viewmodel.setReloading(true)
	Sfx.play("Reload")
end

-- Gatillo táctil (botón de disparar del HUD)
function WeaponController.setTrigger(held: boolean)
	triggerHeld = held
	triggerFromMouse = false
end

-- Botón de apuntar del celular: alterna. El estado vive solo aquí, así se
-- reinicia junto con lo demás al reaparecer.
function WeaponController.toggleAiming()
	aimHeld = not aimHeld
end

function WeaponController.isAiming(): boolean
	return isAiming()
end

function WeaponController.getEquipped(): string
	return equipped
end

-- Para el HUD: energía del cuchillo (0-1) y si alcanza para otro tajo
function WeaponController.getMeleeEnergy(): (number, boolean)
	local now = os.clock()
	return MeleeEnergy.get(energy, now), MeleeEnergy.canUse(energy, now)
end

-- Para el HUD: cargador, tamaño del cargador, reserva, progreso de recarga
-- (0-1 o nil) y si es arma cuerpo a cuerpo
function WeaponController.getAmmoState(): (number, number, number, number?, boolean)
	local progress = if reloading then math.clamp((os.clock() - reloadStart) / (reloadEnd - reloadStart), 0, 1) else nil
	return ammo[equipped] or 0, stats().Magazine, reserve[equipped] or 0, progress, isMelee()
end

local function finishReload()
	reloading = false
	local magazine = stats(reloadWeapon).Magazine
	local current = ammo[reloadWeapon] or 0
	local moved = math.min(magazine - current, reserve[reloadWeapon] or 0)
	ammo[reloadWeapon] = current + moved
	reserve[reloadWeapon] = (reserve[reloadWeapon] or 0) - moved
	Viewmodel.setReloading(false)
end

-- Gatillo sin balas en el cargador ni en la reserva: clic seco y, si sigue
-- intentando cerca de un segundo, saca el cuchillo con un aviso
local function dryFire(now: number)
	if now - lastDry > DRY_RESET then
		dryStart = now
	end
	lastDry = now
	Sfx.play("DryFire")
	if now - dryStart < Config.ShootAssist.DrySwitchTime then
		return
	end
	for _, id in Config.WeaponOrder do
		if Config.Weapons[id].Melee and Profile.get().Weapons[id] then
			lastDry = -math.huge
			WeaponController.equip(id)
			Notify.show("¡Sin balas! Sacaste el cuchillo")
			return
		end
	end
end

local function update()
	local now = os.clock()
	if reloading and now >= reloadEnd then
		finishReload()
	end
	Viewmodel.setAiming(isAiming())

	-- Disparo automático (opción): dispara solo mientras la mira está sobre
	-- un zombi, con la misma cadencia, munición y recarga que el gatillo
	local autoFire = player:GetAttribute("AutoFire") == true and player:GetAttribute("InCinematic") ~= true
	if not (triggerHeld or autoFire) or reloading or not isAlive() or MovementController.isSprinting() then
		return
	end
	local weaponStats = stats()
	if now - lastShot < 1 / weaponStats.FireRate then
		return
	end
	local camera = workspace.CurrentCamera.CFrame
	if weaponStats.Melee then
		if not triggerHeld and not enemies.anyInSwing(camera.Position, camera.LookVector, weaponStats.Range, Config.Weapons[equipped].Arc or 0) then
			return
		end
		-- Sin energía no ataca hasta que el círculo se recargue un poco
		if MeleeEnergy.use(energy, now) then
			lastShot = now
			slash(weaponStats)
		end
		return
	end
	local direction, onTarget = aimAt(camera.Position, camera.LookVector, weaponStats.Range)
	if not triggerHeld and not onTarget then
		return
	end
	if (ammo[equipped] or 0) > 0 then
		lastShot = now
		ammo[equipped] -= 1
		fire(weaponStats, direction)
	elseif (reserve[equipped] or 0) <= 0 then
		dryFire(now)
	end
	if (ammo[equipped] or 0) <= 0 then
		WeaponController.reload()
	end
end

local function isTriggerInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2
end

local function isAimInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton2 or input.KeyCode == Enum.KeyCode.ButtonL2
end

-- Los menús (tiendas de los NPC, resumen, tienda) liberan el mouse con un
-- botón Modal, pero el puntero sigue escondido por el arma: se muestra
-- mientras haya alguno visible y se vuelve a esconder al cerrarlo.
local function watchMenus()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local modals: { [GuiButton]: boolean } = {}
	local function track(instance: Instance)
		if instance:IsA("GuiButton") then
			modals[instance] = true
		end
	end
	for _, descendant in playerGui:GetDescendants() do
		track(descendant)
	end
	playerGui.DescendantAdded:Connect(track)
	playerGui.DescendantRemoving:Connect(function(instance)
		modals[instance :: any] = nil
	end)
	local function isShown(button: GuiButton): boolean
		if not button.Modal or not button.Visible then
			return false
		end
		local parent = button.Parent
		while parent and parent ~= playerGui do
			if parent:IsA("LayerCollector") then
				if not parent.Enabled then
					return false
				end
			elseif parent:IsA("GuiObject") and not parent.Visible then
				return false
			end
			parent = parent.Parent
		end
		return true
	end
	task.spawn(function()
		while true do
			local open = false
			for button in modals do
				if isShown(button) then
					open = true
					break
				end
			end
			if UserInputService.MouseIconEnabled ~= open then
				UserInputService.MouseIconEnabled = open
			end
			task.wait(0.15)
		end
	end)
end

function WeaponController.init(enemyQueries: EnemyQueries, hitCallback: () -> ())
	enemies = enemyQueries
	onEnemyHit = hitCallback

	if UserInputService.MouseEnabled then
		UserInputService.MouseIconEnabled = false
		watchMenus()
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if isTriggerInput(input) then
			triggerHeld = true
			triggerFromMouse = input.UserInputType == Enum.UserInputType.MouseButton1
		elseif isAimInput(input) then
			aimHeld = true
		elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonX then
			WeaponController.reload()
		elseif input.KeyCode == Enum.KeyCode.ButtonY then
			WeaponController.cycle()
		else
			local slot = table.find(NUMBER_KEYS, input.KeyCode)
			if slot and Config.WeaponOrder[slot] then
				WeaponController.equip(Config.WeaponOrder[slot])
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isTriggerInput(input) then
			triggerHeld = false
		elseif isAimInput(input) then
			aimHeld = false
		end
	end)

	-- Al reaparecer nada queda apretado (ni un dedo que siguió en la pantalla)
	player.CharacterAdded:Connect(function()
		cancelReload()
		aimHeld = false
		triggerHeld = false
	end)

	-- El servidor manda la munición inicial (al empezar la partida o al comprar)
	Remotes.AmmoSync.OnClientEvent:Connect(function(newAmmo, newReserve)
		ammo = newAmmo
		reserve = newReserve
		cancelReload()
		-- Al empezar la partida el servidor también llena la energía
		MeleeEnergy.refill(energy)
	end)
	-- Balas ganadas al eliminar un zombi (mismo tope que en el servidor)
	Remotes.AmmoGranted.OnClientEvent:Connect(function(weaponId, amount)
		reserve[weaponId] = math.min((reserve[weaponId] or 0) + amount, stats(weaponId).MaxReserve)
		ammoGranted:Fire(weaponId, amount)
	end)

	Profile.Changed:Connect(function(reason)
		local serverEquipped = Profile.get().Equipped
		if reason ~= "Equip" and serverEquipped ~= equipped then
			equipped = serverEquipped
			cancelReload()
		end
		-- También repinta el arma si subió de nivel (cambia de color)
		showWeapon()
	end)

	RunService.RenderStepped:Connect(update)
end

return WeaponController
