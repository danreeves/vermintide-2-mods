return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TestCustomUnit` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("TestCustomUnit", {
			mod_script       = "scripts/mods/TestCustomUnit/TestCustomUnit",
			mod_data         = "scripts/mods/TestCustomUnit/TestCustomUnit_data",
			mod_localization = "scripts/mods/TestCustomUnit/TestCustomUnit_localization",
		})
	end,
	packages = {
		"resource_packages/TestCustomUnit/TestCustomUnit",
	},
}
