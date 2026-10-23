extends Node2D
var vector=Vector2.ZERO
var radius=72.0
func _draw() -> void:
	draw_circle(Vector2.ZERO,radius,Color(.09,.22,.24,.78));draw_arc(Vector2.ZERO,radius,0,TAU,48,Color(.76,.85,.69,.65),2,true)
	draw_circle(vector*radius*.6,29,Color(.68,.82,.61,.85))
