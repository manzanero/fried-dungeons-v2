shader_type spatial;

render_mode blend_add;
render_mode cull_front;
render_mode specular_disabled;
render_mode fog_disabled;


global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;
global uniform sampler2D wall_atlas : source_color,filter_nearest;


varying float alpha;


void vertex() {
	VERTEX -= NORMAL * 0.001;
}


void fragment() {
	vec4 albedo_tex = texture(wall_atlas, UV);
	ALBEDO = 0.5 * albedo_tex.rgb;
	NORMAL = -NORMAL;
	
	if (int(FRAGCOORD.y) % 2 == 0) if (int(FRAGCOORD.x) % 2 == 0) discard;
	if ((int(FRAGCOORD.x) + 1) % 2 == 0) if ((int(FRAGCOORD.y) + 1) % 2 == 0) discard;
		
	alpha = albedo_tex.a;

	ALPHA = 0.;
}


void light() {
	if (is_master_view) {
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
		ALPHA = alpha;
	} else {
		
		// if is in view for any viewer
		if (ATTENUATION * SPECULAR_AMOUNT > 0.001)
			SPECULAR_LIGHT.x = 0.001;
		else
			DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR * 0.5;  // add the light of the lighter
		
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
