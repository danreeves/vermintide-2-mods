local mod = get_mod("custom-frames")

UIPlayerPortraitFrameSettings.frame_holly_04[1].texture = "custom_frames_flames"

-- mod:hook(UIRenderer, "draw_texture", function(func, ui_renderer, material, lower_left_corner, size, color, masked, saturated, retained_id)
  -- mod:dump({ui_renderer, material, lower_left_corner, size, color, masked, saturated, retained_id}, 'DRAW TEXTURE CALL', 2)
  -- return func(ui_renderer, material, lower_left_corner, size, color, masked, saturated, retained_id)
-- end)

-- mod:hook(UIWidgets, "create_portrait_frame", function(func, ...)
  -- local argos = {...}
  -- local ret = func(...)
  -- if argos[2] == "frame_holly_04" then
    -- mod:echo("@@@@@@@@@@@@@@@@@@@@@@")
    -- mod:dump(argos, "ARGS", 3)
    -- mod:dump(ret, "RETURN", 3)
    -- mod:echo("@@@@@@@@@@@@@@@@@@@@@@")
  -- end
  -- return ret
-- end)
