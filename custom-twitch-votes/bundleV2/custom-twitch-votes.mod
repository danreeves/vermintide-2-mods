return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`custom-twitch-votes` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("custom-twitch-votes", {
			mod_script       = "scripts/mods/custom-twitch-votes/custom-twitch-votes",
			mod_data         = "scripts/mods/custom-twitch-votes/custom-twitch-votes_data",
			mod_localization = "scripts/mods/custom-twitch-votes/custom-twitch-votes_localization",
		})
	end,
	packages = {
		"resource_packages/custom-twitch-votes/custom-twitch-votes",
	},
}
