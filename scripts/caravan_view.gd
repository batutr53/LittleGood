extends Control
const T=preload("res://scripts/trade.gd")
var game
var caravan_id=0
var clock=0.0
var fraction=0.0
var wagon=preload("res://assets/kingdom/wagon.svg")
func _ready() -> void:custom_minimum_size=Vector2(0,280);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	clock+=delta;var c=T.caravan(game.world,caravan_id)
	if c.is_empty():return
	var target=float(c.progress)/c.leg_ticks if c.state in ["outbound","blocked"] else 1-float(c.progress)/c.leg_ticks if c.state=="returning" else 0.0
	fraction=lerpf(fraction,target,minf(1,delta*5));queue_redraw()
func say(en: String,tr: String) -> String:return game.realm_ui.say(en,tr)
func _draw() -> void:
	var c=T.caravan(game.world,caravan_id)
	if c.is_empty():return
	var width=size.x;var start=Vector2(55,148);var finish=Vector2(width-55,86);var path=finish-start
	draw_rect(Rect2(0,0,width,280),Color("284c50"))
	draw_colored_polygon(PackedVector2Array([Vector2(width*.4,140),Vector2(width*.6,20),Vector2(width*.78,112),Vector2(width*.9,40),Vector2(width,143)]),Color("51766c"))
	draw_polyline(PackedVector2Array([Vector2(0,45),Vector2(width*.2,78),Vector2(width*.3,20)]),Color("6a9694"),12,true)
	draw_line(start,finish,Color("739080"),20,true)
	for i in range(17):draw_circle(start+path*i/16.0,3,Color("d0c391"))
	for p in [start,finish]:draw_circle(p,16,Color("d1b578"));draw_circle(p,8,Color("395957"))
	var point=start+path*fraction;var moving=c.state in ["outbound","returning"]
	draw_texture_rect(wagon,Rect2(point+Vector2(-60,-67+(sin(clock*7)*2 if moving else 0)),Vector2(120,80)),false)
	if moving:
		for i in range(2):
			var wheel=point+Vector2(-30+i*43,0);draw_line(wheel+Vector2.from_angle(clock*5)*7,wheel-Vector2.from_angle(clock*5)*7,Color("e2ce99"),2,true)
	var font=game.ui.ui_font();var status={"outbound":say("Outbound","Gidiyor"),"blocked":say("Road hazard · awaiting your decision","Yol tehlikesi · kararını bekliyor"),"returning":say("Returning","Dönüyor"),"ready":say("Home · ready to collect","Evde · teslim alınabilir"),"collected":say("Delivery recorded","Teslimat kaydedildi")}
	draw_string(font,Vector2(16,25),T.routes()[c.route].name[1 if game.ui.language=="tr" else 0],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("eddaa4"))
	draw_string(font,Vector2(18,195),status[c.state]+" · "+str(int(c.progress))+" / "+str(int(c.leg_ticks)),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e4e5c9"))
	draw_string(font,Vector2(18,225),say("Reserved supplies ","Ayrılan erzak ")+str(snappedf(c.supplies/1000.0,.1))+say(" food · escorts "," besin · muhafız ")+str(c.guards.size()),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("b9cdbb"))
	draw_string(font,Vector2(18,255),say("Strategic route · home simulation advances","Stratejik yol · ev simülasyonu ilerler"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("a6c2b8"))
