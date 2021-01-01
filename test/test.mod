return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`test` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("test", {
			mod_script       = "scripts/mods/test/test",
			mod_data         = "scripts/mods/test/test_data",
			mod_localization = "scripts/mods/test/test_localization",
		})
	end,
	packages = {
		"resource_packages/test/test",
	},
}
