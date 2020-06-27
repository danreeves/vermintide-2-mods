-- luacheck: globals get_mod PassiveAbilityQuestingKnight
local mod = get_mod("ChooseGrailKnightQuests")

mod:hook(PassiveAbilityQuestingKnight, "_generate_quest_pool", function(func, self)
  local quests = func(self)
  local chosen_quests = {}
  local selected = { mod:get("quest1"), mod:get("quest2"), mod:get("quest3"), "markus_questing_knight_passive_strength_potion" }
  for _, quest in pairs(quests) do
    if table.contains(selected, quest.reward) then
      table.insert(chosen_quests, quest)
    end
  end
  return chosen_quests
end)
