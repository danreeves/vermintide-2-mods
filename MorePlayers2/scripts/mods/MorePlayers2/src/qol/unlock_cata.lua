-- luacheck: globals get_mod DifficultyManager ExtraDifficultyRequirements
local mod = get_mod("MorePlayers2")

mod:hook(DifficultyManager, "players_below_difficulty_rank", function()
  return {}
end)

mod:hook(ExtraDifficultyRequirements.kill_all_lords_on_legend, "requirement_function", function()
  return true
end)
