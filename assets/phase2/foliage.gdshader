shader_type canvas_item;
void vertex() {
	float local_height = clamp(-VERTEX.y / 232.0, 0.0, 1.0);
	VERTEX.x += sin(TIME * 1.05 + UV.x * 31.0) * local_height * local_height * 2.8;
}
