shader_type spatial;

render_mode blend_mix;
render_mode depth_draw_always;
render_mode cull_back;
render_mode alpha_to_coverage;
render_mode depth_prepass_alpha;
render_mode unshaded;


global uniform bool is_master_view = false;
global uniform bool has_ambient_light = false;
global uniform sampler2D light_texture: source_color,filter_nearest;
global uniform sampler2D wall_atlas : source_color,filter_nearest;


//varying vec4 light_color;


//void vertex() {
    //vec4 world_position = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
    //light_color = texture(light_texture, world_position.xz);
//}


void fragment() {
	vec4 albedo_tex = texture(wall_atlas, UV);
	vec4 light_color = texture(light_texture, UV2);

    vec4 world_position = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
    //vec4 light_color = texture(light_texture, world_position.xz * 16.);

	ALBEDO = 0.25 * albedo_tex.rgb * light_color.rgb;
	//ALPHA = albedo_tex.a * light_color.a;
	ALPHA = albedo_tex.a;
}