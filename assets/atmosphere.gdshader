shader_type canvas_item;
uniform float night : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 p = UV - vec2(0.5, 0.48);
	float halo = exp(-dot(p * vec2(1.0, 1.6), p * vec2(1.0, 1.6)) * 8.0);
	vec3 dark = mix(vec3(0.035, 0.09, 0.13), vec3(0.035, 0.06, 0.12), night);
	vec3 glow = vec3(0.04, 0.12, 0.10) * halo;
	float ribbon = sin(UV.x * 7.0 + TIME * 0.08) * 0.04;
	glow += vec3(0.015, 0.025, 0.02) * exp(-abs(UV.y - 0.43 - ribbon) * 8.0);
	COLOR = vec4(dark + glow, 1.0);
}
