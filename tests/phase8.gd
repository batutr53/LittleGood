extends SceneTree
const C=preload("res://scripts/cosmetics.gd")
const S=preload("res://scripts/planet_showcase.gd")
var passed=0
var failed=0
func verify(ok: bool,text: String) -> void:
	if ok:passed+=1;print("PASS: ",text)
	else:failed+=1;push_error(text)
func _initialize() -> void:call_deferred("run")
func land(w: Dictionary) -> int:
	for i in range(w.cells.size()):
		if C.valid_place(w,"flowers",i):return i
	return -1
func run() -> void:
	var primary=FileAccess.get_file_as_bytes(Persistence.PATH)
	var w=WorldGen.generate(2026,"Atelier test")
	var cells=w.cells.duplicate(true);var species=w.creatures.duplicate(true)
	C.ensure(w)
	verify(C.items().size()==24,"24 defined cosmetics, no random paid rewards")
	verify(C.validate(w) and w.wardrobe.dust==35,"Fresh wardrobe has valid welcome balance")
	verify(C.owned(w,"flowers") and C.owned(w,"stones"),"Two starter decorations require no grind")
	verify(C.reconcile(w)==25,"Existing community earns one meaningful reward")
	verify(C.reconcile(w)==0,"Repeated reconciliation cannot duplicate reward")
	verify(not C.buy(w,"royal_pack"),"Future premium cannot be purchased with local currency")
	verify(not C.buy(w,"crystal"),"Species discovery gate applies")
	w.discoveries=[0,1]
	verify(C.reconcile(w)==40,"Two discovered species earn defined Stardust")
	verify(C.buy(w,"crystal") and w.wardrobe.dust==60,"Purchase subtracts exact price")
	var balance=w.wardrobe.dust
	verify(not C.buy(w,"crystal") and w.wardrobe.dust==balance,"Double purchase cannot spend twice")
	verify(C.equip(w,"crystal") and w.wardrobe.theme=="crystal","Theme equipment persists in model")
	verify(not C.equip(w,"celestial"),"Unowned themes cannot equip")
	verify(C.favorite(w,"crystal") and w.wardrobe.favorites.has("crystal"),"Cosmetic favorites toggle on")
	verify(C.favorite(w,"crystal") and not w.wardrobe.favorites.has("crystal"),"Cosmetic favorites toggle off")
	var spot=land(w)
	var id=C.place(w,"flowers",spot,2)
	verify(id>=1 and w.wardrobe.placements.size()==1,"Decoration places with orientation")
	verify(C.place(w,"stones",spot)==-1,"Overlapping placements rejected")
	verify(C.place(w,"flowers",-1)==-1 and C.place(w,"flowers",999)==-1,"Invalid cells rejected")
	verify(C.place(w,"flowers",int(w.settlements[0].cell))==-1,"Functional settlement protected from large environment props")
	var water=-1
	for i in range(w.cells.size()):
		if int(w.cells[i].biome)==6:water=i;break
	verify(C.place(w,"flowers",water)==-1,"Land flowers cannot go on water")
	verify(C.buy(w,"banner") and C.place(w,"banner",int(w.settlements[0].cell))>=1,"Village ornaments use existing community edge")
	var second=land(w)
	verify(C.place(w,"flowers",second,1,id)==id,"Decoration moves without duplicating instance")
	verify(C.remove(w,id) and C.owned(w,"flowers"),"Storing retains ownership")
	verify(C.buy(w,"mint") and C.equip(w,"mint",int(w.creatures[0].identity)),"Individual creature appearance selected")
	verify(C.coat(w,int(w.creatures[0].identity))=="mint","Coat targets actual creature identity")
	verify(C.validate(w),"Earn/spend ownership ledger stays consistent")
	var capped=WorldGen.generate(2026,"Bounded decoration");C.ensure(capped)
	for i in range(capped.cells.size()):
		if C.valid_place(capped,"flowers",i):C.place(capped,"flowers",i)
	verify(capped.wardrobe.placements.size()==32 and C.validate(capped),"Decoration count is bounded to 32 reusable instances")
	var spare=-1
	for i in range(capped.cells.size()):
		if int(capped.cells[i].biome)!=6 and not capped.settlements.any(func(s):return int(s.cell)==i) and not capped.wardrobe.placements.any(func(p):return int(p.cell)==i):spare=i;break
	verify(not C.valid_place(capped,"flowers",spare) and C.place(capped,"flowers",spare)==-1,"Full editor preview rejects adding a 33rd decoration")
	verify(C.place(capped,"flowers",spare,3,int(capped.wardrobe.placements[0].id))>=1 and capped.wardrobe.placements.size()==32,"Full planet can still move and rotate existing pieces")
	C.remove(capped,int(capped.wardrobe.placements[0].id))
	verify(C.place(capped,"flowers",land(capped))>=1 and C.validate(capped),"Storing a decoration frees capacity without changing ownership")
	verify(w.cells==cells and w.creatures==species,"Cosmetics never alter terrain or simulation creatures")
	var save="user://phase8-test.json"
	verify(Persistence.save_world(w,save),"Customized world saves atomically")
	var restored=Persistence.load_world(save)
	verify(not restored.is_empty() and restored.wardrobe==w.wardrobe,"Economy, equipment, positions and appearance restore")
	verify(C.reconcile(restored)==0,"Load cannot duplicate milestone claims")
	Persistence.save_world(w,save)
	var corrupt=FileAccess.open(save,FileAccess.WRITE);corrupt.store_string("interrupted");corrupt.close()
	verify(Persistence.load_world(save).get("wardrobe",{})==w.wardrobe and Persistence.last_recovery=="backup","Corrupted primary recovers currency/equipment from healthy backup")
	DirAccess.copy_absolute(save+".bak",save+".tmp")
	corrupt=FileAccess.open(save+".bak",FileAccess.WRITE);corrupt.store_string("corrupt");corrupt.close()
	verify(Persistence.load_world(save).get("wardrobe",{})==w.wardrobe and Persistence.last_recovery=="interrupted_write","Interrupted complete temporary save can recover cosmetics")
	var bad=w.duplicate(true);bad.wardrobe.dust=-1
	verify(not Persistence.validate(bad),"Negative currency rejected")
	bad=w.duplicate(true);bad.wardrobe.dust+=1
	verify(not Persistence.validate(bad),"Balance inconsistent with ledger rejected")
	bad=w.duplicate(true);bad.wardrobe.owned.append("crystal")
	verify(not Persistence.validate(bad),"Duplicate ownership rejected")
	bad=w.duplicate(true);bad.wardrobe.owned.append("royal_pack")
	verify(not Persistence.validate(bad),"Local premium ownership flag cannot become valid save")
	var public=S.project(w)
	verify(public.version==2 and S.validate(public),"Customized snapshot uses strict version two")
	verify(not JSON.stringify(public).contains("claimed") and not public.has("wardrobe"),"Showcase omits currency ledger and private favorites")
	var ro=S.world_from(public);var frozen=ro.duplicate(true)
	verify(ro.wardrobe.theme=="crystal" and ro.wardrobe.placements.size()==1,"Visitor sees actual equipped cosmetics")
	verify(not C.buy(ro,"willow") and not C.equip(ro,"enchanted") and C.place(ro,"flowers",spot)==-1 and C.reconcile(ro)==0 and ro==frozen,"Visit cannot earn, spend, equip or place")
	bad=public.duplicate(true);bad.appearance.theme="royal_pack"
	verify(not S.validate(bad),"Imported premium theme is not trusted")
	bad=public.duplicate(true);bad.appearance.placements[0].cell=999
	verify(not S.validate(bad),"Imported cosmetic placement index bounded")
	verify(S.read_file("res://docs/examples/Lumi.lgplanet").version==1,"Previous public v1 examples remain compatible")
	var legacy=Persistence.load_world("res://tests/fixtures/planet-v05.json")
	verify(not legacy.is_empty() and C.validate(legacy) and legacy.wardrobe.version==1,"Legacy actual v0.5 fixture migrates non-destructively")
	var legacy07=Persistence.load_world("res://tests/fixtures/planet-v07.json")
	verify(not legacy07.is_empty() and legacy07.name=="Legacy 0.7" and C.validate(legacy07),"Actual tagged v0.7 save migrates without losing its world")
	Persistence.offline(legacy07,legacy07.saved_at+86400)
	verify(C.validate(legacy07) and C.reconcile(legacy07)==0,"Offline rewards are reconciled once and remain valid")
	var provider=preload("res://scripts/purchase_provider.gd").new()
	verify(provider.purchase(provider.PRODUCT).state=="unavailable" and provider.restore().entitlements.is_empty(),"Real purchase/restore provider stays disabled")
	var mock=preload("res://tests/mock_purchase_provider.gd").new()
	for state in ["pending","cancelled","failed"]:
		mock.state=state;verify(mock.purchase(mock.PRODUCT).state==state and mock.restore().entitlements.is_empty(),"Mock "+state+" grants no entitlement")
	mock.state="completed";mock.purchase(mock.PRODUCT);mock.purchase(mock.PRODUCT)
	verify(mock.restore().entitlements.size()==1,"Test-only mock completion is idempotent")
	mock.state="revoked";mock.purchase(mock.PRODUCT)
	verify(mock.restore().entitlements.is_empty(),"Mock revocation removes test entitlement")
	var game=load("res://scenes/main.tscn").instantiate();game.is_test_session=true;game.save_path="user://phase8-ui.json";root.add_child(game)
	game.new_planet(42,"Editor QA",false);game.decorator.collection(true)
	verify(game.ui.page=="customization","Shop opens in actual scene")
	game.decorator.begin("flowers");game.decorator.cell=land(game.world);game.decorator.commit()
	verify(game.world.wardrobe.placements.size()==1,"Editor confirmation places actual object")
	game.decorator.history(false);verify(game.world.wardrobe.placements.is_empty(),"Editor undo restores prior layout")
	game.decorator.history(true);verify(game.world.wardrobe.placements.size()==1,"Editor redo restores object")
	game.navigate_back();verify(not game.decorator.active,"Back exits decoration mode")
	verify(FileAccess.get_file_as_bytes(Persistence.PATH)==primary,"All customization testing preserves player save")
	var output={"passed":passed,"failed":failed,"source":"automated_customization_tests"}
	var f=FileAccess.open("res://builds/phase8/tests.json",FileAccess.WRITE);f.store_string(JSON.stringify(output));f.close()
	print("PHASE8_RESULT: ",passed," passed, ",failed," failed")
	quit(1 if failed else 0)
