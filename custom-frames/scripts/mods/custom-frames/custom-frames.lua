-- luacheck: globals get_mod callback Managers Material Gui UIUtils
-- luacheck: globals UnitFramesHandler
local mod = get_mod("custom-frames")
local vmf = get_mod("VMF")
local ui_renderers = vmf:persistent_table("_ui_renderers")
local requested_textures = mod:persistent_table("requested_textures")
local texture_resources = mod:persistent_table("texture_resources")
local loading_id = 0
local MAT_NAME = "custom_frame_"

mod.peer_id_to_frame = {}
mod.peer_id_to_mat = {}

mod:command("set_frame", "Set your custom frame URL", function(url)
  -- Fix for double paste
  local len = url:len()
  local first_half = url:sub(1, len / 2)
  local second_half = url:sub((len / 2) + 1, len)
  if first_half == second_half then
    url = first_half
  end

  mod:set("frame", url)
  mod.load_frame(url)
end)

function mod.load_frame(texture_url)

  if not texture_url then
    return
  end

  if not requested_textures[texture_url] then
    loading_id = loading_id + 1
    requested_textures[texture_url] = true
    mod:info(texture_url .. " loading")

    local cb = callback(mod, "cb_on_image_loaded", texture_url)
    Managers.url_loader:load_resource(
      "custom_frames_" .. tostring(loading_id),
      texture_url,
      cb,
      texture_url -- cache key
      )
  else
    mod.set_diffuse_maps()
  end
end

function mod.cb_on_image_loaded(_, texture_url, texture_resource)
  mod:info(texture_url .. " loaded")

  if texture_resource then
    texture_resources[texture_url] = texture_resource
    mod.set_diffuse_maps()
  end
end

function mod.set_diffuse_maps()
  for ui_renderer, _ in pairs(ui_renderers) do
    local gui_immediate = ui_renderer.gui
    local gui_retained = ui_renderer.gui_retained
    for _, gui in pairs({gui_retained, gui_immediate}) do
      if tostring(gui) == "[Gui]" then
        for i = 1, 4 do
          local material_name = MAT_NAME .. tostring(i)
          local material = Gui.material(gui, material_name)
          local texture_resource = texture_resources[mod:get("frame")]
          if material and texture_resource then
            Material.set_resource(material, "diffuse_map", texture_resource)
          end
        end
      end
    end
  end
end

function mod.on_all_mods_loaded()
  mod.set_diffuse_maps()
end

function mod.on_game_state_changed(status, state)
  if status == "enter" and state == "StateIngame" then
    local player = Managers.player:local_player()
    local peer_id = player.peer_id

    -- Set own frame
    mod.peer_id_to_frame[peer_id] = mod:get("frame")

    -- Set own mat
    mod.peer_id_to_mat[peer_id] = MAT_NAME .. "1"
    mod.peer_id_to_mat[MAT_NAME .. "1"] = peer_id
  end
end

function mod.on_setting_changed()
    local player = Managers.player:local_player()
    local peer_id = player.peer_id

    -- Set own frame
    mod.peer_id_to_frame[peer_id] = mod:get("frame")

    mod.send_frame("all")
    mod.set_diffuse_maps()
end

function mod.on_user_joined(player)
  local peer_id = player.peer_id
  local unused_mat = nil
  for i = 1, 4 do
    local material_name = MAT_NAME .. tostring(i)
    local maybe_peer_id = mod.peer_id_to_mat[material_name]
    if not maybe_peer_id then
      unused_mat = material_name
      break
    end
  end

  if unused_mat then
    mod.peer_id_to_mat[peer_id] = unused_mat
    mod.peer_id_to_mat[unused_mat] = peer_id
  end
end

function mod.on_user_left(player)
  local peer_id = player.peer_id
  local material = mod.peer_id_to_mat[peer_id]
  mod.peer_id_to_mat[peer_id] = nil
  mod.peer_id_to_mat[material] = nil
end

mod:network_register("custom-frames-set", function(peer_id, url)
  mod.peer_id_to_frame[peer_id] = url
end)

mod:network_register("custom-frames-request", function(peer_id)
  mod.send_frame(peer_id)
end)

function mod.send_frame(peer_id)
  local url = mod:get("frame")
  mod:network_send("custom-frames-set", peer_id, url)
end

mod:hook_safe(UnitFramesHandler, "_sync_player_stats", function (_, unit_frame)
  local player_data = unit_frame.player_data
  local player = player_data.player
  if player then
    if player:is_player_controlled() then
      local peer_id = player.peer_id
      local texture_url = mod.peer_id_to_frame[peer_id]
      local material_name = mod.peer_id_to_mat[peer_id]
      if texture_url and material_name then
        mod.load_frame(texture_url)
        unit_frame.widget._widgets.portrait_static.content.texture_1 =  material_name
        unit_frame.widget._widgets.portrait_static.style.texture_1.size = {164, 186}
        unit_frame.widget._widgets.portrait_static.style.texture_1.offset = { -83, -77, 10}
      end
    end
  end
end)
