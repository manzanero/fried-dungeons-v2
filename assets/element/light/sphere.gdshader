shader_type spatial;
render_mode unshaded;

uniform vec3 base_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 inside_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float threshold_min = 0.8;
uniform float threshold_max = 1.0;
uniform bool use_dither = false;

void fragment() {
    vec3 N = normalize(NORMAL);
    vec3 V = normalize(VIEW);
    float intensity = clamp(dot(N, V), 0.0, 1.0);
    float smoothValue = smoothstep(threshold_min, threshold_max, intensity);
    
    float finalFactor = smoothValue;
    if (use_dither) {
		if (int(FRAGCOORD.y + FRAGCOORD.x) % 2 == 0) discard;

        //vec2 pixel_coords = SCREEN_UV / SCREEN_PIXEL_SIZE;
        //float parity = mod(floor(pixel_coords.x) + floor(pixel_coords.y), 2.0);
        //finalFactor = (parity < 0.5) ? smoothValue : 0.0;
    }
    
    ALBEDO = mix(base_color, inside_color, finalFactor);
}