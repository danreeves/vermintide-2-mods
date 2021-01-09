return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ExportMutators` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ExportMutators", {
			mod_script       = "scripts/mods/ExportMutators/ExportMutators",
			mod_data         = "scripts/mods/ExportMutators/ExportMutators_data",
			mod_localization = "scripts/mods/ExportMutators/ExportMutators_localization",
		})
	end,
	packages = {
		"resource_packages/ExportMutators/ExportMutators",
	},
}
