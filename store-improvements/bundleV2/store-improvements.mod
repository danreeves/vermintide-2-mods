return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`store-improvements` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("store-improvements", {
			mod_script       = "scripts/mods/store-improvements/store-improvements",
			mod_data         = "scripts/mods/store-improvements/store-improvements_data",
			mod_localization = "scripts/mods/store-improvements/store-improvements_localization",
		})
	end,
	packages = {
		"resource_packages/store-improvements/store-improvements",
	},
}
