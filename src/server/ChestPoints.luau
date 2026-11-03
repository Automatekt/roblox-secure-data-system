--!strict
-- Lista fija de puntos donde pueden aparecer los cofres.
-- Cada punto es el suelo donde se apoya el cofre. Al arrancar, el servidor
-- comprueba cada uno (hay suelo, hay espacio libre encima) y solo usa los válidos.

local Players = game:GetService("Players")

local FLOOR_Y = 1.2 -- altura del suelo de la plaza (ver MapBuilder)
local FLOOR_TOLERANCE = 0.3
local CLEARANCE = Vector3.new(4, 4, 4) -- espacio libre mínimo sobre el punto
local CLEARANCE_START = 0.5 -- el espacio libre empieza un poco por encima del suelo

-- Seis puntos en un anillo interior (radio 10) y ocho en uno exterior (radio 26),
-- repartidos entre los pilares y las antorchas.
local CANDIDATES: { Vector3 } = {
	Vector3.new(8.66, FLOOR_Y, 5),
	Vector3.new(0, FLOOR_Y, 10),
	Vector3.new(-8.66, FLOOR_Y, 5),
	Vector3.new(-8.66, FLOOR_Y, -5),
	Vector3.new(0, FLOOR_Y, -10),
	Vector3.new(8.66, FLOOR_Y, -5),
	Vector3.new(24.02, FLOOR_Y, 9.95),
	Vector3.new(9.95, FLOOR_Y, 24.02),
	Vector3.new(-9.95, FLOOR_Y, 24.02),
	Vector3.new(-24.02, FLOOR_Y, 9.95),
	Vector3.new(-24.02, FLOOR_Y, -9.95),
	Vector3.new(-9.95, FLOOR_Y, -24.02),
	Vector3.new(9.95, FLOOR_Y, -24.02),
	Vector3.new(24.02, FLOOR_Y, -9.95),
}

local validPoints: { Vector3 } = {}

local ChestPoints = {}

local function characterList(): { Instance }
	local list = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	return list
end

-- Comprueba todos los candidatos y guarda los válidos. Espera un cuadro para que
-- las piezas recién creadas ya existan para las consultas físicas.
function ChestPoints.validate(): { Vector3 }
	task.wait()

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = characterList()

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = characterList()

	local result: { Vector3 } = {}
	for index, point in CANDIDATES do
		-- Desde bien arriba hacia abajo: si algo tapa el punto (un arco, un árbol), la altura no coincide
		local hit = workspace:Raycast(Vector3.new(point.X, 40, point.Z), Vector3.new(0, -60, 0), rayParams)
		local hasFloor = hit ~= nil and math.abs(hit.Position.Y - point.Y) <= FLOOR_TOLERANCE

		local center = CFrame.new(point.X, point.Y + CLEARANCE_START + CLEARANCE.Y / 2, point.Z)
		local isFree = #workspace:GetPartBoundsInBox(center, CLEARANCE, overlapParams) == 0

		if hasFloor and isFree then
			table.insert(result, point)
		else
			warn(`[ChestPoints] punto {index} descartado (suelo: {hasFloor}, libre: {isFree})`)
		end
	end

	validPoints = result
	return result
end

-- Puntos válidos (vacío hasta que termine validate)
function ChestPoints.getAll(): { Vector3 }
	return validPoints
end

return ChestPoints
