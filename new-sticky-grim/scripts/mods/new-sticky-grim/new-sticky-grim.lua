local mod = get_mod("new-sticky-grim")

mod:hook(ActionThrowGrimoire, "finish", function(func, self, ...)
	local input_service = Managers.input:get_service("Player")

	if input_service:get("action_two_hold") then
		func(self, ...)
	end
end)
