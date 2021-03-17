-- luacheck: globals get_mod UIRenderer
local mod = get_mod("ComicSans")

mod:hook(UIRenderer, "draw_text", function(func, self, text, font_material, font_size, font_name, position, color, retained_id, color_override)
  return func(self, text, "fonts/mods/ComicSans/ComicSans", font_size, font_name, position, color, retained_id, color_override)
end)
