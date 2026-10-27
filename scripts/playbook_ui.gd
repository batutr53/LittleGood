extends RefCounted
# Navigation and work explanations use existing simulation commands only.
const K=preload("res://scripts/kingdom.gd")
const M=preload("res://scripts/military.gd")
const H=preload("res://scripts/hero.gd")
const T=preload("res://scripts/trade.gd")
var p
var game
var ui
func _init(presentation):p=presentation;game=p.game;ui=p.ui
func say(en,tr):return p.say(en,tr)
func label(v,value,color=Color("ddcda6")):
 v.add_child(p.text(value,22,color))
func button(v,title,cb,primary=false):
 var b=p.action(v,title,cb,primary);p.rpg.compact_button(b);b.custom_minimum_size.y=p.px(48);b.add_theme_font_size_override("font_size",int(p.px(14)));return b
func page(v,key,count,limit=4) -> int:
 var pages=maxi(1,ceili(count/float(limit)));var n=clampi(int(p.playbook_pages.get(key,0)),0,pages-1);p.playbook_pages[key]=n
 if pages==1:return 0
 var row=HBoxContainer.new();v.add_child(row)
 button(row,"‹",func():p.playbook_pages[key]=maxi(0,n-1);p.route(p.current,p.argument,false)).disabled=n==0
 label(row,str(n+1)+" / "+str(pages))
 button(row,"›",func():p.playbook_pages[key]=mini(pages-1,n+1);p.route(p.current,p.argument,false)).disabled=n==pages-1
 return n*limit
func builders(w) -> String:
 var names=[]
 for c in K.assigned(w,0):names.append(c.name)
 return say("No builder · free a worker","İnşaatçı yok · bir işçiyi boşa al") if names.is_empty() else ", ".join(names)
func work_status(w,b) -> String:
 if not K.ready(b):
  var queue=w.kingdom.buildings.filter(func(site):return not K.ready(site));var rank=queue.find(b)+1
  return say("Construction queue #","İnşaat sırası #")+str(rank)+" · "+str(int(100.0*b.progress/maxf(1,b.required)))+"%\n"+builders(w)
 var names=[]
 for c in K.assigned(w,int(b.id)):names.append(c.name)
 if int(K.buildings()[b.kind].slots)==0:return say("Passive building · no worker needed","Pasif bina · işçi gerektirmez")
 if names.is_empty():return say("No production worker assigned","Üretim işçisi atanmadı")
 var state=say("Producing","Üretiyor")
 if b.kind=="barracks":state=say("Instructor · training / recovery","Eğitmen · eğitim / iyileşme")
 elif b.kind=="marketplace":state=say("Merchant · open trade routes","Tüccar · ticaret yollarını aç")
 elif b.kind=="forge" and not w.kingdom.industry.queue.any(func(job):return int(job.building)==int(b.id)):state=say("No order · choose a recipe","Sipariş yok · tarif seç")
 elif K.activity_rate(w,b)<=0:
  var d=K.buildings()[b.kind];state=say("No nearby resources / dry soil","Yakın kaynak yok / toprak kuru")
  if load("res://scripts/estate.gd").enabled(w) and load("res://scripts/estate.gd").room(w,b)<=0:state=say("Output full · collect the bubble","Ürün alanı dolu · simgeden topla")
  elif d.has("inputs"):
   var missing=[]
   for key in d.inputs:
    if int(w.kingdom.stock.get(key,0))<float(d.inputs[key])*K.SCALE:missing.append(game.realm_ui.cost({key:d.inputs[key]}))
   if not missing.is_empty():state=say("Missing input: ","Eksik girdi: ")+", ".join(missing)
 return ", ".join(names)+" · "+state
func intro():
 var v=p.surface(say("Your first village","İlk köyün"),true);v.add_child(p.image(load("res://assets/kingdom/arin.png"),Vector2(0,p.px(82))))
 label(v,say("I'm Arin. Meet your settlers, gather wood and build your village. I'll guide each step.","Ben Arin. Yerleşimcilerle tanış, odun topla ve köyünü kur. Her adımda seni yönlendireceğim."))
 label(v,say("One-time supplies: 12 stone, 8 gold. Your settlement keeps its food and people.","Tek seferlik erzak: 12 taş, 8 altın. Yerleşimin besini ve insanları korunur."))
 button(v,say("Start my village","Köyümü kurmaya başla"),func():
  if K.enable(game.world):game.realm_ui.changed();p.route("quest"),true)
 button(v,say("Explore","Keşfet"),ui.close)
func quest():
 var w=game.world
 if not w.has("kingdom"):intro();return
 var q=K.current(w);var v=p.surface(say("What next?","Sırada ne var?"));var tabs=HBoxContainer.new();v.add_child(tabs)
 button(tabs,say("Village","Köy rehberi"),func():p.route("guide"))
 button(tabs,say("History","Geçmiş"),func():p.route("quest_history"))
 if H.enabled(w):button(tabs,say("Hunts","Av görevleri"),func():p.route("contracts"))
 if q.is_empty():
  label(v,say("Current chapters complete. Choose your next journey.","Mevcut bölümler tamamlandı. Yeni yolculuğunu seç."));button(v,say("Continue story","Hikâyeyi sürdür"),game.realm_ui.legacy_open,true);return
 label(v,game.realm_ui.localized(q.title),Color("f4cf7d"))
 var start=page(v,"objectives",q.objectives.size(),2)
 for o in q.objectives.slice(start,start+2):
  var objective=o;var value=minf(float(o.target),K.progress(w,o));var done=value>=float(o.target)
  label(v,("✓ " if done else "◇ ")+game.realm_ui.localized(o.text)+"  "+str(int(value))+" / "+str(int(o.target)))
  if not done:label(v,instruction(str(o.navigate)))
  if not done:button(v,say("Go to objective","Hedefe git"),func():go_objective(str(objective.navigate)),true)
 label(v,say("Reward: ","Ödül: ")+game.realm_ui.cost(q.rewards))
 button(v,say("Claim verified reward","Doğrulanan ödülü al"),func():game.realm_ui.claim_reward(q.id),K.complete(w,q)).disabled=not K.complete(w,q)
func instruction(key: String) -> String:
 if key=="settlers":return say("Go to the highlighted camp, then tap the settlers.","İşaretlenen kampa git, ardından yerleşimcilere dokun.")
 if key.begins_with("build_"):return say("Choose an empty suitable tile and confirm. Keep a free builder.","Uygun boş kareyi seç ve onayla. Bir inşaatçıyı boşta bırak.")
 if key.begins_with("gather_"):return say("Select a forest for wood or a mountain for stone; confirm gathering.","Odun için orman, taş için dağ seç; toplamayı onayla.")
 if key=="workers":return say("Tap a worker, choose a finished building, then close the menu to work.","İşçiye dokun, tamamlanmış binayı seç; çalışması için menüyü kapat.")
 if key=="army":return say("Build a barracks, assign an instructor, craft a kit and train a free worker.","Kışla kur, eğitmen ata, takım üret ve boştaki işçiyi eğit.")
 if key in ["wildwood","desert","sanctuary"]:return say("Prepare your hero. Enter the region and return home with your loot.","Kahramanını hazırla. Bölgeye gir ve ganimetle eve dön.")
 return say("Open the destination below to complete this objective.","Bu hedefi tamamlamak için aşağıdaki ilgili ekranı aç.")
func go_objective(key: String):
 # A queued required building needs workers/time, not a duplicate placement.
 if key.begins_with("build_") and game.world.has("kingdom"):
  var kind=key.trim_prefix("build_");var queued=game.world.kingdom.buildings.filter(func(b):return b.kind==kind and not K.ready(b))
  if not queued.is_empty():p.route("building",int(queued[0].id));return
 game.realm_ui.navigate(key)
func history():
 var v=p.surface(say("Completed chapters","Tamamlanan bölümler"));var entries=K.quests().filter(func(q):return q.id in game.world.kingdom.claimed);entries.reverse();var start=page(v,"history",entries.size())
 for q in entries.slice(start,start+4):
  var entry=q;button(v,"✓ "+game.realm_ui.localized(q.title),func():p.completed_quest(entry))
func guide():
 if not game.world.has("kingdom"):intro();return
 var w=game.world;var v=p.surface(say("Village & journeys","Köy ve yolculuklar"));var tabs=HBoxContainer.new();v.add_child(tabs)
 button(tabs,say("Goal","Görev"),func():p.route("quest"));button(tabs,say("Build","İnşa et"),func():p.route("construction"));button(tabs,say("Workers","İşçiler"),func():p.route("workers"))
 label(v,say("VILLAGE · tap a building to locate and manage it","KÖY · binaya dokun, yerini gör ve yönet"),Color("f4cf7d"))
 var start=page(v,"village",w.kingdom.buildings.size(),3)
 if w.kingdom.buildings.is_empty():label(v,say("No buildings yet. Follow your first quest.","Henüz bina yok. İlk görevinle başla."))
 for b in w.kingdom.buildings.slice(start,start+3):
  var id=int(b.id);button(v,game.realm_ui.localized(K.buildings()[b.kind].name)+" · "+(say("Ready","Hazır") if K.ready(b) else str(int(100.0*b.progress/maxf(1,b.required)))+"%"),func():p.route("building",id))
 var paths=HBoxContainer.new();v.add_child(paths)
 button(paths,say("Hero expeditions","Kahraman seferi") if H.enabled(w) else say("Hero · after chapter 10","Kahraman · 10. bölüm sonrası"),func():p.route("map") if H.enabled(w) else p.route("quest"))
 button(paths,say("Army & battlefields","Birlik ve savaş alanları") if M.enabled(w) else say("Army · after chapter 15","Birlik · 15. bölüm sonrası"),func():p.route("army") if M.enabled(w) else p.route("quest"))
func workers():
 if not game.world.has("kingdom"):intro();return
 var w=game.world;var v=p.surface(say("Workers & construction","İşçiler ve inşaat"))
 label(v,say("Builders: ","İnşaatçılar: ")+builders(w),Color("f4cf7d"))
 label(v,say("Free workers build in queue order. Production workers stay at their assigned building. Close menus to let time pass.","Boştaki işçiler sırayla inşa eder. Üretim işçisi atandığı binada kalır. Zamanın ilerlemesi için menüyü kapat."))
 var start=page(v,"workers",w.kingdom.workers.size(),3)
 for c in w.kingdom.workers.slice(start,start+3):
  var id=int(c.id);var job=say("Builder","İnşaatçı")
  for b in w.kingdom.buildings:
   if int(b.id)==int(c.building):job=game.realm_ui.localized(K.buildings()[b.kind].name)
  if M.worker_reserved(w,id):job=say("Army · reserved","Birliğe ayrıldı")
  if T.worker_reserved(w,id):job=say("Caravan · reserved","Kervana ayrıldı")
  button(v,c.name+" · "+job,func():p.route("worker",id))
 button(v,say("Recruit · 2 food + 1 gold","İşe al · 2 besin + 1 altın"),func():
  if K.recruit(w):game.realm_ui.changed();p.route("workers",0,false)
  else:ui.toast(say("Needs realm 4, food, gold, trust and housing.","Diyar 4, besin, altın, güven ve konut gerekli."))).disabled=K.level(w)<4 or w.kingdom.workers.size()>=K.MAX_WORKERS
func worker(id):
 if not game.world.has("kingdom"):intro();return
 var w=game.world;var found=w.kingdom.workers.filter(func(c):return int(c.id)==id)
 if found.is_empty():return
 var c=found[0];var v=p.surface(c.name+say(" · choose work"," · iş seç"))
 if M.worker_reserved(w,id) or T.worker_reserved(w,id):
  label(v,say("Reserved for army or caravan. Release through its management screen first.","Birlik veya kervana ayrılmış. Önce ilgili yönetim ekranından serbest bırak."));button(v,say("Back to workers","İşçilere dön"),func():p.route("workers"));return
 button(v,say("Builder · leave production","İnşaatçı · üretimden ayır"),func():assign(id,0),int(c.building)==0)
 var choices=w.kingdom.buildings.filter(func(b):return K.ready(b) and int(K.buildings()[b.kind].slots)>0);var start=page(v,"jobs",choices.size(),3)
 for b in choices.slice(start,start+3):
  var building_id=int(b.id);var d=K.buildings()[b.kind];var occupied=K.occupied(w,building_id)
  button(v,game.realm_ui.localized(d.name)+" · "+str(occupied)+" / "+str(int(d.slots)),func():assign(id,building_id)).disabled=occupied>=int(d.slots) or int(c.building)==building_id
 if p.I.enabled(w):button(v,say("Choose or compare tool","Alet seç veya karşılaştır"),func():game.realm_ui.choose_tool(id))
func assign(worker_id,building_id):
 if K.assign(game.world,worker_id,building_id):
  game.realm_ui.changed();p.route("workers",0,false);ui.toast(say("Assigned. Close the menu to resume work.","Atandı. İşin sürmesi için menüyü kapat."))
func construction():
 if not game.world.has("kingdom"):intro();return
 var w=game.world;var v=p.surface(say("Build · choose then place","İnşaat · seç ve yerleştir"));label(v,say("Builders: ","İnşaatçılar: ")+builders(w))
 var tabs=HBoxContainer.new();v.add_child(tabs);button(tabs,say("Village buildings","Köydeki binalar"),func():p.route("guide"));button(tabs,say("Assign workers","İşçi ata"),func():p.route("workers"))
 var choices=[]
 for id in K.buildings():
  var d=K.buildings()[id]
  if int(d.level)>5 and not p.I.enabled(w):continue
  if int(d.level)>15 and not M.enabled(w):continue
  if int(d.level)>20 and not T.enabled(w):continue
  choices.append(id)
 var start=page(v,"build",choices.size(),3)
 for id in choices.slice(start,start+3):
  var key=id;var d=K.buildings()[id];var row=HBoxContainer.new();v.add_child(row);row.add_child(p.image(game.view.kingdom_layer.texture(id),Vector2.ONE*p.px(58)))
  var count=w.kingdom.buildings.filter(func(b):return b.kind==key).size();var reason=say("Choose site","Yer seç")
  if K.level(w)<int(d.level):reason=say("Realm ","Diyar ")+str(int(d.level))
  elif count>=int(d.limit) or w.kingdom.buildings.size()>=K.MAX_BUILDINGS:reason=say("Limit reached","Sınıra ulaşıldı")
  elif not K.afford(w,d.cost):reason=say("Materials missing","Malzeme eksik")
  var b=button(row,game.realm_ui.localized(d.name)+" · "+game.realm_ui.cost(d.cost)+"\n"+reason,func():game.realm_ui.begin("build",key));b.disabled=reason!=say("Choose site","Yer seç")
 label(v,say("Pick a clear suitable tile, then confirm. Costs are spent once. Free builders start work when you return to the world.","Uygun boş kareyi seçip onayla. Maliyet bir kez ödenir. Dünyaya dönünce boştaki inşaatçılar işe başlar."))
func world_map():
 if not H.enabled(game.world):quest();return
 var R=preload("res://scripts/regions.gd");var v=p.surface(say("Hero expeditions","Kahraman seferleri"));var start=page(v,"regions",R.IDS.size(),1);var key=R.IDS[start];var d=R.data(key)
 v.add_child(p.image(load("res://assets/adventure/"+d.preview+".svg"),Vector2(0,p.px(90))))
 label(v,game.realm_ui.localized(d.name),Color("f4cf7d"));label(v,game.realm_ui.localized(d.resources));label(v,game.realm_ui.localized(d.enemies))
 label(v,say("Path open","Yol açık") if R.unlocked(game.world,key) else say("Locked · inspect requirements","Kilitli · koşulları incele"))
 button(v,say("Inspect destination","Bölgeyi incele"),func():game.hero_ui.destination(key),true)
 button(v,say("Village & army","Köy ve birlik"),func():p.route("guide"))
func hunts():
 var w=game.world;var v=p.surface(say("Boss hunts & adventures","Boss avı ve maceralar"));label(v,say("CONTROL YOUR HERO · explore, fight, collect and return","KAHRAMANINI YÖNET · keşfet, savaş, topla ve dön"),Color("f4cf7d"))
 if not H.enabled(w):
  label(v,say("Complete chapter 10 to unlock heroes; chapter 11 opens Wildwood.","Kahraman için 10. bölümü tamamla; 11. bölüm Yabanorman yolunu açar."));button(v,say("Current quest","Güncel görev"),func():p.route("quest"),true);return
 var R=preload("res://scripts/regions.gd");var regions=["wildwood","sanctuary"];var start=page(v,"hunt_regions",regions.size(),1);var id=regions[start];var d=R.data(id)
 label(v,game.realm_ui.localized(d.name)+" · "+(say("Thornheart guardian","Dikenyürek muhafızı") if id=="wildwood" else say("Sunward Warden","Güneş Muhafızı")))
 label(v,(say("Guardian gate opens after chapter 14.","Muhafız kapısı 14. bölümden sonra açılır.") if w.kingdom.claimed.size()<14 else say("Follow the northern trail. Read warning circles, dodge and attack in recovery windows.","Kuzey patikasını izle. Uyarı alanlarını oku, kaçın ve dinlenme aralığında saldır.")) if id=="wildwood" else say("Complete chapter 22, enter the sanctuary and open the rune doors.","22. bölümü tamamla, tapınağa gir ve rün kapılarını aç."))
 var active=w.kingdom.adventure.run.get("active",false);var live=preload("res://scripts/regions.gd").current(w)
 if active:
  button(v,say("Return to battle","Savaşa dön"),ui.close,true)
  label(v,say("Region travel is on the Regions icon; leave combat before traveling.","Bölge yolculuğu Bölgeler ikonunda; yolculuktan önce savaştan uzaklaş."))
  if is_instance_valid(game.adventure_scene) and live==id:
   button(v,say("Show boss direction","Boss yönünü göster"),func():
    var scene=game.adventure_scene;scene.guide_point=Vector2(720,230) if id=="wildwood" else Vector2(570,270);ui.close();scene.message.text=say("Follow the golden direction marker. Doors and enemies still apply.","Altın yön işaretini izle. Kapı ve düşman koşulları geçerli."))
 else:button(v,say("Inspect / enter region","Bölgeyi incele / gir"),func():game.hero_ui.destination(id),true)
 var row=HBoxContainer.new();v.add_child(row);button(row,say("Drop guide / quests","Drop / av görevleri"),func():p.route("contracts"));button(row,say("Army battles","Birlik savaşları"),func():p.route("army"))
func destination(id):
 var R=preload("res://scripts/regions.gd");var d=R.data(id);var v=p.surface(game.realm_ui.localized(d.name));label(v,game.realm_ui.localized(d.risk));label(v,game.realm_ui.localized(d.resources));label(v,game.realm_ui.localized(d.landmark))
 if R.unlocked(game.world,id):button(v,say("Enter ","Gir: ")+game.realm_ui.localized(d.name),func():game.enter_adventure(id),true)
 else:
  var terms=say("Requires an armed hero and chapter 11 completed.","Silahlı kahraman ve tamamlanmış 11. bölüm gerekli.")
  if id=="iron_hills":terms=say("Complete chapter 21 and equip a Warrior.","21. bölümü tamamla ve Savaşçı'yı silahlandır.")
  if id=="ashen_desert":terms=say("Complete chapter 21, discover the Forgotten Mine, return home and equip a Warrior.","21. bölümü tamamla, Unutulmuş Maden'i keşfet, eve dön ve Savaşçı'yı silahlandır.")
  if id=="sanctuary":terms=say("Complete chapter 22 and equip a Warrior.","22. bölümü tamamla ve Savaşçı'yı silahlandır.")
  label(v,terms)
 label(v,say("Home delivers loot safely. No travel fee. The village pauses during expeditions.","Eve dönüş ganimeti güvenle teslim eder. Yol ücreti yok. Seferde köy duraklar."))
 if id=="wildwood":
  var run=game.world.kingdom.adventure.run
  if not run.is_empty() and not run.active and run.get("region","wildwood")=="wildwood" and not run.enemies.any(func(e):return e.hp>0) and not run.loot.any(func(l):return not l.taken):button(v,say("Refresh cleared trail","Temizlenen patikayı yenile"),func():
   if load("res://scripts/adventure.gd").revisit(game.world):game.checkpoint("new-expedition");destination(id))
 button(v,say("Prepare equipment / potions","Donanım / iksir hazırla"),game.hero_ui.profile)
func army():
 var w=game.world
 if not M.enabled(w):quest();return
 var v=p.surface(say("Army & battlefields","Birlik ve savaş alanları"));var barracks=w.kingdom.buildings.filter(func(b):return b.kind=="barracks")
 if barracks.is_empty():button(v,say("Build barracks","Kışla inşa et"),func():p.route("construction"),true)
 else:
  var id=int(barracks[0].id);button(v,say("Locate barracks · instructors & progress","Kışlayı bul · eğitmenler ve ilerleme"),func():p.route("building",id))
 label(v,str(M.available(w).size())+say(" ready soldiers · battles cost 3 food"," hazır asker · savaş maliyeti 3 besin"))
 var tabs=HBoxContainer.new();v.add_child(tabs);button(tabs,say("Train","Eğit"),game.military_ui.candidates);button(tabs,say("Equipment","Donanım"),game.realm_ui.workshop);button(tabs,say("Roster / formation","Kadro / düzen"),func():p.route("army_roster"))
 for key in ["raid","camp"]:
  var mission=key;var need=18 if key=="raid" else 19;var title=say("Village defense","Köy savunması") if key=="raid" else say("Border camp","Sınır kampı")
  var locked=w.kingdom.claimed.size()<need or M.available(w).is_empty() or K.home(w).food<3
  label(v,title+" · "+(say("Complete chapter ","Tamamlanması gereken bölüm: ")+str(need) if w.kingdom.claimed.size()<need else say("Train soldiers and keep 3 food","Asker eğit ve 3 besin ayır") if locked else say("Ready","Hazır")))
  button(v,say("Enter battlefield","Savaş alanına gir"),func():
   if not game.enter_army(mission):ui.toast(say("Check ready soldiers, food and chapter.","Hazır asker, besin ve bölümü kontrol et.")),not locked).disabled=locked
func candidates():
 var w=game.world;var v=p.surface(say("Choose trainee","Eğitilecek sakini seç"));label(v,say("Requires free worker, finished barracks, instructor, kit, 3 food and 2 gold.","Boştaki işçi, tamamlanmış kışla, eğitmen, takım, 3 besin ve 2 altın gerekir."))
 var choices=K.assigned(w,0);var start=page(v,"trainees",choices.size())
 for c in choices.slice(start,start+4):
  var id=int(c.id);button(v,c.name,func():game.military_ui.kits(id))
 if choices.is_empty():label(v,say("No free worker. Release one from production first.","Boştaki işçi yok. Önce birini üretimden ayır."))
 button(v,say("Workers","İşçiler"),func():p.route("workers"))
func kits(worker_id):
 var w=game.world;var v=p.surface(say("Choose training kit","Eğitim takımını seç"));var choices=w.kingdom.industry.items.filter(func(item):return p.I.recipes()[item.recipe].get("category","")=="military" and not M.item_reserved(w,int(item.id)));var start=page(v,"kits",choices.size(),3)
 var barracks=w.kingdom.buildings.filter(func(b):return b.kind=="barracks" and K.ready(b) and not K.assigned(w,int(b.id)).is_empty())
 label(v,say("Training costs 3 food + 2 gold. Kit stays with the soldier.","Eğitim 3 besin + 2 altın. Takım askerde kalır."))
 for item in choices.slice(start,start+3):
  var owned=item;button(v,game.realm_ui.localized(p.I.recipes()[item.recipe].name)+" #"+str(int(item.id)),func():
   if not barracks.is_empty() and M.train(w,worker_id,owned.recipe.trim_suffix("_kit"),int(owned.id),int(barracks[0].id)):game.military_ui.changed();p.route("army")
   else:ui.toast(say("Needs instructor, free trainee, 3 food and 2 gold.","Eğitmen, boştaki aday, 3 besin ve 2 altın gerekli."))).disabled=barracks.is_empty() or K.home(w).food<3 or not K.afford(w,{"gold":2})
 if choices.is_empty():label(v,say("No available kit. Craft military equipment at the forge.","Kullanılabilir takım yok. Demircide askeri donanım üret."))
 if barracks.is_empty():label(v,say("Finish a barracks and assign an instructor.","Kışlayı tamamla ve bir eğitmen ata."))
 button(v,say("Forge","Demirci"),game.realm_ui.workshop);button(v,say("Workers","İşçiler"),func():p.route("workers"))
func roster():
 var w=game.world;var v=p.surface(say("Roster & formation","Kadro ve düzen"));var units=w.kingdom.military.units;var start=page(v,"roster",units.size(),3)
 for unit in units.slice(start,start+3):
  var id=int(unit.id);var c=w.kingdom.workers.filter(func(citizen):return int(citizen.id)==int(unit.worker))[0];var states={"training":say("Training","Eğitim"),"ready":say("Ready","Hazır"),"injured":say("Injured","Yaralı"),"recovering":say("Recovering","İyileşiyor"),"deployed":say("Deployed","Görevde")}
  button(v,c.name+" · "+str(states.get(unit.status,unit.status))+" · HP "+str(int(unit.hp)),func():p.route("unit",id))
 if units.is_empty():label(v,say("No soldiers yet. Train a free worker.","Henüz asker yok. Boştaki işçiyi eğit."))
 var row=HBoxContainer.new();v.add_child(row)
 for key in M.FORMATIONS:
  var value=key;var titles={"balanced":say("Balanced","Dengeli"),"defensive":say("Defensive","Savunma"),"assault":say("Assault","Hücum")}
  button(row,titles[key],func():
   if M.formation(w,value):game.military_ui.changed();p.route("army_roster",0,false),w.kingdom.military.formed and w.kingdom.military.formation==key)
 label(v,say("Defensive: 80% attack / 140% armor. Assault: 130% / 75%.","Savunma: %80 saldırı / %140 zırh. Hücum: %130 / %75."))
 button(v,say("Army & battlefields","Birlik ve savaş alanları"),func():p.route("army"))
func building(id):
 var w=game.world;var found=w.kingdom.buildings.filter(func(b):return int(b.id)==id)
 if found.is_empty():return
 var b=found[0];var d=K.buildings()[b.kind];game.view.select_cell(int(b.cell));game.view.pan=-game.view.project(w.cells[int(b.cell)])*game.view.zoom
 var v=p.surface(game.realm_ui.localized(d.name));var row=HBoxContainer.new();v.add_child(row);row.add_child(p.image(game.view.kingdom_layer.texture(b.kind),Vector2.ONE*p.px(65)))
 label(row,say("Level ","Seviye ")+str(int(b.level))+" · "+str(K.occupied(w,id))+" / "+str(int(d.slots))+say(" workers"," işçi"))
 label(v,work_status(w,b),Color("f4cf7d"))
 if not K.ready(b):
  var bar=ProgressBar.new();bar.max_value=b.required;bar.value=b.progress;bar.custom_minimum_size.y=p.px(16);v.add_child(bar)
 else:label(v,game.realm_ui.localized(d.description))
 label(v,say("Work resumes when you close this menu.","Menüyü kapatınca çalışma devam eder."))
 var E=load("res://scripts/estate.gd")
 if E.enabled(w) and E.status(w,b)!="":button(v,say("Collect ready output","Hazır ürünü topla"),func():game.view.estate_layer.collect(id);p.route("building",id,false),true)
 var actions=HBoxContainer.new();v.add_child(actions);button(actions,say("Workers","İşçiler"),func():p.route("workers"));button(actions,say("Locate","Yerini göster"),func():game.realm_ui.focus(int(b.cell)))
 if b.kind=="forge":button(v,say("Craft equipment / scrolls","Donanım / parşömen üret"),func():p.route("forge",id))
 if b.kind=="barracks" and M.enabled(w):button(v,say("Army & battlefields","Birlik ve savaş alanları"),func():p.route("army"))
 if b.kind=="marketplace" and T.enabled(w):button(v,say("Trade","Ticaret"),func():p.route("trade"))
 if K.ready(b) and int(b.level)<3:
  button(v,say("Upgrade · ","Geliştir · ")+game.realm_ui.cost(K.upgrade_cost(b)),func():
   if K.upgrade(w,id):game.realm_ui.changed();p.route("building",id,false),true).disabled=not K.afford(w,K.upgrade_cost(b)) or T.building_reserved(w,id)
 button(v,say("Relocate building","Binayı taşı"),func():game.realm_ui.begin("build",b.kind,id)).disabled=T.building_reserved(w,id)
