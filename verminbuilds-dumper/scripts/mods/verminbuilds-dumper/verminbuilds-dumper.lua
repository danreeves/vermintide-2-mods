local mod = get_mod("verminbuilds-dumper")

local locale_code = Application.user_setting("language_id")
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

local function get_localisation_data(data)
  local strings = {}

  local function add (key)
    strings[key] = Localize(key)
  end

  for key, character in pairs(data.characters) do
    add(character.character_name)
    add(character.ingame_display_name)
    add(character.ingame_short_display_name)
  end

  for key, career in pairs(data.careers) do
    mod:echo("Generating strings for: %s", key)
    add(career.display_name)
    add(career.passive_ability.display_name)
    add(career.passive_ability.description)
    for _, perk in ipairs(career.passive_ability.perks) do
      add(perk.display_name)
      add(perk.description)
    end
    add(career.activated_ability.display_name)
    add(career.activated_ability.description)
    for _, talent in ipairs(data.talents[career.profile_name]) do
      add(talent.name)
      add(talent.description)
    end
  end

  for _, item in pairs(data.items) do
    add(item.item_type)
  end

  return strings
end

mod:command("dump", "dump all the data for verminbuilds", function()
  mod:echo("--- Starting ---")

  mod:echo("--- Character & Talent Data ---")

  local characters = {}
  for _, profile_index in ipairs(ProfilePriority) do
    local profile = SPProfiles[profile_index]
    characters[profile.display_name] = {
      character_name = profile.character_name,
      ingame_display_name = profile.ingame_display_name,
      ingame_short_display_name = profile.ingame_short_display_name
    }
  end

  local careers = {}
  for name, settings in pairs(CareerSettings) do
    careers[name] = {
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
    careers[name].activated_ability.ability_class = nil
  end

  mod:echo("--- Items ---")

  local items = {}
  for key, item in pairs(ItemMasterList) do
    if item.item_type and item.can_wield then
      local slot_whitelist =  { melee = true , ranged = true, necklace = true, ring = true, trinket = true }
      if slot_whitelist[item.slot_type] then
        items[key] = {
          slot_type = item.slot_type,
          item_type = item.item_type,
          can_wield = item.can_wield,
        }
      end
    end
  end

  local data = {
    characters = characters,
    careers = careers,
    items = items,
    trees = TalentTrees,
    talents = Talents,
    num_talent_rows = NumTalentRows,
    num_talet_columns = NumTalentColumns,
  }
  write('data.json', cjson.encode(data))

  mod:echo("--- %s localisations ---", locale_code)
  local strings = get_localisation_data(data)
  write(string.format("%s.json", locale_code), cjson.encode(strings))

  mod:echo("--- Done ---")
end)
