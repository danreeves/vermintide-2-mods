local mod = get_mod("super-vortex")

local defaults = {}

function mod:on_enabled()
  for name, settings in pairs(Breeds) do
    if not string.find(name, "sorcerer") then
      defaults[name] = Breeds[name].vortexable
      Breeds[name].vortexable = true
    end
  end
end

function mod:on_disabled()
  for name, val in pairs(defaults) do
    Breeds[name].vortexable = val
  end
end
