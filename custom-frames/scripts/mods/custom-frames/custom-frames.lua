local mod = get_mod("custom-frames")

function mod.on_setting_changed()
  local frame = mod:get("frame")
  local texture = string.format("custom-frames-%s", frame)
  if frame == "" then
    UIPlayerPortraitFrameSettings.frame_0000[1].texture = "portrait_frame_0000"
  else
    UIPlayerPortraitFrameSettings.frame_0000[1].texture = texture
  end
end

mod.on_setting_changed()
