extends Control
# Band Formation 2.0: identity -> recruitment -> reveal.
const UI = preload("res://Scripts/ui_theme.gd")
const Genres = preload("res://Scripts/genre_profiles.gd")
const Catalog = preload("res://Scripts/formation_catalogue.gd")
const Portrait = preload("res://Scripts/member_portrait.gd")
const SAVE_PATH := "user://tour_save.json"
const BAND_PATH := "user://band_profile.json"
var step := 0
var band_name := "The Feedback"
var genre := "Indie rock"
var influence := "The Smiths"
var palette_index := 0
var logo_index := 0
var recruited: Array = []
var canvas: VBoxContainer
var title_entry: LineEdit
var genre_select: OptionButton
var influence_select: OptionButton
var feedback: Label
var back_button: Button
var next_button: Button
var content_scroll: ScrollContainer

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _render()

func _render() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()
 var bg := ColorRect.new()
 bg.color = UI.palette(Genres.normalize(genre))["bg"]
 add_child(bg)
 bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content_scroll = ScrollContainer.new()
 content_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content_scroll.offset_bottom = -100
 content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(content_scroll)
 var margin := MarginContainer.new()
 margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for side in ["left","right"]:
  margin.add_theme_constant_override("margin_"+side,18)
 margin.add_theme_constant_override("margin_top",18)
 margin.add_theme_constant_override("margin_bottom",24)
 content_scroll.add_child(margin)
 canvas = VBoxContainer.new()
 canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 canvas.add_theme_constant_override("separation",16)
 margin.add_child(canvas)
 _label(canvas,"LIVIN' THE DREAM   /   YOUR ORIGIN STORY",12,UI.AMBER)
 _hero()
 var progress := HBoxContainer.new()
 progress.add_theme_constant_override("separation",8)
 canvas.add_child(progress)
 for i in range(3):
  var pill := PanelContainer.new()
  pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  pill.add_theme_stylebox_override("panel",UI.style(UI.AMBER if i == step else UI.ALT,12))
  progress.add_child(pill)
  var text := _label(pill,["01  IDENTITY","02  THE LINEUP","03  DEBUT"][i],11,UI.BG if i == step else UI.WHITE)
  text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 match step:
  0: _identity()
  1: _recruitment()
  2: _review()
 var footer_layer := CanvasLayer.new()
 footer_layer.layer = 10
 add_child(footer_layer)
 var footer := PanelContainer.new()
 footer.add_theme_stylebox_override("panel",UI.style(UI.PANEL,0))
 footer_layer.add_child(footer)
 footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 footer.offset_top = -94
 footer.offset_bottom = 0
 var buttons := HBoxContainer.new()
 buttons.add_theme_constant_override("separation",12)
 footer.add_child(buttons)
 back_button = UI.button("BACK")
 back_button.custom_minimum_size.x = 100
 back_button.disabled = step == 0
 buttons.add_child(back_button)
 back_button.pressed.connect(func() -> void: _go(step-1))
 next_button = UI.button(["FIND YOUR BAND  ›","REVIEW THE BAND  ›","START THE STORY  ›"][step],true)
 buttons.add_child(next_button)
 next_button.pressed.connect(_advance)
 feedback = _label(canvas,"",13,UI.AMBER)
 canvas.modulate.a = 0
 create_tween().tween_property(canvas,"modulate:a",1.0,0.25)

func _hero() -> void:
 var box := PanelContainer.new()
 box.add_theme_stylebox_override("panel",UI.style(UI.PANEL,16))
 canvas.add_child(box)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",8)
 box.add_child(stack)
 var art := TextureRect.new()
 art.custom_minimum_size.y = 190
 art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var source: String = ["res://Art/uk_band_banner.svg","res://Art/uk_actions_banner.svg","res://Art/uk_gigs_banner.svg"][step]
 if not ResourceLoader.exists(source):
  source = "res://Art/launch_uk_venue.webp"
 if ResourceLoader.exists(source):
  art.texture = load(source)
 stack.add_child(art)
 _label(stack,["START SOMETHING REAL","FIND YOUR PEOPLE","THIS IS YOUR BAND"][step],27,UI.WHITE)
 _label(stack,["Find the sound and identity that will shape your first gigs.","Every new musician brings talent, personality and another share of the earnings.","A band name, a sound, and a room full of people. The rest is up to you."][step],15,UI.MUTED)

func _card(parent: Node, heading: String, detail: String = "") -> VBoxContainer:
 var panel := PanelContainer.new()
 panel.add_theme_stylebox_override("panel",UI.style(UI.PANEL,14))
 parent.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 panel.add_child(column)
 _label(column,heading,19,UI.AMBER)
 if not detail.is_empty():
  _label(column,detail,14,UI.MUTED)
 return column

func _identity() -> void:
 var first := _card(canvas,"THE NAME","What will be on the first poster?")
 title_entry = LineEdit.new()
 title_entry.text = band_name
 title_entry.max_length = 36
 title_entry.custom_minimum_size.y = 56
 first.add_child(title_entry)
 var sound := _card(canvas,"THE SOUND","Genre sets the band's starting musical direction. It influences recruitment compatibility, not who you are allowed to hire.")
 genre_select = OptionButton.new()
 for key in Catalog.GENRES.keys():
  genre_select.add_item(str(key))
 genre_select.select(maxi(0,Catalog.GENRES.keys().find(genre)))
 genre_select.custom_minimum_size.y = 56
 sound.add_child(genre_select)
 var genre_details := _label(sound,"",14,UI.WHITE)
 var theme_preview := _label(sound,"",14,UI.AMBER)
 var update_genre := func() -> void:
  var selected := genre_select.get_item_text(genre_select.selected)
  var config: Dictionary = Catalog.GENRES[selected]
  theme_preview.text = "VISUAL IDENTITY  /  "+str(Genres.PROFILES[Genres.normalize(selected)]["name"]).to_upper()
  genre_details.text = str(config["description"])+"\nSTRENGTH  "+str(config["strength"])+"\nTRADE-OFF  "+str(config["challenge"])+"\nTYPICAL LINEUP  "+", ".join(config["roles"])
 genre_select.item_selected.connect(func(_index: int) -> void: update_genre.call())
 update_genre.call()
 var influence_box := _card(canvas,"YOUR INFLUENCE","A reference point for the band's identity. This is stored with the band; future musical scenes can respond to it.")
 influence_select = OptionButton.new()
 for item in Catalog.INFLUENCES:
  influence_select.add_item(str(item))
 influence_select.select(maxi(0,Catalog.INFLUENCES.find(influence)))
 influence_select.custom_minimum_size.y = 56
 influence_box.add_child(influence_select)
 var colour_box := _card(canvas,"BAND COLOURS","These define the band's visual identity and can carry into future artwork.")
 var swatches := HFlowContainer.new()
 swatches.add_theme_constant_override("h_separation",10)
 colour_box.add_child(swatches)
 for i in range(Catalog.PALETTES.size()):
  var palette: Dictionary = Catalog.PALETTES[i]
  var choice := UI.button(("✓  " if palette_index == i else "")+str(palette["name"]))
  choice.add_theme_stylebox_override("normal",UI.style(Color(str(palette["secondary"])),12))
  choice.add_theme_color_override("font_color",Color(str(palette["primary"])))
  choice.custom_minimum_size = Vector2(142,54)
  swatches.add_child(choice)
  var idx := i
  choice.pressed.connect(func() -> void:
   band_name = title_entry.text.strip_edges()
   genre = genre_select.get_item_text(genre_select.selected)
   influence = influence_select.get_item_text(influence_select.selected)
   palette_index = idx
   _render()
  )
 var logo_box := _card(canvas,"LOGO DIRECTION","Choose how the band name should appear on flyers, recordings and posters.")
 for i in range(Catalog.LOGOS.size()):
  var option := UI.button(("✓  " if logo_index == i else "")+str(Catalog.LOGOS[i]))
  logo_box.add_child(option)
  var idx := i
  option.pressed.connect(func() -> void:
   band_name = title_entry.text.strip_edges()
   genre = genre_select.get_item_text(genre_select.selected)
   influence = influence_select.get_item_text(influence_select.selected)
   logo_index = idx
   _render()
  )

func _recruitment() -> void:
 var count := recruited.size()
 var intro := _card(canvas,"BUILD THE LINEUP","Pick 2–6 musicians. A rhythm player is required. Musicians outside your genre can join, but might be less comfortable with the sound.")
 _label(intro,"%d / 6 MEMBERS   •   APPROX. %d%% SHARE EACH" % [count,Catalog.split_per_member(count)],15,UI.AMBER)
 var slots := HFlowContainer.new()
 intro.add_child(slots)
 for i in range(6):
  var slot := PanelContainer.new()
  slot.custom_minimum_size = Vector2(96,100)
  slot.add_theme_stylebox_override("panel",UI.style(UI.ALT,12))
  slots.add_child(slot)
  var who := "EMPTY SLOT"
  if i < recruited.size():
   who = str(recruited[i]["name"])+"\n"+str(recruited[i]["role"])
  var label := _label(slot,who,12,UI.WHITE if i < recruited.size() else UI.MUTED)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 for candidate in Catalog.CANDIDATES:
  var row: Dictionary = candidate
  var selected := false
  for member in recruited:
   if str(member["candidate_id"]) == str(row["id"]):
    selected = true
  var tier := Catalog.affinity(row,genre)
  var block := _card(canvas,str(row["name"]).to_upper()+"  /  "+str(row["role"]),str(row["pitch"]))
  var illustration := Portrait.new()
  illustration.set_character(str(row["id"]),str(row["name"]),Genres.normalize(genre))
  illustration.custom_minimum_size = Vector2(100,108)
  block.add_child(illustration)

  _label(block,"SKILL %d   •   LOYALTY %d   •   %s" % [int(row["skill"]),int(row["loyalty"]),str(row["trait"])],13,UI.WHITE)
  _label(block,"GOOD GENRE FIT" if tier > 0 else "UNUSUAL GENRE MATCH  /  EXPERIMENTAL POTENTIAL",12,UI.AMBER if tier > 0 else UI.MUTED)
  var button := UI.button("REMOVE FROM BAND" if selected else "RECRUIT  +",not selected and tier > 0)
  button.disabled = not selected and count >= 6
  block.add_child(button)
  var person := row.duplicate(true)
  button.pressed.connect(func() -> void:
   if selected:
    for n in range(recruited.size()):
     if str(recruited[n]["candidate_id"]) == str(person["id"]):
      recruited.remove_at(n)
      break
   elif Catalog.can_recruit(recruited,person):
    recruited.append(Catalog.to_member(person,recruited.size()))
   _render()
  )

func _review() -> void:
 var palette: Dictionary = Catalog.PALETTES[palette_index]
 var cover := _card(canvas,"YOUR BAND  /  "+band_name.to_upper(),"The first rehearsals are next. Nothing is guaranteed.")
 _label(cover,"GENRE  "+genre+"\nINFLUENCE  "+influence,15,UI.WHITE)
 var wordmark := PanelContainer.new()
 wordmark.add_theme_stylebox_override("panel",UI.style(Color(str(palette["secondary"])),14))
 cover.add_child(wordmark)
 var mark := _label(wordmark,band_name.to_upper(),30,Color(str(palette["primary"])))
 mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var roster := _card(canvas,"THE MEMBERS","These are the people who will share the cost, pressure and earnings of this career.")
 for member in recruited:
  var line := HBoxContainer.new()
  roster.add_child(line)
  var avatar := Portrait.new()
  avatar.custom_minimum_size = Vector2(70,84)
  avatar.set_character(str(member.get("candidate_id","")),str(member["name"]),Genres.normalize(genre))
  line.add_child(avatar)
  var details := VBoxContainer.new()
  line.add_child(details)
  _label(details,str(member["name"])+"  /  "+str(member["role"]),15,UI.WHITE)
  _label(details,str(member["trait"]),12,UI.MUTED)
 var economy := _card(canvas,"REAL CONSEQUENCES","Everyone expects their share of the earnings. Extra members can broaden the sound, but increase outing costs and split fees further.")
 _label(economy,"%d MEMBERS   /   APPROX. %d%% EACH" % [recruited.size(),Catalog.split_per_member(recruited.size())],16,UI.AMBER)
 if not Catalog.viable(recruited):
  _label(economy,"LINEUP INCOMPLETE — RECRUIT A RHYTHM PLAYER AND AT LEAST TWO MEMBERS",13,UI.AMBER)

func _go(index: int) -> void:
 step = clampi(index,0,2)
 _render()

func _advance() -> void:
 if step == 0:
  band_name = title_entry.text.strip_edges()
  genre = genre_select.get_item_text(genre_select.selected)
  influence = influence_select.get_item_text(influence_select.selected)
  if band_name.is_empty():
   feedback.text = "CHOOSE A BAND NAME FIRST."
   return
 elif step == 1 and not Catalog.viable(recruited):
  feedback.text = "RECRUIT AT LEAST TWO MEMBERS, INCLUDING A DRUMMER OR MULTI-INSTRUMENTALIST."
  return
 if step < 2:
  _go(step+1)
 else:
  _create_band()

func _create_band() -> void:
 if not Catalog.viable(recruited):
  feedback.text = "THE LINEUP NEEDS A RHYTHM PLAYER."
  return
 var roster: Array = []
 for i in range(recruited.size()):
  var member: Dictionary = recruited[i].duplicate(true)
  member["id"] = i
  roster.append(member)
 var palette: Dictionary = Catalog.PALETTES[palette_index]
 var band := {"name":band_name,"genre":genre,"influence":influence,"members":roster,
  "palette":palette.duplicate(true),"logo_style":Catalog.LOGOS[logo_index],"formation_version":2}
 var file := FileAccess.open(BAND_PATH,FileAccess.WRITE)
 if file == null:
  feedback.text = "COULD NOT SAVE YOUR BAND."
  return
 file.store_string(JSON.stringify(band,"\t"))
 file.close()
 if FileAccess.file_exists(SAVE_PATH):
  var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
  if err != OK:
   feedback.text = "COULD NOT CLEAR PREVIOUS CAREER."
   return
 get_tree().change_scene_to_file("res://tour_intro.tscn")

func _label(parent: Node, value: String, size: int, colour: Color) -> Label:
 var label := Label.new()
 label.text = value
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 label.add_theme_color_override("font_color",colour)
 parent.add_child(label)
 return label
