shader_type spatial;


render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;


global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;

uniform vec4 albedo : source_color;


void fragment() {
	ALBEDO = albedo.rgb;
}


void light() {
	if (is_master_view) {
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
	} else {
		// if is in view for any viewer
		if (ATTENUATION * SPECULAR_AMOUNT > 0.01)
			SPECULAR_LIGHT.x = 0.0001;
		else
			DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;  // add the light of the lighter

		// if is in light for any lighter
		if (has_ambient_light || DIFFUSE_LIGHT.x > 0.0001 || DIFFUSE_LIGHT.y > 0.0001 || DIFFUSE_LIGHT.z > 0.0001)
			SPECULAR_LIGHT.y = 0.0001;

		// if is in view and light
		//if (SPECULAR_LIGHT.y > 0.)
		if (SPECULAR_LIGHT.x > 0. && SPECULAR_LIGHT.y > 0.)
			ALPHA = 1.;
		else
			ALPHA = 0.;
	}
}
