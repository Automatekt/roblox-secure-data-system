--!strict
-- Punto de entrada del cliente: arranca la interfaz y los efectos.

local HudController = require(script.HudController)
local ChestEffects = require(script.ChestEffects)

HudController.start()
ChestEffects.start()
