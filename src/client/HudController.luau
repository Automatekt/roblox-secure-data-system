--!strict
-- Panel de monedas e inventario. Solo lee atributos que el servidor pone en el
-- PlayerGui de este jugador (y solo este jugador los recibe); no tiene botones
-- ni envía nada. Los cambios se animan: el contador de monedas sube con cuenta
-- progresiva, y los objetos nuevos "saltan" un poco.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)
local Palette = require(ReplicatedStorage.Shared.Palette)
local HudIcons = require(script.Parent.HudIcons)
local Toasts = require(script.Parent.Toasts)

-- Tamaños pensados para celular: ningún texto por debajo de 16
local PANEL_WIDTH = 220 -- el texto más largo ("1,000,000,000") mide unos 140 px
local COINS_ROW_HEIGHT = 36
local COIN_ICON = 30
local COINS_TEXT = 22
local TITLE_TEXT = 16
local ROW_TEXT = 16
local ROW_HEIGHT = 28
local ITEM_ICON = 24

local HudController = {}

-- 1234567 -> "1,234,567"
local function formatNumber(n: number): string
	local digits = tostring(math.floor(n))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

local function makeLabel(
	parent: Instance,
	text: string,
	size: number,
	font: Enum.Font,
	color: Color3,
	order: number
): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size + 6)
	label.Font = font
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

-- Salto breve de tamaño: sube rápido y vuelve con un pequeño rebote
local function pop(scale: UIScale, amount: number)
	scale.Scale = 1
	local grow = TweenService:Create(scale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = amount })
	grow.Completed:Once(function()
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	grow:Play()
end

function HudController.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DataHud"
	gui.ResetOnSpawn = false
	-- Evita la barra superior de Roblox y los recortes de pantalla del celular
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	-- A la izquierda y centrado en vertical: libre de la barra superior,
	-- del botón de salto (abajo a la derecha) y del chat (arriba a la izquierda)
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.BackgroundColor3 = Color3.new(1, 1, 1)
	panel.BackgroundTransparency = 0.1
	panel.Active = false -- solo informa: no bloquea toques ni clics
	panel.Parent = gui

	local background = Instance.new("UIGradient")
	background.Color = ColorSequence.new(Palette.StoneDark:Lerp(Palette.Ink, 0.45), Palette.Ink)
	background.Rotation = 90
	background.Parent = panel

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel

	local border = Instance.new("UIStroke")
	border.Color = Palette.Gold
	border.Thickness = 1.5
	border.Transparency = 0.3
	border.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 3)
	layout.Parent = panel

	-- Fila de monedas: ícono y número
	local coinsRow = Instance.new("Frame")
	coinsRow.Name = "CoinsRow"
	coinsRow.BackgroundTransparency = 1
	coinsRow.Size = UDim2.new(1, 0, 0, COINS_ROW_HEIGHT)
	coinsRow.LayoutOrder = 1
	coinsRow.Parent = panel

	local coinIcon = HudIcons.create("Coin", COIN_ICON, coinsRow)
	if coinIcon then
		coinIcon.AnchorPoint = Vector2.new(0, 0.5)
		coinIcon.Position = UDim2.new(0, 0, 0.5, 0)
	end

	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "Coins"
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.AnchorPoint = Vector2.new(0, 0.5)
	coinsLabel.Position = UDim2.new(0, COIN_ICON + 8, 0.5, 0)
	coinsLabel.Size = UDim2.new(1, -(COIN_ICON + 8), 1, 0)
	coinsLabel.Font = Palette.NumberFont
	coinsLabel.TextSize = COINS_TEXT
	coinsLabel.TextColor3 = Palette.Gold
	coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinsLabel.TextTruncate = Enum.TextTruncate.AtEnd
	coinsLabel.Text = "Cargando..."
	coinsLabel.Parent = coinsRow

	local coinsScale = Instance.new("UIScale")
	coinsScale.Parent = coinsLabel

	-- Línea fina dorada y título del inventario
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.BackgroundColor3 = Palette.Gold
	divider.BackgroundTransparency = 0.6
	divider.BorderSizePixel = 0
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.LayoutOrder = 2
	divider.Parent = panel

	local titleLabel = makeLabel(panel, "Inventario", TITLE_TEXT, Palette.TitleFont, Palette.Parchment, 3)
	titleLabel.TextTransparency = 0.25
	local emptyLabel = makeLabel(panel, "Vacío", ROW_TEXT, Palette.TitleFont, Palette.Stone:Lerp(Palette.Parchment, 0.35), 4)

	-- Una fila por objeto del catálogo, creadas una sola vez y mostradas u ocultadas
	local itemIds: { string } = {}
	for itemId in ItemCatalog do
		table.insert(itemIds, itemId)
	end
	table.sort(itemIds)

	local rows: { [string]: Frame } = {}
	local counts: { [string]: TextLabel } = {}
	local scales: { [string]: UIScale } = {}
	for index, itemId in itemIds do
		local row = Instance.new("Frame")
		row.Name = itemId
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
		row.LayoutOrder = 10 + index
		row.Visible = false
		row.Parent = panel

		local icon = HudIcons.create(itemId, ITEM_ICON, row)
		if icon then
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.new(0, 0, 0.5, 0)
		end

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.new(0, ITEM_ICON + 8, 0, 0)
		name.Size = UDim2.new(1, -(ITEM_ICON + 8 + 52), 1, 0)
		name.Font = Palette.TitleFont
		name.TextSize = ROW_TEXT
		name.TextColor3 = Palette.Parchment
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Text = ItemCatalog[itemId].DisplayName
		name.Parent = row

		local count = Instance.new("TextLabel")
		count.BackgroundTransparency = 1
		count.AnchorPoint = Vector2.new(1, 0.5)
		count.Position = UDim2.new(1, 0, 0.5, 0)
		count.Size = UDim2.new(0, 48, 1, 0)
		count.Font = Palette.NumberFont
		count.TextSize = ROW_TEXT
		count.TextColor3 = Palette.Gold
		count.TextXAlignment = Enum.TextXAlignment.Right
		count.Parent = row

		local scale = Instance.new("UIScale")
		scale.Parent = row

		rows[itemId] = row
		counts[itemId] = count
		scales[itemId] = scale
	end

	-- Contador animado: un NumberValue suelto que se anima y escribe el texto
	local coinsValue = Instance.new("NumberValue")
	coinsValue.Changed:Connect(function(value: number)
		coinsLabel.Text = formatNumber(math.floor(value + 0.5))
	end)
	local shownCoins: number? = nil -- nil hasta el primer dibujo con datos
	local coinsTween: Tween? = nil
	local shownItems: { [string]: number } = {}

	local function floatText(text: string)
		local floating = Instance.new("TextLabel")
		floating.BackgroundTransparency = 1
		floating.AnchorPoint = Vector2.new(1, 0.5)
		floating.Position = UDim2.new(1, 0, 0.5, 0)
		floating.Size = UDim2.fromOffset(90, 24)
		floating.Font = Palette.NumberFont
		floating.TextSize = 18
		floating.TextColor3 = Palette.Gold
		floating.TextStrokeColor3 = Palette.Ink
		floating.TextStrokeTransparency = 0.4
		floating.TextXAlignment = Enum.TextXAlignment.Right
		floating.Text = text
		floating.ZIndex = 5
		floating.Parent = coinsRow

		local tween = TweenService:Create(floating, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, 0, 0.5, -22),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		tween.Completed:Once(function()
			floating:Destroy()
		end)
		tween:Play()
	end

	local function updateCoins(newCoins: number)
		local before = shownCoins
		shownCoins = newCoins
		if before == nil then
			-- Primer dibujo: sin animación. El texto se escribe a mano porque, si el
			-- valor no cambia (0 monedas), el contador no avisaría.
			coinsValue.Value = newCoins
			coinsLabel.Text = formatNumber(newCoins)
			return
		end
		if newCoins == before then
			return
		end
		if coinsTween then
			coinsTween:Cancel()
		end
		local seconds = math.clamp(math.abs(newCoins - before) / 400, 0.4, 1)
		local tween = TweenService:Create(coinsValue, TweenInfo.new(seconds, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = newCoins })
		coinsTween = tween
		tween:Play()
		if newCoins > before then
			pop(coinsScale, 1.18)
			floatText("+" .. formatNumber(newCoins - before))
		end
	end

	local function render()
		local loaded = playerGui:GetAttribute(DataAttributes.Loaded) == true
		titleLabel.Visible = loaded
		divider.Visible = loaded

		if not loaded then
			coinsLabel.Text = "Cargando..."
			emptyLabel.Visible = false
			for _, row in rows do
				row.Visible = false
			end
			return
		end

		local coins = playerGui:GetAttribute(DataAttributes.Coins)
		updateCoins(if type(coins) == "number" then coins else 0)

		local anyItem = false
		for _, itemId in itemIds do
			local value = playerGui:GetAttribute(DataAttributes.itemKey(itemId))
			local amount = if type(value) == "number" then value else 0
			local before = shownItems[itemId]
			shownItems[itemId] = amount

			rows[itemId].Visible = amount > 0
			if amount > 0 then
				anyItem = true
				counts[itemId].Text = "x" .. formatNumber(amount)
				if before ~= nil and amount > before then
					pop(scales[itemId], 1.1)
				end
			end
		end
		emptyLabel.Visible = not anyItem
	end

	Toasts.start(gui)

	-- Los avisos llegan como "<número>|<código>|<dato>...": solo reaccionamos a cambios nuevos
	playerGui:GetAttributeChangedSignal(DataAttributes.Notice):Connect(function()
		local value = playerGui:GetAttribute(DataAttributes.Notice)
		if type(value) ~= "string" then
			return
		end
		local parts = string.split(value, "|")
		local code = parts[2]
		if code == nil then
			return
		end
		local args = {}
		for index = 3, #parts do
			table.insert(args, parts[index])
		end
		Toasts.show(code, args)
	end)

	-- El HUD vive toda la sesión, así que estas conexiones no necesitan limpiarse
	playerGui:GetAttributeChangedSignal(DataAttributes.Loaded):Connect(render)
	playerGui:GetAttributeChangedSignal(DataAttributes.Coins):Connect(render)
	for _, itemId in itemIds do
		playerGui:GetAttributeChangedSignal(DataAttributes.itemKey(itemId)):Connect(render)
	end

	render()
	gui.Parent = playerGui
end

return HudController
