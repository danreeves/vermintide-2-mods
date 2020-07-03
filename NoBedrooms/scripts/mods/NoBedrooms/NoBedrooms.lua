-- luacheck: globals get_mod
local mod = get_mod("NoBedrooms")

mod:hook(_G, "flow_query_leader_hero_level", function(func, params)
  local hero_name = params.hero_name
  local bedroom_disabled = mod:get(hero_name .. "_disabled")
  local out = func(params)
  if bedroom_disabled then
    -- make it less than 10
    out.value = 9
  end
  return out
end)
