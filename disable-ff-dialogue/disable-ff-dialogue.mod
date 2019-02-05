return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`disable-ff-dialogue` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("disable-ff-dialogue", {
			mod_script       = "scripts/mods/disable-ff-dialogue/disable-ff-dialogue",
			mod_data         = "scripts/mods/disable-ff-dialogue/disable-ff-dialogue_data",
			mod_localization = "scripts/mods/disable-ff-dialogue/disable-ff-dialogue_localization",
		})
	end,
	packages = {
		"resource_packages/disable-ff-dialogue/disable-ff-dialogue",
	},
}
