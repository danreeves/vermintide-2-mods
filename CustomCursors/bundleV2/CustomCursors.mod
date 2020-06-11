return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`CustomCursors` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("CustomCursors", {
			mod_script       = "scripts/mods/CustomCursors/CustomCursors",
			mod_data         = "scripts/mods/CustomCursors/CustomCursors_data",
			mod_localization = "scripts/mods/CustomCursors/CustomCursors_localization",
		})
	end,
	packages = {
		"resource_packages/CustomCursors/CustomCursors",
	},
}
