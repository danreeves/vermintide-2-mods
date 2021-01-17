return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ChooseGrailKnightQuests` mod must be lower than Vermintide Mod Framework in your launcher's load order.")

		new_mod("ChooseGrailKnightQuests", {
			mod_script       = "scripts/mods/ChooseGrailKnightQuests/ChooseGrailKnightQuests",
			mod_data         = "scripts/mods/ChooseGrailKnightQuests/ChooseGrailKnightQuests_data",
			mod_localization = "scripts/mods/ChooseGrailKnightQuests/ChooseGrailKnightQuests_localization",
		})
	end,
	packages = {
		"resource_packages/ChooseGrailKnightQuests/ChooseGrailKnightQuests",
	},
}
