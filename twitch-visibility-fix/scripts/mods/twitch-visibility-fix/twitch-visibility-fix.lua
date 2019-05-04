local mod = get_mod("twitch-visibility-fix")

mod:hook(_G, "local_require", function(func, filename)
  local returns = func(filename)
  if filename == "scripts/ui/views/ingame_hud_definitions" then
    for _, component in ipairs(returns.components) do
      if component.class_name == "TwitchVoteUI" then
        component.visibility_groups = {
          "realism",
          "game_mode_disable_hud",
          "dead",
          "alive"
        }
      end
    end
  end
  return returns
end)
