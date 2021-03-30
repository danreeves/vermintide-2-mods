return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Badgers` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("Badgers", {
			mod_script       = "scripts/mods/Badgers/Badgers",
			mod_data         = "scripts/mods/Badgers/Badgers_data",
			mod_localization = "scripts/mods/Badgers/Badgers_localization",
		})
	end,
	packages = {
		"resource_packages/Badgers/Badgers",
	},
}
