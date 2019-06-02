return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`named-items` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("named-items", {
			mod_script       = "scripts/mods/named-items/named-items",
			mod_data         = "scripts/mods/named-items/named-items_data",
			mod_localization = "scripts/mods/named-items/named-items_localization",
		})
	end,
	packages = {
		"resource_packages/named-items/named-items",
	},
}
