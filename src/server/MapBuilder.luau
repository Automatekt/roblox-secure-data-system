--!strict
-- Construye la escena: un claro de ruinas antiguas al atardecer.
-- Todo es código (piezas y terreno propios), sin modelos descargados.
-- Presupuesto de rendimiento: unas 210 piezas ancladas, 8 luces sin sombras. El terreno
-- (montañas, lomas, rocas) no cuenta como piezas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)
local ChestPoints = require(script.Parent.ChestPoints)
local Landmarks = require(script.Parent.Landmarks)
local Ruins = require(script.Parent.Ruins)
local WorldLayout = require(script.Parent.WorldLayout)
local WorldTerrain = require(script.Parent.WorldTerrain)

local SEED = 20261103 -- misma escena en cada servidor
local PI = math.pi

-- Medidas principales (studs). El centro de la plaza es el origen (0, 0, 0).
local STEP_RADII = { 30, 28.8, 27.6 } -- tres escalones concéntricos
local STEP_TOPS = { 0.4, 0.8, 1.2 }
local PLAZA_TOP = 1.2 -- altura del suelo de la plaza
local PILLAR_RADIUS = 22
local TORCH_RADIUS = 17.5
local SPAWN_POSITION = Vector3.new(0, 0.5, 50)

local PILLAR_BROKEN_HEIGHTS = { [1] = 11, [2] = 5, [3] = 11, [4] = 8, [5] = 11, [6] = 4, [7] = 11, [8] = 7 }

local newPart = MapParts.newPart
local newColumn = MapParts.newColumn
local newBall = MapParts.newBall
local newFolder = MapParts.newFolder
local stoneColor = MapParts.stoneColor
local mossColor = MapParts.mossColor
local polar = MapParts.polar

local MapBuilder = {}

-- Plaza circular con tres escalones y un emblema dorado en el centro
local function buildPlaza(parent: Instance)
	for index, radius in STEP_RADII do
		local top = STEP_TOPS[index]
		local cframe = CFrame.new(0, top / 2, 0) * CFrame.Angles(0, 0, PI / 2)
		local color = if index == 3 then Palette.Stone else Palette.Stone:Lerp(Palette.StoneDark, 0.25 * (3 - index))
		local material = if index == 3 then Enum.Material.Cobblestone else Enum.Material.Slate
		local step = newPart(parent, "PlazaStep" .. index, Vector3.new(top, radius * 2, radius * 2), cframe, color, material, true)
		step.Shape = Enum.PartType.Cylinder
	end

	-- Estrado central y emblema de oro
	newColumn(parent, "Dais", 0, 0, 0, PLAZA_TOP + 0.8, 12, Palette.StoneDark, Enum.Material.Slate, true)
	newColumn(parent, "Emblem", 0, PLAZA_TOP + 0.8, 0, 0.1, 6.4, Palette.Gold, Enum.Material.Metal, false)
end

local function buildPillars(parent: Instance, rng: Random)
	for index = 1, 8 do
		local angle = (index - 1) * PI / 4
		local x, z = polar(PILLAR_RADIUS, angle)
		local height = PILLAR_BROKEN_HEIGHTS[index]
		local intact = height >= 10
		Ruins.pillar(parent, rng, x, z, PLAZA_TOP, if intact then height - 1.9 else height - 1, if intact then "Capital" else "Broken")

		-- Los pilares rotos dejan un trozo de columna caído al lado
		if not intact then
			-- Bien pegado a su pilar: lejos de los puntos del cofre, que quedan entre pilares
			local fx, fz = polar(PILLAR_RADIUS + 3.5, angle + 0.1)
			local lying = CFrame.new(fx, PLAZA_TOP + 1.3, fz) * CFrame.Angles(0, rng:NextNumber(0, PI), 0)
			local piece = newPart(parent, "FallenColumn", Vector3.new(4.5, 2.6, 2.6), lying, stoneColor(rng, 0.35), Enum.Material.Limestone, false)
			piece.Shape = Enum.PartType.Cylinder
		end
	end
end

local function addFlame(flame: Part)
	local fire = Instance.new("ParticleEmitter")
	fire.Name = "Flame"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Color = ColorSequence.new(Palette.Gold, Palette.Amber)
	fire.LightEmission = 1
	fire.Lifetime = NumberRange.new(0.5, 0.9)
	fire.Rate = 14
	fire.Speed = NumberRange.new(1, 2)
	fire.SpreadAngle = Vector2.new(8, 8)
	fire.Acceleration = Vector3.new(0, 3, 0)
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) })
	fire.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	fire.Parent = flame

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Color = ColorSequence.new(Palette.Gold)
	embers.LightEmission = 1
	embers.Lifetime = NumberRange.new(1.2, 2)
	embers.Rate = 3
	embers.Speed = NumberRange.new(2, 4)
	embers.SpreadAngle = Vector2.new(25, 25)
	embers.Acceleration = Vector3.new(0, 2, 0)
	embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	embers.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	embers.Parent = flame

	local light = Instance.new("PointLight")
	light.Color = Palette.Amber:Lerp(Palette.Gold, 0.3)
	light.Range = 22
	light.Brightness = 1.6
	light.Shadows = false -- las sombras de las luces pesan mucho en celular
	light.Parent = flame
end

local function buildTorches(parent: Instance)
	for index = 0, 7 do
		local x, z = polar(TORCH_RADIUS, PI / 8 + index * PI / 4)
		local post = newColumn(parent, "TorchPost", x, PLAZA_TOP, z, 4.5, 0.5, Palette.StoneDark, Enum.Material.Wood, true)
		post.CanCollide = false
		newColumn(parent, "TorchBowl", x, PLAZA_TOP + 4.5, z, 0.5, 1.6, Palette.StoneDark, Enum.Material.Slate, false)
		local flame = newBall(parent, "TorchFlame", Vector3.new(x, PLAZA_TOP + 5.3, z), 0.9, Palette.Amber, Enum.Material.Neon, false)
		addFlame(flame)
	end
end

local function buildVegetation(parent: Instance, rng: Random)
	-- Un arbusto junto a cada pilar
	for index = 0, 7 do
		-- Al otro lado del tronco caído, pegado al pilar y lejos de los puntos del cofre
		local x, z = polar(PILLAR_RADIUS + 2.6, index * PI / 4 - 0.1)
		local size = rng:NextNumber(2.4, 3.6)
		newBall(parent, "Bush", Vector3.new(x, PLAZA_TOP + size * 0.3, z), size, mossColor(rng), Enum.Material.Grass, false)
	end

	-- Arbustos sueltos fuera de la plaza
	local placed = 0
	while placed < 12 do
		local angle = rng:NextNumber(0, 2 * PI)
		local radius = rng:NextNumber(33, 52)
		local x, z = polar(radius, angle)
		-- Fuera del camino de entrada (WorldLayout sabe por dónde pasa)
		if WorldLayout.isFree(x, z, 2.5, 0.5) then
			local size = rng:NextNumber(2.5, 4.5)
			newBall(parent, "Bush", Vector3.new(x, size * 0.3, z), size, mossColor(rng), Enum.Material.Grass, false)
			placed += 1
		end
	end
end

-- Piedras sueltas alrededor de los pilares y los arcos. Ninguna cae encima de un punto
-- donde puede aparecer el cofre.
local function buildRubble(parent: Instance, rng: Random)
	local placed = 0
	while placed < 14 do
		local angle = rng:NextNumber(0, 2 * PI)
		local radius = rng:NextNumber(19, 27)
		local x, z = polar(radius, angle)
		if not ChestPoints.isNearCandidate(x, z, 3.2) then
			local size = Vector3.new(rng:NextNumber(0.8, 1.6), rng:NextNumber(0.5, 1), rng:NextNumber(0.8, 1.6))
			local cframe = CFrame.new(x, PLAZA_TOP + size.Y / 2, z)
				* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, PI), rng:NextNumber(-0.2, 0.2))
			newPart(parent, "Rubble", size, cframe, stoneColor(rng, 0.45), Enum.Material.Slate, false)
			placed += 1
		end
	end
end

-- Punto de aparición de los jugadores: fuera de la plaza, mirando al arco
local function buildSpawn(parent: Instance)
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy() -- el de la plantilla de Studio, que está en el centro
		end
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = SPAWN_POSITION
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Palette.StoneDark
	spawn.Material = Enum.Material.Slate
	spawn.Parent = parent
end

-- Construye toda la escena y devuelve la carpeta que la contiene
function MapBuilder.build(): Folder
	local previous = workspace:FindFirstChild("Map")
	if previous then
		previous:Destroy()
	end

	local rng = Random.new(SEED)
	local map = Instance.new("Folder")
	map.Name = "Map"

	WorldTerrain.build(map, Random.new(SEED + 1))
	buildPlaza(newFolder(map, "Plaza"))
	buildPillars(newFolder(map, "Pillars"), rng)
	local arches = newFolder(map, "Arches")
	Ruins.arch(arches, rng, 0, 38, 0, false) -- arco de entrada, entero
	Ruins.arch(arches, rng, 0, -38, 0, true) -- arco del fondo, roto
	buildTorches(newFolder(map, "Torches"))
	buildVegetation(newFolder(map, "Vegetation"), rng)
	buildRubble(newFolder(map, "Rubble"), rng)
	Landmarks.build(newFolder(map, "Landmarks"), Random.new(SEED + 2))
	buildSpawn(map)

	map.Parent = workspace
	return map
end

return MapBuilder
