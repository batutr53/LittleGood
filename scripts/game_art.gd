class_name GameArt
extends RefCounted

const ATLAS = preload("res://assets/phase2/world-atlas.png")
const FOLIAGE = preload("res://assets/phase2/foliage.gdshader")
static var foliage_material: ShaderMaterial
static var silver_material: ShaderMaterial

static func silver() -> ShaderMaterial:
	if silver_material == null:
		silver_material = ShaderMaterial.new()
		silver_material.shader = preload("res://assets/phase2/silver.gdshader")
	return silver_material

static func sprite(frame: int, size: float) -> Sprite2D:
	var s = Sprite2D.new()
	s.texture = ATLAS
	s.hframes = 4
	s.vframes = 4
	s.frame = frame
	s.offset = Vector2(0, -112)
	if frame == 13: s.offset.y = -86
	s.scale = Vector2.ONE * size / 232.0
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return s

static func foliage() -> ShaderMaterial:
	if foliage_material == null:
		foliage_material = ShaderMaterial.new()
		foliage_material.shader = FOLIAGE
	return foliage_material
