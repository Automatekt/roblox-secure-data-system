--!strict
-- Paleta y tipografía de la escena "ruinas doradas al atardecer".
-- Todos los colores del mapa, el cofre y la interfaz salen de aquí, para que
-- nada quede fuera de estilo.

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

return table.freeze({
	-- Colores principales (4)
	Stone = hex("#7A6F63"), -- piedra cálida
	StoneDark = hex("#4A423B"), -- piedra en sombra y fondos de interfaz
	Gold = hex("#F2B84B"), -- cofre, bordes y números
	Amber = hex("#FF8A3D"), -- llamas y luz de antorchas
	Moss = hex("#5C7A4A"), -- vegetación

	-- Neutros de apoyo para la interfaz
	Ink = hex("#1E1A17"), -- fondo muy oscuro
	Parchment = hex("#F4E9D2"), -- texto claro

	-- Tipografías de Roblox
	TitleFont = Enum.Font.Merriweather, -- títulos y mensajes
	NumberFont = Enum.Font.GothamBold, -- números: se leen bien en pantallas chicas
})
