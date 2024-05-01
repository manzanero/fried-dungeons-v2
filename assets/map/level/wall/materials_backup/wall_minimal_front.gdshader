shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back,diffuse_burley,specular_disabled;
render_mode alpha_to_coverage;

uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap;
uniform float alpha_scissor_threshold;

const vec3 grey_25 = vec3(0.25);
      

void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = grey_25 * albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}


void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
}
