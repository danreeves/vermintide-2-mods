-- luacheck: globals get_mod IngamePlayerListUI UIWidget local_require
local mod = get_mod("MorePlayers2")
local definitions = local_require("scripts/ui/views/ingame_player_list_ui_v2_definitions")

-- Just creates widgets, you can't see them
mod:hook_safe(IngamePlayerListUI, "_create_ui_elements", function(self)
  for i = 9, 32, 1 do
    self._player_list_widgets[i] = UIWidget.init(definitions.player_widget_definition(i))
  end
end)
