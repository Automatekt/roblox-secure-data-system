--!strict
-- Piezas básicas para construir el mapa: partes, columnas, bolas y colores de piedra y musgo.
-- Las comparten MapBuilder, Ruins y Landmarks para no repetir código.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)

local PI = math.pi

local MapParts = {}

function MapParts.newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if not solid then
		-- Las piezas decorativas no chocan ni gastan cálculo de sombras
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
	end
	part.Parent = parent
	return part
end

-- Cilindro de pie (la Part cilíndrica de Roblox se acuesta sobre el eje X)
function MapParts.newColumn(
	parent: Instance,
	name: string,
	x: number,
	baseY: number,
	z: number,
	height: number,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local cframe = CFrame.new(x, baseY + height / 2, z) * CFrame.Angles(0, 0, PI / 2)
	local part = MapParts.newPart(parent, name, Vector3.new(height, diameter, diameter), cframe, color, material, solid)
	part.Shape = Enum.PartType.Cylinder
	return part
end

-- Cilindro que va de un punto a otro (para troncos y ramas inclinados)
function MapParts.newBeam(
	parent: Instance,
	name: string,
	from: Vector3,
	to: Vector3,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local length = (to - from).Magnitude
	-- El eje del cilindro es X; lookAt apunta -Z, por eso el giro de 90 grados
	local cframe = CFrame.lookAt((from + to) / 2, to) * CFrame.Angles(0, PI / 2, 0)
	local part = MapParts.newPart(parent, name, Vector3.new(length, thickness, thickness), cframe, color, material, solid)
	part.Shape = Enum.PartType.Cylinder
	return part
end

function MapParts.newBall(
	parent: Instance,
	name: string,
	position: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local part = MapParts.newPart(
		parent,
		name,
		Vector3.new(diameter, diameter, diameter),
		CFrame.new(position),
		color,
		material,
		solid
	)
	part.Shape = Enum.PartType.Ball
	return part
end

function MapParts.newFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function MapParts.stoneColor(rng: Random, amount: number): Color3
	return Palette.Stone:Lerp(Palette.StoneDark, rng:NextNumber() * amount)
end

function MapParts.mossColor(rng: Random): Color3
	return Palette.Moss:Lerp(Color3.new(0, 0, 0), rng:NextNumber() * 0.3)
end

-- Punto a "radius" studs del centro del mapa, en el ángulo dado (radianes)
function MapParts.polar(radius: number, angle: number): (number, number)
	return radius * math.cos(angle), radius * math.sin(angle)
end

return MapParts
