extends Control
## Read-only current-band print. No game, resolver, formation or save API.
signal closed
signal aborted
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Press = preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
const Mark = preload("res://experiments/playable_flightcase/band_mark.gd")
var layout_ready := false
var _career: Dictionary = {}
var _data: Dictionary = {}
var _reduced := false
var _closed := false
var _epoch := 0
var _shown := false
var _fade: Tween
var _fit_phase := 0
var _draw_serial := 0
var _consumed_draw := 0
var _settle_remaining := 0
var _body: Control
var _poster: VBoxContainer
var _scroll: ScrollContainer
var _back: Button

static func _text(value: Variant, fallback: String = "") -> String:
 return str(value) if value is String and not str(value).strip_edges().is_empty() else fallback

static func display_data(career: Dictionary) -> Dictionary:
 var band_name: String=_text(career.get("band_name"))
 var palette: String=_text(career.get("palette"))
 var result: Dictionary={"available":false,"name":band_name if not band_name.is_empty() else "YOUR BAND","name_recorded":not band_name.is_empty(),"logo":_text(career.get("logo"),"Wordmark"),"palette":palette,"vibe":_text(career.get("vibe")),"style":Style.effective(career.get(Style.KEY),palette),"members":[],"current_members":[],"lead_id":"","lead_name":"","reason":"Full-length artwork is not available for this saved lineup. Your current band is listed below."}
 var raw_members: Variant=career.get("members",[])
 if not raw_members is Array:return result
 var manifest: Dictionary={}
 if FileAccess.file_exists(Press.CAST_PATH):
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(Press.CAST_PATH))
  if parsed is Dictionary and parsed.get("people") is Dictionary:manifest=parsed["people"]
 var complete: bool=raw_members.size()>=1 and raw_members.size()<=6 and not band_name.is_empty()
 var seen: Dictionary={}
 var mapped: Array=[]
 var lead: String=_text(career.get("lead_vocal_candidate_id"))
 var lead_matches := 0
 for raw in raw_members:
  var person: Dictionary=raw if raw is Dictionary else {}
  var person_name: String=_text(person.get("name"),_text(raw,"Unnamed saved musician"))
  var role: String=_text(person.get("role"),"Role not recorded")
  var pid: String=_text(person.get("candidate_id"))
  result["current_members"].append({"name":person_name,"role":role,"candidate_id":pid,"status":_text(person.get("life_status"))})
  if not lead.is_empty() and pid==lead:
   lead_matches+=1
   result["lead_name"]=person_name
  var source: Dictionary=Cast.by_id(pid) if not pid.is_empty() else {}
  var entry: Variant=manifest.get(pid,{})
  var texture_path: String=_text(entry.get("texture")) if entry is Dictionary else ""
  if not raw is Dictionary or pid.is_empty() or seen.has(pid) or source.is_empty() or texture_path.is_empty() or not ResourceLoader.exists(texture_path):complete=false
  seen[pid]=true
  mapped.append({"id":pid,"name":person_name,"primary_role":role})
 if lead_matches==1:result["lead_id"]=lead
 else:result["lead_name"]=""
 result["available"]=complete
 if complete:result["members"]=mapped
 return result

func configure(career: Dictionary, reduced: bool = false) -> void:
 _career=career.duplicate(true)
 _reduced=reduced

func _ready() -> void:
 name="BandPosterView"
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 focus_mode=Control.FOCUS_NONE
 z_index=90
 _data=display_data(_career)
 add_child(C.background())
 var margin:=MarginContainer.new()
 margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
 add_child(margin)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 margin.add_child(column)
 var header:=HBoxContainer.new()
 header.name="BandPosterHeader"
 header.add_theme_constant_override("separation",12)
 column.add_child(header)
 header.add_child(C.brand(44.0))
 var words:=VBoxContainer.new()
 words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 words.add_theme_constant_override("separation",3)
 header.add_child(words)
 words.add_child(C.label("YOUR BAND",24))
 words.add_child(C.label("CURRENT LINEUP / SAVED LOOK",14))
 _body=Control.new()
 _body.name="BandPosterBody"
 _body.size_flags_vertical=Control.SIZE_EXPAND_FILL
 _body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _body.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _body.clip_contents=true
 column.add_child(_body)
 if bool(_data["available"]):
  _poster=Press.new()
  _poster.name="CurrentBandPoster"
  _poster.modulate.a=0.0
  _body.add_child(_poster)
 else:_build_fallback()
 _back=C.button("‹ BACK TO BAND","flightcase","action")
 _back.name="BandPosterBackAction"
 _back.pressed.connect(_close)
 column.add_child(_back)
 resized.connect(_queue_fit)
 _body.resized.connect(_queue_fit)
 visibility_changed.connect(_visibility_changed)
 _queue_fit()
 call_deferred("_take_focus")

func _build_fallback() -> void:
 _scroll=ScrollContainer.new()
 _scroll.name="BandPosterFallback"
 _scroll.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 _scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.follow_focus=true
 _body.add_child(_scroll)
 var list:=VBoxContainer.new()
 list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 list.mouse_filter=Control.MOUSE_FILTER_IGNORE
 list.add_theme_constant_override("separation",14)
 _scroll.add_child(list)
 var mark:=Mark.new()
 mark.name="BandPosterFallbackMark"
 mark.configure(str(_data["name"]),str(_data["logo"]) if bool(_data["name_recorded"]) else "Wordmark",_data["style"],28,true,true)
 list.add_child(mark)
 list.add_child(C.label(str(_data["reason"]),16))
 if (_data["current_members"] as Array).is_empty():list.add_child(C.label("No saved musicians are recorded.",16))
 for i in range(_data["current_members"].size()):
  var person: Dictionary=_data["current_members"][i]
  var text: Label=C.label(str(person["name"])+"  /  "+str(person["role"]),16)
  text.name="BandPosterSavedMember%d" % i
  list.add_child(text)
 var lead: Label=C.label("LEAD VOCALS  /  "+str(_data["lead_name"]) if not str(_data["lead_name"]).is_empty() else "LEAD VOCAL CREDIT UNAVAILABLE",16)
 lead.name="BandPosterSavedLead"
 list.add_child(lead)

func _queue_fit() -> void:
 if _closed:return
 layout_ready=false
 _epoch+=1
 _fit_phase=1
 _consumed_draw=_draw_serial
 if not RenderingServer.frame_post_draw.is_connected(_draw_completed):RenderingServer.frame_post_draw.connect(_draw_completed)
 set_process(true)

func _valid(epoch: int) -> bool:
 return not _closed and epoch==_epoch and is_inside_tree() and is_visible_in_tree()

func _draw_completed() -> void:
 _draw_serial+=1

func _process(_delta: float) -> void:
 if _closed or _fit_phase==0 or not is_visible_in_tree():
  _stop_layout_clock()
  return
 if _draw_serial<=_consumed_draw:return
 _consumed_draw=_draw_serial
 match _fit_phase:
  1:_prepare_fit(_epoch)
  2:_settle_fit(_epoch,_settle_remaining)
  3:_finish_fit(_epoch)

func _stop_layout_clock() -> void:
 _fit_phase=0
 set_process(false)
 if RenderingServer.frame_post_draw.is_connected(_draw_completed):RenderingServer.frame_post_draw.disconnect(_draw_completed)

func _prepare_fit(epoch: int) -> void:
 if not _valid(epoch):return
 if is_instance_valid(_poster):
  var budget: Vector2=_body.size-Vector2(4,4)
  var cover_width: float=maxf(20.0,minf(budget.x,minf(720.0,budget.y*0.86)))
  _poster.position=Vector2((_body.size.x-cover_width)*0.5,2)
  _poster.size=Vector2(cover_width,maxf(20.0,budget.y))
  _poster.configure(_data["members"],str(_data["lead_id"]),str(_data["name"]),str(_data["logo"]),str(_data["palette"]),str(_data["vibe"]),size.x,"career",_data["style"],"tall",Vector2(cover_width,budget.y))
  if not _valid(epoch):return
  _settle_remaining=2
  _fit_phase=2
 else:_fit_phase=3

func _settle_fit(epoch: int, remaining: int) -> void:
 if not _valid(epoch):return
 # Actual native text minima settle before the image row gives up space.
 var excess: float=_poster.get_combined_minimum_size().y-(_body.size.y-4.0)
 if excess>0.5:
  var figures: Control=_poster.find_child("IdentitySelectedPortraitRow",true,false) as Control
  if figures!=null:figures.custom_minimum_size.y=maxf(64.0,figures.custom_minimum_size.y-excess-1.0)
  if remaining>1:
   _settle_remaining=remaining-1
   return
 _fit_phase=3

func _finish_fit(epoch: int) -> void:
 if not _valid(epoch):return
 if is_instance_valid(_poster):
  var cover_width: float=_poster.size.x
  var height: float=minf(maxf(20.0,_body.size.y-4.0),_poster.get_combined_minimum_size().y)
  _poster.size=Vector2(cover_width,height)
  _poster.position=Vector2((_body.size.x-cover_width)*0.5,(_body.size.y-height)*0.5)
  if not _shown and not _reduced:
   _fade=create_tween()
   _fade.tween_property(_poster,"modulate:a",1.0,0.15)
  else:_poster.modulate.a=1.0
 if not _valid(epoch):return
 _shown=true
 layout_ready=true
 _stop_layout_clock()
 _link_focus()

func _take_focus() -> void:
 if not _closed and is_inside_tree() and is_visible_in_tree() and is_instance_valid(_back):_back.grab_focus()

func _focusables() -> Array[Control]:
 var items: Array[Control]=[]
 if is_instance_valid(_scroll):
  var bar: VScrollBar=_scroll.get_v_scroll_bar()
  if bar.visible and bar.max_value>bar.page:
   bar.focus_mode=Control.FOCUS_ALL
   items.append(bar)
 if is_instance_valid(_back) and not _back.disabled:items.append(_back)
 return items

func _link_focus() -> void:
 var items: Array[Control]=_focusables()
 for i in range(items.size()):
  items[i].focus_next=items[(i+1)%items.size()].get_path()
  items[i].focus_previous=items[posmod(i-1,items.size())].get_path()

func _input(event: InputEvent) -> void:
 if _closed or not is_visible_in_tree():return
 if event is InputEventKey:
  get_viewport().set_input_as_handled()
  if not event.pressed or event.echo:return
  if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE]:_close()
  elif event.keycode==KEY_TAB:
   var items: Array[Control]=_focusables()
   var current := -1
   for i in range(items.size()):
    if items[i]==get_viewport().gui_get_focus_owner():current=i;break
   if not items.is_empty():items[posmod(current+(-1 if event.shift_pressed else 1),items.size())].grab_focus()
  elif is_instance_valid(_scroll):
   var bar: VScrollBar=_scroll.get_v_scroll_bar()
   match event.keycode:
    KEY_DOWN:bar.value+=32.0
    KEY_UP:bar.value-=32.0
    KEY_PAGEDOWN:bar.value+=bar.page
    KEY_PAGEUP:bar.value-=bar.page
    KEY_HOME:bar.value=bar.min_value
    KEY_END:bar.value=bar.max_value

func _cancel_presentation() -> void:
 _epoch+=1
 _stop_layout_clock()
 if is_instance_valid(_fade):_fade.kill()
 if is_instance_valid(_back):
  _back.disabled=true
  if _back.is_inside_tree():_back.release_focus()

func _close() -> void:
 if _closed:return
 _closed=true
 _cancel_presentation()
 hide()
 closed.emit()

func abort() -> void:
 if _closed:return
 _closed=true
 _cancel_presentation()
 hide()
 aborted.emit()

func _visibility_changed() -> void:
 if not is_visible_in_tree() and not _closed:abort()

func _exit_tree() -> void:
 _closed=true
 _cancel_presentation()
