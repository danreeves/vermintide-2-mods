local mod = get_mod("letterbox-tweaks")

mod:hook_safe(CutsceneUI, 'init', function(self)
  local letterbox_height = mod:get('letterbox_height')
  self.ui_scenegraph.letterbox_top_bar.size[2] = letterbox_height
  self.ui_scenegraph.letterbox_bottom_bar.size[2] = letterbox_height
end)

mod:hook(CutsceneUI, 'set_letterbox_enabled', function(func, self, ...)
  local letterbox_disabled = mod:get('letterbox_disabled')
  if (letterbox_disabled) then
    func(self, false)
  else
    func(self, ...)
  end
end)
