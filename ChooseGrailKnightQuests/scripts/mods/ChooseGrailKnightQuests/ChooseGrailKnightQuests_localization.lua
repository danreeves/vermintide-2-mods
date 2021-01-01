-- luacheck: globals Localize PassiveAbilityQuestingKnight
local mod = get_mod("ChooseGrailKnightQuests")

local old = Managers.mechanism
Managers.mechanism = {
  current_mechanism_name = function()end
}
local quests = PassiveAbilityQuestingKnight:new({},{},{player={unique_id = function()end}})
quests._tomes_allowed = true
quests._grims_allowed  = true
local all_quests = quests:_generate_quest_pool()
Managers.mechanism = old

local localizations = {
  mod_description = {
    en = "Choose which Grail Knight quests you get. DOESN'T ALLOW DUPLICATES",
  },
  quest1 = {
    en = "Quest 1",
  },
  quest2 = {
    en = "Quest 2",
  },
  quest3 = {
    en = "Quest 3",
  }
}

local function strim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

for _, quest in pairs(all_quests) do
  local name = tostring(strim(string.format(Localize(quest.reward), "")))
  localizations[quest.reward] = {
	en = name
  }
end

return localizations
