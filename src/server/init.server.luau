--!strict
-- Punto de entrada del servidor: arranca los sistemas del juego.

local MapBuilder = require(script.MapBuilder)
local ChestPoints = require(script.ChestPoints)
local DataService = require(script.DataService)
local DataReplicator = require(script.DataReplicator)
local ChestService = require(script.ChestService)

-- El mapa se construye antes que nada para que exista cuando entren los jugadores
MapBuilder.build()
ChestPoints.validate()

-- Los servicios que reaccionan a la carga de datos se registran antes de cargar
-- a nadie, para no perder a ningún jugador
DataReplicator.start()
ChestService.start()
DataService.start()
