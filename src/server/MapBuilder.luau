--!strict
-- Construye la escena: un claro de ruinas antiguas al atardecer.
-- Todo es código (piezas y terreno propios), sin modelos descargados.
-- Presupuesto de rendimiento: unas 200 piezas ancladas, 8 luces sin sombras.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)

local SEED = 20261103 -- misma escena en cada servidor
local PI = math.pi

-- Medidas principales (studs). El centro de la plaza es el origen (0, 0, 0).
local STEP_RADII = { 30, 28.8, 27.6 } -- tres escalones concéntricos
local STEP_TOPS = { 0.4, 0.8, 1.2 }
local PLAZA_TOP = 1.2 -- altura del suelo de la plaza
local PILLAR_RADIUS = 22
local TORCH_RADIUS = 17.5
local HILL_RING_RADIUS = 85
local HILL_COUNT = 12
local SPAWN_POSITION = Vector3.new(0, 0.5, 50)

local PILLAR_BROKEN_HEIGHTS = { [1] = 11, [2] = 5, [3] = 11, [4] = 8, [5] = 11, [6] = 4, [7] = 11, [8] = 7 }

local MapBuilder = {}

local function newPart(
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
local function newColumn(
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
	local part = newPart(parent, name, Vector3.new(height, diameter, diameter), cframe, color, material, solid)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local function newBall(
	parent: Instance,
	name: string,
	position: Vector3,
	diameter: number,
	color: Color3,
	material: Enum.Material,
	solid: boolean
): Part
	local part = newPart(
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

local function newFolder(parent: Instance, name: string): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function stoneColor(rng: Random, amount: number): Color3
	return Palette.Stone:Lerp(Palette.StoneDark, rng:NextNumber() * amount)
end

local function mossColor(rng: Random): Color3
	return Palette.Moss:Lerp(Color3.new(0, 0, 0), rng:NextNumber() * 0.3)
end

local function polar(radius: number, angle: number): (number, number)
	return radius * math.cos(angle), radius * math.sin(angle)
end

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

type PillarFinish = "Capital" | "Broken" | "Flat"

-- Pilar de piedra: base, columna y un remate (capitel, punta rota o plano)
local function buildPillar(
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

local function buildPillars(parent: Instance, rng: Random)
	for index = 1, 8 do
		local angle = (index - 1) * PI / 4
		local x, z = polar(PILLAR_RADIUS, angle)
		local height = PILLAR_BROKEN_HEIGHTS[index]
		local intact = height >= 10
		buildPillar(parent, rng, x, z, PLAZA_TOP, if intact then height - 1.9 else height - 1, if intact then "Capital" else "Broken")

		-- Los pilares rotos dejan un trozo de columna caído al lado
		if not intact then
			local fx, fz = polar(PILLAR_RADIUS + 3.5, angle + 0.25)
			local lying = CFrame.new(fx, PLAZA_TOP + 1.3, fz) * CFrame.Angles(0, rng:NextNumber(0, PI), 0)
			local piece = newPart(parent, "FallenColumn", Vector3.new(4.5, 2.6, 2.6), lying, stoneColor(rng, 0.35), Enum.Material.Limestone, false)
			piece.Shape = Enum.PartType.Cylinder
		end
	end
end

-- Arco de medio punto sobre dos pilares. Si es roto, le faltan las últimas piezas.
local function buildArch(parent: Instance, rng: Random, x: number, z: number, yaw: number, broken: boolean)
	local pivot = CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0)
	local radius = 5.5
	local centerY = 8.45 -- los bloques empiezan justo encima de los pilares (altura 7)

	for _, side in { -1, 1 } do
		local pillarPos = (pivot * CFrame.new(side * radius, 0, 0)).Position
		buildPillar(parent, rng, pillarPos.X, pillarPos.Z, 0, 6, "Flat")
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
		local x, z = polar(PILLAR_RADIUS + 2.6, index * PI / 4 - 0.35)
		local size = rng:NextNumber(2.4, 3.6)
		newBall(parent, "Bush", Vector3.new(x, PLAZA_TOP + size * 0.3, z), size, mossColor(rng), Enum.Material.Grass, false)
	end

	-- Arbustos sueltos fuera de la plaza, sin tapar el camino de entrada
	local placed = 0
	while placed < 12 do
		local angle = rng:NextNumber(0, 2 * PI)
		local radius = rng:NextNumber(33, 52)
		local x, z = polar(radius, angle)
		if math.abs(x) > 8 then
			local size = rng:NextNumber(2.5, 4.5)
			newBall(parent, "Bush", Vector3.new(x, size * 0.3, z), size, mossColor(rng), Enum.Material.Grass, false)
			placed += 1
		end
	end

	-- Árboles estilizados en el borde del claro
	local treeAngles = { 0.5, 1.1, 2.0, 2.7, 3.7, 4.4, 5.5 }
	for _, angle in treeAngles do
		local radius = rng:NextNumber(46, 58)
		local x, z = polar(radius, angle)
		local trunkColor = Palette.StoneDark:Lerp(Palette.Amber, 0.15)
		newColumn(parent, "TreeTrunk", x, 0, z, 6, 1.3, trunkColor, Enum.Material.Wood, true)
		for blob = 1, 3 do
			local size = rng:NextNumber(5.5, 8)
			local offset = Vector3.new(rng:NextNumber(-2, 2), 6 + blob * 0.9, rng:NextNumber(-2, 2))
			newBall(parent, "TreeLeaves", Vector3.new(x, 0, z) + offset, size, mossColor(rng), Enum.Material.Grass, false)
		end
	end
end

-- Piedras sueltas alrededor de los pilares y los arcos
local function buildRubble(parent: Instance, rng: Random)
	for _ = 1, 14 do
		local angle = rng:NextNumber(0, 2 * PI)
		local radius = rng:NextNumber(19, 27)
		local x, z = polar(radius, angle)
		local size = Vector3.new(rng:NextNumber(0.8, 1.6), rng:NextNumber(0.5, 1), rng:NextNumber(0.8, 1.6))
		local cframe = CFrame.new(x, PLAZA_TOP + size.Y / 2, z)
			* CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, PI), rng:NextNumber(-0.2, 0.2))
		newPart(parent, "Rubble", size, cframe, stoneColor(rng, 0.45), Enum.Material.Slate, false)
	end
end

-- Colinas de terreno que cierran el claro y ocultan el borde del mundo
local function buildHills(rng: Random)
	local terrain = workspace.Terrain
	terrain:Clear()
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, Palette.Moss:Lerp(Color3.new(0, 0, 0), 0.15))
	end)
	for index = 0, HILL_COUNT - 1 do
		local angle = index * 2 * PI / HILL_COUNT + rng:NextNumber(-0.1, 0.1)
		local x, z = polar(HILL_RING_RADIUS + rng:NextNumber(-6, 6), angle)
		terrain:FillBall(Vector3.new(x, -6, z), rng:NextNumber(24, 30), Enum.Material.Grass)
	end
end

-- Suelo de hierba que rodea todo. Reemplaza al Baseplate de la plantilla de Studio.
local function buildGround(parent: Instance)
	local template = workspace:FindFirstChild("Baseplate")
	if template then
		template:Destroy()
	end
	local color = Palette.Moss:Lerp(Color3.new(0, 0, 0), 0.15)
	newPart(parent, "Ground", Vector3.new(512, 20, 512), CFrame.new(0, -10, 0), color, Enum.Material.Grass, true)
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

	buildGround(map)
	buildPlaza(newFolder(map, "Plaza"))
	buildPillars(newFolder(map, "Pillars"), rng)
	local arches = newFolder(map, "Arches")
	buildArch(arches, rng, 0, 38, 0, false) -- arco de entrada, entero
	buildArch(arches, rng, 0, -38, 0, true) -- arco del fondo, roto
	buildTorches(newFolder(map, "Torches"))
	buildVegetation(newFolder(map, "Vegetation"), rng)
	buildRubble(newFolder(map, "Rubble"), rng)
	buildSpawn(map)
	buildHills(rng)

	map.Parent = workspace
	return map
end

return MapBuilder
