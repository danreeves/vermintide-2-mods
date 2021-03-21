-- luacheck: globals Unit get_mod
local mod = get_mod("UnitExplorer")

function mod.unit_hash(unit)
  local debug_name = Unit.debug_name(unit)
  debug_name = string.gsub(debug_name, "#ID%[", "")
  debug_name = string.gsub(debug_name, "%]", "")
  return debug_name
end
