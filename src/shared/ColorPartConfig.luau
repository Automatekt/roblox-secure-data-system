--!strict
-- Ajustes de la Part que cambia de color. Se cambian aquí, sin tocar la lógica.

return {
	Name = "ColorPart",
	Size = Vector3.new(6, 1, 6),
	Position = Vector3.new(0, 0.5, -15),
	InitialColor = Color3.fromRGB(255, 255, 255),
	-- Segundos mínimos entre un cambio de color y el siguiente (evita spam al rozarla)
	Cooldown = 0.5,
}
