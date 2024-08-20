shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_front;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;


global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;
global uniform sampler2D wall_atlas : source_color,filter_nearest;


varying float alpha;


void fragment() {
	vec4 albedo_tex = texture(wall_atlas, UV);
	ALBEDO = 0.25 * albedo_tex.rgb;
	alpha = albedo_tex.a;
	ALPHA = min(0.1, alpha);
}


void light() {
	if (is_master_view) {
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
		ALPHA = alpha;
	} else if (LIGHT_IS_DIRECTIONAL) {

	} else {

		// if is in view for any viewer
		if (ATTENUATION * SPECULAR_AMOUNT > 0.001)
			SPECULAR_LIGHT.x = 0.001;
		else
			DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;  // add the light of the lighter

		// if is in light for any lighter
		if (has_ambient_light || DIFFUSE_LIGHT.x > 0.001)
			SPECULAR_LIGHT.y = 0.001;

		// if is in view and light
		if (SPECULAR_LIGHT.x != 0. && SPECULAR_LIGHT.y != 0.)
			ALPHA = alpha;
		else
			ALPHA = 0.;
	}
}