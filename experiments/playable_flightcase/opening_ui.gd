extends Control
## C27 opening; uses existing authentic flight-case UI and controls.
const Model = preload("res://experiments/playable_flightcase/opening_state.gd")
const Recruit = preload("res://experiments/playable_flightcase/ui.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
var setup = Model.new()
var showing_menu := true
var settings_open := false
var muted := false
var notice := ""
var look := "flightcase"
var free_name: String = ""
var chosen_intent: String = "Raw"
var response: String = ""

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_render)
 _render()

func _erase() -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()

func _label(s: String,size: int = 16) -> Label:
 var l: Label = Kit.label(s,look,size)
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return l

func _button(s: String,fn: Callable,family: String = "action",name: String = "") -> Button:
 var b: Button = Kit.button(s,look,family)
 if not name.is_empty():
  b.name = name
 b.pressed.connect(fn)
 return b

func _column() -> VBoxContainer:
 var v := VBoxContainer.new()
 v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 v.add_theme_constant_override("separation",12)
 return v

func _make_shell() -> VBoxContainer:
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.modulate = Color(0.52,0.57,0.61)
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 add_child(bg)
 var outer := MarginContainer.new()
 outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 var narrow := size.x < 720
 for side in ["left","top","right","bottom"]:
  outer.add_theme_constant_override("margin_"+side,16 if narrow else 36)
 add_child(outer)
 var col := _column()
 col.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(col)
 return col

func _render() -> void:
 if not is_inside_tree():
  return
 _erase()
 if showing_menu or setup.screen == "menu":
  _menu()
 elif setup.screen == "genre":
  _genre()
 elif setup.screen == "recruit":
  _recruit()
 elif setup.screen == "formed":
  _formed()
 elif setup.screen == "name":
  _name()
 elif setup.screen == "name_milestone":
  _milestone_two()
 elif setup.screen == "identity":
  _identity()
 elif setup.screen == "complete":
  _summary()
 elif setup.screen == "play":
  _practice()
 else:
  showing_menu = true
  _menu()

func _menu() -> void:
 var root := _make_shell()
 var spacer := Control.new()
 spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(spacer)
 var heading := Kit.frame(look,"portrait")
 root.add_child(heading)
 var column := _column()
 heading.add_child(column)
 var eyebrow := _label("THE MUSIC BUSINESS IS CALLING",14)
 eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(eyebrow)
 var brand := _label("LIVIN' THE DREAM",42 if size.x>=720 else 32)
 brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(brand)
 var tagline := _label("Three chords. A borrowed van. Something to prove.",16)
 tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(tagline)
 column.add_child(_button("NEW BAND",_new_band,"action","NewBandAction"))
 var carry: Button = _button("CONTINUE",_continue,"action","ContinueAction")
 carry.disabled = not setup.has_valid_draft()
 carry.tooltip_text = "No valid band draft to resume." if carry.disabled else "Resume your unfinished band."
 column.add_child(carry)
 if carry.disabled:
  var reason := _label("Continue unlocks when a band draft has been saved.",13)
  reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  column.add_child(reason)
 column.add_child(_button("SETTINGS",_toggle_settings,"tab","SettingsAction"))
 if not OS.has_feature("mobile"):
  column.add_child(_button("QUIT",func(): get_tree().quit(),"tab","QuitAction"))
 if settings_open:
  var settings := Kit.frame(look,"panel")
  root.add_child(settings)
  var panel := _column()
  settings.add_child(panel)
  panel.add_child(_label("SETTINGS — AUDIO",18))
  panel.add_child(_button("MASTER SOUND: MUTED" if muted else "MASTER SOUND: ON",_toggle_sound,"tab","SoundAction"))
 if not notice.is_empty():
  root.add_child(_label(notice,14))
 var tail := Control.new()
 tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(tail)

func _new_band() -> void:
 if setup.has_valid_draft():
  var dialog: Control = Kit.dialog("Start a new band?","This replaces your saved opening draft. This cannot be undone.",look)
  dialog.confirm_text = "REPLACE DRAFT"
  dialog.cancel_text = "KEEP BAND"
  add_child(dialog)
  dialog.completed.connect(func(yes: bool):
   if yes:
    _begin_new()
   dialog.queue_free())
  dialog.call_deferred("open_modal")
 else:
  _begin_new()

func _begin_new() -> void:
 if not setup.begin_new():
  notice = "Couldn't save the new band draft."
  _render()
  return
 showing_menu = false
 settings_open = false
 notice = ""
 _render()

func _continue() -> void:
 if setup.load_draft():
  showing_menu = false
  settings_open = false
  _render()
 else:
  notice = "No valid saved draft was found."
  _render()

func _toggle_settings() -> void:
 settings_open = not settings_open
 _render()
func _toggle_sound() -> void:
 muted = not muted
 AudioServer.set_bus_mute(0,muted)
 _render()
func _home() -> void:
 showing_menu = true
 _render()

func _genre() -> void:
 var root := _make_shell()
 var heading := _label("01 / CHOOSE YOUR SOUND",24)
 root.add_child(heading)
 root.add_child(_label("Your genre sets the starting direction. It does not restrict who you may audition.",14))
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 root.add_child(scroll)
 var grid := GridContainer.new()
 grid.columns = 1 if size.x < 720 else 2
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",10)
 grid.add_theme_constant_override("v_separation",10)
 scroll.add_child(grid)
 for item in Base.genres():
  var name: String = str(item)
  var card := Kit.frame(look,"panel")
  card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  grid.add_child(card)
  var details := _column()
  card.add_child(details)
  var button: Button = _button(("✓  " if setup.game.genre == name else "") + name.to_upper(),_choose_genre.bind(name),"tab","Genre_"+name.replace(" ","_").replace("/","_"))
  button.toggle_mode = true
  button.button_pressed = setup.game.genre == name
  details.add_child(button)
  var descriptor: Dictionary = Formation.GENRES.get(name,{})
  details.add_child(_label(str(descriptor.get("description","Build a sound of your own.")),14))
  details.add_child(_label("Strength: "+str(descriptor.get("strength","Your first gigs")),12))
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation",12)
 root.add_child(footer)
 footer.add_child(_button("‹ MENU",_home,"tab","GenreBackAction"))
 footer.add_child(_button("FIND YOUR PEOPLE ›",_to_recruit,"action","GenreNextAction"))

func _choose_genre(value: String) -> void:
 setup.set_genre(value)
 _render()
func _to_recruit() -> void:
 if setup.to_recruit():
  _render()

func _recruit() -> void:
 var child = Recruit.new()
 child.game = setup.game
 child.onboarding_state = setup
 child.lineup_confirmed.connect(_on_lineup)
 child.back_requested.connect(_back_genre)
 add_child(child)
 child.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

func _back_genre() -> void:
 setup.back_to_genre()
 _render()
func _on_lineup() -> void:
 _render()

func _formed() -> void:
 var root := _make_shell()
 var filler := Control.new()
 filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(filler)
 var panel := Kit.frame(look,"portrait")
 root.add_child(panel)
 var column := _column()
 panel.add_child(column)
 column.add_child(_label("MILESTONE 01  /  THE LINEUP",16))
 column.add_child(_label("YOU'VE GOT A BAND.",32 if size.x>=720 else 25))
 column.add_child(_label("Guitar. Bass. Drums. Somebody's brave enough to sing.",16))
 for person in setup.game.roster:
  var suffix := "  •  LEAD VOCALS" if str(person["id"]) == setup.lead_vocal_id else ""
  column.add_child(_label(str(person["name"])+" — "+str(person.get("primary_role",(person["roles"] as Array)[0]))+suffix,16))
 column.add_child(_label("TALENT %d / 200  •  %d REMAINING" % [200-setup.remaining(),setup.remaining()],16))
 column.add_child(_button("NAME THE BAND ›",_start_naming,"action","MilestoneNextAction"))
 column.add_child(_button("BACK TO MENU",_home,"tab","MilestoneMenuAction"))
 var tail := Control.new()
 tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(tail)

func _scroll_body(root: VBoxContainer) -> VBoxContainer:
 var scroll := ScrollContainer.new()
 scroll.horizontal_scroll_mode = Control.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(scroll)
 var body: VBoxContainer = _column()
 scroll.add_child(body)
 return body

func _start_naming() -> void:
 if setup.start_naming():
  _render()

func _name() -> void:
 var root: VBoxContainer = _make_shell()
 root.add_child(_label("02 / NAME THE BAND",24))
 root.add_child(_label("This is about your bandmates' taste, not an objective judgement of your name.",14))
 var body: VBoxContainer = _scroll_body(root)
 body.add_child(_label("THREE IDEAS",18))
 for entry in setup.suggested_names():
  var suggestion: Dictionary = entry
  var title: String = str(suggestion["name"])
  var intent: String = str(suggestion["intent"])
  var option: Button = _button(title+"  /  "+intent.to_upper(),_submit.bind(title,intent),"tab")
  option.disabled = not setup.name_offer.is_empty()
  body.add_child(option)
 body.add_child(_label("OR WRITE YOUR OWN",18))
 var field := LineEdit.new()
 field.name = "FreeBandName"
 field.text = free_name
 field.max_length = 36
 field.custom_minimum_size.y = 48
 field.placeholder_text = "Band name (2–36 characters)"
 field.text_changed.connect(func(v: String): free_name=v)
 body.add_child(field)
 body.add_child(_label("WHAT ARE YOU GOING FOR?",14))
 var intent_grid := GridContainer.new()
 intent_grid.columns = 2
 body.add_child(intent_grid)
 for value in ["Raw","Dark","Playful","Dreamy"]:
  var tone: String = value
  var btn: Button = _button(("✓ " if chosen_intent==tone else "")+tone.to_upper(),_set_intent.bind(tone),"tab")
  btn.disabled = not setup.name_offer.is_empty()
  intent_grid.add_child(btn)
 var submit: Button = _button("ASK THE BAND",_submit_free,"action","NameSubmitAction")
 submit.disabled = not setup.name_offer.is_empty()
 body.add_child(submit)
 if not response.is_empty():
  body.add_child(_label(response,14))
 if not setup.name_offer.is_empty():
  body.add_child(_label("BAND REACTIONS  /  "+setup.name_offer.to_upper(),18))
  for opinion in setup.name_reactions():
   var feeling: Dictionary = opinion
   var card: PanelContainer = Kit.frame(look,"ticket")
   body.add_child(card)
   card.add_child(_label(str(feeling["name"])+" — "+str(feeling["reaction"]).to_upper()+"\n"+str(feeling["reason"]),14))
  var rethink: Button = _button("ONE MORE IDEA (FREE)",_rethink,"tab","NameRethinkAction")
  rethink.disabled = setup.name_revisions>=1
  body.add_child(rethink)
  body.add_child(_button("LOCK THE NAME ›",_lock,"action","NameLockAction"))
 body.add_child(_button("BACK TO MENU",_home,"tab"))

func _set_intent(v: String) -> void:
 chosen_intent = v
 call_deferred("_render")
func _submit_free() -> void:
 _submit(free_name,chosen_intent)
func _submit(title: String,intent: String) -> void:
 var result: Dictionary = setup.submit_name(title,intent)
 response = str(result.get("message",""))
 _render()
func _rethink() -> void:
 var result: Dictionary = setup.rethink_name()
 response = str(result.get("message",""))
 free_name = ""
 _render()
func _lock() -> void:
 var result: Dictionary = setup.lock_name()
 response = str(result.get("message",""))
 _render()

func _milestone_two() -> void:
 var root: VBoxContainer = _make_shell()
 var gap := Control.new()
 gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(gap)
 var card: PanelContainer = Kit.frame(look,"portrait")
 root.add_child(card)
 var body: VBoxContainer = _column()
 card.add_child(body)
 body.add_child(_label("MILESTONE 02 / THE NAME",16))
 body.add_child(_label(setup.name_locked.to_upper(),31 if size.x>=720 else 25))
 var delta: int = int(setup.name_delta)
 body.add_child(_label("+3 band morale: everyone loves it." if delta==3 else ("−2 morale: a rough consensus." if delta<0 else "Mixed but workable. No morale change."),16))
 body.add_child(_label("Any consequence is applied once.",13))
 body.add_child(_button("LOGO & VIBE ›",_start_identity,"action","NameMilestoneNextAction"))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
 var bottom := Control.new()
 bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(bottom)
func _start_identity() -> void:
 if setup.start_identity():
  _render()

func _identity() -> void:
 var root: VBoxContainer = _make_shell()
 root.add_child(_label("03 / THE LOOK",24))
 root.add_child(_label("Choose a wordmark, palette and attitude. These choices are cosmetic.",14))
 var body: VBoxContainer = _scroll_body(root)
 var preview: PanelContainer = Kit.frame(look,"portrait")
 body.add_child(preview)
 var content: VBoxContainer = _column()
 preview.add_child(content)
 content.add_child(_label("LIVE PREVIEW  /  "+setup.logo.to_upper(),14))
 var logo_text: String = setup.name_locked.to_upper()
 if setup.logo=="Monogram":
  logo_text = ""
  for part in setup.name_locked.split(" ",false):
   if not part.is_empty():
    logo_text+=part.substr(0,1).to_upper()
  logo_text=logo_text.substr(0,6)
 elif setup.logo=="Stamp":
  logo_text="— "+logo_text+" —"
 var mark: Label = _label(logo_text,28 if size.x>=720 else 22)
 mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(mark)
 content.add_child(_label(setup.palette+"  /  "+setup.vibe,13))
 for family in ["logo","palette","vibe"]:
  body.add_child(_label(family.to_upper(),17))
  var options: Array = Model.LOGOS if family=="logo" else (Model.PALETTES if family=="palette" else Model.VIBES)
  var selected: String = setup.logo if family=="logo" else (setup.palette if family=="palette" else setup.vibe)
  var buttons := GridContainer.new()
  buttons.columns=2 if size.x<720 else 3
  body.add_child(buttons)
  for item in options:
   var value: String = str(item)
   buttons.add_child(_button(("✓ " if value==selected else "")+value.to_upper(),_design.bind(family,value),"tab"))
 body.add_child(_button("FINISH THE BAND ›",_finish,"action","IdentityFinishAction"))
 if not response.is_empty():
  body.add_child(_label(response,14))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
func _design(family: String,value: String) -> void:
 var mark: String = value if family=="logo" else setup.logo
 var palette: String = value if family=="palette" else setup.palette
 var vibe: String = value if family=="vibe" else setup.vibe
 setup.set_identity(mark,palette,vibe)
 call_deferred("_render")
func _finish() -> void:
 var result: Dictionary = setup.finish_identity()
 response = str(result.get("message",""))
 _render()

func _summary() -> void:
 var root: VBoxContainer = _make_shell()
 root.add_child(_label("YOU'VE STARTED SOMETHING",24))
 var body: VBoxContainer = _scroll_body(root)
 var card: PanelContainer = Kit.frame(look,"portrait")
 body.add_child(card)
 var info: VBoxContainer = _column()
 card.add_child(info)
 info.add_child(_label(setup.name_locked.to_upper(),30 if size.x>=720 else 25))
 info.add_child(_label(setup.game.genre+"  /  "+setup.vibe+"  /  "+setup.logo,14))
 for p in setup.game.roster:
  info.add_child(_label(str(p["name"])+(" — LEAD VOCALS" if str(p["id"])==setup.lead_vocal_id else " — "+str(p.get("primary_role","Musician"))),14))
 info.add_child(_label("TALENT REMAINING  "+str(setup.remaining()),16))
 info.add_child(_label("STARTING MORALE  "+str(setup.game.career.get("morale",55)),16))
 body.add_child(_button("FIRST PRACTICE ›",_start_playing,"action","StartPlayAction"))
 body.add_child(_button("BACK TO MENU",_home,"tab"))
func _start_playing() -> void:
 if setup.start_playing():
  _render()
func _practice() -> void:
 var panel = Recruit.new()
 panel.game = setup.game
 panel.opening_owner = setup
 panel.back_requested.connect(_home)
 add_child(panel)
 panel.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
