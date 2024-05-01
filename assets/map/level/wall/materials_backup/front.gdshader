shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;


global uniform bool is_master_view = false;
uniform sampler2D texture_albedo : source_color,filter_nearest;


varying float alpha;


void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = 0.25 * albedo_tex.rgb;
	alpha = albedo_tex.a;
	if (is_master_view)
		ALPHA = alpha;
	else
		ALPHA = min(0.1, alpha);
}


void light() {
	if (is_master_view)
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
	else
		if (ATTENUATION * SPECULAR_AMOUNT > 0.001) 
			ALPHA = alpha;
		else
			DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
}