return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MMONames2` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("MMONames2", {
			mod_script       = "scripts/mods/MMONames2/MMONames2",
			mod_data         = "scripts/mods/MMONames2/MMONames2_data",
			mod_localization = "scripts/mods/MMONames2/MMONames2_localization",
		})
	end,
	packages = {
		"resource_packages/MMONames2/MMONames2",
	},
}
