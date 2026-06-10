// NOTE: Shader automatically converted from Godot Engine 4.4.stable's StandardMaterial3D.

shader_type spatial;
//render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform vec3 uv1_scale = vec3(0.125, 2.0, 1.0);
uniform vec3 uv1_offset;

uniform float uv_shift_speed: hint_range(0.0, 2.0, 0.1) = 0.5;

void fragment() {
	vec2 base_uv = UV * uv1_scale.xy * 4.0 + uv1_offset.xy;
	base_uv.x -= TIME * uv_shift_speed * 10.0;
	
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo_tex.rgb;
}
