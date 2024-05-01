shader_type spatial;

render_mode blend_add;
render_mode depth_draw_always;
render_mode cull_back;
render_mode diffuse_burley;
render_mode specular_disabled;
render_mode depth_prepass_alpha;
//render_mode alpha_to_coverage;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap;
uniform float alpha_scissor_threshold;

      
void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}


//void light() {
	//DIFFUSE_LIGHT = ATTENUATION * LIGHT_COLOR;
//}
