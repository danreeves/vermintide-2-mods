return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`weapon_debug` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("weapon_debug", {
			mod_script       = "scripts/mods/weapon_debug/weapon_debug",
			mod_data         = "scripts/mods/weapon_debug/weapon_debug_data",
			mod_localization = "scripts/mods/weapon_debug/weapon_debug_localization",
		})
	end,
	packages = {
		"resource_packages/weapon_debug/weapon_debug",
	},
}
