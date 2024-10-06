shader_type spatial;

render_mode unshaded,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
//render_mode depth_test_disabled;

uniform sampler2D texture_albedo : source_color,filter_nearest,repeat_enable;
uniform vec3 mouse_position;

varying vec3 world_vertex;


void vertex() {
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float d = length(vec2(mouse_position.x - world_vertex.x, mouse_position.z - world_vertex.z));
	float alpha = 1.0 - pow(smoothstep(0.5, 2.5, d), 0.5);

	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo_tex.rgb;
	ALPHA *= alpha * albedo_tex.a * 0.75;
}
