extends RefCounted
const C=preload("res://scripts/colony.gd")
const K=preload("res://scripts/kingdom.gd")
var p
var game
func _init(presentation):p=presentation;game=p.game
func say(en,tr):return p.say(en,tr)
func label(v,value):p.playbook().label(v,value)
func button(v,value,action,primary=false):return p.playbook().button(v,value,action,primary)
func name(key):return C.NAMES[key][1 if p.ui.language=="tr" else 0]
func job_name(worker):
 var w=game.world;var id=int(worker.id)
 if C.reserved(w,id):return name(w.colony.jobs[str(id)].resource)+" · "+C.task_status(w,w.colony.jobs[str(id)],p.ui.language=="tr")
 if preload("res://scripts/military.gd").worker_reserved(w,id):return say("Army · reserved","Birlik · görevde")
 if preload("res://scripts/trade.gd").worker_reserved(w,id):return say("Caravan · reserved","Kervan · görevde")
 for b in w.kingdom.buildings:
  if int(worker.building)==int(b.id):return game.realm_ui.localized(K.buildings()[b.kind].name)+" #"+str(int(b.id))
 for b in w.kingdom.buildings:
  if not K.ready(b):return say("Building: ","İnşaat: ")+game.realm_ui.localized(K.buildings()[b.kind].name)+" #"+str(int(b.id))
 return say("Builder pool","İnşaat havuzu")
func home():
 if not game.world.has("kingdom"):p.playbook().intro();return
 var w=game.world;var v=p.surface(say("The Hearthbound colony","Ocakbağı kolonisi"));label(v,say("Your hero brings relics home. The Hearthkin gather materials, build and defend the settlement.","Kahramanın yadigârlarla eve döner. Ocaklılar kaynak toplar, inşa eder ve yerleşimi savunur."))
 var row=HBoxContainer.new();v.add_child(row);button(row,say("Workers","İşçiler"),func():p.route("workers"));button(row,say("Resources","Kaynaklar"),func():p.route("resources"));button(row,say("Defense","Savunma"),func():p.route("defense"))
 label(v,str(K.assigned(w,0).size())+say(" builders · "," inşaatçı · ")+str(w.get("colony",{}).get("jobs",{}).size())+say(" gathering · "," toplayıcı · ")+str(w.kingdom.buildings.size())+say(" buildings"," bina"))
 button(v,say("Build / locate buildings","Bina kur / yerini bul"),func():p.route("guide"));button(v,say("Hero · boss expeditions & loot","Kahraman · boss seferi ve ganimet"),func():p.route("hunts"),true)
 button(v,say("Current quest","Güncel görev"),func():p.route("quest"))
func resources():
 if not C.enabled(game.world):p.playbook().intro();return
 var w=game.world;var v=p.surface(say("Resources & production","Kaynaklar ve üretim"));var start=p.playbook().page(v,"resources",C.RESOURCES.size(),3)
 for key in C.RESOURCES.slice(start,start+3):
  var resource=key;var amount=int(w.kingdom.stock[key]) if key in ["wood","stone","gold"] else int(w.colony.stock[key]);var rows=VBoxContainer.new();v.add_child(rows)
  label(rows,name(key)+" · "+str(snappedf(amount/1000.0,.01)))
  var count=w.colony.jobs.values().filter(func(job):return job.resource==resource).size();var ready=0
  for job in w.colony.jobs.values():
   if job.resource==key:ready+=int(job.buffer)
  button(rows,str(count)+say(" workers · collect "," işçi · toplanacak ")+str(ready/1000.0)+" · "+say("Manage","Yönet"),func():p.route("gathering",C.RESOURCES.find(resource)))
 var row=HBoxContainer.new();v.add_child(row);button(row,say("Cook meal","Yemek hazırla"),func():
  if C.meal(w):game.realm_ui.changed();p.route("resources",0,false)
  else:p.ui.toast(say("Needs 2 fish + 1 water and room for 4 food.","2 balık + 1 su ve 4 besinlik boşluk gerekir.")))
 button(row,say("Defense","Savunma"),func():p.route("defense"))
func gathering(index):
 if not C.enabled(game.world):p.playbook().intro();return
 var w=game.world;var key=C.RESOURCES[clampi(index,0,C.RESOURCES.size()-1)];var v=p.surface(name(key)+say(" · gathering"," · toplama"));label(v,say("A short trip brings up to 2 materials. Tap the cargo icon to collect. Each worker can carry 6; work pauses in menus and expeditions.","Kısa bir tur en fazla 2 malzeme getirir. Yük ikonuna dokunarak topla. İşçi en fazla 6 taşır; menü ve sefer sırasında iş durur."))
 label(v,say("Forest for wood, mountains for ore, fertile soil for clay, shore for water/fish. Ore deposits are finite; water and fish are renewable.","Odun ormandan, maden dağdan, kil verimli topraktan, su/balık kıyıdan gelir. Madenler sınırlı; su ve balık yenilenebilir."))
 var jobs=[]
 for worker in w.kingdom.workers:
  if C.reserved(w,int(worker.id)) and w.colony.jobs[str(int(worker.id))].resource==key:jobs.append(worker)
 var start=p.playbook().page(v,"gather_"+key,jobs.size(),2)
 for worker in jobs.slice(start,start+2):
  var id=int(worker.id);var job=w.colony.jobs[str(id)];button(v,worker.name+" · "+C.task_status(w,job,p.ui.language=="tr")+" · "+str(job.buffer/1000.0),func():p.route("worker",id))
 var free=K.assigned(w,0)
 if not free.is_empty():
  var worker=free[0];button(v,say("Assign ","Ata: ")+worker.name+say(" · leaves construction pool"," · inşaat havuzundan ayrılır"),func():
   if C.start(w,int(worker.id),key):game.realm_ui.changed();p.route("gathering",index,false),true).disabled=C.source(w,key)<0
 else:label(v,say("No free worker. Release another duty explicitly in Workers.","Boştaki işçi yok. İşçiler ekranında mevcut görevi açıkça bırak."))
 button(v,say("All worker duties","Tüm işçi görevleri"),func():p.route("workers"))
func worker(id):
 var w=game.world;var job=w.colony.jobs[str(id)];var workers=w.kingdom.workers.filter(func(c):return int(c.id)==id);var v=p.surface(workers[0].name+" · "+name(job.resource))
 label(v,C.task_status(w,job,p.ui.language=="tr")+" · "+str(int(job.progress))+" / 10");label(v,say("Cargo: ","Yük: ")+str(job.buffer/1000.0)+" / 6 "+name(job.resource))
 button(v,say("Collect cargo","Yükü teslim al"),func():
  var amount=C.collect(w,id);game.realm_ui.changed();p.route("worker",id,false);p.ui.toast("+"+str(amount/1000.0)+" "+name(job.resource)),true).disabled=int(job.buffer)<=0
 button(v,say("Leave task · return to builder pool","Görevi bırak · inşaat havuzuna dön"),func():
  if C.release(w,id):game.realm_ui.changed();p.route("workers",0,false)).disabled=int(job.buffer)>0
 label(v,say("Collect cargo before release. No other job can claim this worker. Cancelling abandons only unfinished progress.","Bırakmadan önce yükü al. Bu işçi başka işe atanamaz. İptal yalnızca bitmemiş ilerlemeyi bırakır."))
 button(v,say("Locate worker","İşçinin yerini göster"),func():game.realm_ui.focus(int(job.cell)))
func defense():
 if not game.world.has("kingdom"):p.playbook().intro();return
 var w=game.world;var v=p.surface(say("Settlement defense","Yerleşim savunması"));var tower=K.count(w,"watchtower");var wall=K.count(w,"wall");var fort=int(w.get("colony",{}).get("fortification",0));label(v,say("Village defense bonuses: ","Köy savunma bonusları: ")+"+"+str(tower*2)+say(" attack · +"," saldırı · +")+str(wall*3+fort*2)+say(" armor"," zırh"))
 label(v,say("Bonuses apply to your actual soldiers during village-defense battles. Towers need troops; they do not generate a fake defense score.","Bonuslar köy savunma savaşında gerçek askerlerine uygulanır. Kuleler asker ister; sahte savunma puanı üretmez."))
 var n=fort+1;label(v,say("Fortification ","Tahkimat ")+str(fort)+" / 3 · "+str(2*n)+say(" copper + "," bakır + ")+str(2*n)+say(" clay + "," kil + ")+str(n)+say(" silver + "," gümüş + ")+str(3*n)+say(" stone"," taş"))
 button(v,say("Reinforce · +2 defense","Tahkim et · +2 savunma"),func():
  if C.reinforce(w):game.realm_ui.changed();p.route("defense",0,false)
  else:p.ui.toast(say("Needs finished tower + palisade and the listed materials.","Tamamlanmış kule + çit ve listelenen malzemeler gerekir.")),true).disabled=fort>=3
 var row=HBoxContainer.new();v.add_child(row);button(row,say("Build","İnşa et"),func():p.route("construction"));button(row,say("Train / defend","Eğit / savun"),func():p.route("army"))
 label(v,say("Player-versus-player region wars require an authoritative battle server. Only the existing local defense battle is playable in this build.","Oyuncular arası bölge savaşı yetkili savaş sunucusu gerektirir. Bu sürümde mevcut yerel savunma savaşı oynanabilir."))
