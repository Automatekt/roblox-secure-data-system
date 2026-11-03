--!strict
-- Carga los datos de cada jugador al entrar y los libera al salir.
-- ProfileStore se encarga del bloqueo de sesión (un jugador no puede estar
-- cargado en dos servidores a la vez), el guardado automático y el guardado
-- al cerrar el servidor.

local Players = game:GetService("Players")

local ProfileStore = require(script.Parent.Packages.ProfileStore)
local DataTemplate = require(script.Parent.DataTemplate)

local STORE_NAME = "PlayerData"
local KICK_LOAD_FAILED = "No se pudieron cargar tus datos. Vuelve a entrar en unos minutos."
local KICK_SESSION_ENDED = "Tu sesión de datos terminó (¿entraste desde otro servidor?). Vuelve a entrar."

local store = ProfileStore.New(STORE_NAME, DataTemplate)
local profiles: { [Player]: ProfileStore.Profile<DataTemplate.PlayerData> } = {}

local DataService = {}

-- Devuelve los datos del jugador, o nil si todavía no cargaron o ya salió.
function DataService.getData(player: Player): DataTemplate.PlayerData?
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return nil
	end
	return profile.Data
end

local function loadPlayer(player: Player)
	local key = "Player_" .. player.UserId

	-- Si el jugador se va mientras esperamos, dejamos de intentar cargar
	local ok, profile = pcall(function()
		-- (":: any" porque el tipo de ProfileStore no declara el parámetro Cancel)
		return store:StartSessionAsync(key, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		} :: any)
	end)

	if not ok or profile == nil then
		-- Sin datos no se juega: así nunca se pisa un guardado con datos vacíos
		if player.Parent == Players then
			player:Kick(KICK_LOAD_FAILED)
		end
		return
	end

	-- El jugador salió justo cuando terminó de cargar: soltamos el perfil
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Otro servidor tomó el perfil, o se cerró la sesión: se expulsa al jugador
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick(KICK_SESSION_ENDED)
		end
	end)

	profiles[player] = profile
end

local function releasePlayer(player: Player)
	local profile = profiles[player]
	profiles[player] = nil
	if profile ~= nil then
		profile:EndSession()
	end
end

function DataService.start()
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(releasePlayer)

	-- Jugadores que ya estaban dentro antes de que arrancara este servicio
	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end
end

return DataService
