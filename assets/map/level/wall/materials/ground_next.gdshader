shader_type spatial;


render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;

global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;
global uniform bool is_darkvision_view = false;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest_mipmap;

varying float alpha;


void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	alpha = albedo_tex.a;
	ALPHA = min(0.1, alpha);
	
	if (is_darkvision_view) {
		vec3 color = ALBEDO.rgb;
		float brightness = pow((color.r * color.g * color.b), 0.33);
		ALBEDO = vec3(brightness, brightness, brightness);
	}
}


void light() {
	DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
	
	// if fragment is seen
	if (is_master_view || SPECULAR_LIGHT.z > 0.) {
		ALPHA = alpha;
		
	} else {
		
		// if is in view for any viewer
		if (ATTENUATION * SPECULAR_AMOUNT > 0.01)
			SPECULAR_LIGHT.y = 0.0001;                   // fragment is seen
			
		// if is in light for any lighter
		 if (has_ambient_light || DIFFUSE_LIGHT.x > 0.0001 || DIFFUSE_LIGHT.y > 0.0001 || DIFFUSE_LIGHT.z > 0.0001)
			SPECULAR_LIGHT.x = 0.0001;  

		// if is in view and light
		if (SPECULAR_LIGHT.x > 0. && SPECULAR_LIGHT.y > 0.) {
			SPECULAR_LIGHT.z = 0.0001;
			ALPHA = alpha;
		} else
			ALPHA = 0.;
	}
}
