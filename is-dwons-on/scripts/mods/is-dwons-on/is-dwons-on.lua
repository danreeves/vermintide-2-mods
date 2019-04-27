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

  if not Managers.player.is_server and mod.rpc_state.host_synced then
    return mod.rpc_state.dw_enabled, mod.rpc_state.ons_enabled
  end

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

function mod:is_host_or_host_synced()
  return Managers.player.is_server or mod.rpc_state.host_synced
end

local IsDwonsOn = mod:persistent_table("IsDwonsOn_class", class())

function IsDwonsOn:init(ingame_ui_context)
  self.ui_renderer = ingame_ui_context.ui_renderer
  self.input_manager = ingame_ui_context.input_manager
  self:create_ui()
end

function IsDwonsOn:create_ui()
  local scenegraph_definition = definitions.create_scenegraph_definition(mod:get("x"), mod:get("y"))
  self.ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
  self.ui_widget = UIWidget.init(definitions.widget_definition)
  self:update_style()
  DO_RELOAD = false
end

function IsDwonsOn:update_style()
  local font_size = mod:get("font_size")
  self.ui_widget.style.dw_text.font_size = font_size
  self.ui_widget.style.ons_text.font_size = font_size

  if mod:get("align_vertically") then
    local horizontal_alignment = mod:get("horizontal_alignment")
    self.ui_widget.style.dw_text.vertical_alignment = "bottom"
    self.ui_widget.style.ons_text.vertical_alignment = "top"
    self.ui_widget.style.dw_text.horizontal_alignment = horizontal_alignment
    self.ui_widget.style.ons_text.horizontal_alignment = horizontal_alignment
  else
    self.ui_widget.style.dw_text.offset[1] = -(font_size / 4)
    self.ui_widget.style.ons_text.offset[1] = font_size / 4
    self.ui_widget.style.dw_text.vertical_alignment = "center"
    self.ui_widget.style.ons_text.vertical_alignment = "center"
  end
end

function IsDwonsOn:update()
  if DO_RELOAD then
    self:create_ui()
    self:update_style()
  end

  local dw_active, ons_active = mod:get_status()
  self.ui_widget.content.dw_text = string.format("Deathwish: %s", dw_active)
  self.ui_widget.content.ons_text = string.format("Onslaught: %s", ons_active)
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
mod.dwons_active = false
mod:command("dwons", "Toggle Deathwish & Onslaught. Must be host and in the keep.", function()
  mod.dwons_active = not mod.dwons_active

  if not deathwish_mod then
    mod:chat_broadcast("SKIPPING. Deathwish is not installed.")
  else
    local deathwish = deathwish_mod:persistent_table("Deathwish")
    if deathwish.active ~= mod.dwons_active then
      deathwish.toggle()
    else
      mod:chat_broadcast(string.format("Deathwish already %s.", mod.dwons_active and "ENABLED" or "DISABLED"))
    end
  end

  if not onslaught_mod then
    mod:chat_broadcast("SKIPPING. Onslaught is not installed.")
  else
    local onslaught = onslaught_mod:persistent_table("Onslaught")
    if onslaught.active ~= mod.dwons_active then
      onslaught.toggle()
    else
      mod:chat_broadcast(string.format("Onslaught already %s.", mod.dwons_active and "ENABLED" or "DISABLED"))
    end
  end

  mod:sync_state()
end)

-- RPC State
mod.rpc_state = {
  dw_enabled = false,
  ons_enabled = false,
  host_synced = false
}

mod:network_register("dwons_state_sync", function(sender, data)
  mod.rpc_state.host_synced = true
  mod.rpc_state.dw_enabled = data.dw_enabled
  mod.rpc_state.ons_enabled = data.ons_enabled
end)

function mod:on_user_joined()
  mod:sync_state()
end

function mod:on_game_state_changed(status, state)
  if status == "enter" and state == "StateIngame" then
    if Managers.player.is_server then
      mod.rpc_state = {
        ons_enabled = false,
        dw_enabled = false,
        host_synced = false
      }
      mod:sync_state()
    end
  end
end

function mod:sync_state()
  local dw_enabled, ons_enabled = mod:get_status()
  mod:network_send("dwons_state_sync", "others", {
    dw_enabled = dw_enabled,
    ons_enabled = ons_enabled
  })
end

local function hook_mods()
  if deathwish_mod then
    local deathwish = deathwish_mod:persistent_table("Deathwish")
    mod:hook_safe(deathwish, "start", mod.sync_state)
    mod:hook_safe(deathwish, "stop", mod.sync_state)
  end
  if onslaught_mod then
    local onslaught = onslaught_mod:persistent_table("Onslaught")
    mod:hook_safe(onslaught, "start", mod.sync_state)
    mod:hook_safe(onslaught, "stop", mod.sync_state)
  end
end

local function unhook_mods()
  if deathwish_mod then
    local deathwish = deathwish_mod:persistent_table("Deathwish")
    mod:hook_disable(deathwish, "start")
    mod:hook_disable(deathwish, "stop")
  end
  if onslaught_mod then
    local onslaught = onslaught_mod:persistent_table("Onslaught")
    mod:hook_disable(onslaught, "start")
    mod:hook_disable(onslaught, "stop")
  end
end

function mod:on_all_mods_loaded()
  hook_mods()
end

function mod:on_unload()
  unhook_mods()
end
