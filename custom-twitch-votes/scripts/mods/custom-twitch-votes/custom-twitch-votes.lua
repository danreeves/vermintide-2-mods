local mod = get_mod("custom-twitch-votes")

local command = "set_twitch_votes"
local desc = " Set the Twitch vote strings.\n/set_twitch_votes vote1 vote2 vote3 vote4 vote5\nPass no strings to reset."

local DEFAULTS = {
	standard_vote = TwitchSettings.standard_vote,
	multiple_choice = TwitchSettings.multiple_choice,
}

local function isempty(s)
	return s == nil or s == ""
end

mod:command(command, desc, function(a, b, c, d, e)
	local vote_a = not isempty(a) and a or DEFAULTS.multiple_choice.default_vote_a_str
	local vote_b = not isempty(b) and b or DEFAULTS.multiple_choice.default_vote_b_str
	local vote_c = not isempty(c) and c or DEFAULTS.multiple_choice.default_vote_c_str
	local vote_d = not isempty(d) and d or DEFAULTS.multiple_choice.default_vote_d_str
	local vote_e = not isempty(e) and e or DEFAULTS.multiple_choice.default_vote_e_str

	mod:echo("Setting Twitch Votes:")
	mod:echo("#a = " .. vote_a)
	mod:echo("#b = " .. vote_b)
	mod:echo("#c = " .. vote_c)
	mod:echo("#d = " .. vote_d)
	mod:echo("#e = " .. vote_e)

	TwitchSettings.standard_vote.default_vote_a_str = vote_a
	TwitchSettings.standard_vote.default_vote_b_str = vote_b

	TwitchSettings.multiple_choice.default_vote_a_str = vote_a
	TwitchSettings.multiple_choice.default_vote_b_str = vote_b
	TwitchSettings.multiple_choice.default_vote_c_str = vote_c
	TwitchSettings.multiple_choice.default_vote_d_str = vote_d
	TwitchSettings.multiple_choice.default_vote_e_str = vote_e
end)

mod:hook(TwitchVoteUI, "show_ui", function(func, self, ...)
	mod:dump(self._active_vote, "active_vote", 4)
	-- @TODO How do I change standard labels D:
	return func(self, ...)
end)
