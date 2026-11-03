--!strict
-- Envía mensajes cortos al dueño de un PlayerGui (recompensa recibida, cooldown...).
-- El servidor solo manda un código y algunos datos; el texto en español lo
-- arma el cliente. Es solo de servidor a cliente: no hay RemoteEvents.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataAttributes = require(ReplicatedStorage.Shared.DataAttributes)

local counters: { [Player]: number } = setmetatable({}, { __mode = "k" }) :: any

local Notifier = {}

-- Formato del atributo: "<número>|<código>|<dato1>|<dato2>..."
-- El número cambia en cada aviso, así el cliente nota incluso un mensaje repetido.
function Notifier.send(player: Player, code: string, ...: string | number)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui == nil then
		return
	end

	local id = (counters[player] or 0) + 1
	counters[player] = id

	local fields = { tostring(id), code }
	for _, value in { ... } do
		table.insert(fields, tostring(value))
	end
	playerGui:SetAttribute(DataAttributes.Notice, table.concat(fields, "|"))
end

return Notifier
