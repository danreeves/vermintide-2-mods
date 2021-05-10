-- luacheck: globals get_mod callback Managers Material Gui UIUtils
-- luacheck: globals UnitFramesHandler
local mod = get_mod("custom-frames")
local vmf = get_mod("VMF")
local ui_renderers = vmf:persistent_table("_ui_renderers")
local requested_textures = mod:persistent_table("requested_textures")
local texture_resources = mod:persistent_table("texture_resources")
local loading_id = 0
local MAT_NAME = "template"

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
        local material = Gui.material(gui, MAT_NAME)
        local texture_resource = texture_resources[mod:get("frame")]
        if material and texture_resource then
          Material.set_resource(material, "diffuse_map", texture_resource)
        end
      end
    end
  end
end

function mod.on_all_mods_loaded()
  mod.set_diffuse_maps()
end

mod:hook_safe(UnitFramesHandler, "_sync_player_stats", function (self, unit_frame)
	local player_data = unit_frame.player_data
	local player = player_data.player
    if player == Managers.player:local_player() then
      local texture_url = mod:get("frame")
      mod.load_frame(texture_url)
      unit_frame.widget._widgets.portrait_static.content.texture_1 = MAT_NAME
      unit_frame.widget._widgets.portrait_static.style.texture_1.size = {164, 186}
      unit_frame.widget._widgets.portrait_static.style.texture_1.offset = { -83, -77, 10}
    end
end)
