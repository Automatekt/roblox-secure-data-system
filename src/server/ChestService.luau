--!strict
-- Un cofre de recompensa por jugador. El servidor crea cada cofre con un dueño,
-- valida todo al recogerlo (dueño, distancia, cooldown, límites) y luego crea el
-- siguiente en otro punto. El cliente solo muestra los efectos.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChestBuilder = require(script.Parent.ChestBuilder)
local ChestPoints = require(script.Parent.ChestPoints)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local Notifier = require(script.Parent.Notifier)
local ChestShared = require(ReplicatedStorage.Shared.ChestShared)

local REWARD_COINS = 100
local REWARD_ITEM = "HealthPotion"
local REWARD_ITEM_AMOUNT = 1
local COOLDOWN = 3 -- segundos entre dos recompensas del mismo jugador
local FIRST_SPAWN_DELAY = 1 -- espera tras cargar los datos, para que ya se vea el mapa
local RESPAWN_DELAY = 1.2 -- espera entre recoger un cofre y que aparezca el siguiente
local MAX_CLAIM_DISTANCE = 14 -- el prompt llega a 10; el resto es margen por el movimiento
local RECENT_LIMIT = 2 -- puntos recientes que no se repiten para el mismo jugador
local NO_POINTS_RETRY = 5 -- segundos antes de reintentar si no hay ningún punto válido

type Result = "Ok" | "Ignored" | "TooFar" | "Cooldown" | CurrencyService.Result

type PlayerState = {
	chest: Model?,
	point: Vector3?,
	recent: { Vector3 },
	lastClaim: number,
	busy: boolean,
}

local states: { [Player]: PlayerState } = {}
local container: Folder? = nil

local ChestService = {}

-- Puntos que ya usan los cofres de otros jugadores, para no apilarlos
local function pointsUsedByOthers(except: Player): { Vector3 }
	local used = {}
	for player, state in states do
		if player ~= except and state.point ~= nil and state.chest ~= nil then
			table.insert(used, state.point)
		end
	end
	return used
end

local claim

local function spawnChest(player: Player, state: PlayerState)
	-- El jugador pudo salir, o su estado cambiar, mientras esperábamos
	if states[player] ~= state or player.Parent ~= Players or container == nil then
		return
	end

	local avoid = pointsUsedByOthers(player)
	for _, recent in state.recent do
		table.insert(avoid, recent)
	end
	local point = ChestPoints.pickNext(state.point, avoid)
	if point == nil then
		warn("[ChestService] no hay puntos válidos para el cofre de " .. player.Name .. "; se reintenta en 5 s")
		task.delay(NO_POINTS_RETRY, spawnChest, player, state)
		return
	end

	local chest, prompt = ChestBuilder.build(point, player.UserId)
	prompt.Triggered:Connect(function(triggeredBy: Player)
		-- Solo el dueño puede recogerlo; cualquier otro intento se ignora en silencio
		if triggeredBy == player then
			claim(player, chest)
		end
	end)

	state.chest = chest
	state.point = point
	state.busy = false
	table.insert(state.recent, point)
	while #state.recent > RECENT_LIMIT do
		table.remove(state.recent, 1)
	end
	chest.Parent = container
end

-- Intenta recoger el cofre. Devuelve "Ok" o el motivo por el que no se dio nada.
function claim(owner: Player, chest: Model): Result
	local state = states[owner]
	if state == nil or state.chest ~= chest or state.busy then
		return "Ignored"
	end

	-- Distancia medida en el servidor, por si alguien dispara el prompt desde lejos
	local character = owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return "Ignored"
	end
	if (root.Position - chest:GetPivot().Position).Magnitude > MAX_CLAIM_DISTANCE then
		return "TooFar"
	end

	local now = os.clock()
	local remaining = COOLDOWN - (now - state.lastClaim)
	if remaining > 0 then
		Notifier.send(owner, "Cooldown", math.ceil(remaining))
		return "Cooldown"
	end

	-- Las monedas son la recompensa principal; el objeto es un extra si cabe
	local coinsResult = CurrencyService.addCoins(owner, REWARD_COINS)
	if coinsResult == "OverCap" then
		Notifier.send(owner, "CoinsFull")
		return coinsResult
	elseif coinsResult ~= "Ok" then
		return coinsResult
	end
	local itemResult = InventoryService.addItem(owner, REWARD_ITEM, REWARD_ITEM_AMOUNT)
	Notifier.send(owner, if itemResult == "Ok" then "Reward" else "RewardNoItem", REWARD_COINS, REWARD_ITEM)

	-- Recogido: el cliente reproduce la desaparición, luego se borra y aparece el siguiente
	state.lastClaim = now
	state.busy = true
	chest:SetAttribute(ChestShared.StateAttribute, ChestShared.States.Claimed)
	local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		prompt.Enabled = false
	end

	task.delay(ChestShared.ClaimAnimationSeconds, function()
		chest:Destroy()
		if states[owner] == state then
			state.chest = nil
		end
		task.delay(RESPAWN_DELAY, spawnChest, owner, state)
	end)
	return "Ok"
end

function ChestService.start()
	local folder = Instance.new("Folder")
	folder.Name = "RewardChests"
	folder.Parent = workspace
	container = folder

	-- Cada jugador recibe su cofre cuando sus datos terminan de cargar
	DataService.onLoaded(function(player: Player)
		if player.Parent ~= Players or states[player] ~= nil then
			return
		end
		local state: PlayerState = { chest = nil, point = nil, recent = {}, lastClaim = -math.huge, busy = false }
		states[player] = state
		task.delay(FIRST_SPAWN_DELAY, spawnChest, player, state)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local state = states[player]
		states[player] = nil
		if state ~= nil and state.chest ~= nil then
			state.chest:Destroy()
		end
	end)
end

return ChestService
