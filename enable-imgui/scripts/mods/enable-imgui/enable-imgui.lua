local mod = get_mod("enable-imgui")
-- local moreitemslibrary = get_mod("MoreItemsLibrary")

function mod.on_all_mods_loaded()
  Managers.package:load("resource_packages/imgui/imgui", "raindish-mod", function()
    mod:dofile("scripts/imgui/imgui")
    mod.imgui_manager = ImguiManager:new()
  end, false, true)
end

function mod.update()
  if mod.imgui_manager then
    mod.imgui_manager:update()
  end
end

--[[
mod:hook_safe(IngameHud, "init", function()
  mod.imgui_manager = ImguiManager:new()
end)

mod:hook_safe(IngameHud, "update", function()
  if mod.imgui_manager then
    mod.imgui_manager:update()
  end
end)

function mod.on_enabled()
  mod.imgui_manager = ImguiManager:new()
end

mod:hook(ImguiCraftItem, 'give_item', function(func, self, item_key, power_level, skin_name, rarity, properties, traits)
  mod:echo(item_key .. rarity)
  local traits_list = {}
  for trait,_ in pairs(traits) do
    table.insert(traits_list, trait)
  end
  local entry = table.clone(ItemMasterList[item_key])
  local backend_id = string.format("imgui-craft-item %d", math.random(10000))
  entry.mod_data = {
    backend_id = backend_id,
    ItemInstanceId = backend_id,
    CustomData = {
      traits = cjson.encode(traits_list),
      power_level = string.format("%d", power_level),
      properties = cjson.encode(properties),
      rarity = rarity,
    },
    traits = traits_list,
    power_level = power_level,
    properties = properties,
    rarity = rarity,
  }

  if skin_name then
    entry.mod_data.CustomData.skin = skin_name
    entry.mod_data.skin = skin_name
    entry.mod_data.inventory_icon = WeaponSkins.skins[skin_name].inventory_icon
  end

  moreitemslibrary:add_mod_items_to_local_backend({entry}, "enable-imgui")

  local backend_items = Managers.backend:get_interface("items")
  local new_item = backend_items:get_item_from_id(backend_id)

  if rarity then
    new_item.rarity = rarity
    new_item.data.rarity = rarity
    new_item.CustomData.rarity = rarity
  end

  ItemHelper.mark_backend_id_as_new(backend_id)

  if mod.inventory_ui then
    backend_items:_refresh()
    local inv_item_grid = mod.inventory_ui._item_grid
    local index = inv_item_grid._selected_page_index
    local settings = inv_item_grid._category_settings[index]
    local item_filter = settings.item_filter
    inv_item_grid:change_item_filter(item_filter, false)
    inv_item_grid:repopulate_current_inventory_page()
  end
end)

mod.inventory_ui = nil

mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(self)
  mod.inventory_ui = self
end)

mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(self)
  mod.inventory_ui = nil
end)

]]--
