local mod = get_mod("sound_player")

local Canvas = mod:dofile("scripts/mods/sound_player/lib/canvas")
local SoundPlayerView = class()


function SoundPlayerView:init(ingame_ui_context, dialogue_data)
  self:set_context(ingame_ui_context)

  self.caret_t = 0
  self.needle_list = {}
  self.input_data = { text = "", index = 1, mode = "insert" }

  self.selected_event = nil
  self.dialogue_data = dialogue_data
end


function SoundPlayerView:set_context(ingame_ui_context)
  self.ui_renderer = ingame_ui_context.ui_renderer

  local input_manager = ingame_ui_context.input_manager
  input_manager:create_input_service("SoundPlayerView", "IngameMenuKeymaps", "IngameMenuFilters")
  input_manager:map_device_to_service("SoundPlayerView", "keyboard")
  input_manager:map_device_to_service("SoundPlayerView", "mouse")
  input_manager:map_device_to_service("SoundPlayerView", "gamepad")
  self.input_manager = input_manager

  local world = ingame_ui_context.world_manager:world("level_world")
  self.wwise_world = Managers.world:wwise_world(world)

  if self.canvas then
    self.canvas:destroy()
  end
  self.canvas = Canvas:new(self.ui_renderer.world, self.ui_renderer.gui)
end


function SoundPlayerView:play_selected_sound(event_override, ...)
  event_override = event_override or self.selected_event
  return WwiseWorld.trigger_event(self.wwise_world, event_override, ...)
end


function SoundPlayerView:update(dt)
  local input_service = self:input_service()
  if input_service.get(input_service, "toggle_menu") then
    mod:handle_transition("close_sound_player", true, false)
  end

  local changed, needle = self:_handle_text_input()
  needle = string.lower(needle)

  if changed then
    local dialogue_data = self.dialogue_data
    dialogue_data:perform_search(self:_build_needle_list(needle))
    self.caret_t = 0

    if dialogue_data[1].utility > 0 then
      mod:echo("selected_event is " .. dialogue_data[1].event)
      self.selected_event = dialogue_data[1].event
    end
  end

  self:draw(dt)
end


function SoundPlayerView:on_enter(transition_params)
  WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_open")
end
function SoundPlayerView:on_exit(transition_params)
  WwiseWorld.trigger_event(self.wwise_world, "Play_hud_button_close")
end


function SoundPlayerView:input_service()
  return self.input_manager:get_service("SoundPlayerView")
end


function SoundPlayerView:_handle_text_input()
  local input_data = self.input_data
  local new_text
  new_text, input_data.index, input_data.mode = KeystrokeHelper.parse_strokes(input_data.text, input_data.index, input_data.mode, Keyboard.keystrokes())
  local changed = new_text ~= input_data.text
  input_data.text = new_text
  return changed, new_text
end


function SoundPlayerView:_build_needle_list(needle)
  local needle_list = self.needle_list
  local i = 0
  for n in string.gmatch(needle, "%S+") do
    i = i + 1
    needle_list[i] = n
  end
  for j=i+1, #needle_list do
    needle_list[j] = nil
  end
  return needle_list
end


function SoundPlayerView:draw(dt)
  self.caret_t = self.caret_t + 5*dt

  local canvas = self.canvas

  -- Background.
  canvas:set_color(230, 200, 200, 200)
  canvas:rect(50-5, canvas.height - 45, canvas.width - 90, -60 - 0.5*canvas.height)
  canvas:set_color(230, 0, 0, 0)
  canvas:rect(50, canvas.height - 50, canvas.width - 100, -50 - 0.5*canvas.height)
  canvas:set_color(230, 200, 200, 200)
  canvas:rect(50, canvas.height - 50 - 50, canvas.width - 100, 5)

  -- Needle.
  canvas:set_color(255, 255, 255, 0)
  local needle = self.input_data.text
  canvas:text(needle, 100, canvas.height - 80)

  -- Caret.
  canvas:set_color(127 + 127*math.cos(self.caret_t), 255, 255, 255)
  local span = canvas:text_extent(string.sub(needle, 1, self.input_data.index-1))
  canvas:line(100 + span.x, canvas.height - 60, 100 + span.x, canvas.height - 60 - 30, 1)

  local dialogue_data = self.dialogue_data

  local oy = 0
  local max_utility = dialogue_data[1].utility
  if max_utility > 0 then
    for i=1, 50 do
      local data = dialogue_data[i]
      if not data or data.utility < max_utility then break end
      local line_count = canvas:text_color(
        100,
        canvas.height - 100 - oy,
        canvas.width - 200,
        data.subtitle,
        unpack(data.format)
      )

      oy = oy + 24*line_count
      if oy > canvas.height*0.38 then
        break
      end
    end
  end
end

return SoundPlayerView
