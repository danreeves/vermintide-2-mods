return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`debug-slots` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("debug-slots", {
			mod_script       = "scripts/mods/debug-slots/debug-slots",
			mod_data         = "scripts/mods/debug-slots/debug-slots_data",
			mod_localization = "scripts/mods/debug-slots/debug-slots_localization",
		})
	end,
	packages = {
		"resource_packages/debug-slots/debug-slots",
	},
}
