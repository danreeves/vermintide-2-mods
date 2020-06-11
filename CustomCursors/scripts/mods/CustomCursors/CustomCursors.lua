-- luacheck: globals get_mod Window
local mod = get_mod("CustomCursors")

function mod.on_enabled()
  Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
end

function mod.on_disabled()
  Window.set_cursor("gui/cursors/mouse_cursor")
end

if mod:is_enabled() then
  Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
end
