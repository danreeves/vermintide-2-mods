return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`aory-no-boss` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("aory-no-boss", {
			mod_script       = "scripts/mods/aory-no-boss/aory-no-boss",
			mod_data         = "scripts/mods/aory-no-boss/aory-no-boss_data",
			mod_localization = "scripts/mods/aory-no-boss/aory-no-boss_localization",
		})
	end,
	packages = {
		"resource_packages/aory-no-boss/aory-no-boss",
	},
}
