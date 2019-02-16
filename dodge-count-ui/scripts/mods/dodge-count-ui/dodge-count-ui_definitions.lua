local scenegraph_definition = {
  root = {
    is_root = true,
    position = { 0, 0, UILayer.hud },
    size = { 1920, 1080 },
  },
  screen = {
    scale = "fit",
    position = { 0, 0, UILayer.hud },
    size = { 1920, 1080 },
  },

  dodge_ui =  {
    parent = "screen",
    position = { 0, 0, 0 },
    size = { 1920, 1080 },
  },

  interaction_bar = {
    parent = "screen",
    position = { 0, -15, 4 },
    size = { 217, 35 },
    horizontal_alignment = "center",
    vertical_alignment = "center",
  },
  interaction_bar_fill = {
    parent = "interaction_bar",
    position = { 0, 0, 1 },
    size = { 217, 35 },
    horizontal_alignment = "left",
    vertical_alignment = "center",
  },
}

local dodge_ui_definition = {
  scenegraph_id = "dodge_ui",
  element = {
    passes = {
      {
        style_id = "dodge_text",
        pass_type = "text",
        text_id = "dodge_text",
        retained_mode = false,
        fade_out_duration = 5,
        content_check_function = function(content)
          return content.always_on or content.has_dodged
        end
      },
      {
        style_id = "cooldown_text",
        pass_type = "text",
        text_id = "cooldown_text",
        retained_mode = false,
        content_check_function = function(content)
          return content.has_cooldown
        end
      }
    }
  },
  content = {
    dodge_text = "",
    cooldown_text = "",
    has_dodged = false,
    has_cooldown = false,
    always_on = false,
  },
  style = {
    dodge_text = {
      font_type = "hell_shark",
      font_size = 32,
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = { 0, 0, 0 },
    },
    cooldown_text = {
      font_type = "hell_shark",
      font_size = 32,
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = { 0, 0, 0 },
    },
  },
  offset = { 0, 0, 0 },
}

local dodge_ui_bar_definition = {
  scenegraph_id = "interaction_bar",
  element = {
    passes = {
      {
        style_id = "bar",
        pass_type = "texture_uv_dynamic_color_uvs_size_offset",
        dynamic_function = function(content, style, size, dt)
          local bar_value = content.bar_value
          local uv_start_pixels = style.uv_start_pixels
          local uv_scale_pixels = style.uv_scale_pixels
          local uv_pixels = uv_start_pixels + uv_scale_pixels * bar_value
          local uvs = style.uvs
          local uv_scale_axis = style.scale_axis
          local offset_scale = style.offset_scale
          local offset = style.offset
          uvs[2][uv_scale_axis] = uv_pixels / (uv_start_pixels + uv_scale_pixels)
          size[uv_scale_axis] = uv_pixels

          return style.color, uvs, size, offset
        end,
        content_check_function = function(content)
          return content.has_cooldown
        end,
      }
    }
  },
  content = {
    has_cooldown = true,
    texture_id = "interaction_pop_up_glow_1",
    bar_value = 1,
  },
  style = {
    bar = {
      uv_start_pixels = 0,
      scenegraph_id = "interaction_bar_fill",
      uv_scale_pixels = 217,
      offset_scale = 1,
      scale_axis = 1,
      offset = { 0, 0, 0 },
      color = { 255, 255, 255, 255 },
      uvs = { { 0, 0 }, { 1, 1 } },
    },
  },
}

return {
  scenegraph_definition = scenegraph_definition,
  animation_definitions = animation_definitions,
  widget_definitions = {
    dodge_text = dodge_ui_definition,
    dodge_bar = dodge_ui_bar_definition,
  },
}
