--!strict
-- Adornos del exterior de la plaza: el camino de entrada, grupos de árboles retorcidos,
-- muros caídos y dos ruinas lejanas. Pocas piezas, todas fuera de la plaza y del camino.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)
local Ruins = require(script.Parent.Ruins)
local WorldLayout = require(script.Parent.WorldLayout)

local PI = math.pi

local PATH_STEP = 6.5 -- largo de cada tramo de camino
local PATH_THICKNESS = 0.2
local GROVE_COUNT = 3
local TREES_PER_GROVE = 3
local WALL_COUNT = 8

local newPart = MapParts.newPart
local newBeam = MapParts.newBeam
local newBall = MapParts.newBall
local stoneColor = MapParts.stoneColor

local Landmarks = {}

-- Camino de tierra desde el arco de entrada hacia el horizonte, con curvas suaves.
-- Son tramos planos pegados al suelo; no chocan, así que no estorban a nadie.
local function buildPath(parent: Instance, rng: Random)
	local dirt = Palette.StoneDark:Lerp(Palette.Amber, 0.22)
	local width = WorldLayout.PathWidth

	local z = WorldLayout.PathStartZ + 0.5
	local layer = 0 -- cada tramo un poquito más alto que el anterior: sin parpadeo donde se solapan
	while z < WorldLayout.PathEndZ do
		layer += 1
		local nextZ = math.min(z + PATH_STEP, WorldLayout.PathEndZ)
		local height = PATH_THICKNESS / 2 + layer * 0.002
		local from = Vector3.new(WorldLayout.pathX(z), height, z)
		local to = Vector3.new(WorldLayout.pathX(nextZ), height, nextZ)
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
		local cframe = CFrame.new(centerX + offset, size.Y / 2 - 0.1, stoneZ) * CFrame.Angles(0, rng:NextNumber(0, PI), 0)
		newPart(parent, "PathStone", size, cframe, stoneColor(rng, 0.5), Enum.Material.Slate, false)
		side = -side
	end
end

-- Árbol retorcido: el tronco se quiebra a media altura y cambia de dirección.
-- Los vivos llevan dos copas; los secos, dos ramas peladas. Cuatro piezas cada uno.
local function buildTree(parent: Instance, rng: Random, x: number, z: number, dead: boolean)
	local trunkColor = Palette.StoneDark:Lerp(Palette.Amber, 0.15)
	local lean = rng:NextNumber(0, 2 * PI)
	local lx, lz = math.cos(lean), math.sin(lean)

	local base = Vector3.new(x, -0.3, z)
	local knee = base + Vector3.new(lx * 1.6, 4.6, lz * 1.6)
	local top = knee + Vector3.new(-lx * 1.2 + rng:NextNumber(-0.6, 0.6), rng:NextNumber(4, 5.5), -lz * 1.2 + rng:NextNumber(-0.6, 0.6))
	newBeam(parent, "TreeTrunk", base, knee, 1.6, trunkColor, Enum.Material.Wood, true)
	newBeam(parent, "TreeTrunk", knee, top, 1.1, trunkColor, Enum.Material.Wood, true)

	if dead then
		newBeam(parent, "TreeBranch", top - Vector3.new(0, 1.2, 0), top + Vector3.new(lz * 3.4, 2.2, -lx * 3.4), 0.5, trunkColor, Enum.Material.Wood, false)
		newBeam(parent, "TreeBranch", top - Vector3.new(0, 0.4, 0), top + Vector3.new(-lz * 2.6, 2.8, lx * 2.6), 0.4, trunkColor, Enum.Material.Wood, false)
		return
	end

	-- Hojas de musgo, con algo de ámbar para que no sea todo el mismo verde
	local function leafColor(): Color3
		return Palette.Moss:Lerp(Palette.Amber, rng:NextNumber(0, 0.3)):Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.2))
	end
	newBall(parent, "TreeLeaves", top + Vector3.new(0, 2, 0), rng:NextNumber(5, 7), leafColor(), Enum.Material.Grass, false)
	newBall(parent, "TreeLeaves", top + Vector3.new(lx * 2.4, 0.4, lz * 2.4), rng:NextNumber(4, 5.5), leafColor(), Enum.Material.Grass, false)
end

-- Grupos pequeños de árboles, a mitad de camino entre la plaza y las montañas
local function buildGroves(parent: Instance, rng: Random)
	for _ = 1, GROVE_COUNT do
		local center = WorldLayout.findSpot(rng, 55, 100, 9, 3)
		if center == nil then
			continue
		end
		local deadIndex = rng:NextInteger(1, TREES_PER_GROVE)
		for tree = 1, TREES_PER_GROVE do
			local offsetAngle = rng:NextNumber(0, 2 * PI)
			local offsetRadius = rng:NextNumber(0, 6)
			buildTree(
				parent,
				rng,
				center.X + math.cos(offsetAngle) * offsetRadius,
				center.Z + math.sin(offsetAngle) * offsetRadius,
				tree == deadIndex
			)
		end
	end
end

-- Trozos de muro caídos, algo hundidos en el suelo y ladeados
local function buildWalls(parent: Instance, rng: Random)
	for _ = 1, WALL_COUNT do
		local spot = WorldLayout.findSpot(rng, 38, 110, 5, 3)
		if spot == nil then
			continue
		end
		local size = Vector3.new(rng:NextNumber(5, 9), rng:NextNumber(2.4, 4), 1.6)
		local cframe = CFrame.new(spot.X, size.Y / 2 - 0.4, spot.Z)
			* CFrame.Angles(0, rng:NextNumber(0, PI), rng:NextNumber(-0.12, 0.12))
		newPart(parent, "FallenWall", size, cframe, stoneColor(rng, 0.4), Enum.Material.Limestone, true)
	end
end

-- Un par de bloques sueltos en el suelo, junto a una ruina
local function scatterBlocks(parent: Instance, rng: Random, center: Vector3, spread: number)
	for _ = 1, 3 do
		local size = Vector3.new(rng:NextNumber(1.8, 2.8), rng:NextNumber(1.2, 2), rng:NextNumber(1.8, 2.8))
		local offset = Vector3.new(rng:NextNumber(-spread, spread), size.Y / 2 - 0.3, rng:NextNumber(-spread, spread))
		local cframe = CFrame.new(center + offset)
			* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, PI), rng:NextNumber(-0.2, 0.2))
		newPart(parent, "RuinBlock", size, cframe, stoneColor(rng, 0.4), Enum.Material.Limestone, false)
	end
end

-- Ruina lejana 1: dos pilares y tres muros derruidos que forman un rincón abierto
local function buildFarHall(parent: Instance, rng: Random, spot: { x: number, z: number, radius: number })
	local center = Vector3.new(spot.x, 0, spot.z)
	-- Mirando hacia la plaza, para que se vea de frente desde la entrada
	local pivot = CFrame.lookAt(center, Vector3.zero)

	local left = (pivot * CFrame.new(-7, 0, 0)).Position
	local right = (pivot * CFrame.new(7, 0, 0)).Position
	Ruins.pillar(parent, rng, left.X, left.Z, 0, 8, "Capital")
	Ruins.pillar(parent, rng, right.X, right.Z, 0, 4, "Broken")

	local color = stoneColor(rng, 0.35)
	newPart(parent, "HallWall", Vector3.new(15, 7, 1.6), pivot * CFrame.new(0, 3.2, 7), color, Enum.Material.Limestone, true)
	newPart(parent, "HallWall", Vector3.new(9, 4.2, 1.6), pivot * CFrame.new(-8.5, 1.9, 3) * CFrame.Angles(0, PI / 2, 0), color, Enum.Material.Limestone, true)
	newPart(parent, "HallWall", Vector3.new(7, 2.6, 1.6), pivot * CFrame.new(8.5, 1.1, 3) * CFrame.Angles(0, PI / 2, 0), color, Enum.Material.Limestone, true)
	scatterBlocks(parent, rng, center, 9)
end

-- Ruina lejana 2: un arco roto solo, con bloques caídos
local function buildFarArch(parent: Instance, rng: Random, spot: { x: number, z: number, radius: number })
	local yaw = math.atan2(-spot.x, -spot.z) -- la abertura del arco mira hacia la plaza
	Ruins.arch(parent, rng, spot.x, spot.z, yaw, true)
	scatterBlocks(parent, rng, Vector3.new(spot.x, 0, spot.z), 8)
end

-- Construye todos los adornos del exterior dentro de "parent"
function Landmarks.build(parent: Instance, rng: Random)
	buildPath(MapParts.newFolder(parent, "Path"), rng)
	buildGroves(MapParts.newFolder(parent, "Groves"), rng)
	buildWalls(MapParts.newFolder(parent, "Walls"), rng)

	local ruinsFolder = MapParts.newFolder(parent, "FarRuins")
	buildFarHall(ruinsFolder, rng, WorldLayout.RuinSpots[1])
	buildFarArch(ruinsFolder, rng, WorldLayout.RuinSpots[2])
end

return Landmarks
