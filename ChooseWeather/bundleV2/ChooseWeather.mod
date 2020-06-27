return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ChooseWeather` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ChooseWeather", {
			mod_script       = "scripts/mods/ChooseWeather/ChooseWeather",
			mod_data         = "scripts/mods/ChooseWeather/ChooseWeather_data",
			mod_localization = "scripts/mods/ChooseWeather/ChooseWeather_localization",
		})
	end,
	packages = {
		"resource_packages/ChooseWeather/ChooseWeather",
	},
}
