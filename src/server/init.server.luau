--!strict
-- Punto de entrada del servidor: arranca los sistemas del juego.

local DataService = require(script.DataService)
local DataReplicator = require(script.DataReplicator)
local DemoRewardService = require(script.DemoRewardService)

-- El replicador se registra antes de cargar datos para no perder a ningún jugador
DataReplicator.start()
DataService.start()
DemoRewardService.start()
