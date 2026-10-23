shader_type canvas_item;
varying vec2 ground_pos;
uniform vec3 cosmetic_tint = vec3(1.0);
void vertex() { ground_pos = VERTEX; }
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	float grain = hash(floor(ground_pos * 1.8));
	float meadow = sin(ground_pos.x * .13 + sin(ground_pos.y * .09)) * sin(ground_pos.y * .21);
	COLOR.rgb *= 0.965 + grain * .055 + meadow * .025;
	COLOR.rgb *= cosmetic_tint;
}
