-- luacheck: globals get_mod
local mod = get_mod("MMONames2")

mod:network_register("mmonames2_set_color", function(peer_id, r, g, b)
  mod.player_colors[peer_id] = {r, g, b}
end)

mod:network_register("mmonames_2_request_color", function()
  mod.set_color()
end)

function mod.set_color()
  local r, g, b = mod:get("user_color_r"), mod:get("user_color_g"), mod:get("user_color_b")
  mod:network_send("mmonames2_set_color", "all", r, g, b)
end

function mod.on_setting_changed()
  mod.set_color()
end

function mod.on_user_joined()
  mod:network_send("mmonames_2_request_color", "all")
end
