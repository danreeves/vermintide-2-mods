-- luacheck: globals LevelExplorerUi Imgui Managers LevelHelper Level ShowCursorStack class
-- luacheck: globals Keyboard Unit get_mod Vector3Box QuaternionBox World
local mod = get_mod("UnitExplorer")

LevelExplorerUi = class(LevelExplorerUi)

function LevelExplorerUi.init(self)
	self._is_open = false
end

function LevelExplorerUi.toggle(self)
	if self._is_open then
		self:close()
	else
		self:open()
	end
end

function LevelExplorerUi.open(self)
	local world = Managers.world:world("level_world")
	self._raw_units = World.units(world)
	self._units = {}

	for i, unit in ipairs(self._raw_units) do
		-- Unit.set_unit_visibility(unit, true)
		local data = mod.extract_unit_data(unit)
		self._units[i] = data
	end

	self._is_open = true
	Imgui.open_imgui()
	self:capture_input()
end

function LevelExplorerUi.capture_input()
	ShowCursorStack.push()
	Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.enable_imgui_input_system(Imgui.MOUSE)
end

function LevelExplorerUi.draw(self)
	Imgui.set_next_window_size(500, 500)
	Imgui.begin_window("Level Explorer")
	Imgui.spacing()
	for _, unit in pairs(self._units) do
		Imgui.tree_push(unit.id)

		if Imgui.tree_node(unit.id, #unit.extensions > 0) then
			if unit.name ~= "" then
				Imgui.text("Name: " .. unit.name)
			end
			Imgui.text("Hash: " .. unit.hash)
			Imgui.text("Pos: " .. tostring(unit.position:unbox()))
			Imgui.text("Rot: " .. tostring(unit.rotation:unbox()))

			if unit.from_game_mode then
				Imgui.text("Respawn for: " .. (unit.from_game_mode or "default"))
			end

			if Imgui.tree_node("Extensions", #unit.extensions > 0) then
				for _, extension in ipairs(unit.extensions) do
					Imgui.text(extension)
				end

				Imgui.tree_pop()
			end

			Imgui.tree_pop()
		end

		Imgui.tree_pop()
	end
	Imgui.spacing()
	Imgui.end_window()
	if Keyboard.pressed(Keyboard.button_index("esc")) then
		self:close()
	end
end

function LevelExplorerUi.release_input()
	ShowCursorStack.pop()
	Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
	Imgui.disable_imgui_input_system(Imgui.GAMEPAD)
end

function LevelExplorerUi.close(self)
	self._is_open = false
	Imgui.close_imgui()
	self:release_input()
end

return LevelExplorerUi
