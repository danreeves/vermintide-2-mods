return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`WeaponEditor` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("WeaponEditor", {
			mod_script       = "scripts/mods/WeaponEditor/WeaponEditor",
			mod_data         = "scripts/mods/WeaponEditor/WeaponEditor_data",
			mod_localization = "scripts/mods/WeaponEditor/WeaponEditor_localization",
		})
	end,
	packages = {
		"resource_packages/WeaponEditor/WeaponEditor",
	},
}
