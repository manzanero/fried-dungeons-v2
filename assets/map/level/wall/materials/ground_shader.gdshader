shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;
render_mode unshaded;

uniform vec4 albedo: source_color;
uniform sampler2D light_texture: source_color,filter_nearest;
uniform sampler2D texture_albedo: source_color,filter_nearest;


void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	vec4 light_tex = texture(light_texture, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb * light_tex.rgb;
	ALPHA = albedo_tex.a * light_tex.a;
}