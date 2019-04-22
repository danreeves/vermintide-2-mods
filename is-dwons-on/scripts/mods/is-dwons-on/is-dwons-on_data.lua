local mod = get_mod("is-dwons-on")

return {
  name = "Is dwons enabled?",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id = "x",
        type = "numeric",
        default_value = 0,
        range = { -960, 960 },
      },
      {
        setting_id = "y",
        type = "numeric",
        default_value = -400,
        range = { -540, 540 },
      },
    }
  }
}
