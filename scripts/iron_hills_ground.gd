extends Node2D
# Offline-authored vector terrain is imported once; live actors and collision stay separate.
var terrain=preload("res://assets/adventure/iron-hills-ground.svg")
func _draw() -> void:
 draw_rect(Rect2(-1000,-1000,3000,3500),Color("293f4c"))
 draw_texture_rect(terrain,Rect2(0,0,960,1440),false)
