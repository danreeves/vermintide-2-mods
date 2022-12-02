-- luacheck: globals get_mod script_data GameModeAdventure GameModeDeus
local mod = get_mod("MorePlayers2")

script_data.cap_num_bots = mod:get("num_bots")

mod:hook(GameModeAdventure, "_get_first_available_bot_profile", function ()
  return 1, 4
end)

mod:hook(GameModeDeus, "_get_first_available_bot_profile", function ()
  return 1, 4
end)
