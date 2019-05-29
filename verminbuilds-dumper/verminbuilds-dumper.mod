return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`verminbuilds-dumper` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("verminbuilds-dumper", {
			mod_script       = "scripts/mods/verminbuilds-dumper/verminbuilds-dumper",
			mod_data         = "scripts/mods/verminbuilds-dumper/verminbuilds-dumper_data",
			mod_localization = "scripts/mods/verminbuilds-dumper/verminbuilds-dumper_localization",
		})
	end,
	packages = {
		"resource_packages/verminbuilds-dumper/verminbuilds-dumper",
	},
}
