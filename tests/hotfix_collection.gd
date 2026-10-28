extends SceneTree
const K=preload("res://scripts/kingdom.gd")
const E=preload("res://scripts/estate.gd")
const I=preload("res://scripts/industry.gd")
var checks={}
func _initialize():call_deferred("run")
func tick(w,n):
	for i in range(n):w.tick+=1;K.tick(w)
func build(w,kind):
	for cell in range(w.cells.size()):
		if K.valid_site(w,kind,cell):return K.begin_build(w,kind,cell)
	return 0
func run():
	var w=Persistence.load_world("res://tests/fixtures/planet-v085e2.json");E.start(w)
	for b in w.kingdom.buildings:E.collect(w,int(b.id))
	var farm=w.kingdom.buildings.filter(func(b):return b.kind=="farm")[0];var lumber=w.kingdom.buildings.filter(func(b):return b.kind=="lumber")[0]
	var snapshot=w.duplicate(true);checks.no_ready=E.collect(w,int(farm.id)).is_empty() and w==snapshot;checks.no_ready_reason=E.collection_state(w,int(farm.id)).code in ["running","empty"]
	tick(w,60);var report=E.collection_state(w,int(farm.id));checks.production_real=report.code=="ready" and report.pending.get("food",0)>0
	snapshot=w.duplicate(true);E.collection_state(w,int(farm.id));checks.report_readonly=w==snapshot
	var food=K.home(w).food;var pending=int(report.pending.food);var event=int(w.kingdom.events.get("produce_food",0));var wood_before=w.estate.pending.get(str(int(lumber.id)),{}).duplicate();var received=E.collect(w,int(farm.id));var amount=int(received.get("food",0))
	checks.correct_destination=is_equal_approx(K.home(w).food,food+amount/1000.0);checks.conservation=amount+int(w.estate.pending.get(str(int(farm.id)),{}).get("food",0))==pending;checks.selected_building_only=w.estate.pending.get(str(int(lumber.id)),{})==wood_before
	checks.event_once=int(w.kingdom.events.get("produce_food",0))==event+amount
	snapshot=w.duplicate(true);checks.double_tap=E.collect(w,int(farm.id)).is_empty() and w==snapshot;checks.full_food_reason=E.collection_state(w,int(farm.id)).code=="full"
	# The legacy fixture already exceeds base storage; output must remain intact.
	snapshot=w.duplicate(true);checks.full_warehouse_keeps_output=not E.collection_state(w,int(lumber.id)).pending.is_empty() and E.collect(w,int(lumber.id)).is_empty() and w==snapshot
	checks.build_storage=build(w,"storage")>0;tick(w,20)
	# Fill expanded warehouse using real existing forest gathering, not injected balances.
	for cell in range(w.cells.size()):
		while w.cells[cell].biome==1 and w.cells[cell].resources>0 and w.kingdom.stock.wood<roundi(K.storage(w)*1000):
			tick(w,4)
			if K.gather(w,"wood",cell)<=0:break
		if w.kingdom.stock.wood>=roundi(K.storage(w)*1000):break
	checks.warehouse_filled_legally=w.kingdom.stock.wood==roundi(K.storage(w)*1000)
	snapshot=w.duplicate(true);checks.expanded_full_keeps_output=E.collect(w,int(lumber.id)).is_empty() and w==snapshot
	# A real building order spends wood and makes room; transfer can resume.
	checks.create_room_by_building=build(w,"farm")>0
	var forge=w.kingdom.buildings.filter(func(b):return b.kind=="forge")[0];var free=K.assigned(w,0)
	checks.smith=not free.is_empty() and K.assign(w,int(free[0].id),int(forge.id));checks.order=I.queue(w,"armory_refine_scroll",int(forge.id))
	var before=int(w.kingdom.stock.wood);var old_pending=int(w.estate.pending[str(int(lumber.id))].wood);received=E.collect(w,int(lumber.id))
	checks.partial_warehouse=received.get("wood",0)>0 and int(w.kingdom.stock.wood)==before+int(received.wood) and int(w.estate.pending[str(int(lumber.id))].wood)==old_pending-int(received.wood)
	tick(w,30);checks.item_ready=E.collection_state(w,int(forge.id)).items>0;var items=w.kingdom.industry.items.size();var queue=w.kingdom.industry.queue.size();received=E.collect(w,int(forge.id));checks.item_owner=received.get("crafted",0)>0 and w.kingdom.industry.items.size()==items+int(received.crafted) and w.kingdom.industry.queue.size()==queue-int(received.crafted)
	snapshot=w.duplicate(true);checks.item_double_tap=E.collect(w,int(forge.id)).is_empty() and w==snapshot
	snapshot=w.duplicate(true);checks.invalid_id=E.collect(w,999999).is_empty() and E.collection_state(w,999999).code=="unavailable" and w==snapshot
	var read_only=w.duplicate(true);read_only._read_only=true;snapshot=read_only.duplicate(true);checks.readonly=E.collect(read_only,int(farm.id)).is_empty() and read_only==snapshot
	checks.save=Persistence.save_world(w,"user://hotfix-collection-private.json");var restored=Persistence.load_world("user://hotfix-collection-private.json");checks.restore=not restored.is_empty() and restored.estate==w.estate and restored.kingdom.industry==w.kingdom.industry;checks.valid=Persistence.validate(w)
	DirAccess.make_dir_recursive_absolute("res://builds/hotfix");var result={"count":checks.size(),"all_passed":not checks.values().has(false),"checks":checks,"method":"Existing fixture and authoritative gather/queue/tick/collect commands; no demonstration balance/output injection"};var f=FileAccess.open("res://builds/hotfix/collection.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));print("HOTFIX_COLLECTION "+JSON.stringify(result));quit(0 if result.all_passed else 1)
