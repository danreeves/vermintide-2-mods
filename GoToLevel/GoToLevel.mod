return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`GoToLevel` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("GoToLevel", {
			mod_script       = "scripts/mods/GoToLevel/GoToLevel",
			mod_data         = "scripts/mods/GoToLevel/GoToLevel_data",
			mod_localization = "scripts/mods/GoToLevel/GoToLevel_localization",
		})
	end,
	packages = {
		"resource_packages/GoToLevel/GoToLevel",
	},
}
