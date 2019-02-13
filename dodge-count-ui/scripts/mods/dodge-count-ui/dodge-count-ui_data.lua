local mod = get_mod("dodge-count-ui")

return {
  name = "Dodge Count UI",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id = "always_on",
        type = "checkbox",
        default_value = true,
      },
      {
        setting_id = "offset_x",
        type = "numeric",
        default_value = 1000,
        range = { -2500, 2500 },
      },
      {
        setting_id = "offset_y",
        type = "numeric",
        default_value = 500,
        range = { -2500, 2500 },
      },
      {
        setting_id = "dodge_count_font_size",
        type = "numeric",
        default_value = 32,
        range = { 8, 128 },
      },
      {
        setting_id = "cooldown_font_size",
        type = "numeric",
        default_value = 24,
        range = { 8, 128 },
      },
    }
  }
}
