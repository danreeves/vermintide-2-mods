local mod = get_mod('game-stats')
local simple_ui = get_mod("SimpleUI")

mod.create_window = function(self)
	local native_screen_width, native_screen_height = Application.resolution()
	local width = 800
	local height = 600
	local x = (1920 / 2) - (width / 2)
	local y = (1080 / 2) - (height / 2)
	local window = simple_ui:create_window('mission stats', {x, y}, {width, height})
	window:create_title('title', 'Mission Stats')
	window:create_close_button('close')
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