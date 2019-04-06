return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`custom-frames` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("custom-frames", {
			mod_script       = "scripts/mods/custom-frames/custom-frames",
			mod_data         = "scripts/mods/custom-frames/custom-frames_data",
			mod_localization = "scripts/mods/custom-frames/custom-frames_localization",
		})
	end,
	packages = {
		"resource_packages/custom-frames/custom-frames",
	},
}
