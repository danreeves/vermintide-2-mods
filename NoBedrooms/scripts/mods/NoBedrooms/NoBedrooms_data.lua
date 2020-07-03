-- luacheck: globals get_mod
local mod = get_mod("NoBedrooms")

return {
  name = "NoBedrooms",
  description = mod:localize("mod_description"),
  is_togglable = true,
  options = {
    widgets = {
      {
        setting_id    = "empire_soldier_disabled",
        type          = "checkbox",
        default_value = true,
      },
      {
        setting_id    = "dwarf_ranger_disabled",
        type          = "checkbox",
        default_value = true,
      },
      {
        setting_id    = "bright_wizard_disabled",
        type          = "checkbox",
        default_value = true,
      },
      {
        setting_id    = "wood_elf_disabled",
        type          = "checkbox",
        default_value = true,
      },
      {
        setting_id    = "witch_hunter_disabled",
        type          = "checkbox",
        default_value = true,
      },
    }
  },
}
