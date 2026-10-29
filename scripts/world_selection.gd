extends Control
const K=preload("res://scripts/kingdom.gd")
const T=preload("res://scripts/premium_theme.gd")
var game
var title: Label
var detail: Label
var command: Button
var timer=0.0
var selection={}
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE;var p=game.ui.premium
	var plate=Panel.new();plate.name="SelectionPlate";plate.mouse_filter=Control.MOUSE_FILTER_IGNORE;plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);plate.add_theme_stylebox_override("panel",T.skin());add_child(plate)
	title=p.text("",23,T.CREAM);title.name="SelectionTitle";title.clip_text=true;title.autowrap_mode=TextServer.AUTOWRAP_OFF;add_child(title);title.position=Vector2(10,5)*p.scale_ui();title.size=Vector2(235,24)*p.scale_ui()
	detail=p.text("",19,T.MUTED);detail.clip_text=true;detail.autowrap_mode=TextServer.AUTOWRAP_OFF;add_child(detail);detail.position=Vector2(10,33)*p.scale_ui();detail.size=Vector2(235,22)*p.scale_ui()
	command=game.ui.button("",activate);command.name="SelectionAction";p.rpg.compact_button(command);add_child(command);command.position=Vector2(250,8)*p.scale_ui();command.size=Vector2(66,48)*p.scale_ui()
	var close=game.ui.button("×",clear);close.name="ClearWorldSelection";p.rpg.compact_button(close);add_child(close);close.position=Vector2(320,8)*p.scale_ui();close.size=Vector2(32,48)*p.scale_ui();close.custom_minimum_size.x=0
	refresh()
func say(en,tr):return tr if game.ui.language=="tr" else en
func resolve() -> Dictionary:
	var w=game.world;var view=game.view
	if w.is_empty():return {}
	if view.selected_worker_id>=0:
		var workers=w.get("kingdom",{}).get("workers",[]).filter(func(worker):return int(worker.id)==view.selected_worker_id)
		if workers.is_empty():view.selected_worker_id=-1;return {}
		return {"kind":"worker","id":view.selected_worker_id,"title":workers[0].name,"detail":game.ui.premium.colony_ui().job_name(workers[0]),"action":say("Manage","Yönet")}
	if view.selected_creature>=0 and view.selected_creature<w.creatures.size():
		var c=w.creatures[view.selected_creature];return {"kind":"creature","id":int(view.selected_creature),"title":c.given_name,"detail":game.ui.species(int(c.species))+" · "+game.ui.t(c.trait),"action":say("Inspect","İncele")}
	if view.selected<0 or view.selected>=w.cells.size():return {}
	for b in w.get("kingdom",{}).get("buildings",[]):
		if int(b.cell)==view.selected:return {"kind":"building","id":int(b.id),"title":game.realm_ui.localized(K.buildings()[b.kind].name),"detail":say("Level ","Seviye ")+str(int(b.level))+" · "+(say("Ready","Hazır") if K.ready(b) else str(int(100.0*b.progress/maxf(1,b.required)))+"%"),"action":say("Manage","Yönet")}
	for home in w.settlements:
		if int(home.cell)==view.selected:return {"kind":"settlement","id":int(home.cell),"title":home.given_name,"detail":str(int(home.population))+say(" residents"," sakin"),"action":say("Meet","Tanış")}
	var c=w.cells[view.selected]
	return {"kind":"terrain","id":view.selected,"title":Biomes.title(int(c.biome),game.ui.language),"detail":say("SELECTED LAND · ","SEÇİLİ ARAZİ · ")+str(int(c.x))+", "+str(int(c.y)),"action":say("Inspect","İncele")}
func clear():
	game.view.select_cell(-1);refresh()
func activate():
	selection=resolve()
	if selection.is_empty():return
	match selection.kind:
		"worker":game.ui.premium.route("worker",int(selection.id))
		"building":game.realm_ui.inspect_building(int(selection.id))
		"creature":game.ui.show_creature(game.world.creatures[int(selection.id)])
		"settlement":
			for home in game.world.settlements:
				if int(home.cell)==int(selection.id):game.ui.inspect_settlement(home);game.ui.premium.route("settlement",int(home.cell))
		"terrain":game.ui.premium.route("terrain",int(selection.id))
func refresh():
	selection=resolve();visible=not selection.is_empty() and not game.in_menu and game.power<0 and not game.realm_ui.active and not game.decorator.active
	if selection.is_empty():return
	title.text="◆ "+selection.title;detail.text=selection.detail;command.text=selection.action
	command.disabled=game.visiting and selection.kind in ["building","terrain"]
func _process(delta):
	timer+=delta
	if timer<.1:return
	timer=0;refresh()
