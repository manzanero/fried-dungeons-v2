shader_type spatial;

render_mode specular_disabled;
render_mode fog_disabled;
render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_front;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;


global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;
global uniform sampler2D wall_atlas : source_color,filter_nearest;
global uniform bool is_darkvision_view = false;


varying float alpha;


void vertex() {
	VERTEX -= NORMAL * 0.001;
}


void fragment() {
	vec4 albedo_tex = texture(wall_atlas, UV);
	ALBEDO = 0.25 + 0.25 * albedo_tex.rgb;
	NORMAL = -NORMAL;

	//if (int(FRAGCOORD.y) % 2 == 0) if (int(FRAGCOORD.x) % 2 == 0) discard;
	//if ((int(FRAGCOORD.x) + 1) % 2 == 0) if ((int(FRAGCOORD.y) + 1) % 2 == 0) discard;
	if (int(FRAGCOORD.y + FRAGCOORD.x) % 2 == 0) discard;

	alpha = albedo_tex.a;

	ALPHA = 0.;

	if (is_darkvision_view) {
		vec3 color = ALBEDO.rgb;
		float brightness = pow((color.r * color.g * color.b), 0.33);
		ALBEDO = vec3(brightness, brightness, brightness);
	}
}


void light() {

	// if fragment is seen
	if (is_master_view || SPECULAR_LIGHT.z == 0.0001) {
		ALPHA = alpha;
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;

	} else {

		// if is in view for any viewer
		if (ATTENUATION * SPECULAR_AMOUNT > 0.01)
			SPECULAR_LIGHT.y = 0.0001;                   // fragment is seen
		else
			DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;

		// if is in light for any lighter
		 if (has_ambient_light || DIFFUSE_LIGHT.x > 0.0001 || DIFFUSE_LIGHT.y > 0.0001 || DIFFUSE_LIGHT.z > 0.0001)
			SPECULAR_LIGHT.x = 0.0001;

		// if is in view and light
		if (SPECULAR_LIGHT.x == 0.0001 && SPECULAR_LIGHT.y == 0.0001) {
			SPECULAR_LIGHT.z = 0.0001;
			ALPHA = alpha;
		} else
			ALPHA = 0.;
	}
}
