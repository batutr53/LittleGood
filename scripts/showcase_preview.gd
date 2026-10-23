extends Control
# Tiny map of the actual published terrain; no downloaded images or resource paths.
var tiles: Array=[]
func _init(data: Array = []) -> void:
	tiles=data
	custom_minimum_size=Vector2(0,160)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	var center=Vector2(size.x*.5,78)
	draw_circle(center+Vector2(0,10),72,Color(.08,.15,.19,.65))
	var bounds=Rect2()
	var first=true
	for tile in tiles:
		if not tile is Array or tile.size()!=3:continue
		var p=Vector2((float(tile[0])-float(tile[1]))*4.1,(float(tile[0])+float(tile[1]))*2.05)
		if first:bounds=Rect2(p,Vector2.ZERO);first=false
		else:bounds=bounds.expand(p)
	var offset=bounds.get_center()
	for tile in tiles:
		if not tile is Array or tile.size()!=3:continue
		var b=int(tile[2])
		if b<0 or b>=Biomes.COLORS.size():continue
		var point=center+Vector2((float(tile[0])-float(tile[1]))*4.1,(float(tile[0])+float(tile[1]))*2.05)-offset
		var diamond=PackedVector2Array([point+Vector2(0,-2.2),point+Vector2(4.3,0),point+Vector2(0,2.2),point+Vector2(-4.3,0)])
		draw_colored_polygon(diamond,Biomes.COLORS[b])
	draw_arc(center,76,0,TAU,64,Color(.7,.84,.74,.25),1.0,true)
