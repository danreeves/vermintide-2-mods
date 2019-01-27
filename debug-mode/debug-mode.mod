return {
	run = function()
		fassert(rawget(_G, "new_mod"), "debug-mode must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("debug-mode", {
			mod_script       = "scripts/mods/debug-mode/debug-mode",
			mod_data         = "scripts/mods/debug-mode/debug-mode_data",
			mod_localization = "scripts/mods/debug-mode/debug-mode_localization"
		})
	end,
	packages = {
		"resource_packages/debug-mode/debug-mode"
	}
}
