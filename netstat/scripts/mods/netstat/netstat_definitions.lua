local mod = get_mod("netstat")
local WIDTH = 1920
local HEIGHT = 1080
local ROW_HEIGHT = 20
local COL_WIDTH = 40
local MARGIN_RIGHT = 50
local MARGIN_TOP = 100

local scenegraph_definition = {
	screen = {
		scale = "fit",
		size = {
			WIDTH,
			HEIGHT,
		},
		position = {
			0,
			0,
			UILayer.hud,
		},
	},
	pivot = {
		parent = "screen",
		size = { 0, 0 },
		vertical_alignment = "top",
		horizontal_alignment = "right",
		position = {
			-(MARGIN_RIGHT + (COL_WIDTH * 5)),
			-MARGIN_TOP,
			UILayer.hud,
		},
	},
}

local DEFAULT_PASS = {
	style_id = nil,
	pass_type = "text",
	text_id = nil,
	retained_mode = false,
	fade_out_duration = 5,
	content_check_function = function(content)
		return true
	end,
}

local DEFAULT_STYLE = {
	font_type = "hell_shark",
	font_size = 16,
	vertical_alignment = "center",
	horizontal_alignment = "center",
	text_color = Colors.get_table("white"),
	offset = {
		0,
		0,
		0,
	},
}

local function create_widgets(rows)
	local passes = {}
	local content = {}
	local style = {}

	for row_i, row in ipairs(rows) do
		content = table.merge(content, row.content or {})

		for col_i, col in ipairs(row) do
			-- Create the pass
			local pass = table.clone(DEFAULT_PASS)
			pass.style_id = col.name
			pass.text_id = col.name
			pass.content_check_function = row.content_check_function or function()
				return true
			end
			table.insert(passes, pass)

			-- Content
			content[col.name] = col.content or ""

			-- Create the style
			local col_style = table.clone(DEFAULT_STYLE)
			col_style = table.merge(col_style, col.style or {})
			col_style.offset[1] = COL_WIDTH * col_i
			col_style.offset[2] = -(ROW_HEIGHT * row_i)
			style[col.name] = col_style
		end
	end

	return {
		scenegraph_id = "pivot",
		element = {
			passes = passes,
		},
		content = content,
		style = style,
		offset = {
			0,
			0,
			0,
		},
	}
end

local function create_row(i)
	return {
		{
			name = string.format("player_name_%i", i),
			style = {
				horizontal_alignment = "right",
			},
		},
		{
			name = string.format("current_ping_text_%i", i),
		},
		{
			name = string.format("min_ping_text_%i", i),
		},
		{
			name = string.format("max_ping_text_%i", i),
		},
		{
			name = string.format("avg_ping_text_%i", i),
		},
		content = {
			[string.format("show_player_%i", i)] = false,
		},
		content_check_function = function(content)
			return content[string.format("show_player_%i", i)]
		end,
	}
end

local widget_definition = create_widgets({
	{
		{
			name = "player_name_title",
		},
		{
			name = "current_title",
		},
		{
			name = "min_title",
			content = "min",
		},
		{
			name = "max_title",
			content = "max",
		},
		{
			name = "avg_title",
			content = "avg",
		},
		content_check_function = function(content)
			return content.show_player_1 or content.show_player_2 or content.show_player_3 or content.show_player_4
		end,
	},
	create_row(1),
	create_row(2),
	create_row(3),
	create_row(4),
})

return {
	scenegraph_definition = scenegraph_definition,
	widget_definition = widget_definition,
}
