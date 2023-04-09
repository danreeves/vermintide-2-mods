-- luacheck: globals get_mod PassiveAbilityQuestingKnight InGameChallengeTemplates table.clone
local mod = get_mod("ChooseGrailKnightQuests")
local all_quests = require("scripts/mods/ChooseGrailKnightQuests/get_quests")

local options = {}
for _, quest in ipairs(all_quests) do
	table.insert(options, { text = quest, value = quest })
end

return {
	name = "Choose Grail Knight Quests",
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "quest1",
				type = "dropdown",
				default_value = all_quests[1],
				options = table.clone(options),
			},
			{
				setting_id = "quest2",
				type = "dropdown",
				default_value = all_quests[2],
				options = table.clone(options),
			},
			{
				setting_id = "quest3",
				type = "dropdown",
				default_value = all_quests[3],
				options = table.clone(options),
			},
		},
	},
}
