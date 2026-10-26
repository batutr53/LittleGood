extends Node2D
var view
var roads: Array=[]
var signature=""
func sync(w: Dictionary):
	var next=str(w.seed)+str(w.has("estate"))
	for building in w.get("kingdom",{}).get("buildings",[]):next+=":"+str(building.id)+":"+str(building.cell)
	if next==signature:return
	signature=next;roads.clear()
	if not w.has("estate") or not w.has("kingdom"):queue_redraw();return
	var points=[]
	for home in w.settlements:points.append(view.project(w.cells[int(home.cell)])+Vector2(0,12))
	for b in w.kingdom.buildings:
		var point=view.project(w.cells[int(b.cell)])+Vector2(0,12);var nearest=Vector2.ZERO;var distance=INF
		for other in points:
			if point.distance_to(other)<distance:nearest=other;distance=point.distance_to(other)
		if distance<600:
			var line=PackedVector2Array();var midpoint=(point+nearest)*.5+Vector2(15,10)
			for i in range(13):
				var t=i/12.0;line.append((1-t)*(1-t)*nearest+2*(1-t)*t*midpoint+t*t*point)
			roads.append(line)
		points.append(point)
	queue_redraw()
func _draw():
	for road in roads:
		draw_polyline(road,Color("7b7860"),18,true);draw_polyline(road,Color("bcb591"),13,true);draw_polyline(road,Color("cfcaab"),3,true)
