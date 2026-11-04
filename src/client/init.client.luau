--!strict
-- Punto de entrada del cliente: arranca la interfaz y los efectos.

local AmbientEffects = require(script.AmbientEffects)
local HudController = require(script.HudController)
local SaveIndicator = require(script.SaveIndicator)
local ChestEffects = require(script.ChestEffects)
local ChestSounds = require(script.ChestSounds)

HudController.start()
SaveIndicator.start()
ChestSounds.start()
ChestEffects.start()
AmbientEffects.start()
