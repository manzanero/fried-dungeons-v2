shader_type spatial;

render_mode blend_add,depth_draw_opaque,cull_front,diffuse_burley,specular_disabled;

uniform sampler2D texture_albedo : source_color,filter_nearest_mipmap;


void fragment() {
	ALBEDO = 0.5 * texture(texture_albedo,UV).rgb;
	NORMAL = -NORMAL;
	BACKLIGHT = vec3(0.5);
}


//void light() {
	//DIFFUSE_LIGHT += ATTENUATION * LIGHT_COLOR;
//}