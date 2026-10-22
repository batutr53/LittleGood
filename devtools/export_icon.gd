extends SceneTree

func _initialize() -> void:
	var texture = load("res://assets/icon.svg") as Texture2D
	texture.get_image().save_png("res://assets/phase2/splash-icon.png")
	quit()
