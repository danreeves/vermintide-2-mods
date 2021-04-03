return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ChooChooMF` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ChooChooMF", {
			mod_script       = "scripts/mods/ChooChooMF/ChooChooMF",
			mod_data         = "scripts/mods/ChooChooMF/ChooChooMF_data",
			mod_localization = "scripts/mods/ChooChooMF/ChooChooMF_localization",
		})
	end,
	packages = {
		"resource_packages/ChooChooMF/ChooChooMF",
	},
}
