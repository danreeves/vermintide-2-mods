-- luacheck: globals get_mod EndViewStateScore
local mod = get_mod("MorePlayers2")

mod:hook(EndViewStateScore, "_set_topic_data", function (func, self, player_data, widget_index)
  local widget = self._score_widgets[widget_index]
  -- Check we will get a widget before we run the function
  if not widget then
    return
  else
    return func(self, player_data, widget_index)
  end
end)

mod:hook(EndViewStateScore, "_setup_player_scores", function (func, self, players_session_scores)
  local scores = {}

  local stat_names = {"kills_total", "damage_dealt", "damage_taken", "revives"}

  for _, stat_name in pairs(stat_names) do
    local highest_value = -1e309
    local highest_player = nil
    local highest_player_key = nil

    for key, data in pairs(players_session_scores) do
      local stat = nil
      for _, s in pairs(data.group_scores.offense) do
        if s.stat_name == stat_name then
          stat =  s
        end
      end
      local current_value = stat.score
      if current_value > highest_value then
        highest_value = current_value
        highest_player = data
        highest_player_key = key
      end
    end

    scores[highest_player_key .. stat_name] = highest_player
  end

  return func(self, scores)
end)
