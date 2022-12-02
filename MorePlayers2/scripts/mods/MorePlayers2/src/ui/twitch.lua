-- luacheck: globals get_mod TwitchVoteUI table.shuffle table.slice
local mod = get_mod("MorePlayers2")

-- TODO: THIS IS BUGGY
-- I fixed the crash and tried to make it work nicely by shuffling the players.
-- It doesn't crash anymore but the same character can show up multiple times,
-- obviously, and they share votes and I don't know who actually gets the
-- twitch buff or item yet...
-- It kinda works but is worth fixing!

mod:hook(TwitchVoteUI, "_sorted_player_list", function (func, self)
  local players = func(self)
  table.shuffle(players)
  local sliced_players = table.slice(players, 1, 4)
  return sliced_players
end)

