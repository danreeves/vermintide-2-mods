return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`twitch-visibility-fix` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("twitch-visibility-fix", {
			mod_script       = "scripts/mods/twitch-visibility-fix/twitch-visibility-fix",
			mod_data         = "scripts/mods/twitch-visibility-fix/twitch-visibility-fix_data",
			mod_localization = "scripts/mods/twitch-visibility-fix/twitch-visibility-fix_localization",
		})
	end,
	packages = {
		"resource_packages/twitch-visibility-fix/twitch-visibility-fix",
	},
}
