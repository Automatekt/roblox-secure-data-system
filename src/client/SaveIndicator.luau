--!strict
-- Ícono de "progreso guardado" en la esquina superior derecha. El servidor sube un
-- contador en el PlayerGui del jugador cada vez que termina de guardar; aquí solo se
-- anima: aparece un disquete con un anillo que gira, luego una palomita, y se encoge
-- hasta desaparecer. Antes del primer guardado no se ve nada.
-- Es solo visual: no tiene botones ni envía nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local Palette = require(ReplicatedStorage.Shared.Palette)

local SIZE = 44
local FLOPPY = 20
local SPIN_SECONDS = 0.9
local HOLD_SECONDS = 1.3
local SHRINK_SECONDS = 0.25
local DONE_COLOR = Palette.Moss:Lerp(Palette.Parchment, 0.45)

local SaveIndicator = {}

local function box(parent: Instance, name: string, size: UDim2, position: UDim2, color: Color3, radius: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

-- Disquete: cuerpo dorado, ventanita arriba y etiqueta abajo
local function buildFloppy(parent: Instance): Frame
	local floppy = Instance.new("Frame")
	floppy.Name = "Floppy"
	floppy.AnchorPoint = Vector2.new(0.5, 0.5)
	floppy.Position = UDim2.fromScale(0.5, 0.5)
	floppy.Size = UDim2.fromOffset(FLOPPY, FLOPPY)
	floppy.BackgroundTransparency = 1
	floppy.Parent = parent

	box(floppy, "Body", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Palette.Gold, 3)
	box(floppy, "Shutter", UDim2.fromScale(0.56, 0.36), UDim2.fromScale(0.2, 0), Palette.Ink, 2)
	box(floppy, "Label", UDim2.fromScale(0.7, 0.4), UDim2.fromScale(0.15, 0.58), Palette.Parchment, 2)
	return floppy
end

-- Palomita hecha con dos barras giradas
local function buildCheck(parent: Instance): Frame
	local check = Instance.new("Frame")
	check.Name = "Check"
	check.AnchorPoint = Vector2.new(0.5, 0.5)
	check.Position = UDim2.fromScale(0.5, 0.5)
	check.Size = UDim2.fromOffset(22, 22)
	check.BackgroundTransparency = 1
	check.Visible = false
	check.Parent = parent

	local short = box(check, "Short", UDim2.fromOffset(8, 3.5), UDim2.fromOffset(6.5, 14.5), DONE_COLOR, 2)
	short.AnchorPoint = Vector2.new(0.5, 0.5)
	short.Rotation = 45
	local long = box(check, "Long", UDim2.fromOffset(15, 3.5), UDim2.fromOffset(13.5, 11.5), DONE_COLOR, 2)
	long.AnchorPoint = Vector2.new(0.5, 0.5)
	long.Rotation = -50
	return check
end

function SaveIndicator.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "SaveIndicator"
	gui.ResetOnSpawn = false
	-- Dentro de la zona segura: no choca con la barra superior de Roblox ni con el notch
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	-- Un Frame normal que se muestra y se oculta con Visible: no depende de transparencias
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -12, 0, 12)
	badge.Size = UDim2.fromOffset(SIZE, SIZE)
	badge.BackgroundColor3 = Palette.Ink
	badge.BackgroundTransparency = 0.15
	badge.Visible = false -- no se ve hasta que el servidor guarda
	badge.Active = false -- solo informa: no bloquea toques ni clics
	badge.Parent = gui

	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = badge

	local scale = Instance.new("UIScale")
	scale.Parent = badge

	-- Anillo con un arco visible que gira (un UIGradient sobre el borde)
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(SIZE - 10, SIZE - 10)
	ring.BackgroundTransparency = 1
	ring.Parent = badge
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius = UDim.new(0.5, 0)
	ringCorner.Parent = ring
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Color = Palette.Gold
	ringStroke.Thickness = 3
	ringStroke.Parent = ring
	local arc = Instance.new("UIGradient")
	arc.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.45, 0),
		NumberSequenceKeypoint.new(0.5, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	arc.Parent = ringStroke

	local floppy = buildFloppy(badge)
	local check = buildCheck(badge)
	local checkScale = Instance.new("UIScale")
	checkScale.Parent = check

	local token = 0 -- cambia en cada guardado para que los temporizadores viejos no actúen

	local function play()
		token += 1
		local mine = token

		-- Estado inicial: disquete con el anillo girando
		floppy.Visible = true
		ring.Visible = true
		check.Visible = false
		arc.Rotation = 0
		scale.Scale = 0.2
		badge.Visible = true
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(arc, TweenInfo.new(SPIN_SECONDS, Enum.EasingStyle.Linear), { Rotation = 360 }):Play()

		task.delay(SPIN_SECONDS, function()
			if token ~= mine then
				return
			end
			-- Terminó: sale la palomita con un pequeño rebote y luego todo se encoge y se oculta
			floppy.Visible = false
			ring.Visible = false
			check.Visible = true
			checkScale.Scale = 0.2
			TweenService:Create(checkScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

			task.delay(HOLD_SECONDS, function()
				if token ~= mine then
					return
				end
				local shrink = TweenService:Create(scale, TweenInfo.new(SHRINK_SECONDS, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.01 })
				shrink.Completed:Once(function()
					if token == mine then -- si llegó otro guardado mientras tanto, no se oculta
						badge.Visible = false
					end
				end)
				shrink:Play()
			end)
		end)
	end

	-- Vive toda la sesión, así que esta conexión no necesita limpiarse
	playerGui:GetAttributeChangedSignal(DataAttributes.SaveCount):Connect(play)
	gui.Parent = playerGui
end

return SaveIndicator
