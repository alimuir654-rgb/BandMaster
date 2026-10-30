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
 column.add_child(_label("Next step: give this band a name. Naming and logo screens are not yet wired in this C27 checkpoint.",14))
 column.add_child(_button("BACK TO MENU",_home,"tab","MilestoneMenuAction"))
 var tail := Control.new()
 tail.size_flags_vertical = Control.SIZE_EXPAND_FILL
 root.add_child(tail)
