--!strict
-- Pilares y arcos de piedra. Los usan la plaza y las ruinas lejanas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)

local PI = math.pi

local newPart = MapParts.newPart
local newColumn = MapParts.newColumn
local stoneColor = MapParts.stoneColor

export type PillarFinish = "Capital" | "Broken" | "Flat"

local Ruins = {}

-- Pilar de piedra: base, columna y un remate (capitel, punta rota o plano)
function Ruins.pillar(
	parent: Instance,
	rng: Random,
	x: number,
	z: number,
	groundY: number,
	columnHeight: number,
	finish: PillarFinish
)
	local baseColor = Palette.StoneDark:Lerp(Palette.Stone, 0.4)
	newPart(parent, "PillarBase", Vector3.new(4.2, 1, 4.2), CFrame.new(x, groundY + 0.5, z), baseColor, Enum.Material.Slate, true)

	local color = stoneColor(rng, 0.35)
	newColumn(parent, "PillarColumn", x, groundY + 1, z, columnHeight, 2.6, color, Enum.Material.Limestone, true)

	local topY = groundY + 1 + columnHeight
	if finish == "Capital" then
		newPart(parent, "PillarCapital", Vector3.new(3.6, 0.9, 3.6), CFrame.new(x, topY + 0.45, z), baseColor, Enum.Material.Slate, true)
	elseif finish == "Broken" then
		-- Punta rota: un trozo inclinado encima de la columna
		local tilt = CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, PI), rng:NextNumber(-0.2, 0.2))
		newPart(parent, "PillarBreak", Vector3.new(2.1, 0.9, 1.5), CFrame.new(x, topY + 0.2, z) * tilt, color, Enum.Material.Limestone, false)
	end
end

-- Arco de medio punto sobre dos pilares. Si es roto, le faltan las últimas piezas.
function Ruins.arch(parent: Instance, rng: Random, x: number, z: number, yaw: number, broken: boolean)
	local pivot = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	local radius = 5.5
	local centerY = 8.45 -- los bloques empiezan justo encima de los pilares (altura 7)

	for _, side in { -1, 1 } do
		local pillarPos = (pivot * CFrame.new(side * radius, 0, 0)).Position
		Ruins.pillar(parent, rng, pillarPos.X, pillarPos.Z, 0, 6, "Flat")
	end

	for step = 0, 6 do
		if broken and step >= 5 then
			continue
		end
		local theta = step * PI / 6
		local size = if step == 3 then Vector3.new(3.1, 2, 3.4) else Vector3.new(2.9, 1.6, 3.2)
		local cframe = pivot
			* CFrame.new(radius * math.cos(theta), centerY + radius * math.sin(theta), 0)
			* CFrame.Angles(0, 0, theta - PI / 2)
		newPart(parent, "ArchBlock", size, cframe, stoneColor(rng, 0.3), Enum.Material.Limestone, true)
	end
end

return Ruins
