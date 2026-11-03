--!strict
-- Nombres y medidas que el servidor y el cliente comparten sobre el cofre.
-- El servidor crea el cofre real con un dueño; el cliente solo lo adorna y
-- oculta los cofres de otros jugadores.

return table.freeze({
	Tag = "RewardChest", -- etiqueta (CollectionService) de cada cofre
	OwnerAttribute = "OwnerUserId", -- UserId del jugador que puede recogerlo
	StateAttribute = "ChestState",
	States = table.freeze({
		Idle = "Idle", -- esperando a que su dueño lo recoja
		Claimed = "Claimed", -- ya recogido: el cliente reproduce la desaparición
	}),
	HoverHeight = 2.2, -- altura del centro del cofre sobre el suelo del punto
	ClaimAnimationSeconds = 1.0, -- el servidor espera esto antes de borrar el cofre recogido
})
