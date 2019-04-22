local mod = get_mod("is-dwons-on")

local scenegraph_definition = {
  root = {
    scale = "fit",
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      UILayer.hud
    }
  }
}

local widget_definition = {
  scenegraph_id = "root",
  element = {
    passes = {
      {
        pass_type = "text",
        style_id = "mod_text",
        text_id = "mod_text",
        retained_mode = false,
        content_check_function = function(content)
          return mod:is_at_inn()
        end
      },
    },
  },
  content = {
    mod_text = "",
  },
  style = {
    mod_text = {
      font_type = "hell_shark",
      font_size = mod:get("font_size"),
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        mod:get("x"),
        mod:get("y"),
        0,
      }
    },
  },
}

return {
  scenegraph_definition = scenegraph_definition,
  widget_definition = widget_definition
}
