--!strict
-- Dibuja y anima el cofre de recompensa del jugador local. Solo muestra efectos:
-- no envía nada al servidor. Los cofres de otros jugadores no se dibujan, y su
-- prompt se apaga en este cliente.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Palette = require(ReplicatedStorage.Shared.Palette)
local ChestShared = require(ReplicatedStorage.Shared.ChestShared)
local ChestVisual = require(script.Parent.ChestVisual)
local ChestSounds = require(script.Parent.ChestSounds)

local ENTRANCE_SECONDS = 0.8 -- crece desde cero con un pequeño rebote
local BOB_HEIGHT = 0.35 -- cuánto sube y baja flotando
local BOB_SPEED = 2
local SPIN_SPEED = 0.9 -- radianes por segundo
local CLAIM_GROW_SECONDS = 0.18 -- hincha un poco antes de desaparecer
local CLAIM_END_SECONDS = 0.8 -- cuándo termina de encogerse (el servidor lo borra a 1.0)
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds" -- textura oficial de Roblox

-- Tamaño de los efectos (studs). El cofre mide unos 3 de ancho: se mantienen pequeños
-- para que acompañen al cofre sin taparlo ni invadir el mapa.
local FLASH_ENTRANCE_SIZE = 3.6
local FLASH_CLAIM_SIZE = 4.2
local FLASH_START_TRANSPARENCY = 0.6 -- empieza ya translúcido: se ve el cofre a través del destello
local BURST_PARTICLE_SIZE = 0.5
local ENTRANCE_BURST = { count = 18, speed = NumberRange.new(3, 6) }
local CLAIM_BURST = { count = 28, speed = NumberRange.new(4, 8) }
local POOF_BURST = { count = 10, speed = NumberRange.new(1.5, 3) }
local IDLE_SPARKLE_SIZE = 0.3
local IDLE_SPARKLE_RATE = 5
local LIGHT_RANGE = 11

local localPlayer = Players.LocalPlayer
local visuals: Folder -- carpeta solo de este cliente donde viven los cofres dibujados

local ChestEffects = {}

local function easeOutBack(alpha: number): number
	return TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function easeInQuad(alpha: number): number
	return TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

local function easeOutQuad(alpha: number): number
	return TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

-- Destello: una esfera brillante que se expande y se desvanece
local function flash(position: Vector3, color: Color3, finalSize: number, seconds: number)
	local part = Instance.new("Part")
	part.Name = "Flash"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = FLASH_START_TRANSPARENCY
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Parent = visuals

	local tween = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * finalSize,
		Transparency = 1,
	})
	tween.Completed:Once(function()
		part:Destroy()
	end)
	tween:Play()
end

-- Ráfaga de chispas que sale del cofre y se limpia sola
local function burst(parent: BasePart, config: { count: number, speed: NumberRange })
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Burst"
	emitter.Texture = SPARKLE_TEXTURE
	emitter.Color = ColorSequence.new(Palette.Gold, Palette.Amber)
	emitter.LightEmission = 1
	emitter.Rate = 0 -- solo emite cuando se lo pedimos
	emitter.Lifetime = NumberRange.new(0.5, 0.8)
	emitter.Speed = config.speed
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, BURST_PARTICLE_SIZE), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Parent = parent
	emitter:Emit(config.count)
	Debris:AddItem(emitter, 1.5)
end

-- El cofre del servidor es solo una caja invisible; este es el aspecto que ve su dueño
local function animateOwnChest(chest: Model)
	chest:WaitForChild("Hitbox") -- el cofre llega completo antes de leer su posición
	local home = chest:GetPivot()

	local visual = ChestVisual.build()
	visual:ScaleTo(0.01)
	visual:PivotTo(home)
	visual.Parent = visuals

	local aura = visual:FindFirstChild("Aura") :: BasePart

	-- Las partículas y la luz van en una pieza invisible APARTE del modelo: ScaleTo
	-- escala también los emisores, y como el cofre crece desde 0.01 las chispas
	-- salían 100 veces más grandes. Esta pieza solo sigue su posición.
	local fx = Instance.new("Part")
	fx.Name = "FxAnchor"
	fx.Size = Vector3.one * 0.2
	fx.Transparency = 1
	fx.Anchored = true
	fx.CanCollide = false
	fx.CanTouch = false
	fx.CanQuery = false
	fx.CastShadow = false
	fx.CFrame = home
	fx.Parent = visuals

	-- Luz cálida y chispas suaves que se activan al terminar la entrada
	local light = Instance.new("PointLight")
	light.Color = Palette.Gold
	light.Range = LIGHT_RANGE
	light.Brightness = 0
	light.Shadows = false
	light.Parent = fx

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "Sparkles"
	sparkles.Texture = SPARKLE_TEXTURE
	sparkles.Color = ColorSequence.new(Palette.Gold)
	sparkles.LightEmission = 1
	sparkles.Enabled = false
	sparkles.Rate = IDLE_SPARKLE_RATE
	sparkles.Lifetime = NumberRange.new(0.8, 1.2)
	sparkles.Speed = NumberRange.new(0.3, 0.8)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Acceleration = Vector3.new(0, 1, 0)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, IDLE_SPARKLE_SIZE), NumberSequenceKeypoint.new(1, 0) })
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Parent = fx

	-- Entrada: destello y chispas
	flash(home.Position, Palette.Gold, FLASH_ENTRANCE_SIZE, 0.5)
	burst(fx, ENTRANCE_BURST)
	ChestSounds.play("Appear")

	local phase = "Entering" -- Entering, Idle, Claiming
	local phaseStart = os.clock()
	local angle = 0
	local claimBurstDone = false

	local function startClaim()
		if phase == "Claiming" then
			return
		end
		phase = "Claiming"
		phaseStart = os.clock()
		sparkles.Enabled = false
		flash(visual:GetPivot().Position, Palette.Parchment, FLASH_CLAIM_SIZE, 0.45)
		burst(fx, CLAIM_BURST)
		ChestSounds.play("Collect")
	end

	local stateConnection = chest:GetAttributeChangedSignal(ChestShared.StateAttribute):Connect(function()
		if chest:GetAttribute(ChestShared.StateAttribute) == ChestShared.States.Claimed then
			startClaim()
		end
	end)

	local frameConnection: RBXScriptConnection
	frameConnection = RunService.RenderStepped:Connect(function(dt: number)
		local now = os.clock()
		local elapsed = now - phaseStart
		local scale = 1
		local lift = 0
		local spinSpeed = SPIN_SPEED

		if phase == "Entering" then
			local progress = math.clamp(elapsed / ENTRANCE_SECONDS, 0, 1)
			scale = easeOutBack(progress)
			spinSpeed = SPIN_SPEED + (1 - progress) * 7 -- gira rápido al aparecer y se calma
			light.Brightness = 1.4 * progress
			if progress >= 1 then
				phase = "Idle"
				phaseStart = now
				sparkles.Enabled = true
			end
		elseif phase == "Idle" then
			lift = math.sin(elapsed * BOB_SPEED) * BOB_HEIGHT
			-- El brillo "respira" suavemente
			light.Brightness = 1.4 + math.sin(elapsed * 3) * 0.25
			aura.Transparency = 0.9 + math.sin(elapsed * 3) * 0.03
		else
			-- Recogido: se hincha, sube girando cada vez más rápido y se encoge hasta desaparecer
			if elapsed < CLAIM_GROW_SECONDS then
				scale = 1 + 0.3 * easeOutQuad(elapsed / CLAIM_GROW_SECONDS)
			else
				local shrink = math.clamp((elapsed - CLAIM_GROW_SECONDS) / (CLAIM_END_SECONDS - CLAIM_GROW_SECONDS), 0, 1)
				scale = 1.3 * (1 - easeInQuad(shrink))
			end
			lift = math.clamp(elapsed / CLAIM_END_SECONDS, 0, 1) * 2.5
			spinSpeed = SPIN_SPEED + elapsed * 14
			light.Brightness = math.max(0, light.Brightness - dt * 4)
			if elapsed >= CLAIM_END_SECONDS - 0.1 and not claimBurstDone then
				claimBurstDone = true
				burst(fx, POOF_BURST) -- el último "puf"
			end
		end

		angle += dt * spinSpeed
		visual:ScaleTo(math.max(scale, 0.01))
		visual:PivotTo(home * CFrame.new(0, lift, 0) * CFrame.Angles(0, angle, 0))
		fx.Position = home.Position + Vector3.new(0, lift, 0)
	end)

	-- Cuando el servidor borra el cofre, se limpia todo lo local (una sola vez)
	local ancestryConnection: RBXScriptConnection
	ancestryConnection = chest.AncestryChanged:Connect(function()
		if chest:IsDescendantOf(game) then
			return
		end
		ancestryConnection:Disconnect()
		frameConnection:Disconnect()
		stateConnection:Disconnect()
		visual:Destroy()
		fx:Destroy()
	end)
end

-- El prompt de un cofre ajeno no debe aparecerle a este jugador
local function hideOthersPrompt(chest: Model)
	local function disable(descendant: Instance)
		if descendant:IsA("ProximityPrompt") then
			descendant.Enabled = false
		end
	end
	for _, descendant in chest:GetDescendants() do
		disable(descendant)
	end
	chest.DescendantAdded:Connect(disable)
end

local function onChestAdded(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	if instance:GetAttribute(ChestShared.OwnerAttribute) == localPlayer.UserId then
		animateOwnChest(instance)
	else
		hideOthersPrompt(instance)
	end
end

function ChestEffects.start()
	visuals = Instance.new("Folder")
	visuals.Name = "ChestVisuals" -- creada en el cliente: nadie más la recibe
	visuals.Parent = workspace

	CollectionService:GetInstanceAddedSignal(ChestShared.Tag):Connect(onChestAdded)
	for _, chest in CollectionService:GetTagged(ChestShared.Tag) do
		task.spawn(onChestAdded, chest)
	end
end

return ChestEffects
