--!strict
-- Única puerta para añadir o quitar objetos del inventario. Solo el servidor la usa.
-- Solo acepta objetos que existen en el catálogo y cantidades válidas, y respeta
-- el máximo de cada objeto.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(script.Parent.DataService)
local Validation = require(script.Parent.Validation)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

export type Result = "Ok" | "NoData" | "InvalidItem" | "InvalidAmount" | "NotEnoughItems" | "OverCap"

local InventoryService = {}

-- Un id válido es un texto que está en el catálogo
local function getItemInfo(itemId: any): ItemCatalog.ItemInfo?
	if type(itemId) ~= "string" then
		return nil
	end
	return ItemCatalog[itemId]
end

function InventoryService.getItemCount(player: Player, itemId: any): number?
	if getItemInfo(itemId) == nil then
		return nil
	end
	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	return data.Inventory[itemId] or 0
end

-- Añade objetos. Si se pasara del máximo del objeto, no añade nada y devuelve "OverCap".
function InventoryService.addItem(player: Player, itemId: any, amount: any): Result
	local info = getItemInfo(itemId)
	if info == nil then
		return "InvalidItem"
	end
	if not Validation.isValidAmount(amount) then
		return "InvalidAmount"
	end
	local data = DataService.getData(player)
	if data == nil then
		return "NoData"
	end

	local current = data.Inventory[itemId] or 0
	if current + amount > info.MaxStack then
		return "OverCap"
	end
	data.Inventory[itemId] = current + amount
	return "Ok"
end

-- Quita objetos. Si no hay suficientes, no cambia nada.
function InventoryService.removeItem(player: Player, itemId: any, amount: any): Result
	if getItemInfo(itemId) == nil then
		return "InvalidItem"
	end
	if not Validation.isValidAmount(amount) then
		return "InvalidAmount"
	end
	local data = DataService.getData(player)
	if data == nil then
		return "NoData"
	end

	local current = data.Inventory[itemId] or 0
	if current < amount then
		return "NotEnoughItems"
	end
	-- Al llegar a 0 se borra la entrada para no guardar basura
	data.Inventory[itemId] = if current == amount then nil else current - amount
	return "Ok"
end

return InventoryService
