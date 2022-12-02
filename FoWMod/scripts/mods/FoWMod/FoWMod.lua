-- luacheck: globals get_mod
local mod = get_mod("FoWMod")

mod:dofile("scripts/mods/FoWMod/debug_spawners")
local custom_terror_events = mod:dofile("scripts/mods/FoWMod/terror_events_plaza")

fow_default_terror_events = fow_default_terror_events or table.clone(TerrorEventBlueprints.plaza)

if mod:is_enabled() then
  TerrorEventBlueprints.plaza = custom_terror_events
end

function mod.on_enabled()
  TerrorEventBlueprints.plaza = custom_terror_events
end

function mod.on_disabled()
  TerrorEventBlueprints.plaza = fow_default_terror_events
end

mod:command("debug_toggle_plaza", "", function()
  if TerrorEventBlueprints.plaza == fow_default_terror_events then
	mod:echo("setting custom terror events")
	TerrorEventBlueprints.plaza = custom_terror_events
  else
	mod:echo("setting default terror events")
	TerrorEventBlueprints.plaza = fow_default_terror_events
  end
end)
