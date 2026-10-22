shader_type canvas_item;

// Recolor the original painted fox while preserving its shading and silhouette.
void fragment() {
	vec4 painted = texture(TEXTURE, UV) * COLOR;
	float light = dot(painted.rgb, vec3(0.299, 0.587, 0.114));
	vec3 silver = vec3(light * .88, light * 1.02, light * 1.14) + .08;
	COLOR = vec4(mix(painted.rgb, silver, .88), painted.a);
}
