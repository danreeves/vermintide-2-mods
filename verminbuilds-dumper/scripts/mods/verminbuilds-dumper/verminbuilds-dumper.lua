local mod = get_mod("verminbuilds-dumper")

local locales = {"en",}-- "fr", "de", "it", "pl", "br-pt", "ru", "es", "zh"}
local out_dir = "C:\\dev\\"

mod:command("outdir", "set the output director for dumping, defaults to C:\\dev\\", function(path)
  out_dir = path
  mod:echo("Output directory: %s", path)
end)

local function write(filename, contents)
  local file = io.open(string.format("%s%s", out_dir, filename), "w+")
  file:write(contents)
  file:close()
end

local function get_localisation_data(language_id, data)
  local profiles_complete = {}
  local strings = {}

  for _, character in pairs(data.characters) do
    if not profiles_complete[character.profile_name] then
      mod:echo("Generating strings for: %s", character.profile_name)
      strings[character.display_name] = Localize(character.display_name)
      strings[character.description] = Localize(character.description)
      for _, talent in ipairs(data.talents[character.profile_name]) do
        strings[talent.name] = Localize(talent.name)
        strings[talent.description] = Localize(talent.description)
      end
    end
    profiles_complete[character.profile_name] = true
  end

  return strings
end

mod:command("dump", "dump all the data for verminbuilds", function()
  mod:echo("--- Starting ---")

  mod:echo("--- Character & Talent Data ---")

  local characters = {}
  for name, settings in pairs(CareerSettings) do
    characters[name] = {
      profile_name = settings.profile_name,
      display_name = settings.display_name,
      description = settings.description,
      talent_tree_index = settings.talent_tree_index,
      sort_order = settings.sort_order,
      attributes = settings.attributes,
      activated_ability = settings.activated_ability,
      passive_ability = settings.passive_ability,
      portrait_image = settings.portrait_image,
      loadout_equipment_slots = settings.loadout_equipment_slots,
    }
    characters[name].activated_ability.ability_class = nil
  end

  local data = {
    characters = characters,
    trees = TalentTrees,
    talents = Talents
  }
  write('data.json', cjson.encode(data))

  for _, locale in ipairs(locales) do
    mod:echo("--- %s localisations ---", locale)
    local strings = get_localisation_data(locale, data)
    write(string.format("%s.json", locale), cjson.encode(strings))
  end

  mod:echo("--- Done ---")
end)
