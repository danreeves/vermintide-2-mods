return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`WeaponTweaks` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("WeaponTweaks", {
			mod_script       = "scripts/mods/WeaponTweaks/WeaponTweaks",
			mod_data         = "scripts/mods/WeaponTweaks/WeaponTweaks_data",
			mod_localization = "scripts/mods/WeaponTweaks/WeaponTweaks_localization",
		})
	end,
	packages = {
		"resource_packages/WeaponTweaks/WeaponTweaks",
	},
}
