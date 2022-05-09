return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`SkipVote` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("SkipVote", {
			mod_script       = "scripts/mods/SkipVote/SkipVote",
			mod_data         = "scripts/mods/SkipVote/SkipVote_data",
			mod_localization = "scripts/mods/SkipVote/SkipVote_localization",
		})
	end,
	packages = {
		"resource_packages/SkipVote/SkipVote",
	},
}
