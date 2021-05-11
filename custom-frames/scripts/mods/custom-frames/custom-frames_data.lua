local mod = get_mod("custom-frames")

return {
  name = "custom-frames",
  description = mod:localize("mod_description"),
  is_togglable = true,
  custom_gui_textures = {
    ui_renderer_injections = {
      {
        "ingame_ui",
        "materials/mods/custom-frames/custom_frame_1",
        "materials/mods/custom-frames/custom_frame_2",
        "materials/mods/custom-frames/custom_frame_3",
        "materials/mods/custom-frames/custom_frame_4",
      },
      {
        "level_end_view_wrapper",
        "materials/mods/custom-frames/custom_frame_1",
        "materials/mods/custom-frames/custom_frame_2",
        "materials/mods/custom-frames/custom_frame_3",
        "materials/mods/custom-frames/custom_frame_4",
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
          { text = "Sadcat by Ivyoary", value = "ivyoary" },
        },
      },
    },
  },
}
