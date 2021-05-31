-- luacheck: globals get_mod PassiveAbilityQuestingKnight table.contains
local mod = get_mod("ChooseGrailKnightQuests")

mod:hook(PassiveAbilityQuestingKnight, "_generate_quest_pool", function(func, self)
  local quests = func(self)
  local chosen_quests = {}
  local selected = {
    mod:get("quest1"),
    mod:get("quest2"),
    "deus_" .. mod:get("quest1"),
    "deus_" .. mod:get("quest2"),
  }

  if self._talent_extension:has_talent("markus_questing_knight_passive_additional_quest") then
    table.insert(selected, mod:get("quest3"))
    table.insert(selected, "deus_" .. mod:get("quest3"))
  end

  for _, quest in pairs(quests) do
    if table.contains(selected, quest.reward) then
      table.insert(chosen_quests, quest)
    end
  end

  return chosen_quests
end)
