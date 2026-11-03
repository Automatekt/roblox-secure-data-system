--!strict
-- Lista de objetos que existen en el juego. El servidor solo acepta ids de
-- esta lista, y el cliente la usa para mostrar los nombres.

export type ItemInfo = {
	DisplayName: string,
	MaxStack: number, -- máximo que un jugador puede tener de este objeto
}

local items: { [string]: ItemInfo } = {
	Sword = { DisplayName = "Espada", MaxStack = 1 },
	HealthPotion = { DisplayName = "Poción de vida", MaxStack = 99 },
	Gem = { DisplayName = "Gema", MaxStack = 999 },
	Key = { DisplayName = "Llave", MaxStack = 10 },
}

-- Congelado para que ningún script cambie el catálogo por accidente
for _, info in items do
	table.freeze(info)
end

return table.freeze(items)
