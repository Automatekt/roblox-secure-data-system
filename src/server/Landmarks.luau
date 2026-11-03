--!strict
-- Adornos del exterior de la plaza: el camino de entrada y, más adelante, árboles,
-- muros caídos y ruinas lejanas. Pocas piezas, todas fuera de la plaza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)
local WorldLayout = require(script.Parent.WorldLayout)

local PATH_STEP = 6.5 -- largo de cada tramo de camino
local PATH_THICKNESS = 0.2

local newPart = MapParts.newPart

local Landmarks = {}

-- Camino de tierra desde el arco de entrada hacia el horizonte, con curvas suaves.
-- Son tramos planos pegados al suelo; no chocan, así que no estorban a nadie.
local function buildPath(parent: Instance, rng: Random)
	local dirt = Palette.StoneDark:Lerp(Palette.Amber, 0.22)
	local width = WorldLayout.PathWidth

	local z = WorldLayout.PathStartZ + 0.5
	while z < WorldLayout.PathEndZ do
		local nextZ = math.min(z + PATH_STEP, WorldLayout.PathEndZ)
		local from = Vector3.new(WorldLayout.pathX(z), PATH_THICKNESS / 2, z)
		local to = Vector3.new(WorldLayout.pathX(nextZ), PATH_THICKNESS / 2, nextZ)
		-- Un poco más largo que el paso para que los tramos se solapen en las curvas
		local length = (to - from).Magnitude + 0.8
		local color = dirt:Lerp(Palette.Stone, rng:NextNumber(0, 0.25))
		newPart(
			parent,
			"PathSegment",
			Vector3.new(width, PATH_THICKNESS, length),
			CFrame.lookAt((from + to) / 2, to),
			color,
			Enum.Material.Ground,
			false
		)
		z = nextZ
	end

	-- Piedras pequeñas a los lados, alternando, para que el camino no parezca una cinta
	local side = 1
	for stoneZ = 42, 160, 9 do
		local centerX = WorldLayout.pathX(stoneZ)
		local offset = side * (width / 2 + rng:NextNumber(0.4, 1.2))
		local size = Vector3.new(rng:NextNumber(1, 1.8), rng:NextNumber(0.6, 1.1), rng:NextNumber(1, 1.6))
		local cframe = CFrame.new(centerX + offset, size.Y / 2 - 0.1, stoneZ) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0)
		newPart(parent, "PathStone", size, cframe, MapParts.stoneColor(rng, 0.5), Enum.Material.Slate, false)
		side = -side
	end
end

-- Construye todos los adornos del exterior dentro de "parent"
function Landmarks.build(parent: Instance, rng: Random)
	buildPath(MapParts.newFolder(parent, "Path"), rng)
end

return Landmarks
