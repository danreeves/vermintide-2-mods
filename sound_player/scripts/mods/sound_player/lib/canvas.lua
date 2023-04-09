--[[---------------------------------------------------------------------------------------------------------
DESCRIPTION: API similar to Love2D for GUI drawing.
AUTHOR: Zaphio
--]]
---------------------------------------------------------------------------------------------------------
local Canvas = class()

function Canvas:init(world, gui)
	self.world = world

	if gui then
		self.gui = gui
		self.keep_gui = true
	else
		self.gui = World.create_screen_gui(
			world,
			"immediate",
			"material",
			"materials/fonts/gw_fonts",
			"material",
			"materials/ui/ui_1080p_hud_atlas_textures",
			"material",
			"materials/ui/ui_1080p_hud_single_textures",
			"material",
			"materials/ui/ui_1080p_menu_atlas_textures",
			"material",
			"materials/ui/ui_1080p_menu_single_textures",
			"material",
			"materials/ui/ui_1080p_common"
		)
	end

	self.width, self.height = Gui.resolution()
	self.color = { 255, 255, 255, 255 }
	self.font = Fonts.arial
end

function Canvas:destroy()
	if not self.gui or self.keep_gui then
		return
	end

	World.destroy_gui(self.world, self.gui)
	self.gui = nil
end

function Canvas:set_color(a, r, g, b)
	self.color[1] = a
	self.color[2] = r
	self.color[3] = g
	self.color[4] = b
end

function Canvas:get_color(a, r, g, b)
	return self.color[1], self.color[2], self.color[3], self.color[4]
end

function Canvas:set_font(font)
	self.font = Fonts[font]
end

function Canvas:get_size()
	return self.width, self.height
end

function Canvas:rect(x, y, w, h)
	if not self.gui then
		return
	end

	return Gui.rect(self.gui, Vector2(x, y), Vector2(w, h), Color(unpack(self.color)))
end

function Canvas:line(x1, y1, x2, y2, line_width)
	if not self.gui then
		return
	end

	line_width = line_width or 3
	local dx, dy = x2 - x1, y2 - y1

	Gui.rect_3d(
		self.gui,
		Rotation2D(Vector2(x1, y1), -math.atan2(dy, dx)),
		Vector2(0, 0),
		1, -- layer
		Vector2((dx * dx + dy * dy) ^ 0.5, line_width),
		Color(unpack(self.color))
	)
end

function Canvas:texture(texture, x, y, w, h)
	if not self.gui then
		return
	end

	local texture_settings = UIAtlasHelper.get_atlas_settings_by_texture_name(texture)

	return Gui.bitmap_uv(
		self.gui,
		texture_settings.material_name,
		Vector2(texture_settings.uv00[1], texture_settings.uv00[2]),
		Vector2(texture_settings.uv11[1], texture_settings.uv11[2]),
		Vector2(x, y),
		Vector2(w, h),
		Color(unpack(self.color))
	)
end

function Canvas:text(str, x, y)
	if not self.gui then
		return
	end

	return Gui.text(
		self.gui,
		str,
		self.font[1], -- font_material
		self.font[2], -- font size
		self.font[3], -- font name
		Vector2(x, y),
		Color(unpack(self.color))
	)
end

function Canvas:text_extent(text, ...)
	if not self.gui then
		return
	end

	local min, max, caret = Gui.text_extents(
		self.gui,
		text,
		self.font[1], -- font_material
		self.font[2], -- font_size,
		...
	)

	return caret --, max.x - min.x, max.y - min.y
end

function Canvas:word_wrap(text, width, ...)
	if not self.gui then
		return
	end

	return Gui.word_wrap(
		self.gui,
		text,
		self.font[1], -- font_material
		self.font[2], -- font_size
		width,
		" ", -- whitespace
		"-+&/*", -- soft_dividers
		"\n", -- return_dividers
		true, -- reuse_global_table
		...
	)
	-- list of strings
end

function Canvas:text_color(x, y, w, text, ...)
	local line_height = 24

	-- Compute the wrap, because it's the same regardless of the colors.
	local lines = self:word_wrap(text, w)

	local current_pos, style_index = 1, 1
	for i, line in ipairs(lines) do
		local ox, oy = x, y - line_height * i
		repeat
			-- Get the next (position, color) tuple.
			local next_pos, next_col
			while true do
				next_pos, next_col = select(style_index, ...)
				next_pos = next_pos or math.huge
				if current_pos >= next_pos then
					self:set_color(unpack(next_col))
					style_index = style_index + 2
				else
					break
				end
			end

			-- Get the shortest between: change of color and end-of-line.
			local len = math.min(next_pos - current_pos, #line)

			local prefix = string.sub(line, 1, len)
			local span = self:text_extent(prefix)
			self:text(prefix, ox, oy)
			line, current_pos = string.sub(line, len + 1), current_pos + len
			ox = ox + span.x
		until line == ""
	end

	return #lines
end

return Canvas
