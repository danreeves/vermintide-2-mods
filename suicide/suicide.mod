return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`suicide` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("suicide", {
			mod_script       = "scripts/mods/suicide/suicide",
			mod_data         = "scripts/mods/suicide/suicide_data",
			mod_localization = "scripts/mods/suicide/suicide_localization",
		})
	end,
	packages = {
		"resource_packages/suicide/suicide",
	},
}
