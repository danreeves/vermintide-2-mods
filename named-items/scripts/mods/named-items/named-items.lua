local mod = get_mod("named-items")
local SimpleUI = get_mod("SimpleUI")

mod.SETTING_ID = "item_names"
local ITEM_NAME = ""
local ITEM_DESC = ""

mod:hook_safe(HeroWindowLoadoutInventory, "on_enter", function(hero_window_inventory)
  mod.item_grid = hero_window_inventory._item_grid
end)

mod:hook_safe(HeroWindowLoadoutInventory, "on_exit", function(hero_window_inventory)
  mod.item_grid = nil
  if mod.modal then
    mod.modal:destroy()
    mod.modal = nil
  end
end)

function mod.save_item_info(backend_id, name, description)
  local info_table = mod:get(mod.SETTING_ID) or {}
  info_table[backend_id] = { name = name, description = description }
  mod:set(mod.SETTING_ID, info_table)
end

function mod.get_item_info(backend_id)
  local info_table = mod:get(mod.SETTING_ID) or {}
  return info_table[backend_id]
end

local function open_info_modal(backend_id)
  if not SimpleUI then
    mod:echo("The Simple UI mod is required")
    return
  end


  local current_data = mod.get_item_info(backend_id) or { name = "", description = ""}
  ITEM_NAME = current_data.name
  ITEM_DESC = current_data.description

  local width = 300
  local height = 220
  local x = (1920 / 2) - (width / 2)
  local y = (1080 / 2) - (height / 2)
  local window = SimpleUI:create_window("named_item_info_modal", {x, y}, {width, height})

  window:create_title("modal_title", "Add name and description", 45)

  local row_height = 35
  local row_margin = 5
  local row_width = width - (row_margin * 2)
  local row_y = height - 55

  local size = { row_width, row_height }

  local function get_row_pos()
    row_y = row_y - (row_height + row_margin)
    return { row_margin, row_y }
  end

  window:create_label("name_label", { row_margin, row_y }, size, nil, "Name")
  local name_input = window:create_textbox("name_input", get_row_pos(), size, nil)
  name_input.text = current_data.name

  window:create_label("desc_label", get_row_pos(), size, nil, "Description")
  local desc_input = window:create_textbox("desc_input", get_row_pos(), size, nil)
  desc_input.text = current_data.description

  local button_row = get_row_pos()
  local close_button = window:create_button("close_button", button_row, {(row_width / 2) - (row_margin/2), row_height}, "bottom_left", "Cancel")
  local save_button = window:create_button("save_button", button_row, {(row_width / 2) - (row_margin/2), row_height}, "bottom_right", "Save")

  name_input.on_text_changed = function(self)
    ITEM_NAME = self.text
  end

  desc_input.on_text_changed = function(self)
    ITEM_DESC = self.text
  end

  close_button.on_click = function()
    ITEM_NAME = ""
    ITEM_DESC = ""
    window:destroy()
  end

  save_button.on_click = function ()
    mod.save_item_info(backend_id, ITEM_NAME, ITEM_DESC)
    ITEM_NAME = ""
    ITEM_DESC = ""
    window:destroy()
  end

  mod.modal = window
  window:init()
end

function mod.on_select_item()
  if not mod.item_grid then
    return
  end

  -- We're in the inventory view
  local item_grid = mod.item_grid
  local item = item_grid:get_item_hovered()
  if not item then
    return
  end

  -- An item is hovered
  open_info_modal(item.backend_id)
end

mod:hook(_G, "Localize", function(func, id, ...)
  -- Item grid not open, return early
  if not mod.item_grid then
    return func(id, ...)
  end

  -- Not hovering an item, return early
  local item_grid = mod.item_grid
  local item = item_grid:get_item_hovered()
  if not item then
    return func(id, ...)
  end

  -- Hovered item is not the localization this pass wants, return early
  local _, display_name, description = UIUtils.get_ui_information_from_item(item)
  if description ~= id and display_name ~= id then
    return func(id, ...)
  end

  -- If we don't have data for the hovered item, return early
  local data = mod.get_item_info(item.backend_id)
  if not data then
    return func(id, ...)
  end

  if id == display_name then
    return data.name ~= "" and data.name or func(id, ...)
  end

  if id == description then
    return data.description ~= "" and data.description or func(id, ...)
  end

  return func(id, ...)
end)
