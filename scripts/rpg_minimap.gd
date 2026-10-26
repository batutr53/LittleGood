extends Control
var game
var adventure=false
var elapsed=0.0
var signature=""
func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE;set_process(true)
func _process(delta):
	elapsed+=delta
	if elapsed<.15:return
	elapsed=0
	var next=str(game.world.get("seed",0))+":"+str(game.world.get("tick",0))+":"+str(game.world.get("cells",[]).size())
	if adventure:next+=str(game.world.get("kingdom",{}).get("adventure",{}).get("run",{}).get("clock",0))
	if next!=signature:signature=next;queue_redraw()
func _draw():
	draw_style_box(preload("res://scripts/premium_theme.gd").box(Color(.04,.055,.05,.9),true),Rect2(Vector2.ZERO,size))
	if game.world.is_empty():return
	if adventure:
		var scene=game.adventure_scene
		if not is_instance_valid(scene):return
		var r=game.world.kingdom.adventure.run;var extent=scene.region_map.SIZE
		for rect in scene.region_map.solids(game.world.kingdom.claimed.size()<14):draw_rect(Rect2(rect.position/extent*size,rect.size/extent*size),Color("5a6256"))
		draw_circle(Vector2(r.x,r.y)/extent*size,4,Color("f7dc8d"))
		for e in r.enemies:
			if e.hp>0:draw_circle(Vector2(e.x,e.y)/extent*size,2,Color("c46a55"))
	else:
		var bounds=Rect2(Vector2.ZERO,Vector2.ONE);var first=true
		for cell in game.world.cells:
			var point=Vector2(cell.x-cell.y,(cell.x+cell.y)*.5)
			if first:bounds=Rect2(point,Vector2.ONE);first=false
			else:bounds=bounds.expand(point)
		for cell in game.world.cells:
			var point=(Vector2(cell.x-cell.y,(cell.x+cell.y)*.5)-bounds.position)/bounds.size*(size-Vector2(8,8))+Vector2(4,4)
			draw_rect(Rect2(point,Vector2(2,2)),TerrainSurface.PALETTE[clampi(int(cell.biome),0,6)])
