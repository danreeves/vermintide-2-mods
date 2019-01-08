return {
	run = function()
		fassert(rawget(_G, "new_mod"), "game-stats must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("game-stats", {
			mod_script       = "scripts/mods/game-stats/game-stats",
			mod_data         = "scripts/mods/game-stats/game-stats_data",
			mod_localization = "scripts/mods/game-stats/game-stats_localization"
		})
	end,
	packages = {
		"resource_packages/game-stats/game-stats"
	}
}
