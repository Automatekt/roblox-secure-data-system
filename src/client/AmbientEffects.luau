--!strict
-- Ambiente solo visual y solo en el cliente: luciérnagas y polvo flotando en la luz.
-- Una pieza invisible sigue al jugador y de ella nacen las partículas, así que el
-- servidor no sabe nada de esto y no hay nada que replicar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Palette = require(ReplicatedStorage.Shared.Palette)

local SOFT_TEXTURE = "rbxasset://textures/particles/smoke_main.dds" -- textura oficial de Roblox
local FOLLOW_HEIGHT = 6 -- la nube de partículas está centrada a esta altura sobre el jugador

-- Versión completa y versión ligera para celulares y tabletas
local FULL = { area = Vector3.new(64, 14, 64), fireflyRate = 4, dustRate = 7 }
local LIGHT = { area = Vector3.new(44, 12, 44), fireflyRate = 2, dustRate = 3 }

local AmbientEffects = {}

local function newFireflies(anchor: Part, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Fireflies"
	emitter.Texture = SOFT_TEXTURE
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Color = ColorSequence.new(Palette.Gold:Lerp(Palette.Moss, 0.45))
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(6, 9)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.3, 0.9)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 0.6
	emitter.Size = NumberSequence.new(0.35)
	-- Aparecen, se apagan y se encienden suave, y se van: parpadeo lento
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.2),
		NumberSequenceKeypoint.new(0.4, 0.85),
		NumberSequenceKeypoint.new(0.62, 0.15),
		NumberSequenceKeypoint.new(0.85, 0.8),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = anchor
end

local function newDust(anchor: Part, rate: number)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Dust"
	emitter.Texture = SOFT_TEXTURE
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Color = ColorSequence.new(Palette.Parchment)
	emitter.LightEmission = 0.5
	emitter.Lifetime = NumberRange.new(7, 10)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.1, 0.4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0.25, 0.05, 0.1) -- una brisa muy suave
	emitter.Size = NumberSequence.new(0.14)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.6),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = anchor
end

function AmbientEffects.start()
	local settings = if UserInputService.TouchEnabled then LIGHT else FULL

	local anchor = Instance.new("Part")
	anchor.Name = "AmbientAnchor"
	anchor.Size = settings.area
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Transparency = 1
	newFireflies(anchor, settings.fireflyRate)
	newDust(anchor, settings.dustRate)

	-- Esta conexión vive lo mismo que el script del cliente (toda la sesión), por eso no se
	-- desconecta. La pieza se crea en el cliente: el servidor y los demás jugadores no la reciben.
	local localPlayer = Players.LocalPlayer
	RunService.Heartbeat:Connect(function()
		local character = localPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root ~= nil and root:IsA("BasePart") then
			anchor.CFrame = CFrame.new(root.Position + Vector3.new(0, FOLLOW_HEIGHT, 0))
			if anchor.Parent == nil then
				anchor.Parent = workspace -- recién ahora, para no emitir en el origen sin personaje
			end
		end
	end)
end

return AmbientEffects
