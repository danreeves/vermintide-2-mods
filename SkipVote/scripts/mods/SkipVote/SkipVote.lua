-- luacheck: globals get_mod Managers
local mod = get_mod("SkipVote")

local function complete_vote(vote)
	if Managers.player.is_server and Managers.state.voting:vote_in_progress() then
		Managers.state.network.network_transmit:send_rpc_all("rpc_client_complete_vote", vote)
	end
end

function mod.skip_vote()
	complete_vote(1)
end

function mod.cancel_vote()
	complete_vote(0)
end

VoteTemplates.game_settings_vote.initial_vote_func = function()
			return {}
end
