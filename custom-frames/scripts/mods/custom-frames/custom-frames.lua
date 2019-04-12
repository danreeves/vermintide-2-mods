local mod = get_mod("custom-frames")

UIPlayerPortraitFrameSettings.frame_holly_04[1].texture = "custom_frames_flames"

mod:hook(UIWidgets, "create_portrait_frame", function(func, ...)
  local argos = {...}
  local ret = func(...)
  if argos[2] == "frame_holly_04" then
    mod:echo("@@@@@@@@@@@@@@@@@@@@@@")
    mod:dump(argos, "ARGS", 3)
    mod:dump(ret, "RETURN", 3)
    mod:echo("@@@@@@@@@@@@@@@@@@@@@@")
  end
  return ret
end)
