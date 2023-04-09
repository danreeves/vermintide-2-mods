local mod = get_mod("disable-ff-dialogue")

mod:hook(WwiseWorld, "trigger_event", function(func, ...)
	local arg = { ... }
	if string.match(arg[2], "friendly_fire") then
		return -1, -1
	end
	return func(...)
end)
