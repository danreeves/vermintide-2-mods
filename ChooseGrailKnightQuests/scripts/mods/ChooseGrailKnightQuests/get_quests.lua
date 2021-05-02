-- luacheck: globals Localize PassiveAbilityQuestingKnight Managers get_mod

-- Mock the things we need
local old_mechanism = Managers.mechanism
Managers.mechanism = {
  current_mechanism_name = function()end
}

local old_game_mode = Managers.state.game_mode and Managers.state.game_mode or nil
Managers.state.game_mode = {
  is_round_started = function() return true end,
}

local quests = PassiveAbilityQuestingKnight:new({},{},{player={unique_id = function()end}})
quests._tomes_allowed = true
quests._grims_allowed  = true
local all_quests = quests:_generate_quest_pool()

-- Put back the old versions
Managers.mechanism = old_mechanism
Managers.state.game_mode = old_game_mode

return all_quests
