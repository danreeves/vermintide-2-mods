-- luacheck: globals get_mod LevelTransitionHandler LevelHelper
local mod = get_mod("ChooseWeather")

mod:hook_safe(LevelTransitionHandler, "set_next_level", function(self)
  self.picked_environment_id = mod:get("environment_id")
end)

mod:hook_origin(LevelHelper, "get_environment_variation_id", function()
  return mod:get("environment_id")
end)
