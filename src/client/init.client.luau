local EnemyRenderer = require(script.EnemyRenderer)
local Hud = require(script.Hud)
local WeaponController = require(script.WeaponController)

EnemyRenderer.init()
WeaponController.init(EnemyRenderer.folder, Hud.flashHitMarker)
Hud.init(WeaponController.setTrigger)
