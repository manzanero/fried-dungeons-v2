shader_type spatial;

render_mode blend_add;
render_mode depth_prepass_alpha;
render_mode cull_back;
render_mode specular_disabled;
render_mode diffuse_burley;
//depth_draw_always,cull_back,diffuse_burley,specular_disabled;


void light() {
    //DIFFUSE_LIGHT = vec3(0);
	if (pow(length(LIGHT_COLOR / PI), 2) > 2.99) {
		DIFFUSE_LIGHT += ATTENUATION;
	}
}
