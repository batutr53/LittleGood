extends VBoxContainer
var game
var channel="system"
var peer=""
var rows: RichTextLabel
var entry: LineEdit
var state: Label
var recipients: OptionButton
var last_id=0
var seen={}
var elapsed=0.0
var pending=false
var epoch=0
var messages=[]
var message_selector: OptionButton
var oldest=0
var reason: LineEdit
func say(en: String,tr: String) -> String:return tr if game.ui.language=="tr" else en
func _ready():
	var tr=game.ui.language=="tr";var tabs=HBoxContainer.new();add_child(tabs)
	for pair in [["system","Sistem" if tr else "System"],["general","Genel" if tr else "General"],["private","Özel" if tr else "Private"]]:
		var key=pair[0];var b=game.ui.button(pair[1],func():change_channel(key));tabs.add_child(b)
	recipients=OptionButton.new();recipients.add_item("Arkadaş seç" if tr else "Choose friend");recipients.custom_minimum_size.y=48;recipients.item_selected.connect(func(i):peer=str(recipients.get_item_metadata(i));last_id=0;seen.clear();rows.clear();poll());add_child(recipients);recipients.hide()
	rows=RichTextLabel.new();rows.bbcode_enabled=false;rows.custom_minimum_size.y=220;rows.fit_content=false;rows.scroll_following=true;rows.selection_enabled=true;rows.add_theme_font_override("normal_font",game.ui.ui_font());rows.add_theme_font_size_override("normal_font_size",20);add_child(rows)
	entry=LineEdit.new();entry.max_length=300;entry.placeholder_text="Mesaj · en fazla 300 karakter" if tr else "Message · maximum 300 characters";entry.custom_minimum_size.y=48;entry.focus_entered.connect(game.reset_gesture);entry.text_submitted.connect(func(_value):send());add_child(entry)
	var buttons=HBoxContainer.new();add_child(buttons);buttons.add_child(game.ui.button("Gönder" if tr else "Send",send));state=game.ui.label("",18);add_child(state)
	var safety=game.ui.button("Arkadaşlar / engelle" if tr else "Friends / block",game.ui.online_screen);buttons.add_child(safety)
	buttons.add_child(game.ui.button(say("Older messages","Eski mesajlar"),func():poll(true)))
	message_selector=OptionButton.new();message_selector.custom_minimum_size.y=48;add_child(message_selector)
	reason=LineEdit.new();reason.max_length=300;reason.placeholder_text=say("Report reason","Bildirim gerekçesi");reason.custom_minimum_size.y=48;add_child(reason)
	var moderation=HBoxContainer.new();add_child(moderation);moderation.add_child(game.ui.button(say("Report selected message","Seçili mesajı bildir"),report_selected));moderation.add_child(game.ui.button(say("Block sender","Göndereni engelle"),block_selected))
	change_channel("system")
func _exit_tree():epoch+=1
func change_channel(key):
	epoch+=1;channel=key;last_id=0;oldest=0;messages.clear();seen.clear();rows.clear();message_selector.clear();recipients.visible=key=="private";entry.editable=key!="system";state.text="";elapsed=0
	if key=="system":
		for e in game.world.get("events",[]).slice(-50):rows.append_text(game.ui.event_text(e)+"\n")
	elif key=="private":load_friends()
	else:poll()
func _process(delta):
	if game.suspended or not is_visible_in_tree() or channel=="system":return
	elapsed+=delta
	if elapsed>=3:elapsed=0;poll()
func load_friends():
	if game.online.access.is_empty():state.text="Sohbet için çevrimiçi hesabına giriş yap.";return
	var revision=epoch;var result=await game.online.call_api(HTTPClient.METHOD_GET,"/friends")
	if not is_inside_tree() or revision!=epoch:return
	recipients.clear();recipients.add_item("Arkadaş seç");recipients.set_item_metadata(0,"")
	if result.ok:
		for row in result.data.get("items",[]):
			if row.state!="accepted":continue
			recipients.add_item(row.profile.name);recipients.set_item_metadata(recipients.item_count-1,row.profile.code)
func poll(older=false):
	if pending or game.suspended or channel=="system":return
	if game.online.access.is_empty():state.text="Sohbet için çevrimiçi hesabına giriş yap.";return
	if channel=="private" and peer.is_empty():return
	pending=true;var revision=epoch;var path="/chat/messages?"+("before="+str(oldest) if older and oldest>0 else "after="+str(last_id))
	if channel=="private":path+="&peer="+peer.uri_encode()
	var result=await game.online.call_api(HTTPClient.METHOD_GET,path);pending=false
	if not is_inside_tree() or revision!=epoch:return
	if not result.ok:state.text="Bağlantı yok. Mesaj gönderilmedi.";return
	state.text=""
	for message in result.data.get("items",[]):
		var id=int(message.get("id",0))
		if id<=0 or seen.has(id):continue
		seen[id]=true;last_id=maxi(last_id,id);oldest=id if oldest==0 else mini(oldest,id);messages.append(message)
	messages.sort_custom(func(a,b):return int(a.id)<int(b.id))
	if messages.size()>200:messages=messages.slice(-200)
	rows.clear();message_selector.clear()
	for message in messages:
		rows.append_text(str(message.get("name",""))+": "+str(message.get("text",""))+"\n");message_selector.add_item(str(message.get("name",""))+": "+str(message.get("text","")).left(45));message_selector.set_item_metadata(message_selector.item_count-1,message)
	if seen.size()>500:seen.clear();oldest=0
func selected_message() -> Dictionary:
	return message_selector.get_item_metadata(message_selector.selected) if message_selector.selected>=0 else {}
func report_selected():
	var message=selected_message()
	if message.is_empty() or reason.text.strip_edges().is_empty() or pending:return
	pending=true;var result=await game.online.call_api(HTTPClient.METHOD_POST,"/chat/messages/"+str(int(message.id))+"/report",{"reason":reason.text.strip_edges()});pending=false
	if is_inside_tree():state.text=say("Report received","Bildirim alındı") if result.ok else say("Report could not be sent","Bildirim gönderilemedi")
func block_selected():
	var message=selected_message()
	if message.is_empty() or pending:return
	pending=true;var result=await game.online.call_api(HTTPClient.METHOD_PUT,"/blocks/"+str(message.sender),{});pending=false
	if not is_inside_tree():return
	if result.ok:change_channel(channel)
	else:state.text=say("Could not block sender","Gönderen engellenemedi")
func send():
	if pending or channel=="system" or game.suspended:return
	var value=entry.text.strip_edges()
	if value.is_empty() or channel=="private" and peer.is_empty():return
	if game.online.access.is_empty():state.text="Önce çevrimiçi hesabına giriş yap.";return
	pending=true;var revision=epoch;var body={"text":value,"recipient":peer if channel=="private" else null};var result=await game.online.call_api(HTTPClient.METHOD_POST,"/chat/messages",body);pending=false
	if not is_inside_tree() or revision!=epoch:return
	if result.ok:entry.clear();poll()
	else:state.text="Gönderilmedi · 2 saniye bekle veya bağlantını kontrol et. Yeniden gönderim sana ait."
