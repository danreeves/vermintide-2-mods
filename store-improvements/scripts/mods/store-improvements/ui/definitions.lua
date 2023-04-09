local scenegraph_definition = {
	root = {
		is_root = true,
		position = {
			0,
			0,
			UILayer.default + 10,
		},
		size = {
			1920,
			1080,
		},
	},
	owned_checkbox = {
		vertical_alignment = "top",
		parent = "root",
		horizontal_alignment = "right",
		size = {
			200,
			40,
		},
		position = {
			-300,
			123,
			UILayer.default + 10,
		},
	},
	affordable_checkbox = {
		vertical_alignment = "top",
		parent = "root",
		horizontal_alignment = "right",
		size = {
			200,
			40,
		},
		position = {
			-525,
			123,
			UILayer.default + 10,
		},
	},
}

local widgets = {
	owned_checkbox = UIWidgets.create_checkbox_widget(
		"store_improvements_filter_owned",
		"store_improvements_filter_owned_desc",
		"owned_checkbox",
		0,
		nil
	),
	affordable_checkbox = UIWidgets.create_checkbox_widget(
		"store_improvements_filter_affordable",
		"store_improvements_filter_affordable_desc",
		"affordable_checkbox",
		0,
		nil
	),
}

return {
	scenegraph_definition = scenegraph_definition,
	widgets = widgets,
}
