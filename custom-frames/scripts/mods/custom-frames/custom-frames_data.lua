local mod = get_mod("custom-frames")

local function build_custom_gui_textures(textures)
  local atlases = {}
  local chat_manager_injections = { "chat_manager" }
  for i, tex in ipairs(textures) do
    local path_material = "materials/custom-frames/" .. tex
    local path_atlas = path_material .. "_atlas"
    atlases[i] = { path_atlas, tex }
    chat_manager_injections[i + 1] = path_material
  end

  return {
    atlases = atlases,
    ui_renderer_injections = { chat_manager_injections },
  }
end

return {
  name = "custom-frames",
  description = mod:localize("mod_description"),
  is_togglable = true,
  custom_gui_textures = build_custom_gui_textures({ "frames" })
}
