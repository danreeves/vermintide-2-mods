return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`new-sticky-grim` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("new-sticky-grim", {
			mod_script       = "scripts/mods/new-sticky-grim/new-sticky-grim",
			mod_data         = "scripts/mods/new-sticky-grim/new-sticky-grim_data",
			mod_localization = "scripts/mods/new-sticky-grim/new-sticky-grim_localization",
		})
	end,
	packages = {
		"resource_packages/new-sticky-grim/new-sticky-grim",
	},
}
