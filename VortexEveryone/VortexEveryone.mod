return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`VortexEveryone` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("VortexEveryone", {
			mod_script       = "scripts/mods/VortexEveryone/VortexEveryone",
			mod_data         = "scripts/mods/VortexEveryone/VortexEveryone_data",
			mod_localization = "scripts/mods/VortexEveryone/VortexEveryone_localization",
		})
	end,
	packages = {
		"resource_packages/VortexEveryone/VortexEveryone",
	},
}
