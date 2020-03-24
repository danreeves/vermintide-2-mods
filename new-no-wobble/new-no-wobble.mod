return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`new-no-wobble` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("new-no-wobble", {
			mod_script       = "scripts/mods/new-no-wobble/new-no-wobble",
			mod_data         = "scripts/mods/new-no-wobble/new-no-wobble_data",
			mod_localization = "scripts/mods/new-no-wobble/new-no-wobble_localization",
		})
	end,
	packages = {
		"resource_packages/new-no-wobble/new-no-wobble",
	},
}
