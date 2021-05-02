-- luacheck: globals get_mod ImguiWeaponEditor CharacterStateHelper Vector3
-- luacheck: globals Managers Imgui ShowCursorStack
local mod = get_mod("WeaponEditor")

function mod.on_all_mods_loaded()
	Managers.package:load("resource_packages/imgui/imgui", "raindish-mod", function()
		require("scripts/imgui/imgui")
	end)
end

function mod.toggle_ui()
	if ImguiWeaponEditor then
		if mod.editor ~= nil then
			mod.editor = nil
			Imgui.close_imgui()
			ShowCursorStack.pop()
			Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
			Imgui.disable_imgui_input_system(Imgui.GAMEPAD)
		else
			mod.editor = ImguiWeaponEditor:new()
			Imgui.open_imgui()
			ShowCursorStack.push()
			Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
			Imgui.enable_imgui_input_system(Imgui.MOUSE)
		end
	end
end

function mod.update()
	if mod.editor then
		mod.editor:update()
		mod.editor:draw()
	end
end

mod:hook(CharacterStateHelper, "get_look_input", function(func, input_extension, ...)
	if mod.editor then
		local player_unit = Managers.player:local_player().player_unit
		if input_extension.unit == player_unit then
			return Vector3(0, 0, 0)
		end
	end
	return func(input_extension,...)
end)
