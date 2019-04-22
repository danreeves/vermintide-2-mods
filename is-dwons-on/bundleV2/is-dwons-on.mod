return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`is-dwons-on` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("is-dwons-on", {
			mod_script       = "scripts/mods/is-dwons-on/is-dwons-on",
			mod_data         = "scripts/mods/is-dwons-on/is-dwons-on_data",
			mod_localization = "scripts/mods/is-dwons-on/is-dwons-on_localization",
		})
	end,
	packages = {
		"resource_packages/is-dwons-on/is-dwons-on",
	},
}
