return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`wikitool` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("wikitool", {
			mod_script       = "scripts/mods/wikitool/wikitool",
			mod_data         = "scripts/mods/wikitool/wikitool_data",
			mod_localization = "scripts/mods/wikitool/wikitool_localization",
		})
	end,
	packages = {
		"resource_packages/wikitool/wikitool",
	},
}
