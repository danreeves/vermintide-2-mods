-- luacheck: globals get_mod ChallengeTrackerUI table.contains
local mod = get_mod("MorePlayers2")

-- copied from definitions file
local QUEST_SIZE = {
	200,
	75,
}
local QUEST_PADDING = 20
local function get_widget_position(offset, index)
	return {
		offset[1],
		offset[2] - (QUEST_SIZE[2] + QUEST_PADDING) * (index - 1),
		offset[3],
	}
end

mod:hook_safe(ChallengeTrackerUI, "_refresh_challenge_data", function(self)
	local data = self._data
	local widgets = data.widgets

	local seen_types = {}
	local new_widgets = {}
	for i = 1, #widgets, 1 do
		local widget = widgets[i]
		local challenge_type = widget.content.challenge:get_challenge_name()
		if not table.contains(seen_types, challenge_type) then
			widget.offset = get_widget_position(data.offset, i)
			table.insert(seen_types, challenge_type)
			table.insert(new_widgets, widget)
		end
	end
	self._data.widgets = new_widgets
end)
