return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`steam-rich-presence` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("steam-rich-presence", {
			mod_script       = "scripts/mods/steam-rich-presence/steam-rich-presence",
			mod_data         = "scripts/mods/steam-rich-presence/steam-rich-presence_data",
			mod_localization = "scripts/mods/steam-rich-presence/steam-rich-presence_localization",
		})
	end,
	packages = {
		"resource_packages/steam-rich-presence/steam-rich-presence",
	},
}
