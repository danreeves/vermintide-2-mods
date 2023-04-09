local ShadingEnvironment = stingray.ShadingEnvironment
local BeastIf = stingray.BeastIf
local Quaternion = stingray.Quaternion

function export_shading_environment(beast_context, shading_environment, skydome_unit, skylight_intensity)
	--local sun_direction = ShadingEnvironment.vector3(shading_environment, "sun_direction")
	--local sun_color = ShadingEnvironment.vector3(shading_environment, "sun_color")
	--local transform = Quaternion.matrix4x4(Quaternion.look(sun_direction))
	--BeastIf.create_directional_light(beast_context, "sun", transform, sun_color)
	--BeastIf.set_light_intensity_scale(beast_context, "sun", 0.0, 1.0)
	BeastIf.create_skylight(beast_context, shading_environment, "skydome", skydome_unit, 256, 128, skylight_intensity)
end

function get_light_falloff()
	-- Light falloff is 1 / (1 + d^2)
	return 1, 0, 1
end

function lightmap_category()
	return "core/stingray_renderer/texture_categories/lightmap"
end
