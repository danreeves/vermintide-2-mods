-- luacheck: globals get_mod PartyManager
local mod = get_mod("MorePlayers2")

mod:hook_origin(PartyManager, "server_peer_left_session", function(self, peer_id)
	self._hot_join_synced_peers[peer_id] = false
	local parties = self._parties

	for party_id = 0, #parties, 1 do
		local party = parties[party_id]
		local slots = party.slots
		local num_slots = party.num_slots

		for i = 1, num_slots, 1 do
			local status = slots[i]

			-- MODIFIED. CHECK IF STATUS BEFORE INDEXING ON IT
			if not status then
				return
			end

			if status.peer_id == peer_id then
				self:remove_peer_from_party(status.peer_id, status.local_player_id, party_id)
			end
		end
	end
end)
