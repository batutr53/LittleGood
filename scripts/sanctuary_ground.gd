extends Node2D
var terrain=preload("res://assets/adventure/sanctuary-ground.svg")
func _draw() -> void:
	draw_rect(Rect2(-1000,-1000,3000,3500),Color("17283d"))
	draw_texture_rect(terrain,Rect2(0,0,960,1440),false)
