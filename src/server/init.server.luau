--!strict
-- Punto de entrada del servidor: arranca los sistemas del juego.

local MapBuilder = require(script.MapBuilder)
local ChestPoints = require(script.ChestPoints)
local DataService = require(script.DataService)
local DataReplicator = require(script.DataReplicator)
local DemoRewardService = require(script.DemoRewardService)

-- El mapa se construye antes que nada para que exista cuando entren los jugadores
MapBuilder.build()

-- El replicador se registra antes de cargar datos para no perder a ningún jugador
DataReplicator.start()
DataService.start()
DemoRewardService.start()

ChestPoints.validate()
