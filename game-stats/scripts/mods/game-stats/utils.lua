local mod = get_mod("game-stats")

mod.stats_for_class = function(classname)
  local levels = mod.levels
  local difficulties = mod.difficulties
  local player_manager = Managers.player
  local player = player_manager:local_player()
  local stats_id = player:stats_id()
  local stats_db = player_manager:statistics_db()

  local total_wins = 0
  local difficulty_total_wins = {}
  local level_total_wins = {}

  for i, level in pairs(levels) do
    local level_count = 0
    for i, difficulty in pairs(difficulties) do
      local current_wins = stats_db:get_persistent_stat(stats_id, "completed_career_levels", classname, level, difficulty) or 0
      difficulty_total_wins[difficulty] = (difficulty_total_wins[difficulty] or 0) + current_wins
      level_total_wins[level] = (level_total_wins[level] or 0) + current_wins
      total_wins = total_wins + current_wins
    end
  end

  return total_wins, difficulty_total_wins, level_total_wins
end

mod.debug_stats_db = function()
  local player_manager = Managers.player
  local player = player_manager:local_player()
  local stats_id = player:stats_id()
  local stats_db = player_manager:statistics_db()

  mod:dump(stats_db.statistics, 'statistics_db', 1)
end

mod.debug_interesting_stats = function(interesting)
  local player_manager = Managers.player
  local player = player_manager:local_player()
  local stats_id = player:stats_id()
  local stats_db = player_manager:statistics_db()

  mod:echo('-------------')
  for i, key in pairs(mod['interesting_'..interesting]) do
    mod:dump(stats_db.statistics[stats_id][key], key, 4)
  end
end

mod:command('debug_stats', '[DEBUG]', function(arg)
  local type = arg or 'numbers'
  mod.debug_interesting_stats(arg)
end)

return
