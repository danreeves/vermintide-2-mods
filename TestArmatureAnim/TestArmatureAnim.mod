return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`TestArmatureAnim` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("TestArmatureAnim", {
			mod_script       = "scripts/mods/TestArmatureAnim/TestArmatureAnim",
			mod_data         = "scripts/mods/TestArmatureAnim/TestArmatureAnim_data",
			mod_localization = "scripts/mods/TestArmatureAnim/TestArmatureAnim_localization",
		})
	end,
	packages = {
		"resource_packages/TestArmatureAnim/TestArmatureAnim",
	},
}
