-- luacheck: globals get_mod ColorPicker class Imgui Keyboard VMFOptionsView
local vmf = get_mod("VMF")
local mod = get_mod("MMONames2")
local MOD_NAME = "MMONames2"

ColorPicker = class(ColorPicker)

function ColorPicker.init(self, color, callback)
  self.color = { color[1] / 255, color[2] / 255, color[3] / 255 }
  self.callback = callback
end

function ColorPicker.open(self)
  Imgui.open_imgui()
  self:capture_input()
end

function ColorPicker.capture_input()
  Imgui.enable_imgui_input_system(Imgui.KEYBOARD)
  Imgui.enable_imgui_input_system(Imgui.MOUSE)
end

function ColorPicker.draw(self)
  Imgui.begin_window("Color Picker")
  local r, g, b = Imgui.color_picker_3("Color", self.color[1], self.color[2], self.color[3], self.color[4])
  self.color = {r, g, b}
  if Imgui.button("Confirm") then
    self:save()
  end
  Imgui.end_window()
  if Keyboard.pressed(Keyboard.button_index("esc")) then
    self:close()
  end
end

function ColorPicker.save(self)
  local r = self.color[1] * 255
  local g = self.color[2] * 255
  local b = self.color[3] * 255
  mod:set("user_color_r", r)
  mod:set("user_color_g", g)
  mod:set("user_color_b", b)
  self.callback({r, g, b})
  self:close()
end

function ColorPicker.release_input()
  Imgui.disable_imgui_input_system(Imgui.KEYBOARD)
  Imgui.disable_imgui_input_system(Imgui.MOUSE)
end

function ColorPicker.close(self)
  Imgui.close_imgui()
  self:release_input()
end

-- Hell yeah
mod:hook(vmf, "register_view", function(func, self1, options, ...)
  if options.view_name == "vmf_options_view" then
    mod:hook_safe(VMFOptionsView, "callback_change_numeric_menu_visibility", function(self, widget_content)
      -- It's our widget
      if widget_content.mod_name == MOD_NAME then
        -- It's a numeric menu and open
        if widget_content.is_numeric_menu_opened then
          -- It's on of the colour inputs
          if string.starts_with(widget_content.setting_id, "user_color_") then
            -- Open Imgui
            local old_color = {mod:get("user_color_r"), mod:get("user_color_g"), mod:get("user_color_b")}
            mod.colorpicker = ColorPicker:new(old_color, function(new_color)
              local new_values = {
                user_color_r = new_color[1],
                user_color_g = new_color[2],
                user_color_b = new_color[3],
              }
              for _, widgets in pairs(self.settings_list_widgets) do
                for _, widget in pairs(widgets) do
                  if widget.content and widget.content.setting_id then
                    if string.starts_with(widget.content.setting_id, "user_color_") then
                      widget.content.current_value_text = string.format("%d", new_values[widget.content.setting_id])
                    end
                  end
                end
              end
              mod.on_setting_changed()
            end)
            mod.colorpicker:open()
          end
        end
      end
    end)
  end
  func(self1, options, ...)
end)

function mod.update ()
  if mod.colorpicker then
    mod.colorpicker:draw()
  end
end
