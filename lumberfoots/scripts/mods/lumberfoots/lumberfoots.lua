local mod = get_mod("lumberfoots")

mod:hook(WwiseWorld, "trigger_event", function(func, ...)
  local arg = {...}
  if string.match(arg[2], "pwe_activate_ability_handmaiden") then
    arg[2] = "pwe_activate_ability_handmaiden_03"
    return func(unpack(arg))
  end
  return func(...)
end)
