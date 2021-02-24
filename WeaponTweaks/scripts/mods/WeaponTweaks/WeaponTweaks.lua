-- luacheck: globals get_mod Weapons
local mod = get_mod("WeaponTweaks")

-- Remove hold left click to chain puff
-- This causes you to puff if you get hit out of a charged attack
-- which is very inconvenient. This is not actually a useful ability so removing
-- it is fine to fix this little annoyance.
--
-- Mostly an issue on IB with the under pressure talent because
-- it makes the puff animation take much longer to end.
Weapons.drakegun_template_1.actions.action_one.default.hold_input = nil
Weapons.drakegun_template_1.actions.action_one.default.minimum_hold_time = nil
Weapons.drakegun_template_1.actions.action_one.default.allowed_chain_actions[2].release_required = nil

-- Same as Drakegun
Weapons.staff_flamethrower_template.actions.action_one.default.hold_input = nil
Weapons.staff_flamethrower_template.actions.action_one.default.minimum_hold_time = nil
Weapons.staff_flamethrower_template.actions.action_one.default.allowed_chain_actions[2].release_required = nil
