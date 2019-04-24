local mod = get_mod("is-dwons-on")
local definitions = mod:dofile("scripts/mods/is-dwons-on/is-dwons-on_definitions")
local deathwish_mod = get_mod("Deathwish")
local onslaught_mod = get_mod("Onslaught")

-- Reload the UI when mods are reloaded or a setting is changed.
local DO_RELOAD = true

function mod:on_setting_changed()
  DO_RELOAD = true
end

function mod:get_status()
  local dw_enabled = false
  local ons_enabled = false
  if deathwish_mod then
    local deathwish = deathwish_mod:persistent_table("Deathwish")
    dw_enabled = deathwish.active and true or false
  end
  if onslaught_mod then
    local onslaught = onslaught_mod:persistent_table("Onslaught")
    ons_enabled = onslaught.active and true or false
  end
  return dw_enabled, ons_enabled
end

-- Are we currently loaded at the inn?
-- from Zaphio
function mod:is_at_inn()
  local game_mode = Managers.state.game_mode
  if not game_mode then return nil end
  return game_mode:game_mode_key() == "inn"
end

function mod:is_server()
  return Managers.player.is_server
end

local IsDwonsOn = mod:persistent_table("IsDwonsOn_class", class())

function IsDwonsOn:init(ingame_ui_context)
  self.ui_renderer = ingame_ui_context.ui_renderer
  self.input_manager = ingame_ui_context.input_manager
  self:create_ui()
end

function IsDwonsOn:create_ui()
  self.ui_scenegraph = UISceneGraph.init_scenegraph(definitions.scenegraph_definition)
  self.ui_widget = UIWidget.init(definitions.widget_definition)
  DO_RELOAD = false
end

function IsDwonsOn:update()
  if DO_RELOAD then
    self:create_ui()
    self.ui_widget.style.mod_text.offset[1] = mod:get("x")
    self.ui_widget.style.mod_text.offset[2] = mod:get("y")
    self.ui_widget.style.mod_text.font_size = mod:get("font_size")
  end

  local dw_active, ons_active = mod:get_status()
  self.ui_widget.content.mod_text = string.format("Deathwish: %s Onslaught: %s", dw_active, ons_active)
end

function IsDwonsOn:draw(dt)
  local ui_renderer = self.ui_renderer
  local ui_scenegraph = self.ui_scenegraph
  local input_service = self.input_manager:get_service("ingame_menu")
  local ui_widget = self.ui_widget

  UIRenderer.begin_pass(ui_renderer, ui_scenegraph, input_service, dt)
  UIRenderer.draw_widget(ui_renderer, ui_widget)
  UIRenderer.end_pass(ui_renderer)
end

-- INIT
mod:hook_safe(IngameHud, "init", function(self, parent, ingame_ui_context)
  self._mod_ui = IsDwonsOn:new(ingame_ui_context)
end)

-- HOOKS
mod:hook_safe(IngameHud, "update", function(self, dt , t)
  if not self._mod_ui then
    return
  end
  self._mod_ui:update()
  self._mod_ui:draw(dt)
end)

-- COMMANDS
mod.active = false
mod:command("dwons", "Toggle Deathwish & Onslaught. Must be host and in the keep.", function()
  mod.active = not mod.active

  if not deathwish_mod then
    mod:chat_broadcast("SKIPPING. Deathwish is not installed.")
  else
    local deathwish = deathwish_mod:persistent_table("Deathwish")
    if deathwish.active ~= mod.active then
      deathwish.toggle()
    else
      mod:chat_broadcast(string.format("Deathwish already %s.", mod.active and "ENABLED" or "DISABLED"))
    end
  end

  if not onslaught_mod then
    mod:chat_broadcast("SKIPPING. Onslaught is not installed.")
  else
    local onslaught = onslaught_mod:persistent_table("Onslaught")
    if onslaught.active ~= mod.active then
      onslaught.toggle()
    else
      mod:chat_broadcast(string.format("Onslaught already %s.", mod.active and "ENABLED" or "DISABLED"))
    end
  end
end)
