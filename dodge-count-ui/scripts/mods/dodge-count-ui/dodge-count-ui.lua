local mod = get_mod("dodge-count-ui")

local fake_input_service = {
  get = function ()
    return
  end,
  has = function ()
    return
  end
}

local scenegraph_definition = {
  root = {
    is_root = true,
    size = {
      1920,
      1080
    },
    position = {
      0,
      0,
      UILayer.hud
    }
  },
  screen = {
    scale = "fit",
    position = {
      0,
      0,
      UILayer.hud
    },
    size = {
      1920,
      1080
    }
  },
}

local dodge_ui_definition = {
  scenegraph_id = "screen",
  element = {
    passes = {
      {
        style_id = "dodge_text",
        pass_type = "text",
        text_id = "dodge_text",
        retained_mode = false,
        content_check_function = function ()
          return true
        end
      },
      {
        style_id = "cooldown_text",
        pass_type = "text",
        text_id = "cooldown_text",
        retained_mode = false,
        content_check_function = function (content)
          return content.actual_cooldown > 0
        end
      }
    }
  },
  content = {
    dodge_text = "",
    cooldown_text = "",
    actual_cooldown = 0
  },
  style = {
    dodge_text = {
      font_type = "hell_shark",
      font_size = 32,
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        mod:get('offset_x'),
        -mod:get('offset_y'),
        0
      }
    },
    cooldown_text = {
      font_type = "hell_shark",
      font_size = 32,
      vertical_alignment = "center",
      horizontal_alignment = "center",
      text_color = Colors.get_table("white"),
      offset = {
        mod:get('offset_x'),
        -(mod:get('offset_y') + mod:get('dodge_count_font_size')),
        0
      }
    },
  },
  offset = {
    0,
    0,
    0
  },
}

mod.on_disabled = function()
  mod.ui_renderer = nil
  mod.ui_scenegraph = nil
  mod.ui_widget = nil
end

mod.on_setting_changed = function()
  if not mod.ui_widget then
    return
  end
  mod.ui_widget.style.dodge_text.offset[1] = mod:get('offset_x')
  mod.ui_widget.style.dodge_text.offset[2] = -mod:get('offset_y')
  mod.ui_widget.style.dodge_text.font_size = mod:get('dodge_count_font_size')
  mod.ui_widget.style.cooldown_text.offset[1] = mod:get('offset_x')
  mod.ui_widget.style.cooldown_text.offset[2] = -(mod:get('offset_y') + mod:get('dodge_count_font_size'))
  mod.ui_widget.style.cooldown_text.font_size = mod:get('cooldown_font_size')
end

function mod:init()
  if mod.ui_widget then
    return
  end

  local world = Managers.world:world("top_ingame_view")
  mod.ui_renderer = UIRenderer.create(world, "material", "materials/fonts/gw_fonts")
  mod.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
  mod.ui_widget = UIWidget.init(dodge_ui_definition)
end

mod:hook_safe(IngameHud, 'update', function()
  local t = Managers.time:time("game")
  local player_unit = Managers.player:local_player().player_unit
  local status_system = ScriptUnit.has_extension(player_unit, "status_system")

  if not status_system or not player_unit then
    return
  end

  if not mod.ui_widget then
    mod.init()
    status_system:get_dodge_item_data()
  end

  local current_dodge_count = status_system.dodge_cooldown
  local efficient_dodge_count = status_system.dodge_count
  local cooldown = status_system.dodge_cooldown_delay or 0

  local widget = mod.ui_widget
  local ui_renderer = mod.ui_renderer
  local ui_scenegraph = mod.ui_scenegraph

  widget.content.dodge_text = string.format('%i/%u', efficient_dodge_count - current_dodge_count, efficient_dodge_count)
  widget.content.cooldown_text = string.format('%.1fs', cooldown - t)
  widget.content.actual_cooldown = cooldown - t

  UIRenderer.begin_pass(ui_renderer, ui_scenegraph, fake_input_service, dt)
  UIRenderer.draw_widget(ui_renderer, widget)
  UIRenderer.end_pass(ui_renderer)
end)

local function update_dodge_data()
  local local_player = Managers.player:local_player()
  if not local_player then
    return
  end
  local status_system = ScriptUnit.has_extension(local_player.player_unit, "status_system")
  if status_system then
    status_system:get_dodge_item_data()
  end
end

mod.on_game_state_changed = function(state, state_name)
  if state == "enter" and state_name == "StateIngame" then
    update_dodge_data()
  end
end
mod:hook_safe(SimpleInventoryExtension, 'wield', update_dodge_data)
