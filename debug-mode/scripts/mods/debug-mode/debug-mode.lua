local mod = get_mod("debug-mode")

-- Re-enable the DebugDrawerRelease drawer
mod:dofile('scripts/mods/debug-mode/debug-drawer')
local debug_draw_slots = mod:dofile('scripts/mods/debug-mode/draw-slots')

script_data.force_debug_disabled = false
script_data.debug_enabled = true
script_data.disable_debug_draw = false

-- script_data.debug_key_handler_visible = true
-- script_data.disable_debug_position_lookup = false
-- script_data.enabled_detailed_tooltips = true
-- script_data.debug_interactions = true
-- script_data.debug_behavior_trees = true
-- script_data.ai_debugger_freeflight_only = false
-- GameSettingsDevelopment.disable_free_flight = false

function mod:toggle_with_hotkey()
  local active = not DebugScreen.active
  Debug.active = active
  DebugScreen.active = active
  DebugScreen.is_blocked = not active
  DebugKeyHandler.enabled = active

  local debug_key_input_manager = DebugKeyHandler.input_manager:get_service("Debug")
  if debug_key_input_manager then
    Managers.input:device_unblock_service("keyboard", 1, "Debug")
  else
    mod:echo('NOT got Debug input_service')
  end
end

mod:hook_safe(LocomotionSystem, 'update', function(self, context, t)
  local dt = context.dt
  local input_manager = Managers.input
  local input_service = input_manager:get_service("DebugMenu")

  if DebugScreen.active then
    DebugScreen.update(dt, t, input_service, input_manager)
  end

  local ai_system = Managers.state.entity:system("ai_system")

  if ai_system.ai_debugger then
    local ai_debugger = ai_system.ai_debugger

    ai_debugger:update(dt, t)

    if ai_debugger.show_slots then
      local ai_slot_system = Managers.state.entity:system("ai_slot_system")
      local target_units = ai_slot_system.target_units
      local unit_extension_data = ai_slot_system.unit_extension_data
      local nav_world = ai_slot_system.nav_world
      debug_draw_slots.update(target_units, unit_extension_data, nav_world, t)
    else
      Managers.state.debug_text:clear_world_text()
      Managers.state.debug_text:clear_unit_text()
    end
  end

  Managers.state.debug:update(dt, t)
end)
