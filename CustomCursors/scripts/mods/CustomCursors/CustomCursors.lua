-- luacheck: globals get_mod Window WwiseWorld
local mod = get_mod("CustomCursors")
mod:dofile("scripts/mods/CustomCursors/Sound")

function mod.on_enabled()
  Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
end

function mod.on_disabled()
  Window.set_cursor("gui/cursors/mouse_cursor")
end

function mod.on_all_mods_loaded()
  if mod:is_enabled() then
    Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
  end
end

mod:hook(WwiseWorld, "trigger_event", function(func, wwise_world, event)
  if event == "Play_hud_hover" then
    mod.play_sound()
    return -1, -1
  end
  return func(wwise_world, event)
end)
