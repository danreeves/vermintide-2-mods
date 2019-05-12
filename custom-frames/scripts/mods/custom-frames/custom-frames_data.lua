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
      {
        "ingame_hud",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
      {
        "ui_renderer",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
      {
        "ui_passes",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
      {
        "unit_frame_ui",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
      {
        "unit_frames_handler",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
      {
        "loading_view",
        "materials/mods/custom-frames/frames",
        "materials/mods/custom-frames/frames_masked",
        "materials/mods/custom-frames/frames_point_sample",
        "materials/mods/custom-frames/frames_point_sample_masked",
      },
    }
  }
}
