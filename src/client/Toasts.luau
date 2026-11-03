--!strict
-- Avisos cortos para el jugador (recompensa recibida, cooldown, saldo lleno).
-- El servidor solo manda un código; aquí se arma el texto en español.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Palette = require(ReplicatedStorage.Shared.Palette)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

local SHOW_SECONDS = 2.6
local FADE_IN = 0.25
local FADE_OUT = 0.35
local TITLE_SIZE = 18 -- nada por debajo de 16 para que se lea en celular
local DETAIL_SIZE = 16
local MAX_WIDTH = 360

local toast: CanvasGroup
local titleLabel: TextLabel
local detailLabel: TextLabel
local token = 0 -- cambia con cada aviso para que los temporizadores viejos no actúen

local Toasts = {}

local function itemName(itemId: string): string
	local info = ItemCatalog[itemId]
	return if info then info.DisplayName else itemId
end

-- Devuelve título, detalle y si es una buena noticia (dorado) o una advertencia (ámbar)
local function describe(code: string, args: { string }): (string, string, boolean)
	if code == "Reward" then
		return "¡Recompensa recibida!", `+{args[1]} monedas  y  +1 {itemName(args[2])}`, true
	elseif code == "RewardNoItem" then
		return "¡Recompensa recibida!", `+{args[1]} monedas ({itemName(args[2])} ya está al máximo)`, true
	elseif code == "Cooldown" then
		return "Espera un momento", `El cofre se podrá abrir en {args[1]} s`, false
	elseif code == "CoinsFull" then
		return "Monedero lleno", "Gasta algunas monedas para seguir recibiendo", false
	end
	return code, "", false
end

local function label(parent: Instance, size: number, font: Enum.Font, order: number): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.AutomaticSize = Enum.AutomaticSize.XY
	text.Size = UDim2.fromOffset(0, 0)
	text.Font = font
	text.TextSize = size
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Center
	text.LayoutOrder = order
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(MAX_WIDTH, math.huge)
	limit.Parent = text
	text.Parent = parent
	return text
end

function Toasts.start(gui: ScreenGui)
	toast = Instance.new("CanvasGroup")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 16)
	toast.AutomaticSize = Enum.AutomaticSize.XY
	toast.Size = UDim2.fromOffset(0, 0)
	toast.BackgroundColor3 = Palette.Ink
	toast.GroupTransparency = 1
	toast.Visible = false
	toast.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = toast

	local border = Instance.new("UIStroke")
	border.Color = Palette.Gold
	border.Thickness = 1.5
	border.Transparency = 0.25
	border.Parent = toast

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.Parent = toast

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = toast

	titleLabel = label(toast, TITLE_SIZE, Palette.TitleFont, 1)
	detailLabel = label(toast, DETAIL_SIZE, Palette.NumberFont, 2)
	detailLabel.TextColor3 = Palette.Parchment
end

function Toasts.show(code: string, args: { string })
	local title, detail, good = describe(code, args)
	titleLabel.Text = title
	titleLabel.TextColor3 = if good then Palette.Gold else Palette.Amber
	detailLabel.Text = detail
	detailLabel.Visible = detail ~= ""

	token += 1
	local myToken = token

	toast.Visible = true
	toast.Position = UDim2.new(0.5, 0, 0, 4)
	TweenService:Create(toast, TweenInfo.new(FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = 0,
		Position = UDim2.new(0.5, 0, 0, 16),
	}):Play()

	task.delay(SHOW_SECONDS, function()
		if token ~= myToken then
			return -- llegó otro aviso: este ya no manda
		end
		local fade = TweenService:Create(toast, TweenInfo.new(FADE_OUT), { GroupTransparency = 1 })
		fade.Completed:Once(function()
			if token == myToken then
				toast.Visible = false
			end
		end)
		fade:Play()
	end)
end

return Toasts
