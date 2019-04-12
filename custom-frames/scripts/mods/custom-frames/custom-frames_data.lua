local mod = get_mod("custom-frames")

return {
  name = "custom-frames",
  description = mod:localize("mod_description"),
  is_togglable = true,
  custom_gui_textures = {
    atlases = {
      {
        "materials/mods/custom-frames/frames_atlas",
        "materials/mods/custom-frames/frames",
      },
    },
    ui_renderer_injections = {
      {
        "ingame_ui",
        "materials/mods/custom-frames/frames",
      },
    }
  }
}
