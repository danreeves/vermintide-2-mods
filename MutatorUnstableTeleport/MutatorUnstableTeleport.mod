return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`MutatorUnstableTeleport` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("MutatorUnstableTeleport", {
			mod_script       = "scripts/mods/MutatorUnstableTeleport/MutatorUnstableTeleport",
			mod_data         = "scripts/mods/MutatorUnstableTeleport/MutatorUnstableTeleport_data",
			mod_localization = "scripts/mods/MutatorUnstableTeleport/MutatorUnstableTeleport_localization",
		})
	end,
	packages = {
		"resource_packages/MutatorUnstableTeleport/MutatorUnstableTeleport",
	},
}
