local mod = get_mod("sound_player")

local Dialogue = mod:dofile("scripts/mods/sound_player/lib/dialogue")
local SoundPlayerView = mod:dofile("scripts/mods/sound_player/lib/sound_player_view")

-- Dialogue data. {{{1
-------------------------------------------------------------------------------------------------------------

local dialogue_data = Dialogue:new()
-- Common stuff.
dialogue_data:load_from_file_list(DialogueSettings.auto_load_files)
-- Level specific.
for level, level_dialogue_file_list in pairs(DialogueSettings.level_specific_load_files) do
	dialogue_data:load_from_file_list(level_dialogue_file_list)
end

-- Loehner's Loading Long Lullabies.
for _, level in pairs(LevelSettings) do
	if level.loading_screen_wwise_events then
		for _, wwise_event in ipairs(level.loading_screen_wwise_events) do
			dialogue_data:add_dialogue(wwise_event, wwise_event)
		end
	end
end

-- SoundPlayerView. {{{1
-------------------------------------------------------------------------------------------------------------
local view
mod:register_view({
	view_name = "sound_player_view",

	view_settings = {
		init_view_function = function(ingame_ui_context)
			if not view then
				view = SoundPlayerView:new(ingame_ui_context, dialogue_data)
			else
				view:set_context(ingame_ui_context)
			end
			return view
		end,
		active = { inn = true, ingame = true },
	},

	view_transitions = {
		open_sound_player = function(ingame_ui, transition_params)
			if ShowCursorStack.stack_depth == 0 then
				ShowCursorStack.push()
			end

			ingame_ui.input_manager:block_device_except_service("SoundPlayerView", "keyboard", 1)
			ingame_ui.input_manager:block_device_except_service("SoundPlayerView", "mouse", 1)
			ingame_ui.input_manager:block_device_except_service("SoundPlayerView", "gamepad", 1)

			ingame_ui.menu_active = true
			ingame_ui.current_view = "sound_player_view"
		end,

		close_sound_player = function(ingame_ui, transition_params)
			ShowCursorStack.pop()

			ingame_ui.input_manager:device_unblock_all_services("keyboard", 1)
			ingame_ui.input_manager:device_unblock_all_services("mouse", 1)
			ingame_ui.input_manager:device_unblock_all_services("gamepad", 1)

			ingame_ui.menu_active = false
			ingame_ui.current_view = nil
		end,
	},
})

-- Play sound. {{{1
-------------------------------------------------------------------------------------------------------------
function mod.play_selected_sound()
	if not view or not view.selected_event then
		mod:error("No sound selected!")
	end

	view:play_selected_sound()
end
