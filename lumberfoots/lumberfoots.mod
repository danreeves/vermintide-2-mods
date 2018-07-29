return {
	run = function()
		fassert(rawget(_G, "new_mod"), "lumberfoots must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("lumberfoots", {
			mod_script       = "scripts/mods/lumberfoots/lumberfoots",
			mod_data         = "scripts/mods/lumberfoots/lumberfoots_data",
			mod_localization = "scripts/mods/lumberfoots/lumberfoots_localization"
		})
	end,
	packages = {
		"resource_packages/lumberfoots/lumberfoots"
	}
}
