return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`UnitExplorer` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("UnitExplorer", {
			mod_script       = "scripts/mods/UnitExplorer/UnitExplorer",
			mod_data         = "scripts/mods/UnitExplorer/UnitExplorer_data",
			mod_localization = "scripts/mods/UnitExplorer/UnitExplorer_localization",
		})
	end,
	packages = {
		"resource_packages/UnitExplorer/UnitExplorer",
	},
}
