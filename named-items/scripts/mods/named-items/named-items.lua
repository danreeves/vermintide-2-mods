local mod = get_mod("named-items")

mod.SETTING_ID = "item_names"

NamePopup = class(NamePopup)

function NamePopup.init(self)
	self.backend_id = nil
	self.name = nil
	self.description = nil
end

function NamePopup.capture_input()
	local input_manager = Managers.input

	if input_manager then
		input_manager:capture_input({
			"keyboard",
			"gamepad",
			"mouse",
		}, 1, "chat_input", "Imgui")
	end

	ShowCursorStack.push()
	Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.enable_imgui_input_system(Imgui.MOUSE)
end

function NamePopup.release_input()
	local input_manager = Managers.input

	if input_manager then
		input_manager:release_input({
			"keyboard",
			"gamepad",
			"mouse",
		}, 1, "chat_input", "Imgui")
	end

	ShowCursorStack.pop()
	Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.disable_imgui_input_system(Imgui.MOUSE)
end

function NamePopup.draw(self)
	if self.backend_id then
		self:capture_input()
		Imgui.Begin("Name Item")
		self.name = Imgui.InputText("Name", self.name)
		self.description = Imgui.InputTextMultiline("Description", self.description)

		if Imgui.Button("Cancel", 300, 50) then
			self:close()
		end

		Imgui.SameLine()
		if Imgui.Button("Save", 300, 50) then
			mod.save_item_info(self.backend_id, self.name, self.description)
			self:close()
		end
		Imgui.End()
	end

	if Keyboard.pressed(Keyboard.button_index("esc")) then
		self:close()
	end
end

function NamePopup.open(self, backend_id)
	self.backend_id = backend_id
	local current_data = mod.get_item_info(backend_id) or { name = "", description = "" }
	self.name = current_data.name
	self.description = current_data.description

	Imgui.open_imgui()
	self:capture_input()
end

function NamePopup.close(self)
	self.backend_id = nil
	self.name = nil
	self.description = nil
	Imgui.close_imgui()
	self:release_input()
end

mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(hero_window_inventory)
	mod.item_grid = hero_window_inventory._item_grid
	mod.name_popup = NamePopup:new()
end)

mod:hook_safe(HeroWindowLoadoutInventory, "update", function()
	if mod.name_popup then
		mod.name_popup:draw()
	end
end)

mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(hero_window_inventory)
	mod.item_grid = nil

	if mod.name_popup then
		mod.name_popup:close()
		mod.name_popup:release_input()
		mod.name_popup = nil
	end
end)

function mod.save_item_info(backend_id, name, description)
	local info_table = mod:get(mod.SETTING_ID) or {}
	info_table[backend_id] = { name = name, description = description }
	mod:set(mod.SETTING_ID, info_table)
end

function mod.get_item_info(backend_id)
	local info_table = mod:get(mod.SETTING_ID) or {}
	return info_table[backend_id]
end

function mod.on_select_item()
	if not mod.item_grid then
		return
	end

	-- We're in the inventory view
	local item_grid = mod.item_grid
	local item = item_grid:get_item_hovered()
	if not item then
		return
	end

	-- An item is hovered
	if mod.name_popup then
		mod.name_popup:open(item.backend_id)
	end
end

mod:hook(_G, "Localize", function(func, id, ...)
	-- Item grid not open, return early
	if not mod.item_grid then
		return func(id, ...)
	end

	-- Not hovering an item, return early
	local item_grid = mod.item_grid
	local item = item_grid:get_item_hovered()
	if not item then
		return func(id, ...)
	end

	-- Hovered item is not the localization this pass wants, return early
	local _, display_name, description = UIUtils.get_ui_information_from_item(item)
	if description ~= id and display_name ~= id then
		return func(id, ...)
	end

	-- If we don't have data for the hovered item, return early
	local data = mod.get_item_info(item.backend_id)
	if not data then
		return func(id, ...)
	end

	if id == display_name then
		return data.name ~= "" and data.name or func(id, ...)
	end

	if id == description then
		return data.description ~= "" and data.description or func(id, ...)
	end

	return func(id, ...)
end)
