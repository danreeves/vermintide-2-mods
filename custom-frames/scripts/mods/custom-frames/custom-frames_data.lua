local mod = get_mod("custom-frames")

return {
  name = "custom-frames",
  description = mod:localize("mod_description"),
  is_togglable = true,
  custom_gui_textures = {
    atlases = {
      {
        "materials/mods/custom-frames/frames",
        "frames",
        "frames_masked",
        "frames_point_sample",
        "frames_point_sample_masked",
      },
    },
    ui_renderer_injections = {
      {
        "ingame_ui",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
    },
  },
  options = {
    widgets = {
      {
        setting_id = "frame",
        type = "dropdown",
        default_value = "",
        options = {
          { text = "None", value = "" },
          { text = "Warpfire by Mio", value = "warpfire" },
          { text = "Storm Vermin by Mio", value = "stormvermin" },
          { text = "Nurgle by Mio", value = "nurgle" },
        },
      },
    },
  },
}
