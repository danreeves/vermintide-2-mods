return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`super-vortex` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("super-vortex", {
			mod_script       = "scripts/mods/super-vortex/super-vortex",
			mod_data         = "scripts/mods/super-vortex/super-vortex_data",
			mod_localization = "scripts/mods/super-vortex/super-vortex_localization",
		})
	end,
	packages = {
		"resource_packages/super-vortex/super-vortex",
	},
}
