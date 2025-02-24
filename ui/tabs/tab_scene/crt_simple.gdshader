shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;

uniform vec2 resolution = vec2(320.0, 180.0);

uniform float grille_amount :hint_range(0.0, 1.0) = 0.1;
uniform float grille_size :hint_range(1.0, 5.0) = 1.0;
uniform float vignette_amount :hint_range(0.0, 2.0) = 0.6;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float roll_line_amount :hint_range(0.0, 1.0) = 0.3;
uniform float roll_speed :hint_range(-8.0, 8.0) = 1.0;

vec3 fetch_pixel(vec2 uv, vec2 off){
	vec2 pos = floor(uv * resolution + off) / resolution + vec2(0.5) / resolution;

	if(max(abs(pos.x - 0.5), abs(pos.y - 0.5)) > 0.5){
		return vec3(0.0, 0.0, 0.0);
	}

	vec3 clr = texture(SCREEN_TEXTURE , pos, -16.0).rgb;
	return clr;
}

// Allow nearest three lines to effect pixel.
vec3 Tri(vec2 pos){
	vec3 clr = fetch_pixel(pos, vec2(0.0));
	return clr;
}

float vignette(vec2 uv){
	uv *= 1.0 - uv.xy;
	float vignette = uv.x * uv.y * 15.0;
	return pow(vignette, vignette_intensity * vignette_amount);
}

vec3 grille(vec2 uv){
	float unit = PI / 3.0;
	float scale = 2.0*unit/grille_size;
	float r = smoothstep(0.5, 0.8, cos(uv.x*scale - unit));
	float g = smoothstep(0.5, 0.8, cos(uv.x*scale + unit));
	float b = smoothstep(0.5, 0.8, cos(uv.x*scale + 3.0*unit));
	return mix(vec3(1.0), vec3(r,g,b), grille_amount);
}

float roll_line(vec2 uv){
	float x = uv.y * 3.0 - TIME * roll_speed;
	float f = cos(x) * cos(x * 2.35 + 1.1) * cos(x * 4.45 + 2.3);
	float roll_line = smoothstep(0.5, 0.9, f);
	return roll_line * roll_line_amount;
}

void fragment(){
	vec2 pix = FRAGCOORD.xy;

	float line = 0.0;
	if(roll_line_amount > 0.0){
		line = roll_line(SCREEN_UV);
	}

	vec3 clr = Tri(SCREEN_UV);
	if(grille_amount > 0.0)clr *= grille(pix);
	clr *= 1.0 + line * 3.0 + grille_amount * 2.0;
	if(vignette_amount > 0.0)clr *= vignette(SCREEN_UV);

	COLOR.rgb = clr;
	COLOR.a = 1.0;
}