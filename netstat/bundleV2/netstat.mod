return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`netstat` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("netstat", {
			mod_script       = "scripts/mods/netstat/netstat",
			mod_data         = "scripts/mods/netstat/netstat_data",
			mod_localization = "scripts/mods/netstat/netstat_localization",
		})
	end,
	packages = {
		"resource_packages/netstat/netstat",
	},
}
