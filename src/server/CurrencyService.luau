--!strict
-- Única puerta para sumar o gastar monedas. Solo el servidor la usa.
-- Cada función valida la cantidad antes de tocar el saldo, así un valor raro
-- (negativo, texto, NaN, infinito, decimales) nunca llega a los datos guardados.

local DataService = require(script.Parent.DataService)

local MAX_COINS = 1_000_000_000

export type Result = "Ok" | "NoData" | "InvalidAmount" | "NotEnoughCoins" | "OverCap"

local CurrencyService = {}

-- Una cantidad válida es un número entero, finito y mayor que cero
local function isValidAmount(amount: any): boolean
	return type(amount) == "number"
		and amount == amount -- descarta NaN (NaN no es igual a sí mismo)
		and amount > 0
		and amount < math.huge
		and amount % 1 == 0
end

function CurrencyService.getCoins(player: Player): number?
	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	return data.Coins
end

-- Suma monedas. Si el saldo pasara del tope, no suma nada y devuelve "OverCap".
function CurrencyService.addCoins(player: Player, amount: any): Result
	if not isValidAmount(amount) then
		return "InvalidAmount"
	end
	local data = DataService.getData(player)
	if data == nil then
		return "NoData"
	end
	if data.Coins + amount > MAX_COINS then
		return "OverCap"
	end
	data.Coins += amount
	return "Ok"
end

-- Gasta monedas. Si no alcanzan, no cambia nada.
function CurrencyService.spendCoins(player: Player, amount: any): Result
	if not isValidAmount(amount) then
		return "InvalidAmount"
	end
	local data = DataService.getData(player)
	if data == nil then
		return "NoData"
	end
	if data.Coins < amount then
		return "NotEnoughCoins"
	end
	data.Coins -= amount
	return "Ok"
end

return CurrencyService
