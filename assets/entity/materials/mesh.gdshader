shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;

render_mode specular_disabled;
render_mode fog_disabled;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_nearest;

global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;


varying float alpha;


//void vertex() {
	//MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	//MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
//}


void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = 0.125 * albedo.rgb * albedo_tex.rgb;
	alpha = albedo_tex.a;
	ALPHA = min(0.1, alpha);
}


void light() {
	if (is_master_view) {
		DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;  // add the light of the lighter
		ALPHA = alpha;
	}
	else {
		
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
