-- luacheck: globals Boot Managers get_mod script_data Development Debug DebugDrawerRelease DebugDrawer LineObject
local mod = get_mod("debug-slots")
mod:dofile("scripts/mods/debug-slots/game-code/debug-drawer")
local debuggers = mod:dofile("scripts/mods/debug-slots/game-code/ai_slot_system")
local debug_draw_slots = debuggers.debug_draw_slots
-- local debug_print_slots_count = debuggers.debug_print_slots_count

local enabled = false

mod:command('debug_slots', 'Enable the Slot Debug UI', function()
  enabled = not enabled

  script_data.disable_debug_draw = not enabled
  Development._hardcoded_dev_params.disable_debug_draw = not enabled
end)

mod:hook_safe(Boot, 'game_update', function(_, real_world_dt)
  if enabled then
    local t = Managers.time:time("main")
    local ai_slot_system = Managers.state.entity:system("ai_slot_system")
    local target_units = ai_slot_system.target_units
    local unit_extension_data = ai_slot_system.unit_extension_data
    local nav_world = ai_slot_system.nav_world
    debug_draw_slots(target_units, unit_extension_data, nav_world, t)
    if Managers.state.debug then
      for _, drawer in pairs(Managers.state.debug._drawers) do
        drawer:update(Managers.state.debug._world)
      end
    end
  end
end)

