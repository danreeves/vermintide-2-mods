local mod = get_mod("named-items")

return {
  name = "Named items",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id = "select_item",
        type = "keybind",
        default_value = {},
        keybind_global = true,
        keybind_trigger = "pressed",
        keybind_type = "function_call",
        function_name = "on_select_item"
      },
    }
  }
}
