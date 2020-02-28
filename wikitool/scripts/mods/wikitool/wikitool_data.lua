local mod = get_mod("wikitool")

return {
  name = "wikitool",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id    = "show_stamina_ui",
        type          = "checkbox",
        default_value = true,
      }
    },
  },
}
