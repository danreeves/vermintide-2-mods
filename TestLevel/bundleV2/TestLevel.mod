return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TestLevel` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("TestLevel", {
			mod_script       = "scripts/mods/TestLevel/TestLevel",
			mod_data         = "scripts/mods/TestLevel/TestLevel_data",
			mod_localization = "scripts/mods/TestLevel/TestLevel_localization",
		})
	end,
	packages = {
		"resource_packages/TestLevel/TestLevel",
	},
}
