--!strict
-- Íconos dibujados con elementos de interfaz (marcos redondeados y degradados).
-- Sin imágenes subidas ni descargadas: todo sale de la paleta del proyecto.
-- Cada ícono se construye dentro de un marco cuadrado y escala con su tamaño.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)

local HudIcons = {}

local function box(
	parent: Instance,
	x: number,
	y: number,
	width: number,
	height: number,
	color: Color3,
	radius: number?
): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(x, y)
	frame.Size = UDim2.fromScale(width, height)
	if radius then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(radius, 0)
		corner.Parent = frame
	end
	frame.Parent = parent
	return frame
end

local function gradient(frame: Instance, top: Color3, bottom: Color3, rotation: number)
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new(top, bottom)
	uiGradient.Rotation = rotation
	uiGradient.Parent = frame
end

local function stroke(frame: Instance, color: Color3, thickness: number, transparency: number?)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color
	uiStroke.Thickness = thickness
	uiStroke.Transparency = transparency or 0
	uiStroke.Parent = frame
end

-- Contenedor girado 45 grados para íconos en diagonal (espada, llave, gema)
local function diagonal(parent: Instance, scale: number): Frame
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(scale, scale)
	holder.Rotation = 45
	holder.Parent = parent
	return holder
end

local function coin(parent: Instance)
	local darkGold = Palette.Amber:Lerp(Palette.StoneDark, 0.45)
	local outer = box(parent, 0, 0, 1, 1, Palette.Gold, 0.5)
	gradient(outer, Palette.Gold:Lerp(Palette.Parchment, 0.3), Palette.Gold:Lerp(Palette.Amber, 0.35), 90)
	stroke(outer, darkGold, 1.5)

	local ring = box(parent, 0.2, 0.2, 0.6, 0.6, Palette.Gold, 0.5)
	ring.BackgroundTransparency = 1
	stroke(ring, darkGold, 1.5, 0.35)

	local shine = box(parent, 0.27, 0.2, 0.2, 0.1, Palette.Parchment, 0.5)
	shine.BackgroundTransparency = 0.45
	shine.Rotation = -35
end

local function potion(parent: Instance)
	local glass = Palette.Parchment
	local body = box(parent, 0.1, 0.34, 0.8, 0.64, Palette.Amber, 0.5)
	gradient(body, Palette.Gold, Palette.Amber:Lerp(Palette.StoneDark, 0.2), 90)
	stroke(body, glass, 1.5, 0.3)

	local neck = box(parent, 0.36, 0.1, 0.28, 0.34, glass, 0.15)
	neck.BackgroundTransparency = 0.45
	stroke(neck, glass, 1.2, 0.4)

	box(parent, 0.31, 0, 0.38, 0.15, Palette.Gold:Lerp(Palette.StoneDark, 0.5), 0.3)

	local shine = box(parent, 0.24, 0.52, 0.14, 0.22, glass, 0.5)
	shine.BackgroundTransparency = 0.5
end

local function sword(parent: Instance)
	local holder = diagonal(parent, 0.95)
	local blade = box(holder, 0.43, 0, 0.14, 0.64, Palette.Parchment:Lerp(Palette.Stone, 0.2), 0.25)
	gradient(blade, Palette.Parchment, Palette.Stone, 0)
	box(holder, 0.2, 0.62, 0.6, 0.1, Palette.Gold, 0.3)
	box(holder, 0.44, 0.7, 0.12, 0.2, Palette.Amber:Lerp(Palette.StoneDark, 0.55), 0.2)
	box(holder, 0.4, 0.88, 0.2, 0.12, Palette.Gold, 0.5)
end

local function gem(parent: Instance)
	local holder = diagonal(parent, 1)
	local crystal = box(holder, 0.2, 0.2, 0.6, 0.6, Palette.Moss, 0.14)
	gradient(crystal, Palette.Moss:Lerp(Palette.Parchment, 0.4), Palette.Moss:Lerp(Color3.new(0, 0, 0), 0.25), 45)
	stroke(crystal, Palette.Gold, 1.5)

	local facet = box(holder, 0.33, 0.33, 0.22, 0.22, Palette.Parchment, 0.12)
	facet.BackgroundTransparency = 0.55
end

local function key(parent: Instance)
	local holder = diagonal(parent, 0.95)
	local ring = box(holder, 0.28, 0, 0.44, 0.44, Palette.Gold, 0.5)
	ring.BackgroundTransparency = 1
	stroke(ring, Palette.Gold, 2.5)

	box(holder, 0.45, 0.4, 0.1, 0.58, Palette.Gold, 0.2)
	box(holder, 0.55, 0.68, 0.22, 0.09, Palette.Gold, 0.2)
	box(holder, 0.55, 0.85, 0.17, 0.09, Palette.Gold, 0.2)
end

local BUILDERS: { [string]: (Instance) -> () } = {
	Coin = coin,
	HealthPotion = potion,
	Sword = sword,
	Gem = gem,
	Key = key,
}

-- Crea el ícono de "Coin" o de un objeto del catálogo. Devuelve nil si no existe.
function HudIcons.create(name: string, size: number, parent: Instance): Frame?
	local builder = BUILDERS[name]
	if builder == nil then
		return nil
	end
	local holder = Instance.new("Frame")
	holder.Name = name .. "Icon"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(size, size)
	builder(holder)
	holder.Parent = parent
	return holder
end

return HudIcons
