shader_type canvas_item;
render_mode blend_mix;

uniform vec2 mouse_position;
uniform float fade_distance = 0.5;

varying vec2 world_vertex;


void fragment() {
	if (COLOR.a == 0.0) {
		discard;
	}
	
	float d = distance(mouse_position + vec2(0.5), UV) - 0.16;
	//float alpha = 1.0 - pow(smoothstep(0.5, fade_distance, d), 0.5);
	//float alpha = 1.0 - 2.0 * d;
	if (d <= 0.0) {
		COLOR.a = 1.0;
	} else {
		float alpha = 1.0 - 2.0 * pow(d, 0.5);
		COLOR.a = alpha;
	}

}