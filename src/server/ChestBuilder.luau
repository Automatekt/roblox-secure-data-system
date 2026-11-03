--!strict
-- Cofre del servidor: una caja invisible con el prompt, un dueño y un estado.
-- La parte que se ve (el cofre dorado) la dibuja solo el cliente del dueño, así
-- ningún otro jugador recibe el modelo ni sus efectos.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChestShared = require(ReplicatedStorage.Shared.ChestShared)

local ChestBuilder = {}

-- Crea el cofre flotando sobre un punto del suelo. Devuelve el modelo y su prompt.
function ChestBuilder.build(groundPoint: Vector3, ownerUserId: number): (Model, ProximityPrompt)
	local model = Instance.new("Model")
	model.Name = "RewardChest_" .. ownerUserId

	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = Vector3.new(3.2, 3.2, 3.2)
	hitbox.Transparency = 1
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = false
	hitbox.CastShadow = false
	hitbox.Parent = model

	model.PrimaryPart = hitbox
	model:PivotTo(CFrame.new(groundPoint + Vector3.new(0, ChestShared.HoverHeight, 0)))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Cofre de recompensa"
	prompt.ActionText = "Abrir"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = hitbox

	model:SetAttribute(ChestShared.OwnerAttribute, ownerUserId)
	model:SetAttribute(ChestShared.StateAttribute, ChestShared.States.Idle)
	CollectionService:AddTag(model, ChestShared.Tag)

	return model, prompt
end

return ChestBuilder
