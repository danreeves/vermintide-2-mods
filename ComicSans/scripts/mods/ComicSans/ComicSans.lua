-- luacheck: globals get_mod UIRenderer
local mod = get_mod("ComicSans")

mod:hook(UIRenderer, "draw_text", function(func, self, text, font_material, font_size, font_name, position, color, retained_id, color_override)
  local font = mod:get("font")
  local material = "fonts/mods/ComicSans/" .. font
  return func(self, text, material, font_size, font_name, position, color, retained_id, color_override)
end)
