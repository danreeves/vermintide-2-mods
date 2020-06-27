-- luacheck: globals get_mod Localize DifficultySettings WeaveSettings WeaveManager
local mod = get_mod("WeaveExporter")

local function gsc(weave, key)
  local active_weave = {
    _active_weave_name = weave.name,
  }
  return (1 + WeaveManager.get_scaling_value(active_weave, key)) * 100
end

local weave_extra_data = {
  "time_to_explode",
  "follow_time",
  "power_level_player",
  "spawn_rate",
  "power_level_ai",
  "radius",
  "chase_speed",
  "damage",
  "wait_time",
  "chase_time",
  "curse_rate",
  "value",
  "light_radius",
  "damage_taken",
  "respawn_rate",
  "thorns_damage",
  "thorns_life_time",
  "thorns_buff_duration",
  "buff_time_player",
  "buff_time_enemy",
}

local function write(filename, contents)
  local file = io.open(filename, "w+")
  file:write(contents)
  file:close()
end

mod:command("export_weaves", "Export weave data", function()
  local data = {}
  for _, weave in pairs(WeaveSettings.templates_ordered) do
    local row = {}
    row.weave = weave.tier
    row.difficulty = Localize(DifficultySettings[weave.difficulty_key].display_name)
    row.wind = weave.wind
    row.strength = weave.wind_strength
    row.level = Localize(weave.objectives[1].base_level_id)
    row.objective = Localize(weave.objectives[1].display_name)
    row.arena_objective = Localize(weave.objectives[2].display_name)
    row.enemy_damage = string.format("%d%%", gsc(weave, "enemy_damage"))
    row.diminishing_damage = string.format("%d%%", gsc(weave, "diminishing_damage"))
    -- local extra_index = 0
    -- for i = 1, #weave_extra_data, 1 do
    --   local key = weave_extra_data[i]
    --   local val = WindSettings[weave.wind][key][weave.difficulty_key]
    --   if val then
    --     extra_index = extra_index + 1
    --     row["extra_mutator_setting_" .. extra_index] = key .. "=" .. val
    --   end
    -- end
    table.insert(data, row)
  end

  write('C:\\dev\\weave_data.json', cjson.encode(data))
end)
