local mod = get_mod("MorePlayers2")

local actual_anim = {}
local skipped_anims = 0

mod:hook_safe(StateIngame, "on_enter", function(self)
	actual_anim = {}

	if skipped_anims > 1 then
		mod:echo("BandwidthFreer prevented " .. skipped_anims .. " packets from being sent")
	end
	skipped_anims = 0
end)

mod:hook_origin(GameNetworkManager, "anim_event", function(self, unit, event)
	local go_id = self.unit_storage:go_id(unit)

	fassert(go_id, "Unit storage does not have a game object id for %q", unit)

	local event_id = NetworkLookup.anims[event]

	if self.game_session then
		if self.is_server then
			local time = Managers.time:time("game")
			if
				not actual_anim[unit]
				or (time - actual_anim[unit].timer) > 0.5
				or actual_anim[unit].event_id ~= event_id
			then
				self.network_transmit:send_rpc_clients("rpc_anim_event", event_id, go_id)
				actual_anim[unit] = {
					event_id = event_id,
					timer = time,
				}
			else
				skipped_anims = skipped_anims + 1
			end
		else
			self.network_transmit:send_rpc_server("rpc_anim_event", event_id, go_id)
		end
	end

	Unit.animation_event(unit, event)
end)
