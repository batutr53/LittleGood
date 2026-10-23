shader_type canvas_item;
varying vec2 water_pos;
uniform vec3 cosmetic_tint = vec3(1.0);
void vertex() { water_pos = VERTEX; }
void fragment() {
	float wave = sin(water_pos.x * .14 + water_pos.y * .24 - TIME * 1.1);
	float cross_wave = sin(water_pos.x * .28 - water_pos.y * .15 + TIME * .7);
	float glint = pow(max(0., wave * cross_wave), 8.);
	COLOR.rgb += vec3(.08, .15, .12) * glint;
	COLOR.rgb += vec3(.015, .035, .03) * wave;
	COLOR.rgb *= cosmetic_tint;
}
