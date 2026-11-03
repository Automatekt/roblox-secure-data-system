--!strict
-- Demo para mostrar el sistema funcionando: un cofre con un ProximityPrompt
-- que da monedas y un objeto. Usa los mismos servicios que usaría cualquier
-- sistema real (tienda, misiones...), así que pasa por todas las validaciones.

local Players = game:GetService("Players")

local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)

local CHEST_NAME = "RewardChest"
local CHEST_POSITION = Vector3.new(-12, 1.5, -15)
local REWARD_COINS = 100
local REWARD_ITEM = "HealthPotion"
local REWARD_ITEM_AMOUNT = 1
local COOLDOWN = 5 -- segundos entre reclamos del mismo jugador

local lastAttempt: { [Player]: number } = {}

local DemoRewardService = {}

-- Las monedas son la recompensa principal; el objeto es un extra que solo se da
-- si cabe en el inventario. Devuelve "Ok" o el motivo por el que no se dio nada.
function DemoRewardService.claim(player: Player): string
	-- El cooldown cuenta desde el intento, así que spamear el prompt no sirve de nada
	local now = os.clock()
	local last = lastAttempt[player]
	if last ~= nil and now - last < COOLDOWN then
		return "Cooldown"
	end
	lastAttempt[player] = now

	local coinsResult = CurrencyService.addCoins(player, REWARD_COINS)
	if coinsResult ~= "Ok" then
		return coinsResult
	end

	-- Si el objeto ya está al máximo, se ignora: el jugador igual recibió las monedas
	InventoryService.addItem(player, REWARD_ITEM, REWARD_ITEM_AMOUNT)
	return "Ok"
end

function DemoRewardService.start()
	local previous = workspace:FindFirstChild(CHEST_NAME)
	if previous then
		previous:Destroy()
	end

	local chest = Instance.new("Part")
	chest.Name = CHEST_NAME
	chest.Size = Vector3.new(4, 3, 4)
	chest.Position = CHEST_POSITION
	chest.Color = Color3.fromRGB(150, 98, 51)
	chest.Material = Enum.Material.Wood
	chest.Anchored = true
	chest.Parent = workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Cofre de recompensa"
	prompt.ActionText = "Abrir"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.Parent = chest

	-- Roblox ya comprueba la distancia; el servidor valida el cooldown y los límites
	prompt.Triggered:Connect(function(player: Player)
		DemoRewardService.claim(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastAttempt[player] = nil
	end)
end

return DemoRewardService
