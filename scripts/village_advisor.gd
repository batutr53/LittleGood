extends Node2D
# Existing elder Arin, anchored to the original settlement. No extra worker/NPC IDs.
var view
var phase=0.0
var status_clock=1.0
func _process(delta):
	var w=view.world;visible=w.has("kingdom") and not w.settlements.is_empty() and not view.get_parent().visiting
	if not visible:return
	phase+=delta;position=view.project(w.cells[int(w.settlements[0].cell)])+Vector2(105,38)
	status_clock+=delta
	if status_clock>=.35:
		status_clock=0;var K=load("res://scripts/kingdom.gd");var q=K.current(w)
		$QuestMark.text="?" if not q.is_empty() and K.complete(w,q) and K.level(w)>=int(q.level) else "!"
	$Art.position.y=-30+sin(phase*1.5)*1.2
func pick(screen: Vector2) -> bool:
	if not visible:return false
	var at=get_global_transform_with_canvas()*Vector2(0,-30)
	if screen.distance_to(at)>maxf(28,38*view.display_zoom):return false
	view.get_parent().ui.premium.route("journey");return true
