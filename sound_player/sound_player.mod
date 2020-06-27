return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`sound_player` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("sound_player", {
			mod_script       = "scripts/mods/sound_player/sound_player",
			mod_data         = "scripts/mods/sound_player/sound_player_data",
			mod_localization = "scripts/mods/sound_player/sound_player_localization",
		})
	end,
	packages = {
		"resource_packages/sound_player/sound_player",
	},
}
