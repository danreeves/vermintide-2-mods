return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`enable-imgui` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("enable-imgui", {
			mod_script       = "scripts/mods/enable-imgui/enable-imgui",
			mod_data         = "scripts/mods/enable-imgui/enable-imgui_data",
			mod_localization = "scripts/mods/enable-imgui/enable-imgui_localization",
		})
	end,
	packages = {
		"resource_packages/enable-imgui/enable-imgui",
	},
}
