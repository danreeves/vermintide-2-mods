local mod = get_mod("store-improvements")
local definitions = mod:dofile("scripts/mods/store-improvements/ui/definitions")
local scenegraph_definition = definitions.scenegraph_definition
local widget_definitions = definitions.widgets
local NOTIFY_MOD = true

StoreImprovementsUI = class(StoreImprovementsUI)

function StoreImprovementsUI.init(self, params)
	self._params = params
	self._parent = params.parent
	local ui_renderer, ui_top_renderer = self._parent:get_renderers()
	self._ui_renderer = ui_renderer
	self._ui_top_renderer = ui_top_renderer
	self._render_settings = {
		snap_pixel_positions = true,
	}

	self._ui_scenegraph = UISceneGraph.init_scenegraph(scenegraph_definition)
	local widgets = {}

	for name, widget_definition in pairs(widget_definitions) do
		local widget = UIWidget.init(widget_definition)
		widgets[#widgets + 1] = widget
		local key = widget.content.setting_text:gsub("store_improvements_", "")
		local current = mod:get(key)
		widget.content.checked = current
	end

	self._widgets = widgets

	UIRenderer.clear_scenegraph_queue(self._ui_top_renderer)
end

function StoreImprovementsUI.update(self, dt)
	local ui_renderer = self._ui_renderer
	local ui_top_renderer = self._ui_top_renderer
	local ui_scenegraph = self._ui_scenegraph
	local input_service = self._parent:window_input_service()

	for _, widget in ipairs(self._widgets) do
		local hotspot = widget.content.button_hotspot
		if hotspot.on_hover_enter then
			if mod.wwise_world then
				WwiseWorld.trigger_event(mod.wwise_world, "Play_hud_hover")
			end
		end
		if hotspot.on_release then
			if mod.wwise_world then
				WwiseWorld.trigger_event(mod.wwise_world, "Play_hud_select")
			end
			local key = widget.content.setting_text:gsub("store_improvements_", "")
			local current = mod:get(key)
			mod:set(key, not current, NOTIFY_MOD)
			widget.content.checked = not current
		end
	end

	UIRenderer.begin_pass(ui_top_renderer, ui_scenegraph, input_service, dt, nil, self._render_settings)

	for _, widget in ipairs(self._widgets) do
		UIRenderer.draw_widget(ui_top_renderer, widget)
	end

	UIRenderer.end_pass(ui_top_renderer)
end

function StoreImprovementsUI.destroy(self)
	if self._viewport_widget then
		UIWidget.destroy(self.ui_top_renderer, self._viewport_widget)

		self._viewport_widget = nil
	end
end

mod:hook(_G, "Localize", function(func, id, ...)
	if string.starts_with(id, "store_improvements_") then
		return mod:localize(id)
	end
	return func(id, ...)
end)
