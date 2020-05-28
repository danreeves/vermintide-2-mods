return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`EpicGamerCrosshairs` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("EpicGamerCrosshairs", {
			mod_script       = "scripts/mods/EpicGamerCrosshairs/EpicGamerCrosshairs",
			mod_data         = "scripts/mods/EpicGamerCrosshairs/EpicGamerCrosshairs_data",
			mod_localization = "scripts/mods/EpicGamerCrosshairs/EpicGamerCrosshairs_localization",
		})
	end,
	packages = {
		"resource_packages/EpicGamerCrosshairs/EpicGamerCrosshairs",
	},
}
