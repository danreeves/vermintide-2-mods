-- luacheck: globals get_mod PassiveAbilityQuestingKnight InGameChallengeTemplates
local mod = get_mod("ChooseGrailKnightQuests")

local all_quests = PassiveAbilityQuestingKnight._generate_quest_pool({
  _tomes_allowed = true,
  _grims_allowed = true,
})

local quest_names = {}
local options = {}

for _, quest in pairs(all_quests) do
  table.insert(quest_names, quest.reward)
  table.insert(options, { text = quest.reward, value = quest.reward })
end

return {
  name = "ChooseGrailKnightQuests",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id    = "quest1",
        type          = "dropdown",
        default_value = quest_names[1],
        options = options,
      },
      {
        setting_id    = "quest2",
        type          = "dropdown",
        default_value = quest_names[2],
        options = options,
      },
      {
        setting_id    = "quest3",
        type          = "dropdown",
        default_value = quest_names[3],
        options = options,
      },
    },
  },
}
