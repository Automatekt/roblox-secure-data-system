--!strict
-- Copia los datos del servidor a atributos del jugador para que el cliente
-- pueda mostrarlos. Es solo lectura para el cliente: no existe ningún
-- RemoteEvent con el que pueda pedir un cambio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

local DataReplicator = {}

function DataReplicator.syncCoins(player: Player)
	local data = DataService.getData(player)
	if data ~= nil then
		player:SetAttribute(DataAttributes.Coins, data.Coins)
	end
end

function DataReplicator.syncItem(player: Player, itemId: string)
	local data = DataService.getData(player)
	if data ~= nil then
		player:SetAttribute(DataAttributes.itemKey(itemId), data.Inventory[itemId] or 0)
	end
end

local function syncAll(player: Player)
	DataReplicator.syncCoins(player)
	for itemId in ItemCatalog do
		DataReplicator.syncItem(player, itemId)
	end
	-- Va al final: el cliente espera esta señal para mostrar los datos ya completos
	player:SetAttribute(DataAttributes.Loaded, true)
end

-- Debe llamarse antes de DataService.start() para no perder ningún jugador
function DataReplicator.start()
	DataService.onLoaded(syncAll)
end

return DataReplicator
