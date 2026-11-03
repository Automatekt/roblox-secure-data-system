--!strict
-- Modelo visual del cofre dorado, hecho solo con piezas (14). Sin modelos descargados.
-- Solo se crea en el cliente del dueño: los demás jugadores nunca lo reciben.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)

local ChestVisual = {}

local function newPart(
	model: Model,
	name: string,
	size: Vector3,
	offset: Vector3,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = model
	return part
end

-- Devuelve el cofre centrado en el origen. PrimaryPart es el cuerpo y "Aura" la esfera de brillo.
function ChestVisual.build(): Model
	local model = Instance.new("Model")
	model.Name = "ChestVisual"

	local wood = Palette.StoneDark:Lerp(Palette.Amber, 0.2)
	local gold = Palette.Gold
	local cylinder = Enum.PartType.Cylinder

	-- Cuerpo y tapa redondeada
	local body = newPart(model, "Body", Vector3.new(3, 1.6, 2), Vector3.zero, wood, Enum.Material.WoodPlanks)
	newPart(model, "Lid", Vector3.new(3, 2, 2), Vector3.new(0, 0.8, 0), wood, Enum.Material.WoodPlanks, cylinder)

	-- Bandas de oro alrededor del cuerpo y de la tapa
	for _, side in { -1, 1 } do
		newPart(model, "BodyBand", Vector3.new(0.3, 1.64, 2.08), Vector3.new(side * 0.9, 0, 0), gold, Enum.Material.Metal)
		newPart(model, "LidBand", Vector3.new(0.3, 2.12, 2.12), Vector3.new(side * 0.9, 0.8, 0), gold, Enum.Material.Metal, cylinder)
	end

	-- Esquinas inferiores de oro
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			newPart(model, "Corner", Vector3.new(0.5, 0.5, 0.5), Vector3.new(x * 1.45, -0.75, z * 0.95), gold, Enum.Material.Metal)
		end
	end

	-- Cerradura con ojo de cerradura brillante, y una joya en la tapa
	newPart(model, "LockPlate", Vector3.new(0.6, 0.7, 0.12), Vector3.new(0, 0.35, 1.03), gold, Enum.Material.Metal)
	newPart(model, "Keyhole", Vector3.new(0.16, 0.3, 0.06), Vector3.new(0, 0.33, 1.1), Palette.Amber, Enum.Material.Neon)
	newPart(model, "Gem", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 1.95, 0), gold, Enum.Material.Neon, Enum.PartType.Ball)

	-- Aura dorada translúcida: con el bloom da el brillo suave
	local aura = newPart(model, "Aura", Vector3.new(3.8, 3.8, 3.8), Vector3.new(0, 0.5, 0), gold, Enum.Material.Neon, Enum.PartType.Ball)
	aura.Transparency = 0.9

	model.PrimaryPart = body
	return model
end

return ChestVisual
