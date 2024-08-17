shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;

render_mode specular_disabled;
render_mode fog_disabled;

uniform vec4 albedo : source_color;

global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;


varying float alpha;


void fragment() {
	ALBEDO = 0.125 * albedo.rgb;
	alpha = albedo.a;
	ALPHA = 0.;
}


void light() {
	if (is_master_view) {
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;  // add the light of the lighter
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
		if (SPECULAR_LIGHT.x > 0. && SPECULAR_LIGHT.y > 0.)
			ALPHA = alpha;
		else
			ALPHA = 0.;
	}
}
