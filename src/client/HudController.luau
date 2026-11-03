--!strict
-- Muestra las monedas y el inventario del jugador.
-- Solo lee atributos que pone el servidor; no tiene botones ni envía nada.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)
local ItemCatalog = require(ReplicatedStorage.Shared.ItemCatalog)

local PANEL_WIDTH = 220 -- "Monedas: 1,000,000,000" (el máximo) mide unos 190 px a tamaño 18
local TITLE_SIZE = 18 -- tamaños pensados para celular: nada por debajo de 16
local ROW_SIZE = 16
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local MUTED_COLOR = Color3.fromRGB(190, 190, 200)

local HudController = {}

-- 1234567 -> "1,234,567"
local function formatNumber(n: number): string
	local digits = tostring(math.floor(n))
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

local function makeLabel(parent: Instance, text: string, size: number, color: Color3, order: number): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, size + 4)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = text
	label.LayoutOrder = order
	label.Parent = parent
	return label
end

function HudController.start()
	local player = Players.LocalPlayer

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
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
	panel.BackgroundTransparency = 0.3
	panel.Active = false -- solo informa: no bloquea toques ni clics
	panel.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = panel

	local coinsLabel = makeLabel(panel, "Cargando datos...", TITLE_SIZE, TEXT_COLOR, 1)
	local headerLabel = makeLabel(panel, "Inventario", ROW_SIZE, MUTED_COLOR, 2)
	local emptyLabel = makeLabel(panel, "Vacío", ROW_SIZE, MUTED_COLOR, 3)

	-- Una fila por objeto del catálogo, creadas una sola vez y mostradas u ocultadas
	local itemIds: { string } = {}
	for itemId in ItemCatalog do
		table.insert(itemIds, itemId)
	end
	table.sort(itemIds)

	local rows: { [string]: TextLabel } = {}
	for index, itemId in itemIds do
		rows[itemId] = makeLabel(panel, "", ROW_SIZE, TEXT_COLOR, 10 + index)
	end

	local function render()
		local loaded = player:GetAttribute(DataAttributes.Loaded) == true
		headerLabel.Visible = loaded

		if not loaded then
			coinsLabel.Text = "Cargando datos..."
			emptyLabel.Visible = false
			for _, row in rows do
				row.Visible = false
			end
			return
		end

		local coins = player:GetAttribute(DataAttributes.Coins)
		coinsLabel.Text = "Monedas: " .. formatNumber(if type(coins) == "number" then coins else 0)

		local anyItem = false
		for itemId, row in rows do
			local count = player:GetAttribute(DataAttributes.itemKey(itemId))
			local amount = if type(count) == "number" then count else 0
			row.Visible = amount > 0
			if amount > 0 then
				anyItem = true
				row.Text = ItemCatalog[itemId].DisplayName .. ": " .. formatNumber(amount)
			end
		end
		emptyLabel.Visible = not anyItem
	end

	-- El HUD vive toda la sesión, así que estas conexiones no necesitan limpiarse
	player:GetAttributeChangedSignal(DataAttributes.Loaded):Connect(render)
	player:GetAttributeChangedSignal(DataAttributes.Coins):Connect(render)
	for _, itemId in itemIds do
		player:GetAttributeChangedSignal(DataAttributes.itemKey(itemId)):Connect(render)
	end

	render()
	gui.Parent = player:WaitForChild("PlayerGui")
end

return HudController
