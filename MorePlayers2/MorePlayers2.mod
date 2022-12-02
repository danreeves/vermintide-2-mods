return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MorePlayers2` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("MorePlayers2", {
			mod_script       = "scripts/mods/MorePlayers2/MorePlayers2",
			mod_data         = "scripts/mods/MorePlayers2/MorePlayers2_data",
			mod_localization = "scripts/mods/MorePlayers2/MorePlayers2_localization",
		})
	end,
	packages = {
		"resource_packages/MorePlayers2/MorePlayers2",
		"resource_packages/MorePlayers2/MorePlayersNetworkConfig"
	},
}
