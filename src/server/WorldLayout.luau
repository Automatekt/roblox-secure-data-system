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
	for _, spot in WorldLayout.RuinSpots do
		local dx = x - spot.x
		local dz = z - spot.z
		if math.sqrt(dx * dx + dz * dz) < spot.radius + gap then
			return false
		end
	end
	return true
end

return WorldLayout
