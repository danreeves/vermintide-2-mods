local mod = get_mod("debug-mode")

-- Re-enable the DebugDrawerRelease drawer
mod:dofile('scripts/mods/debug-mode/debug-drawer')
-- A copy of the debug_draw_slots from ai_slot_system.lua
local debug_draw_slots = mod:dofile('scripts/mods/debug-mode/draw-slots')

-- save some time and default this stuff
script_data.debug_enabled = true
script_data.force_debug_disabled = false
script_data.disable_debug_draw = false
script_data.debug_key_handler_visible = true
Development._hardcoded_dev_params.force_debug_disabled = false
Development._hardcoded_dev_params.disable_debug_draw = false
Development._hardcoded_dev_params.debug_key_handler_visible = true

-- Stripped from release, needs to be redefined.
-- It should map consideration tables to names but /shrug
UtilityConsiderationNames = {}

-- Close the debug stuff when entering a loading screen
mod:hook_safe(StateLoading, 'on_enter', function()
  Debug.active = false
  DebugScreen.active = false
  DebugKeyHandler.enabled = false
  Managers.input:device_unblock_all_services("keyboard", 1)
  Managers.input:device_unblock_all_services("mouse", 1)
end)

function mod:toggle_debug()
  local active = not Debug.active
  Debug.active = active
  DebugKeyHandler.enabled = active

  local debug_key_input_manager = DebugKeyHandler.input_manager:get_service("Debug")
  if debug_key_input_manager then
    if active then
      Managers.input:device_unblock_service("keyboard", 1, "Debug")
      Managers.input:device_unblock_service("mouse", 1, "Debug")
    else
      Managers.input:device_block_service("keyboard", 1, "Debug")
      Managers.input:device_block_service("mouse", 1, "Debug")
    end
  else
    mod:echo('NOT got Debug input_service')
  end
end

function mod:toggle_debug_menu()
  local active = not DebugScreen.active
  DebugScreen.active = active
  DebugScreen.is_blocked = not active
end

mod:hook_safe(Boot, 'game_update', function(self, real_world_dt)
  local dt = Managers.time:scaled_delta_time(real_world_dt)
  local t = Managers.time:time("main")
  local input_manager = Managers.input
  local input_service = input_manager:get_service("DebugMenu")

  if Managers.state.debug_text then
    Managers.state.debug_text:clear_world_text()
    Managers.state.debug_text:clear_unit_text()
  end

  if Debug.active then
    Debug.update(t, dt)

    if DebugScreen.active then
      -- TODO why is this positioned weirdly?
      DebugKeyHandler.current_y = 1000
      DebugKeyHandler.render()
      DebugScreen.update(dt, t, input_service, input_manager)
    end

    if Managers.state.entity then
      local health_system = Managers.state.entity:system("health_system")
      local ai_system = Managers.state.entity:system("ai_system")

      health_system:update_debug()

      if ai_system.ai_debugger then
        local ai_debugger = ai_system.ai_debugger

        ai_debugger:update(dt, t)

        if ai_debugger.show_slots then
          local ai_slot_system = Managers.state.entity:system("ai_slot_system")
          local target_units = ai_slot_system.target_units
          local unit_extension_data = ai_slot_system.unit_extension_data
          local nav_world = ai_slot_system.nav_world
          debug_draw_slots.update(target_units, unit_extension_data, nav_world, t)
        end
      end
    end

    if Managers.state.debug then
      Managers.state.debug:update(dt, t)
    end
  end

end)

-- Fix for missing font packages
mod:hook(Gui, 'text', function(func, ...)
  local args = {...}

  if args[5] == 'core/editor_slave/gui/arial' then
    args[5] = 'gw_arial_16'
  end

  if args[3] == 'core/editor_slave/gui/arial' then
    args[3] = 'materials/fonts/gw_arial_16'
  end

  return func(unpack(args))
end)

-- Fix for gui created with missing font packages
mod:hook(SpawnZoneBaker, 'draw_zone_info_on_screen', function(func, self)
  self._gui = World.create_screen_gui(self.world, "material", "materials/fonts/gw_fonts", "immediate")
  func(self)
end)
