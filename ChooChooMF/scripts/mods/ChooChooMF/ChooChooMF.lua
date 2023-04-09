local mod = get_mod("ChooChooMF")

local unit_path = "units/Thomas/Thomas"

mod:hook(PackageManager, "load", function(func, self, package_name, reference_name, callback, asynchronous, prioritize)
	if package_name ~= unit_path and package_name ~= unit_path .. "_3p" then
		func(self, package_name, reference_name, callback, asynchronous, prioritize)
	end
end)

mod:hook(PackageManager, "unload", function(func, self, package_name, reference_name)
	if package_name ~= unit_path and package_name ~= unit_path .. "_3p" then
		func(self, package_name, reference_name)
	end
end)

mod:hook(PackageManager, "has_loaded", function(func, self, package, reference_name)
	if package == unit_path or package == unit_path .. "_3p" then
		return true
	end
	return func(self, package, reference_name)
end)

for k, v in pairs(WeaponSkins.skins) do
	if
		string.starts_with(k, "es_2h_hammer")
		or string.starts_with(k, "dw_1h_hammer")
		or string.starts_with(k, "dw_2h_hammer")
		or string.starts_with(k, "we_2h_axe")
		or string.starts_with(k, "dw_2h_pick")
	then
		v["right_hand_unit"] = unit_path
	end
	if string.starts_with(k, "dr_dual_wield_hammers") then
		v["left_hand_unit"] = unit_path
		v["right_hand_unit"] = unit_path
	end
end

local nwlid = #NetworkLookup.inventory_packages + 1
NetworkLookup.inventory_packages[nwlid] = unit_path
NetworkLookup.inventory_packages[unit_path] = nwlid

nwlid = #NetworkLookup.inventory_packages + 1
NetworkLookup.inventory_packages[nwlid] = unit_path .. "_3p"
NetworkLookup.inventory_packages[unit_path .. "_3p"] = nwlid
