local mod = get_mod("debug-mode")

-- Everything here is optional. You can remove unused parts.
return {
  name = "debug-mode",                               -- Readable mod name
  description = mod:localize("mod_description"),  -- Mod description
  is_togglable = true,                            -- If the mod can be enabled/disabled
  is_mutator = false,                             -- If the mod is mutator
  mutator_settings = {},                          -- Extra settings, if it's mutator
  options = {
    widgets = {                                 -- Widget settings for the mod options menu
      {
        setting_id = "toggle_hotkey",
        type = "keybind",
        title = "hotkey_title",
        tooltip = "hotkey_tooltip",
        default_value = {},
        keybind_trigger = "pressed",
        keybind_type = "function_call",
        function_name = "toggle_with_hotkey"
      }
    }
  }
}
