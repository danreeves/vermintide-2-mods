local mod = get_mod("debug-mode")

-- Everything here is optional. You can remove unused parts.
return {
  name = "Debug mode",
  description = mod:localize("mod_description"),
  is_togglable = true,
  is_mutator = false,
  mutator_settings = {},
  options = {
    widgets = {
      {
        setting_id = "toggle_debug",
        type = "keybind",
        default_value = {},
        keybind_trigger = "pressed",
        keybind_type = "function_call",
        function_name = "toggle_debug"
      },
      {
        setting_id = "toggle_debug_menu",
        type = "keybind",
        default_value = {},
        keybind_trigger = "pressed",
        keybind_type = "function_call",
        function_name = "toggle_debug_menu"
      }
    }
  }
}
