--!strict
-- Crea la Part y cambia su color cuando un jugador la toca.
-- Todo corre en el servidor: así todos los jugadores ven el mismo color
-- y ningún cliente puede forzar el cambio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.ColorPartConfig)

local ColorPartService = {}

function ColorPartService.start()
	-- Si ya hay una con ese nombre (por ejemplo al reiniciar el script), la quitamos
	local previous = workspace:FindFirstChild(Config.Name)
	if previous then
		previous:Destroy()
	end

	local part = Instance.new("Part")
	part.Name = Config.Name
	part.Size = Config.Size
	part.Position = Config.Position
	part.Color = Config.InitialColor
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.Parent = workspace

	local lastChange = 0

	part.Touched:Connect(function(otherPart: BasePart)
		-- Solo cuenta si lo toca el personaje de un jugador real
		local character = otherPart.Parent
		if not character or not Players:GetPlayerFromCharacter(character) then
			return
		end

		-- Cooldown sin pausar el evento: comparamos con el último cambio
		local now = os.clock()
		if now - lastChange < Config.Cooldown then
			return
		end
		lastChange = now

		part.Color = Color3.fromHSV(math.random(), 0.8, 1)
	end)
end

return ColorPartService
