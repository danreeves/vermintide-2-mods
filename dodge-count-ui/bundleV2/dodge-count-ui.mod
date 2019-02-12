return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`dodge-count-ui` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("dodge-count-ui", {
			mod_script       = "scripts/mods/dodge-count-ui/dodge-count-ui",
			mod_data         = "scripts/mods/dodge-count-ui/dodge-count-ui_data",
			mod_localization = "scripts/mods/dodge-count-ui/dodge-count-ui_localization",
		})
	end,
	packages = {
		"resource_packages/dodge-count-ui/dodge-count-ui",
	},
}
