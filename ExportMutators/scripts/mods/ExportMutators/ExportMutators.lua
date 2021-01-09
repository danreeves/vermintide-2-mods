-- luacheck: globals get_mod Localize MutatorTemplates cjson
local mod = get_mod("ExportMutators")

local app_data = os.getenv("APPDATA")
local desktop = app_data:gsub("\\AppData\\Roaming", "\\Desktop\\")

local function write(filename, contents)
  local path = desktop .. filename
  mod:echo("Writing to " .. path)
  local file = io.open(path, "w+")
  file:write(contents)
  file:close()
end

mod:command("exportmutators", "", function()
  local out = {}
  for key, data in pairs(MutatorTemplates) do
	out[key] = Localize(data.display_name)
  end
  write("mutators.json", cjson.encode(out))
end)
