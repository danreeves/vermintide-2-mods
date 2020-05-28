-- luacheck: globals get_mod
local mod = get_mod("EpicGamerCrosshairs")

return {
  name = "Custom Crosshairs",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id = "thickness",
        type = "numeric",
        default_value = 1,
        range = { 0, 255 },
      },
      {
        setting_id = "size",
        type = "numeric",
        default_value = 10,
        range = { 0, 255 },
      },
      {
        setting_id = "gap",
        type = "numeric",
        default_value = 3,
        range = { -255, 255 },
      },
      {
        setting_id = "show_dot",
        type = "checkbox",
        default_value = false,
      },
      {
        setting_id = "color",
        type = "group",
        sub_widgets = {
          {
            setting_id = "color_r",
            type = "numeric",
            range = { 0, 255 },
            default_value = 50,
          },
          {
            setting_id = "color_g",
            type = "numeric",
            range = { 0, 255 },
            default_value = 250,
          },
          {
            setting_id = "color_b",
            type = "numeric",
            range = { 0, 255 },
            default_value = 50,
          },
          {
            setting_id = "color_a",
            type = "numeric",
            range = { 0, 255 },
            default_value = 255,
          },
        },
      },
      {
        setting_id = "disable_default_crosshairs",
        type = "checkbox",
        default_value = true,
      },
    },
  },
}
