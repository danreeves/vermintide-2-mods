return {
	run = function()
		fassert(rawget(_G, "new_mod"), "letterbox-tweaks must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("letterbox-tweaks", {
			mod_script       = "scripts/mods/letterbox-tweaks/letterbox-tweaks",
			mod_data         = "scripts/mods/letterbox-tweaks/letterbox-tweaks_data",
			mod_localization = "scripts/mods/letterbox-tweaks/letterbox-tweaks_localization"
		})
	end,
	packages = {
		"resource_packages/letterbox-tweaks/letterbox-tweaks"
	}
}
