local mod = get_mod('game-stats')
local simple_ui = get_mod('SimpleUI')

local classes = mod.classes
local difficulties = mod.difficulties
local levels = mod.levels

function to_localised_options(list, SettingsTable)
  local options = {}
  for i, key in pairs(list) do
    local settings = SettingsTable[key]
    local display_name = settings.display_name
    options[Localize(display_name)] = i
  end
  return options
end

local class_options = to_localised_options(classes, CareerSettings)
local difficulty_options = to_localised_options(difficulties, DifficultySettings)
local level_options = to_localised_options(levels, LevelSettings)

mod.create_window = function(self)
  local native_screen_width, native_screen_height = Application.resolution()
  local width = 800
  local height = 600
  local x = (1920 / 2) - (width / 2)
  local y = (1080 / 2) - (height / 2)
  local window = simple_ui:create_window('mission stats', {x, y}, {width, height})

  window:create_title('title', 'Mission Stats')
  window:create_close_button('close')

  window:create_dropdown('classes', {20, 25}, {200, 30}, 'top_left', class_options)
  window:create_dropdown('difficulties', {240, 25}, {200, 30}, 'top_left', difficulty_options)
  window:create_dropdown('levels', {460, 25}, {200, 30}, 'top_left', level_options)

  window:init()
  window:bring_to_front()

  window._was_closed = false
  window.before_destroy = function(self)
    self._was_closed = true
  end

  self.window = window
end

mod.destroy_window = function(self)
  if self.window then
    self.window:destroy()
    self.window = nil
  end
end

mod.reload_window = function(self)
  self:destroy_window()
  self:create_window()
end

mod.toggle_window = function()
  if mod.window and not mod.window._was_closed then
    mod:destroy_window()
  else
    mod:reload_window()
  end
end

return
