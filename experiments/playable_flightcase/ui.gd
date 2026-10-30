extends Control
signal lineup_confirmed
signal back_requested
## C26 player-facing isolated scene. Existing photographic flightcase controls,
## original inert meters and genuine career rules; no flattened clickable mockup.
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Recap = preload("res://experiments/playable_flightcase/rehearsal_recap.gd")
var game = Game.new()
var onboarding_state = null
var opening_owner = null
var role: String = "Singer"
var selected_index := 2
var idea_index := 0
var form_index := 0
var leader_index := 0
var song_title := "THE LAST BUS HOME"
var last_message := "Build a band. Talent points are separate from your cash."
var recap_expanded := true
var look := "flightcase"

func _ready() -> void:
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 get_viewport().size_changed.connect(_rebuild)
 _rebuild()

func _clear() -> void:
 for child in get_children():
  remove_child(child)
  child.queue_free()

func _label(content: String, points: int = 16) -> Label:
 var label: Label = Kit.label(content,look,points)
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return label

func _box() -> VBoxContainer:
 var box := VBoxContainer.new()
 box.add_theme_constant_override("separation",8)
 box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return box

func _panel(body: Control, kind := "panel") -> PanelContainer:
 var panel: PanelContainer = Kit.frame(look,kind)
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.add_child(body)
 return panel

func _button(title: String, action: Callable, family: String = "action") -> Button:
 var button: Button = Kit.button(title,look,family)
 button.pressed.connect(action)
 return button

func _rebuild() -> void:
 if not is_inside_tree():
  return
 _clear()
 var size_now: Vector2 = get_viewport_rect().size
 var mobile: bool = size_now.x < 840 or size_now.x < size_now.y
 var bg := TextureRect.new()
 bg.texture = load("res://components/control_atlas/art/case_surface.png")
 bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 bg.stretch_mode = TextureRect.STRETCH_SCALE
 bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 bg.modulate = Color(0.52,0.57,0.61)
 add_child(bg)
 var outer := MarginContainer.new()
 outer.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 for side in ["left","top","right","bottom"]:
  outer.add_theme_constant_override("margin_"+side,12 if mobile else 20)
 add_child(outer)
 var root_box := _box()
 root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
 outer.add_child(root_box)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 var title := _label("LIVIN' THE DREAM",26 if not mobile else 21)
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 var visible_remaining: int = int(onboarding_state.remaining()) if onboarding_state != null else game.remaining()
 var budget := _label("TALENT %d / %d" % [visible_remaining,Base.MAX_TALENT] if game.phase=="recruit" else "DAY %d   £%d" % [int(game.career.get("tour_day",1)),int(game.career.get("cash",0))],16)
 budget.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 header.add_child(budget)
 root_box.add_child(header)
 var status := _label(last_message,14)
 status.custom_minimum_size.y = 32
 status.add_theme_color_override("font_color",Color("f0c78b"))
 root_box.add_child(status)
 if onboarding_state != null and game.phase == "recruit":
  var back := _button("‹  CHANGE GENRE",func(): back_requested.emit(),"tab")
  back.name = "RecruitBackAction"
  root_box.add_child(back)
 if game.phase == "recruit":
  _recruit_page(root_box,mobile)
 else:
  _practice_page(root_box,mobile)

func _recruit_page(root_box: VBoxContainer, mobile: bool) -> void:
 var tabs := GridContainer.new()
 tabs.columns = 3 if mobile else 5
 tabs.add_theme_constant_override("h_separation",5)
 tabs.add_theme_constant_override("v_separation",4)
 root_box.add_child(tabs)
 for name in Base.ROLE_TABS:
  var item: Button = _button(str(name).to_upper(),_change_role.bind(str(name)),"tab")
  item.toggle_mode = true
  item.button_pressed = str(name)==role
  tabs.add_child(item)
 var choices: Array = game.choices(role)
 if choices.is_empty():
  root_box.add_child(_label("No candidates for this role."))
  return
 selected_index = clampi(selected_index,0,choices.size()-1)
 var person: Dictionary = choices[selected_index]
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 root_box.add_child(scroll)
 var content: BoxContainer = _box() if mobile else HBoxContainer.new()
 if not mobile:
  content.add_theme_constant_override("separation",12)
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(content)
 var detail := _box()
 detail.custom_minimum_size.x = 0 if mobile else 390
 content.add_child(_panel(detail,"portrait"))
 var browse := HBoxContainer.new()
 browse.add_theme_constant_override("separation",6)
 detail.add_child(browse)
 var previous: Button = _button("‹",_move_candidate.bind(-1),"browse")
 previous.custom_minimum_size.x = 48
 browse.add_child(previous)
 var name := _label("%s  •  %s" % [str(person["name"]).to_upper(),role.to_upper()],19)
 name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 browse.add_child(name)
 var following: Button = _button("›",_move_candidate.bind(1),"browse")
 following.custom_minimum_size.x = 48
 browse.add_child(following)
 var image_path := str(person.get("portrait_preview",""))
 if image_path.is_empty() or not ResourceLoader.exists(image_path):
  detail.add_child(_label("ARCHIVE PROFILE  •  PORTRAIT PROVISIONAL",13))
 else:
  var image := TextureRect.new()
  image.texture = load(image_path)
  image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  image.custom_minimum_size = Vector2(210,205)
  image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  image.mouse_filter = Control.MOUSE_FILTER_IGNORE
  detail.add_child(image)
 var stats: Array = Base.stats_for(person,role)
 var captions: Array = Base.labels_for(role)
 for i in range(stats.size()):
  var line := HBoxContainer.new()
  line.add_theme_constant_override("separation",8)
  detail.add_child(line)
  var label := _label(str(captions[i]).to_upper(),13)
  label.custom_minimum_size.x = 90
  line.add_child(label)
  var meter := Kit.PassiveMeter.new(look,int(stats[i]))
  meter.name = "PassiveMeter"+str(i)
  line.add_child(meter)
  line.add_child(_label(str(int(stats[i])),14))
 var cost := Base.incremental_cost(game.roster,person)
 var recruited := Base.contains(game.roster,str(person["id"]))
 var action: Button = _button("REMOVE FROM BAND" if recruited else "RECRUIT  •  %d TALENT" % cost,_remove.bind(str(person["id"])) if recruited else _recruit.bind(str(person["id"])))
 action.name = "RecruitAction" if not recruited else "RemoveAction"
 action.disabled = false if recruited else not (bool(onboarding_state.can_recruit(str(person["id"]))) if onboarding_state != null else Base.can_add(game.roster,person))
 # Keep the portrait and six passive meters scrollable, with the native
 # recruit/remove decision persistently visible underneath the dossier.
 var aside := _box()
 aside.custom_minimum_size.x = 0 if mobile else 320
 aside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_child(_panel(aside,"panel"))
 aside.add_child(_label("THE PERSON",19))
 aside.add_child(_label("%s • %s" % [str(person.get("town","UK")),str(person.get("personality","Musician"))],15))
 aside.add_child(_label(str(person.get("story","An aspiring musician looking for a band.")),14))
 aside.add_child(_label("STRENGTH • "+str(person.get("strength","Still developing")),14))
 aside.add_child(_label("FRICTION • "+str(person.get("friction","Unknown")),14))
 if person.has("collaboration"):
  aside.add_child(_label("RELIABILITY %d/10   COLLABORATION %d/10" % [int(person["reliability"]),int(person["collaboration"])],14))
 aside.add_child(_label("YOUR BAND",18))
 for member in game.roster:
  aside.add_child(_label("• %s   %s" % [str(member["name"]),str(member.get("primary_role",(member["roles"] as Array)[0]))],14))
 if onboarding_state != null:
  aside.add_child(_label("LEAD VOCALS  •  ASSIGN ONE BAND MEMBER",16))
  for member in game.roster:
   if onboarding_state.vocal_scores(member).size() == 6:
    var chosen: bool = str(onboarding_state.lead_vocal_id) == str(member["id"])
    var extra: int = 0 if (member["roles"] as Array).has("Singer") else 5
    var vocal: Button = _button(("✓  " if chosen else "") + str(member["name"]) + ("  +%d TALENT" % extra if extra > 0 else "  INCLUDED"),_choose_vocal.bind(str(member["id"])),"tab")
    vocal.disabled = chosen
    aside.add_child(vocal)
  aside.add_child(_label("Fifth member +6, sixth +12 additional. Vocalist doubling an instrument adds 5. Talent points buy ability and options, not cash.",13))
  aside.add_child(_label("TALENT USED %d/200  •  %s" % [200-int(onboarding_state.remaining()),"READY" if bool(onboarding_state.ready()) else str(onboarding_state.missing())],14))
 else:
  aside.add_child(_label("TALENT USED %d/200  •  %s" % [game.spent(),"READY" if game.can_start() else Base.missing(game.roster)],14))
 var start: Button = _button("COMPLETE THE LINEUP" if onboarding_state != null else "START YOUR FIRST PRACTICE",_launch)
 start.name = "StartAction"
 start.disabled = not (bool(onboarding_state.ready()) if onboarding_state != null else game.can_start())
 # Real source-backed actions live outside the scroll on every viewport.
 var dock: BoxContainer = _box() if mobile else HBoxContainer.new()
 dock.name = "RecruitDecisionDock"
 dock.add_theme_constant_override("separation",8)
 if mobile:
  dock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 else:
  dock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
  dock.custom_minimum_size.x = 760.0
 root_box.add_child(dock)
 action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 dock.add_child(action)
 if not start.disabled:
  start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  if mobile:
   start.text = "COMPLETE LINEUP"
  dock.add_child(start)

func _practice_page(root_box: VBoxContainer, mobile: bool) -> void:
 var scroll := ScrollContainer.new()
 scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 root_box.add_child(scroll)
 var content: BoxContainer = _box() if mobile else HBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if not mobile:
  content.add_theme_constant_override("separation",12)
 scroll.add_child(content)
 var actions := _box()
 actions.custom_minimum_size.x = 0 if mobile else 470
 content.add_child(_panel(actions))
 if opening_owner != null:
  actions.add_child(_button("‹ MENU",func(): back_requested.emit(),"tab"))
 var saved_report: Dictionary = game.career.get("last_rehearsal_outcome",{})
 if mobile and not saved_report.is_empty():
  actions.add_child(_recap_section(saved_report))
 actions.add_child(_label("FIRST PRACTICE",22))
 actions.add_child(_label("SONGS %d  •  READINESS %d/100  •  MORALE %d  •  TENSION %d" % [int(game.career.get("songs",0)),int(game.career.get("readiness",0)),int(game.career.get("morale",0)),int(game.career.get("tension",0))],14))
 actions.add_child(_label("WRITE AN ORIGINAL  •  SESSION %d OF 3" % [int(game.career.get("song_draft_progress",0))+1],18))
 actions.add_child(_label("IDEA",13))
 var ideas := Kit.ChoiceStrip.new(look,PackedStringArray(["Riff","Lyric","Groove"]),idea_index)
 ideas.selection_changed.connect(func(index: int): idea_index=index)
 actions.add_child(ideas)
 actions.add_child(_label("ARRANGEMENT",13))
 var forms := Kit.ChoiceStrip.new(look,PackedStringArray(["Verse / Chorus","Slow Build","Loose Jam"]),form_index)
 forms.selection_changed.connect(func(index: int): form_index=index)
 actions.add_child(forms)
 actions.add_child(_label("SONG TITLE",13))
 var entry := LineEdit.new()
 entry.name = "SongTitle"
 entry.text = song_title
 entry.custom_minimum_size.y = 48
 entry.text_changed.connect(func(value: String): song_title=value)
 entry.add_theme_font_size_override("font_size",17)
 actions.add_child(entry)
 var leader_names := PackedStringArray()
 for p in game.career.get("members",[]):
  leader_names.append(str(p.get("name","Musician")))
 var lead := Kit.BrowseSelector.new(look,leader_names)
 lead.selected = clampi(leader_index,0,maxi(0,leader_names.size()-1))
 lead.call("_refresh")
 lead.selection_changed.connect(func(index: int,_item: String): leader_index=index)
 actions.add_child(_label("SESSION LEADER",13))
 actions.add_child(lead)
 var write: Button = _button("WRITE SESSION  •  %d/3" % [int(game.career.get("song_draft_progress",0))+1],_write)
 write.name = "WriteAction"
 actions.add_child(write)
 var rehearse: Button = _button("REHEARSE  •  £15",_rehearse)
 rehearse.name = "RehearseAction"
 rehearse.disabled = int(game.career.get("cash",0))<15
 actions.add_child(rehearse)
 actions.add_child(_button("CLEAR THE AIR",_connect))
 var info := _box()
 info.custom_minimum_size.x = 0 if mobile else 350
 content.add_child(_panel(info))
 if not mobile and not saved_report.is_empty():
  info.add_child(_recap_section(saved_report))
 info.add_child(_label("THE BAND",19))
 for p in game.career.get("members",[]):
  info.add_child(_label("%s  •  %s   morale %d" % [str(p.get("name","")),str(p.get("role","")),int(p.get("morale",0))],14))
 info.add_child(_label("SETLIST",18))
 if game.career.get("song_catalogue",[]).is_empty():
  info.add_child(_label("No finished original songs. Write three sessions.",14))
 else:
  for song in game.career.get("song_catalogue",[]):
   info.add_child(_label("%s  •  quality %d" % [str(song.get("title","UNTITLED")),int(song.get("quality",0))],14))
 info.add_child(_label("GIG PREP: Build a complete original and rehearse. Booking isn't available in this isolated proof yet.",14))
 info.add_child(_button("SAVE SANDBOX",_save,"tab"))
 info.add_child(_button("LOAD SANDBOX",_load,"tab"))


# A recap is a VIEW of an already settled, saved S38 result. Buttons never
# call the practice resolver and cannot award the same improvement again.
func _recap_section(saved_report: Dictionary) -> Control:
 var view: Dictionary = Recap.present(saved_report,game.career.get("members",[]))
 var wrapper := _box()
 wrapper.name = "RehearsalRecapSection"
 if view.is_empty():
  wrapper.add_child(_label("Last session report is unavailable.",13))
  return wrapper
 var toggle: Button = _button("HIDE SESSION NOTES" if recap_expanded else "VIEW LAST SESSION NOTES ›",_toggle_recap,"tab")
 toggle.name = "RecapToggleAction"
 wrapper.add_child(toggle)
 if not recap_expanded:
  wrapper.add_child(_label(str(view.get("verdict","Session completed"))+"  •  "+str(view.get("heading","SESSION")),14))
  return wrapper
 var body := _box()
 body.add_child(_label("AFTER THE SESSION  /  FROM THE ROOM",13))
 body.add_child(_label(str(view.get("heading","SESSION")),15))
 var verdict: Label = _label(str(view.get("verdict","Session completed")),22)
 verdict.name = "RecapVerdict"
 verdict.add_theme_color_override("font_color",Color("f0c78b"))
 body.add_child(verdict)
 body.add_child(_label(str(view.get("reason","")),13))
 body.add_child(_label("WHAT ACTUALLY CHANGED",14))
 var rows: Array = view.get("metric_rows",[])
 for row in rows:
  if not row is Dictionary:
   continue
  var number: Label = _label(str(row.get("text","")),13)
  number.name = "RecapMetric_"+str(row.get("key",""))
  body.add_child(number)
 body.add_child(_label(str(view.get("footnote","")),12))
 body.add_child(_label("FROM THE BAND",14))
 for voice in view.get("reactions",[]):
  if not voice is Dictionary:
   continue
  var person: Label = _label(str(voice.get("name","Musician"))+"  —  “"+str(voice.get("quote",""))+"”",13)
  person.name = "RecapMember_"+str(voice.get("candidate_id",""))
  body.add_child(person)
  body.add_child(_label("    "+str(voice.get("effects","")),12))
 body.add_child(_label("NEXT: "+str(view.get("next_step","")),13))
 var panel: PanelContainer = _panel(body)
 panel.name = "RehearsalRecapPanel"
 wrapper.add_child(panel)
 return wrapper

func _toggle_recap() -> void:
 recap_expanded = not recap_expanded
 _rebuild()

func _change_role(value: String) -> void:
 role = value
 selected_index = 0
 _rebuild()
func _move_candidate(delta: int) -> void:
 var items: Array = game.choices(role)
 selected_index = posmod(selected_index+delta,items.size())
 _rebuild()
func _recruit(id: String) -> void:
 last_message = str(onboarding_state.recruit(id)["message"] if onboarding_state != null else game.recruit(id)["message"])
 _rebuild()
func _remove(id: String) -> void:
 last_message = str(onboarding_state.remove_member(id)["message"] if onboarding_state != null else game.remove_member(id)["message"])
 _rebuild()
func _choose_vocal(id: String) -> void:
 if onboarding_state == null:
  return
 last_message = str(onboarding_state.choose_vocal(id)["message"])
 _rebuild()
func _launch() -> void:
 if onboarding_state != null:
  var result: Dictionary = onboarding_state.confirm_lineup()
  last_message = str(result.get("message",""))
  if bool(result.get("ok",false)):
   lineup_confirmed.emit()
  else:
   _rebuild()
 else:
  last_message = str(game.launch()["message"])
  _rebuild()
func _write() -> void:
 var result: Dictionary = game.write_session(str(["Riff","Lyric","Groove"][idea_index]),str(["Verse / Chorus","Slow Build","Loose Jam"][form_index]),song_title,leader_index)
 last_message = str(result["message"])
 if bool(result.get("ok",false)):
  recap_expanded = true
 if opening_owner != null and bool(result.get("ok",false)):
  opening_owner.save_draft()
 _rebuild()
func _outcome_line(result: Dictionary) -> String:
 if not bool(result.get("ok",false)) or not result.has("outcome"):
  return str(result.get("message",""))
 var report: Dictionary = result["outcome"]
 var metrics: Dictionary = report.get("metrics",{})
 var key := "cohesion" if str(report.get("focus",""))=="connect" else "readiness"
 var title := "cohesion" if key=="cohesion" else "set"
 var value: int = int(metrics.get(key,{}).get("delta",0))
 var tension: int = int(metrics.get("tension",{}).get("delta",0))
 return "%s. %s %s; tension %s." % [str(report.get("verdict","Session done")),title,("+" if value>0 else "")+str(value),("+" if tension>0 else "")+str(tension)]

func _rehearse() -> void:
 var result: Dictionary = game.rehearse()
 last_message = _outcome_line(result)
 if bool(result.get("ok",false)):
  recap_expanded = true
 if opening_owner != null and bool(result.get("ok",false)):
  opening_owner.save_draft()
 _rebuild()
func _connect() -> void:
 var result: Dictionary = game.clear_air()
 last_message = _outcome_line(result)
 if bool(result.get("ok",false)):
  recap_expanded = true
 if opening_owner != null and bool(result.get("ok",false)):
  opening_owner.save_draft()
 _rebuild()
func _save() -> void:
 var okay: bool = bool(opening_owner.save_draft()) if opening_owner != null else game.save_sandbox()
 last_message = "Sandbox saved." if okay else "Sandbox save failed."
 _rebuild()
func _load() -> void:
 var okay: bool = bool(opening_owner.load_draft()) if opening_owner != null else game.load_sandbox()
 if okay and opening_owner != null:
  game = opening_owner.game
 if okay:
  recap_expanded = true
 last_message = "Sandbox restored." if okay else "No valid sandbox save."
 _rebuild()
