extends TextureRect
# Inventory breathing only. Directional combat animation is a separate production task.
var ui
var clock=0.0
func _process(delta):
	if ui!=null and ui.reduce_motion:scale=Vector2.ONE;return
	clock+=delta;pivot_offset=Vector2(size.x*.5,size.y)
	scale=Vector2(1+sin(clock*.9)*.002,1+sin(clock*.9)*.004)
