--!strict
-- Comprobaciones compartidas por los servicios que reciben cantidades.

local Validation = {}

-- Una cantidad válida es un número entero, finito y mayor que cero
function Validation.isValidAmount(amount: any): boolean
	return type(amount) == "number"
		and amount == amount -- descarta NaN (NaN no es igual a sí mismo)
		and amount > 0
		and amount < math.huge
		and amount % 1 == 0
end

return Validation
