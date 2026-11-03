--!strict
-- Terreno del mundo: un anillo de montañas rocosas lejanas que esconde el borde del
-- suelo, y el suelo mismo. Todo es Terrain o una sola pieza, para gastar muy poco.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Palette)
local MapParts = require(script.Parent.MapParts)

local PI = math.pi

local GROUND_RADIUS = 260 -- el suelo es un disco, sin esquinas
local MOUNTAIN_RING_RADIUS = 225 -- las montañas cubren de 180 a 290 studs del centro
local MOUNTAIN_COUNT = 20

local WorldTerrain = {}

-- Colores del terreno: todos salen de la paleta
local function paintTerrain(terrain: Terrain)
	local grass = Palette.Moss:Lerp(Color3.new(0, 0, 0), 0.15)
	local rock = Palette.Stone:Lerp(Palette.StoneDark, 0.35)
	local slate = Palette.StoneDark:Lerp(Palette.Stone, 0.2)
	pcall(function()
		terrain:SetMaterialColor(Enum.Material.Grass, grass)
		terrain:SetMaterialColor(Enum.Material.Rock, rock)
		terrain:SetMaterialColor(Enum.Material.Slate, slate)
	end)
end

-- Cada montaña son tres bultos de roca: el cuerpo, una cima y un hombro al costado.
-- Los vecinos se solapan, así que no quedan huecos por donde se vea el borde.
local function buildMountains(terrain: Terrain, rng: Random)
	for index = 0, MOUNTAIN_COUNT - 1 do
		local angle = index * 2 * PI / MOUNTAIN_COUNT + rng:NextNumber(-0.06, 0.06)
		local ring = MOUNTAIN_RING_RADIUS + rng:NextNumber(-12, 12)
		local cx, cz = MapParts.polar(ring, angle)

		-- Cuerpo
		local bodyRadius = rng:NextNumber(46, 60)
		local bodyY = bodyRadius * 0.15
		terrain:FillBall(Vector3.new(cx, bodyY, cz), bodyRadius, Enum.Material.Rock)

		-- Cima: más chica y más alta, algo desplazada
		local peakRadius = bodyRadius * rng:NextNumber(0.5, 0.65)
		local px = cx + rng:NextNumber(-0.3, 0.3) * bodyRadius
		local pz = cz + rng:NextNumber(-0.3, 0.3) * bodyRadius
		terrain:FillBall(Vector3.new(px, bodyY + bodyRadius * 0.55, pz), peakRadius, Enum.Material.Slate)

		-- Hombro: un bulto bajo a un lado, sobre la línea del anillo
		local side = if rng:NextNumber() < 0.5 then -1 else 1
		local sx, sz = MapParts.polar(ring, angle + side * 0.16)
		terrain:FillBall(Vector3.new(sx, bodyRadius * 0.05, sz), bodyRadius * 0.7, Enum.Material.Rock)
	end
end

-- Suelo de hierba que rodea todo. Reemplaza al Baseplate de la plantilla de Studio.
local function buildGround(parent: Instance)
	local template = workspace:FindFirstChild("Baseplate")
	if template then
		template:Destroy()
	end
	local color = Palette.Moss:Lerp(Color3.new(0, 0, 0), 0.15)
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
	paintTerrain(terrain)
	buildGround(parent)
	buildMountains(terrain, rng)
end

return WorldTerrain
