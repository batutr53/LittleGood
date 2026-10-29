extends RefCounted
# A real centered layout keeps the icon and its caption separate and non-interactive.
static func attach(button:Button,texture:Texture2D,caption:String,scale:float,font:Font):
	button.text="";button.icon=null
	var inset=MarginContainer.new();inset.name="IconCaption";inset.mouse_filter=Control.MOUSE_FILTER_IGNORE;button.add_child(inset);inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+side,maxi(1,roundi(2*scale)))
	var stack=VBoxContainer.new();stack.mouse_filter=Control.MOUSE_FILTER_IGNORE;stack.alignment=BoxContainer.ALIGNMENT_CENTER;stack.add_theme_constant_override("separation",maxi(1,roundi(scale)));inset.add_child(stack)
	var icon=TextureRect.new();icon.name="NavIcon";icon.texture=texture;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2.ONE*roundf(21*scale);icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;icon.modulate=preload("res://scripts/premium_theme.gd").GOLD;stack.add_child(icon)
	var label=Label.new();label.name="Caption";label.text=caption;label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.mouse_filter=Control.MOUSE_FILTER_IGNORE;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_override("font",font);label.add_theme_font_size_override("font_size",maxi(8,roundi(11*scale)));label.add_theme_color_override("font_color",preload("res://scripts/premium_theme.gd").CREAM);stack.add_child(label)
