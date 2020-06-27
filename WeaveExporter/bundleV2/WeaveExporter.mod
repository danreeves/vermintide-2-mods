return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`WeaveExporter` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("WeaveExporter", {
			mod_script       = "scripts/mods/WeaveExporter/WeaveExporter",
			mod_data         = "scripts/mods/WeaveExporter/WeaveExporter_data",
			mod_localization = "scripts/mods/WeaveExporter/WeaveExporter_localization",
		})
	end,
	packages = {
		"resource_packages/WeaveExporter/WeaveExporter",
	},
}
