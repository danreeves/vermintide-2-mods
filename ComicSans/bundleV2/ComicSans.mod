return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ComicSans` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ComicSans", {
			mod_script       = "scripts/mods/ComicSans/ComicSans",
			mod_data         = "scripts/mods/ComicSans/ComicSans_data",
			mod_localization = "scripts/mods/ComicSans/ComicSans_localization",
		})
	end,
	packages = {
		"resource_packages/ComicSans/ComicSans",
	},
}
