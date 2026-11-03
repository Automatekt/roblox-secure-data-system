--!strict
-- Sonidos del cofre. Se reproducen solo en el cliente del dueño, sin posición
-- (suenan igual de fuerte donde esté el jugador).
--
-- Origen de los audios: biblioteca de efectos que Roblox distribuye gratis en el
-- Creator Store, publicada por la cuenta verificada "ProSoundEffects"
-- ("Courtesy of Pro Sound Effects"). Cualquier experiencia puede usarlos.

local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")

type SoundSpec = { id: number, volume: number, note: string }

local SPECS: { [string]: SoundSpec } = {
	Appear = { id = 9116162487, volume = 0.35, note = "Key Dings Metal Clinking 3 (SFX), 2.1 s" },
	Collect = { id = 9113728042, volume = 0.55, note = "Cash Register 1 (SFX), 2.1 s" },
}

local sounds: { [string]: Sound } = {}

local ChestSounds = {}

function ChestSounds.start()
	local group = Instance.new("Folder")
	group.Name = "ChestSounds"
	group.Parent = SoundService

	for name, spec in SPECS do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = "rbxassetid://" .. spec.id
		sound.Volume = spec.volume
		sound.Parent = group
		sounds[name] = sound
	end

	-- Se descargan al entrar para que no haya retraso la primera vez que suenan
	task.spawn(function()
		local list: { Instance } = {}
		for _, sound in sounds do
			table.insert(list, sound)
		end
		ContentProvider:PreloadAsync(list)
		for name, sound in sounds do
			if not sound.IsLoaded then
				warn(`[ChestSounds] el sonido {name} ({SPECS[name].note}) no se pudo cargar`)
			end
		end
	end)
end

function ChestSounds.play(name: string)
	local sound = sounds[name]
	if sound then
		sound:Play()
	end
end

return ChestSounds
