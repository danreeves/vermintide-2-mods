-- luacheck: globals get_mod Development DebugManager DebugDrawer World Vector3 Unit QuickDrawer Managers Color TerrorEventBlueprints
local mod = get_mod("FoWMod")

local enabled = false
Development._hardcoded_dev_params.disable_debug_draw = not enabled
script_data.disable_debug_draw = not enabled

DebugManager.drawer = function (self, options)
  options = options or {}
  local drawer_name = options.name
  local drawer
  local drawer_api = DebugDrawer -- MODIFIED. We just want debug drawer

  if drawer_name == nil then
    local line_object = World.create_line_object(self._world)
    drawer = drawer_api:new(line_object, options.mode)
    self._drawers[#self._drawers + 1] = drawer
  elseif self._drawers[drawer_name] == nil then
    local line_object = World.create_line_object(self._world)
    drawer = drawer_api:new(line_object, options.mode)
    self._drawers[drawer_name] = drawer
  else
    drawer = self._drawers[drawer_name]
  end

  return drawer
end

mod:command("debug_spawners", "Draw the spawners", function()
  enabled = not enabled
  Development._hardcoded_dev_params.disable_debug_draw = not enabled
  script_data.disable_debug_draw = not enabled
  if not enabled then
    QuickDrawer:reset()
  end
end)

function mod.update()
  if enabled then
    mod.draw_debug_spawners()
  end
end

function mod.draw_debug_spawners()
  local z = Vector3.up() * 0.5
  if not Managers.state.entity then
    return
  end
  local spawner_system = Managers.state.entity:system("spawner_system")
  local level_key = Managers.state.game_mode:level_key()
  local color = Color(255, 0, 200, 0)
  local color_vector = Vector3(255, 0, 200, 0) -- luacheck: ignore
  local text_size = 0.5
  local terror_events = TerrorEventBlueprints[level_key]

  local debug_text =  Managers.state.debug_text
  if not terror_events then
    return
  end

  debug_text:clear_world_text("category: spawner_id")
  for key, event in pairs(terror_events) do
    for _, tbl in pairs(event) do
      if tbl and tbl.spawner_id then
        local spawner_unit = spawner_system:get_raw_spawner_unit(tbl.spawner_id)
        if spawner_unit then
          local pos = Unit.local_position(spawner_unit, 0)
          QuickDrawer:sphere(pos + z, 0.5, color)
          debug_text:output_world_text(tbl.spawner_id, text_size, pos+z, nil, "category: spawner_id", color_vector)
        else
          local spawners = spawner_system._id_lookup[tbl.spawner_id]
          if not spawners then
            mod:echo("No unit for %s", tbl.spawner_id)
          end
          for _, spawner in pairs(spawners) do
            local pos = Unit.local_position(spawner, 0)
            QuickDrawer:sphere(pos + z, 0.5, color)
            debug_text:output_world_text(tbl.spawner_id, text_size, pos+z, nil, "category: spawner_id", color_vector)
          end
        end
      end
    end
  end

  if Managers.state.debug then
    for _, drawer in pairs(Managers.state.debug._drawers) do
      drawer:update(Managers.state.debug._world)
    end
  end
end
