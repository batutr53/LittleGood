extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	get_parent().get_node("LivingWorld").draw_foreground(self)
