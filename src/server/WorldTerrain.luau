--!strict
-- Terreno del mundo: un anillo de montañas rocosas lejanas que esconde el borde del
-- suelo, y el suelo mismo. Todo es Terrain o una sola pieza, para gastar muy poco.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)
local WorldLayout = require(script.Parent.WorldLayout)

local PI = math.pi

local GROUND_RADIUS = 260 -- el suelo es un disco, sin esquinas
local MOUNTAIN_RING_RADIUS = 225 -- las montañas cubren de 180 a 290 studs del centro
local MOUNTAIN_COUNT = 20

local WorldTerrain = {}

-- Colores del terreno: todos salen de la paleta
local function paintTerrain(terrain: Terrain)
	local grass = Palette.Moss:Lerp(Palette.Gold, 0.12)
	local rock = Palette.Stone
	local slate = Palette.StoneDark:Lerp(Palette.Stone, 0.55)
	terrain:SetMaterialColor(Enum.Material.Grass, grass)
	terrain:SetMaterialColor(Enum.Material.Rock, rock)
	terrain:SetMaterialColor(Enum.Material.Slate, slate)
	terrain:SetMaterialColor(Enum.Material.Limestone, Palette.Stone:Lerp(Palette.Parchment, 0.3)) -- cimas claras
end

-- Cada montaña son tres bultos de roca (cuerpo, cima y hombro al costado) y a veces una aguja.
-- Los vecinos se solapan, así que no quedan huecos por donde se vea el borde.
local function buildMountains(terrain: Terrain, rng: Random)
	for index = 0, MOUNTAIN_COUNT - 1 do
		local angle = index * 2 * PI / MOUNTAIN_COUNT + rng:NextNumber(-0.06, 0.06)
		local ring = MOUNTAIN_RING_RADIUS + rng:NextNumber(-12, 12)
		local cx, cz = MapParts.polar(ring, angle)

		-- Cuerpo
		local bodyRadius = rng:NextNumber(52, 62) -- grandes, para que ningún par de vecinos deje hueco
		local bodyY = bodyRadius * 0.15
		-- Variedad: algunos cuerpos de pizarra oscura y las cimas alternan caliza clara y pizarra
		local bodyMaterial = if rng:NextNumber() < 0.3 then Enum.Material.Slate else Enum.Material.Rock
		terrain:FillBall(Vector3.new(cx, bodyY, cz), bodyRadius, bodyMaterial)

		-- Cima: más chica y más alta, algo desplazada
		local peakRadius = bodyRadius * rng:NextNumber(0.5, 0.65)
		local px = cx + rng:NextNumber(-0.3, 0.3) * bodyRadius
		local pz = cz + rng:NextNumber(-0.3, 0.3) * bodyRadius
		local peakMaterial = if rng:NextNumber() < 0.5 then Enum.Material.Limestone else Enum.Material.Slate
		terrain:FillBall(Vector3.new(px, bodyY + bodyRadius * 0.55, pz), peakRadius, peakMaterial)

		-- A veces una aguja más alta sobre la cima, para romper la silueta redonda
		if rng:NextNumber() < 0.4 then
			local spire = peakRadius * 0.55
			terrain:FillBall(Vector3.new(px, bodyY + bodyRadius * 0.55 + peakRadius * 0.8, pz), spire, peakMaterial)
		end

		-- Hombro: un bulto bajo a un lado, sobre la línea del anillo
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local sx, sz = MapParts.polar(ring, angle + side * 0.16)
		terrain:FillBall(Vector3.new(sx, bodyRadius * 0.05, sz), bodyRadius * 0.7, Enum.Material.Rock)
	end
end

-- Lomas anchas y bajas: una bola de hierba casi enterrada. Algunas llevan una cima de roca.
local function buildMounds(terrain: Terrain, rng: Random)
	for _ = 1, 14 do
		local radius = rng:NextNumber(18, 34)
		local spot = WorldLayout.findSpot(rng, 72, 150, radius * 0.7, 4)
		if spot == nil then
			continue
		end
		terrain:FillBall(Vector3.new(spot.X, -radius * 0.72, spot.Z), radius, Enum.Material.Grass)
		WorldLayout.reserve(spot.X, spot.Z, radius * 0.7)
		if rng:NextNumber() < 0.3 then
			terrain:FillBall(Vector3.new(spot.X, -radius * 0.07, spot.Z), radius * 0.45, Enum.Material.Rock)
		end
	end
end

-- Cordilleras bajas: cuatro bultos seguidos en línea. La última es de roca viva.
local function buildRidges(terrain: Terrain, rng: Random)
	for index = 1, 3 do
		local spot = WorldLayout.findSpot(rng, 100, 165, 52, 4) -- cabe la cordillera entera (60 de largo y 20 de radio en las puntas)
		if spot == nil then
			continue
		end
		local direction = rng:NextNumber(0, PI)
		local along = Vector3.new(math.cos(direction), 0, math.sin(direction))
		local material = if index == 3 then Enum.Material.Rock else Enum.Material.Grass
		for link = -1.5, 1.5 do
			local radius = rng:NextNumber(14, 20)
			local center = spot + along * (link * 20)
			terrain:FillBall(Vector3.new(center.X, -radius * 0.5, center.Z), radius, material)
			WorldLayout.reserve(center.X, center.Z, radius)
		end
	end
end

-- Mesetas: un bloque de roca con la cima de hierba, para romper las siluetas redondas
local function buildMesas(terrain: Terrain, rng: Random)
	for _ = 1, 2 do
		local radius = rng:NextNumber(20, 25)
		local spot = WorldLayout.findSpot(rng, 115, 165, radius, 6)
		if spot == nil then
			continue
		end
		terrain:FillCylinder(CFrame.new(spot.X, 4, spot.Z), 14, radius, Enum.Material.Rock)
		terrain:FillCylinder(CFrame.new(spot.X, 11.5, spot.Z), 2, radius * 0.95, Enum.Material.Grass)
		WorldLayout.reserve(spot.X, spot.Z, radius)
	end
end

-- Rocas grandes medio enterradas. Son terreno, no piezas, así que no suman al conteo.
local function buildBoulders(terrain: Terrain, rng: Random)
	for _ = 1, 12 do
		local radius = rng:NextNumber(3, 6.5)
		local spot = WorldLayout.findSpot(rng, 36, 110, radius, 3)
		if spot == nil then
			continue
		end
		terrain:FillBall(Vector3.new(spot.X, radius * 0.35, spot.Z), radius, Enum.Material.Rock)
		WorldLayout.reserve(spot.X, spot.Z, radius * 1.6) -- incluye la roca pequeña de al lado
		if rng:NextNumber() < 0.4 then
			local small = radius * 0.55
			terrain:FillBall(Vector3.new(spot.X + radius * 0.9, small * 0.3, spot.Z + radius * 0.4), small, Enum.Material.Rock)
		end
	end
end

-- Suelo de hierba que rodea todo. Reemplaza al Baseplate de la plantilla de Studio.
local function buildGround(parent: Instance)
	local template = workspace:FindFirstChild("Baseplate")
	if template then
		template:Destroy()
	end
	local color = Palette.Moss:Lerp(Palette.Gold, 0.12) -- el mismo verde que la hierba del terreno
	-- Cilindro tumbado en vertical: 20 de grosor, con la cara de arriba en y = 0
	local ground = MapParts.newPart(
		parent,
		"Ground",
		Vector3.new(20, GROUND_RADIUS * 2, GROUND_RADIUS * 2),
		CFrame.new(0, -10, 0) * CFrame.Angles(0, 0, PI / 2),
		color,
		Enum.Material.Grass,
		true
	)
	ground.Shape = Enum.PartType.Cylinder
end

-- Borra el terreno anterior, pinta los materiales y levanta el mundo
function WorldTerrain.build(parent: Instance, rng: Random)
	local terrain = workspace.Terrain
	terrain:Clear()
	WorldLayout.clearReserved()
	paintTerrain(terrain)
	buildGround(parent)
	buildMountains(terrain, rng)
	buildMounds(terrain, rng)
	buildRidges(terrain, rng)
	buildMesas(terrain, rng)
	buildBoulders(terrain, rng)
end

return WorldTerrain
