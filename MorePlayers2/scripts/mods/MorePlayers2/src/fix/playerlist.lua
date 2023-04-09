-- luacheck: globals get_mod UnitFramesHandler UnitFrameUI
local mod = get_mod("MorePlayers2")

mod:hook_origin(UnitFramesHandler, "_create_party_members_unit_frames", function(self)
	local unit_frames = self._unit_frames

	-- MODIFIED. USE MAX PLAYERS INSTEAD OF 3
	for i = 1, mod.MAX_PLAYERS, 1 do
		local unit_frame = self:_create_unit_frame_by_type("team", i)
		unit_frames[#unit_frames + 1] = unit_frame
	end
	self:_align_party_member_frames()
end)

mod:hook(UnitFrameUI, "_create_ui_elements", function(func, self, frame_index)
	if frame_index then
		-- MODIFIED. Ensure it's in the range 1-3
		func(self, frame_index % 3 + 1)
	else
		func(self, nil)
	end
end)
