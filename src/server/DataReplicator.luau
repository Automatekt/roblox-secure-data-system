--!strict
-- Copia los datos del servidor a atributos del PlayerGui del jugador para que
-- su cliente pueda mostrarlos. El PlayerGui solo se replica a su dueño, así que
-- los demás jugadores no ven nada. Es solo lectura para el cliente: no existe
-- ningún RemoteEvent con el que pueda pedir un cambio.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

local PLAYER_GUI_TIMEOUT = 10 -- segundos que se espera a que exista el PlayerGui

local DataReplicator = {}

local function getPlayerGui(player: Player): PlayerGui?
	return player:FindFirstChildOfClass("PlayerGui")
end

function DataReplicator.syncCoins(player: Player)
	local data = DataService.getData(player)
	local playerGui = getPlayerGui(player)
	if data ~= nil and playerGui ~= nil then
		playerGui:SetAttribute(DataAttributes.Coins, data.Coins)
	end
end

function DataReplicator.syncItem(player: Player, itemId: string)
	local data = DataService.getData(player)
	local playerGui = getPlayerGui(player)
	if data ~= nil and playerGui ~= nil then
		playerGui:SetAttribute(DataAttributes.itemKey(itemId), data.Inventory[itemId] or 0)
	end
end

local function syncAll(player: Player)
	-- El PlayerGui puede tardar un instante en existir cuando el jugador acaba de entrar
	local playerGui = player:WaitForChild("PlayerGui", PLAYER_GUI_TIMEOUT)
	if playerGui == nil then
		warn(`[DataReplicator] {player.Name} no tiene PlayerGui; no se pueden mostrar sus datos`)
		return
	end

	DataReplicator.syncCoins(player)
	for itemId in ItemCatalog do
		DataReplicator.syncItem(player, itemId)
	end
	-- Va al final: el cliente espera esta señal para mostrar los datos ya completos
	playerGui:SetAttribute(DataAttributes.Loaded, true)
end

-- Debe llamarse antes de DataService.start() para no perder ningún jugador
function DataReplicator.start()
	DataService.onLoaded(syncAll)
end

return DataReplicator
