--!strict
-- Nombres de los atributos con los que el servidor muestra los datos al dueño.
-- Se ponen en el PlayerGui del jugador: Roblox solo replica el PlayerGui a su
-- dueño, así que ningún otro jugador puede ver estos datos, y la replicación es
-- solo de servidor a cliente (el cliente puede leerlos, pero no cambiarlos).

return {
	Loaded = "DataLoaded", -- true cuando los datos del jugador ya cargaron
	Coins = "Coins",
	itemKey = function(itemId: string): string
		return "Item_" .. itemId
	end,
}
