--!strict
-- Dónde está cada cosa grande del mundo: la plaza, el camino y las ruinas lejanas.
-- El terreno y los adornos preguntan aquí para no taparlos ni plantarse encima.

local WorldLayout = {}

WorldLayout.PlazaRadius = 31 -- la plaza llega a 30; un margen
WorldLayout.PathStartZ = 30
WorldLayout.PathEndZ = 165
WorldLayout.PathWidth = 7

local PATH_STRAIGHT_UNTIL = 56 -- hasta aquí el camino sigue recto desde el arco de entrada
local PATH_SWAY = 16 -- cuánto se curva a cada lado
local PATH_WAVE = 32 -- largo de cada curva

-- Sitios reservados para ruinas lejanas: x, z y radio libre alrededor
WorldLayout.RuinSpots = {
	{ x = 61, z = -103, radius = 22 },
	{ x = -120, z = 90, radius = 18 },
}

-- Círculos fijos que tampoco deben pisarse: los dos arcos de la plaza (z = 38 y z = -38)
local FIXED_SPOTS = {
	{ x = 0, z = 38, radius = 9 },
	{ x = 0, z = -38, radius = 9 },
}

-- Bultos de terreno ya colocados (lomas, cordilleras, mesetas, rocas). WorldTerrain los
-- anota aquí para que los árboles y muros no queden enterrados dentro de ellos.
local reserved: { { x: number, z: number, radius: number } } = {}

-- Vacía la lista de bultos reservados (al reconstruir el mapa)
function WorldLayout.clearReserved()
	table.clear(reserved)
end

-- Anota un bulto de terreno de "radius" studs centrado en (x, z)
function WorldLayout.reserve(x: number, z: number, radius: number)
	table.insert(reserved, { x = x, z = z, radius = radius })
end

-- Posición lateral del centro del camino a la altura z (el camino va hacia +z)
function WorldLayout.pathX(z: number): number
	local travelled = math.max(0, z - PATH_STRAIGHT_UNTIL)
	return PATH_SWAY * math.sin(travelled / PATH_WAVE) * math.min(1, travelled / 40)
end

-- Distancia aproximada de un punto al camino
function WorldLayout.distanceToPath(x: number, z: number): number
	local clampedZ = math.clamp(z, WorldLayout.PathStartZ, WorldLayout.PathEndZ)
	local dx = (x - WorldLayout.pathX(clampedZ)) * 0.9 -- el camino va algo inclinado
	local dz = z - clampedZ
	return math.sqrt(dx * dx + dz * dz)
end

-- Comprueba que un adorno circular de "radius" studs en (x, z) no pisa la plaza,
-- el camino ni una ruina lejana. "margin" es el aire que se deja alrededor.
function WorldLayout.isFree(x: number, z: number, radius: number, margin: number): boolean
	local gap = radius + margin
	if math.sqrt(x * x + z * z) < WorldLayout.PlazaRadius + gap then
		return false
	end
	if WorldLayout.distanceToPath(x, z) < WorldLayout.PathWidth / 2 + gap then
		return false
	end
	for _, list in { WorldLayout.RuinSpots, FIXED_SPOTS, reserved } do
		for _, spot in list do
			local dx = x - spot.x
			local dz = z - spot.z
			if math.sqrt(dx * dx + dz * dz) < spot.radius + gap then
				return false
			end
		end
	end
	return true
end

-- Busca un sitio libre entre dos radios del centro (hasta 12 intentos al azar).
-- Devuelve nil si no encuentra ninguno; quien llama simplemente se salta ese adorno.
function WorldLayout.findSpot(rng: Random, minRadius: number, maxRadius: number, footprint: number, margin: number): Vector3?
	for _ = 1, 12 do
		local radius = rng:NextNumber(minRadius, maxRadius)
		local angle = rng:NextNumber(0, 2 * math.pi)
		local x = radius * math.cos(angle)
		local z = radius * math.sin(angle)
		if WorldLayout.isFree(x, z, footprint, margin) then
			return Vector3.new(x, 0, z)
		end
	end
	return nil
end

return WorldLayout
