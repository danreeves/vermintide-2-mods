-- luacheck: globals get_mod
local mod = get_mod("debug-slots")

return {
  name = "Slot System Debugger",
  description = mod:localize("mod_description"),
  is_togglable = true,
}
