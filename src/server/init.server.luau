--!strict
-- Punto de entrada del servidor: arranca los sistemas del juego.

local DataService = require(script.DataService)
local ColorPartService = require(script.ColorPartService)

DataService.start()
ColorPartService.start()
