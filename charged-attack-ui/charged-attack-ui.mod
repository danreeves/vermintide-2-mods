return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`charged-attack-ui` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("charged-attack-ui", {
			mod_script       = "scripts/mods/charged-attack-ui/charged-attack-ui",
			mod_data         = "scripts/mods/charged-attack-ui/charged-attack-ui_data",
			mod_localization = "scripts/mods/charged-attack-ui/charged-attack-ui_localization",
		})
	end,
	packages = {
		"resource_packages/charged-attack-ui/charged-attack-ui",
	},
}
