local mod = get_mod("dodge-count-ui")


-- Allow live-reloading.
-- =====================================================================================================================

-- Reload the UI when mods are reloaded or a setting is changed.
local DO_RELOAD = true
function mod.on_setting_changed()
  DO_RELOAD = true
end


-- Define our UI class.
-- =====================================================================================================================

-- Keeping the reference in a persistant table allows us to live-reload the UI.
local DodgeCountUI = mod:persistent_table("DodgeCountUI_class", class())
local definitions = mod:dofile("scripts/mods/dodge-count-ui/dodge-count-ui_definitions")


function DodgeCountUI:init(ingame_ui_context)
  self.ui_renderer = ingame_ui_context.ui_renderer
  self.input_manager = ingame_ui_context.input_manager

  self.render_settings = {
    alpha_multiplier = 0,
    snap_pixel_positions = true,
  }

  self:create_ui_elements()
end


function DodgeCountUI:destroy()
  -- Noop.
end


function DodgeCountUI:create_ui_elements()
  -- Prepare scenegraph.
  UIRenderer.clear_scenegraph_queue(self.ui_renderer)
  self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
  -- Initialize all widgets.
  local widgets_by_name = {}
  for name, definition in pairs(definitions.widget_definitions) do
    local widget = UIWidget.init(definition)
    widgets_by_name[name] = widget
  end
  self.widgets_by_name = widgets_by_name

  -- Update the positions of the text according to the settings.
  self:update_settings()

  DO_RELOAD = false
end


function DodgeCountUI:update_settings()
  local offset_x, offset_y = mod:get("offset_x"), mod:get("offset_y")
  local dodge_count_font_size = mod:get("dodge_count_font_size")
  local cooldown_font_size = mod:get("cooldown_font_size")
  -- Dodge text.
  local widget_style = self.widgets_by_name.dodge_text.style
  widget_style.dodge_text.offset[1] = offset_x
  widget_style.dodge_text.offset[2] = -offset_y
  widget_style.dodge_text.font_size = dodge_count_font_size
  -- Cooldown text.
  widget_style.cooldown_text.offset[1] = offset_x
  widget_style.cooldown_text.offset[2] = -(offset_y + dodge_count_font_size)
  widget_style.cooldown_text.font_size = cooldown_font_size

  self.widgets_by_name.dodge_text.always_on = mod:get("always_on")
end


function DodgeCountUI:update(dt, t, my_player)
  if DO_RELOAD then
    self:create_ui_elements()
  end

  local player_unit = my_player.player_unit
  local status_system = ScriptUnit.has_extension(player_unit, "status_system")

  self:update_dodge_data(status_system, t)
  self:draw(dt)
end


function DodgeCountUI:update_dodge_data(status_system, t)
  local game_t = Managers.time:time("game")

  -- Read the data from the status system extension.
  local current_dodge_count = status_system.dodge_cooldown
  local efficient_dodge_count = status_system.dodge_count
  local cooldown = status_system.dodge_cooldown_delay or 0
  -- Compute common data.
  local diff = cooldown - game_t
  local has_cooldown = diff > 0
  --mod:echo("%s %s %s", has_cooldown, cooldown, t)
  -- Update the text widget.
  local text_content = self.widgets_by_name.dodge_text.content
  text_content.dodge_text = string.format("%i/%u", efficient_dodge_count - current_dodge_count, efficient_dodge_count)
  text_content.cooldown_text = string.format("%.1fs", diff)
  text_content.has_dodged = current_dodge_count > 0
  text_content.has_cooldown = has_cooldown
  -- Update the bar widget.
  local bar_content = self.widgets_by_name.dodge_bar.content
  bar_content.has_cooldown = has_cooldown
  bar_content.bar_value = math.clamp(diff * 2, 0, 1)
end


function DodgeCountUI:draw(dt)
  local ui_renderer = self.ui_renderer
  local ui_scenegraph = self.ui_scenegraph
  local input_service = self.input_manager:get_service("ingame_menu")
  local render_settings = self.render_settings
  -- Draw all widgets.
  UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt, nil, render_settings)
  for _, widget in pairs(self.widgets_by_name) do
    UIRenderer.draw_widget(ui_renderer, widget)
  end
  UIRenderer.end_pass(ui_renderer)
end


-- Hook into the IngameHud.
-- =====================================================================================================================
mod:hook_safe(IngameHud, "init", function(self, ingame_ui_context)
  self._mod_dodge_count_ui = DodgeCountUI:new(ingame_ui_context)
end)

mod:hook_safe(IngameHud, "destroy", function(self)
  if not self._mod_dodge_count_ui then return end

  self._mod_dodge_count_ui:destroy()
end)

mod:hook_safe(IngameHud, "_update_while_alive", function(self, dt, t, player, context)
  if not self._mod_dodge_count_ui then return end

  local game_mode = Managers.state.game_mode:game_mode()
  local game_mode_disable_hud = game_mode.game_mode_hud_disabled and game_mode:game_mode_hud_disabled()

  if not game_mode_disable_hud then
    self._mod_dodge_count_ui:update(dt, t, player)
  end
end)
