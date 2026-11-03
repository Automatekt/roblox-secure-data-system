--!strict
-- Datos con los que empieza un jugador nuevo.
-- Si más adelante se añade un campo aquí, los jugadores antiguos lo reciben
-- automáticamente al entrar (Reconcile), sin perder lo que ya tenían.

export type PlayerData = {
	SchemaVersion: number, -- por si algún día hay que migrar la estructura
	Coins: number,
	Inventory: { [string]: number }, -- [idDelObjeto] = cantidad
}

local template: PlayerData = {
	SchemaVersion = 1,
	Coins = 0,
	Inventory = {},
}

return template
