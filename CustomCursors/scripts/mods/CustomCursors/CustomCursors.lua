local mod = get_mod("CustomCursors")

Wwise.load_bank("wwise/mods/CustomCursors/YoshiTongue")

function mod.on_enabled()
	Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
end

function mod.on_disabled()
	Window.set_cursor("gui/cursors/mouse_cursor")
end

function mod.on_all_mods_loaded()
	if mod:is_enabled() then
		Window.set_cursor("cursors/mods/CustomCursors/Yoshi")
	end
end

mod:hook(WwiseWorld, "trigger_event", function(func, wwise_world, event, ...)
	if event == "play_gui_start_menu_button_hover" then
		return func(wwise_world, "mlem", ...)
	end
	return func(wwise_world, event, ...)
end)
