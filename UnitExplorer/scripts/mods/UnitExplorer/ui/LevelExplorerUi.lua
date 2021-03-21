-- luacheck: globals LevelExplorerUi Imgui Managers LevelHelper Level ShowCursorStack class Keyboard Unit

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
  local level = LevelHelper:current_level(world)
  self._units = Level.units(level)
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
	Imgui.tree_push(tostring(Unit.id(unit)))
	if Imgui.tree_node(tostring(Unit.id(unit)), Unit.has_data(unit, "outlined_meshes")) then
	  Imgui.text(tostring(unit))
	  if Unit.has_data(unit, "outlined_meshes") then
		Imgui.text("has outline mesh")
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
