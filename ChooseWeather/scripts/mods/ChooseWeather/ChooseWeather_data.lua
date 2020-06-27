-- luacheck: globals get_mod
local mod = get_mod("ChooseWeather")

return {
  name = "ChooseWeather",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id      = "environment_id",
        type            = "numeric",
        default_value   = 0,
        range           = { 0, 1 },
      }
    },
  },
}
