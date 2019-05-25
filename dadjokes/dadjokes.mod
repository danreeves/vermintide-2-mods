return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`dadjokes` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("dadjokes", {
			mod_script       = "scripts/mods/dadjokes/dadjokes",
			mod_data         = "scripts/mods/dadjokes/dadjokes_data",
			mod_localization = "scripts/mods/dadjokes/dadjokes_localization",
		})
	end,
	packages = {
		"resource_packages/dadjokes/dadjokes",
	},
}
