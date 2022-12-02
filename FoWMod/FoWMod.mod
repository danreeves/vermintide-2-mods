return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`FoWMod` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("FoWMod", {
			mod_script       = "scripts/mods/FoWMod/FoWMod",
			mod_data         = "scripts/mods/FoWMod/FoWMod_data",
			mod_localization = "scripts/mods/FoWMod/FoWMod_localization",
		})
	end,
	packages = {
		"resource_packages/FoWMod/FoWMod",
	},
}
