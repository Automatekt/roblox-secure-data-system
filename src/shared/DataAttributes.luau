--!strict
-- Nombres de los atributos con los que el servidor muestra los datos al cliente.
-- Los atributos del jugador se replican solos y solo en una dirección
-- (servidor a cliente): el cliente puede leerlos, pero no puede cambiarlos.

return {
	Loaded = "DataLoaded", -- true cuando los datos del jugador ya cargaron
	Coins = "Coins",
	itemKey = function(itemId: string): string
		return "Item_" .. itemId
	end,
}
