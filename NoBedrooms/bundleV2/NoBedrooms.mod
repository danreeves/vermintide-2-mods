return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`NoBedrooms` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("NoBedrooms", {
			mod_script       = "scripts/mods/NoBedrooms/NoBedrooms",
			mod_data         = "scripts/mods/NoBedrooms/NoBedrooms_data",
			mod_localization = "scripts/mods/NoBedrooms/NoBedrooms_localization",
		})
	end,
	packages = {
		"resource_packages/NoBedrooms/NoBedrooms",
	},
}
