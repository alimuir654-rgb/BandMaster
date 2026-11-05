extends Control
## One-shot presentation of an ALREADY committed saved show receipt.
## Configure before add_child, as with SessionTransition. No resolver/save API.
signal covered
signal finished

const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const BandMark = preload("res://experiments/playable_flightcase/band_mark.gd")
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const STAGE_PATH := "res://experiments/playable_flightcase/art/s53_stage.png"
const FALLBACK_STAGE_PATH := "res://experiments/playable_flightcase/art/opening_stage.png"

var reduced_motion := false
var stage_texture_path := STAGE_PATH
var _receipt: Dictionary = {}
var _identity: Dictionary = {}
var _cards: Array[Control] = []
var _column: VBoxContainer
var _scroll: ScrollContainer
var _hero: TextureRect
var _progress: Label
var _ack: Button
var _timeline: Tween
var _reveal_motion: Tween
var _close_motion: Tween
var _started := false
var _covered := false
var _closed := false
var _closing := false
var _aborted := false

func configure(receipt: Dictionary, reduced: bool, identity: Dictionary = {}) -> void:
 # Never retain a mutable caller-owned model/receipt reference.
 _receipt = receipt.duplicate(true)
 # Current saved appearance is cosmetic context, never settlement history.
 _identity = identity.duplicate(true)
 reduced_motion = reduced

func _ready() -> void:
 name = "ShowReplay"
 # The owning parent already applies physical safe-area conversion.
 set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 focus_mode = Control.FOCUS_NONE
 z_index = 80
 add_child(C.background())
 var margin := MarginContainer.new()
 margin.name = "ShowReplayMargin"
 margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
 margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for side in ["left","top","right","bottom"]:
  margin.add_theme_constant_override("margin_"+side,12)
 add_child(margin)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",0)
 margin.add_child(row)
 var left := Control.new()
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(left)
 _column = VBoxContainer.new()
 _column.name = "ShowReplayColumn"
 _column.add_theme_constant_override("separation",10)
 _column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 row.add_child(_column)
 var right := Control.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 right.mouse_filter = Control.MOUSE_FILTER_IGNORE
 row.add_child(right)
 var header := HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 _column.add_child(header)
 header.add_child(C.brand(44.0))
 var headings := VBoxContainer.new()
 headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 headings.add_theme_constant_override("separation",4)
 header.add_child(headings)
 var band_name: String = _text(_identity.get("band_name"),"").strip_edges()
 var title: Label
 if not band_name.is_empty():
  var mark := BandMark.new()
  mark.configure(band_name,_text(_identity.get("logo"),"Wordmark"),IdentityStyle.effective(_identity.get(IdentityStyle.KEY),_text(_identity.get("palette"),"")),28,true,true)
  # Reserve two readable lines; only the notes viewport absorbs this growth.
  mark.custom_minimum_size.y = 56.0
  title = mark
 else:
  title = C.label("TONIGHT'S SHOW",18)
  title.add_theme_color_override("font_color",Color("f0c78b"))
 title.name = "ShowReplayTitle"
 headings.add_child(title)
 var location: String = _text(_receipt.get("venue"),"SAVED SHOW")
 var city: String = _text(_receipt.get("city"),"")
 if not city.is_empty():location += " • "+city
 var venue: Label = C.label(location,16)
 venue.name = "ShowReplayVenue"
 headings.add_child(venue)
 # Artwork, settled facts and the whole-show response stay OUTSIDE the notes
 # scroll. The passive band is configured once from saved response[1].
 _hero = TextureRect.new()
 _hero.name = "ShowReplayStageIllustration"
 _hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 _hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 _hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _hero.set_meta("illustrative_only",true)
 _hero.set_meta("actual_attendance_claim",false)
 var image_path: String = stage_texture_path if ResourceLoader.exists(stage_texture_path) else FALLBACK_STAGE_PATH
 if ResourceLoader.exists(image_path):
  _hero.texture = load(image_path) as Texture2D
  _hero.set_meta("source",image_path)
 _column.add_child(_hero)
 var day_before: int = _integer(_receipt.get("day_before"),1)
 var day_after: int = _integer(_receipt.get("day_after"),day_before)
 var cash_before: int = _integer(_receipt.get("cash_before"),0)
 var cash_after: int = _integer(_receipt.get("cash_after"),cash_before)
 var summary: Label = C.label("DAY %d → %d • £%d → £%d • GROSS £%d" % [day_before,day_after,cash_before,cash_after,_integer(_receipt.get("settled_fee"),0)],16)
 summary.name = "ShowReplaySavedSettlement"
 _column.add_child(summary)
 _add_whole_show_response(_column)
 _scroll = ScrollContainer.new()
 _scroll.name = "ShowReplayScroll"
 _scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 _scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 _scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 _scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
 _scroll.follow_focus = true
 _scroll.mouse_filter = Control.MOUSE_FILTER_STOP
 _column.add_child(_scroll)
 var body := VBoxContainer.new()
 body.name = "ShowReplayBody"
 body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",14)
 _scroll.add_child(body)
 _progress = C.label("SAVED RESPONSES",14)
 _progress.name = "ShowReplayProgress"
 body.add_child(_progress)
 var raw_responses: Variant = _receipt.get("responses",[])
 if raw_responses is Array:
  for raw in raw_responses:
   if raw is Dictionary and _cards.size()<3:
    _add_response(body,raw,_cards.size())
 if _cards.is_empty():
  _add_response(body,{"title":"SAVED SHOW","text":_text(_receipt.get("message"),"No saved response text is available."),"kind":"modelled_summary"},0)
 # Complete authored set order remains readable below the saved narrative;
 # it no longer displaces the actual room response from the first fold.
 var songs: Label = C.label(_song_copy(),16)
 songs.name = "ShowReplaySavedSongOrder"
 body.add_child(songs)
 for song in _receipt.get("plan",{}).get("song_snapshots",[]):
  if song is Dictionary:preload("res://experiments/playable_flightcase/song_audio.gd").attach(body,song,func():return is_inside_tree() and is_visible_in_tree() and not _closing and not _closed,false)

 _ack = C.button("SHOW SAVED NOTES  ›","flightcase","action")
 _ack.name = "ShowReplayContinueAction"
 _ack.pressed.connect(finish_now)
 _column.add_child(_ack)
 resized.connect(_fit)
 visibility_changed.connect(_visibility_changed)
 _fit()
 call_deferred("_start")

func _add_whole_show_response(parent: VBoxContainer) -> void:
 var group := VBoxContainer.new()
 group.name = "ShowReplayWholeShowResponse"
 group.add_theme_constant_override("separation",4)
 parent.add_child(group)
 var meaning: Label = C.label("Saved show response · coarse modelled summary",16)
 meaning.name = "ShowReplayMeaning"
 meaning.add_theme_color_override("font_color",Color("f0c78b"))
 meaning.tooltip_text = "A saved coarse response band, not a percentage, audio measurement or attendance count."
 group.add_child(meaning)
 var whole: Dictionary = {}
 var responses: Variant = _receipt.get("responses",[])
 if responses is Array and responses.size()>1 and responses[1] is Dictionary:
  whole = responses[1]
 group.set_meta("response_id",_text(whole.get("id"),""))
 group.set_meta("kind",_text(whole.get("kind"),"modelled_summary"))
 group.set_meta("read_only",true)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 group.add_child(row)
 var mood: Label = C.label(_text(whole.get("mood"),"SAVED RESPONSE").to_upper(),16)
 mood.name = "ShowReplayWholeShowMood"
 mood.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 mood.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 row.add_child(mood)
 var raw_score: Variant = whole.get("meter_score",null)
 if typeof(raw_score)==TYPE_INT or (typeof(raw_score)==TYPE_FLOAT and is_finite(float(raw_score))):
  var score: int = clampi(int(raw_score),0,10)
  var meter := Kit.PassiveMeter.new("flightcase",score)
  meter.name = "ShowReplayResponseMeter1"
  meter.set_meta("read_only",true)
  meter.set_meta("kind","coarse_modelled_summary")
  meter.set_meta("saved_score",score)
  row.add_child(meter)
  var value: Label = C.label("%d / 10" % score,16)
  value.name = "ShowReplayResponseValue1"
  value.autowrap_mode = TextServer.AUTOWRAP_OFF
  value.size_flags_horizontal = Control.SIZE_SHRINK_END
  value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  row.add_child(value)

func _add_response(body: VBoxContainer, response: Dictionary, index: int) -> void:
 # Quiet printed notes: one immutable summary meter above, no repeated raised
 # hardware cards or changing VU suggestion attached to sequential text.
 var panel := VBoxContainer.new()
 panel.name = "ShowReplayResponse%d" % index
 panel.add_theme_constant_override("separation",6)
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.visible = false
 panel.set_meta("response_id",_text(response.get("id"),str(index)))
 panel.set_meta("kind",_text(response.get("kind"),"modelled_summary"))
 body.add_child(panel)
 var heading: Label = C.label(_text(response.get("title"),"SAVED RESPONSE"),16)
 heading.name = "ShowReplayResponseTitle%d" % index
 heading.add_theme_color_override("font_color",Color("f0c78b"))
 panel.add_child(heading)
 var text: Label = C.label(_text(response.get("text"),"No saved response text is available."),16)
 text.name = "ShowReplayResponseText%d" % index
 panel.add_child(text)
 _cards.append(panel)

func _song_copy() -> String:
 var plan: Variant = _receipt.get("plan",{})
 var lines: PackedStringArray = []
 if plan is Dictionary:
  var songs: Variant = plan.get("song_snapshots",[])
  if songs is Array:
   for song in songs:
    if song is Dictionary:
     var title: String = _text(song.get("title"),_text(song.get("id"),"Untitled original"))
     lines.append("%d. %s" % [lines.size()+1,title])
 if lines.is_empty():
  return "SAVED ORIGINALS\nNo originals recorded in this set."
 return "SAVED ORIGINALS\n"+"\n".join(lines)

func _fit() -> void:
 if not is_instance_valid(_column):
  return
 _column.custom_minimum_size.x = maxf(0.0,minf(900.0,size.x-24.0))
 if is_instance_valid(_hero):
  _hero.custom_minimum_size.y = 120.0 if size.x<600.0 else 140.0
 # Reflow retained nodes; do not rebuild/drop controls or lose semantic focus.
 call_deferred("_link_focus")

func _start() -> void:
 if _closed or not is_inside_tree():
  return
 if not is_visible_in_tree():
  abort()
  return
 _started = true
 _cover_once()
 if _closed:
  return
 _ack.grab_focus()
 if reduced_motion:
  _reveal(_cards.size(),false)
  _hold()
  return
 _reveal(1,true)
 _timeline = create_tween()
 for count in range(2,_cards.size()+1):
  _timeline.tween_interval(1.20)
  _timeline.tween_callback(_reveal.bind(count,true))
 _timeline.tween_interval(1.20)
 _timeline.tween_callback(_hold)

func _cover_once() -> void:
 if _covered or _closed:
  return
 _covered = true
 covered.emit()

func _reveal(count: int, animate: bool) -> void:
 if _closed or _closing:
  return
 if is_instance_valid(_reveal_motion):
  _reveal_motion.kill()
 for i in range(_cards.size()):
  if i<count and not _cards[i].visible:
   _cards[i].show()
   _cards[i].modulate.a = 1.0
   if animate and not reduced_motion:
    _cards[i].modulate.a = 0.0
    _reveal_motion = create_tween()
    _reveal_motion.tween_property(_cards[i],"modulate:a",1.0,0.22)
 _progress.text = "SAVED RESPONSES • %d OF %d" % [mini(count,_cards.size()),_cards.size()]
 _link_focus()

func _hold() -> void:
 if _closed or _closing:
  return
 _reveal(_cards.size(),false)
 _progress.text = "ALL SAVED RESPONSES • READY TO READ"
 set_meta("held_for_acknowledgement",true)

func _focusables() -> Array[Control]:
 var choices: Array[Control] = []
 if is_instance_valid(_scroll):
  var bar: VScrollBar = _scroll.get_v_scroll_bar()
  if bar.visible and bar.max_value>bar.page:
   bar.focus_mode = Control.FOCUS_ALL
   choices.append(bar)
 if is_instance_valid(_ack) and not _ack.disabled:
  choices.append(_ack)
 return choices

func _link_focus() -> void:
 if _closed or not is_inside_tree():
  return
 var choices: Array[Control] = _focusables()
 for i in range(choices.size()):
  var prior: Control = choices[posmod(i-1,choices.size())]
  var next: Control = choices[(i+1)%choices.size()]
  choices[i].focus_previous = prior.get_path()
  choices[i].focus_next = next.get_path()
  choices[i].focus_neighbor_top = prior.get_path()
  choices[i].focus_neighbor_bottom = next.get_path()
  choices[i].focus_neighbor_left = choices[i].get_path()
  choices[i].focus_neighbor_right = choices[i].get_path()

func _cycle_focus(backward: bool) -> void:
 var choices: Array[Control] = _focusables()
 if choices.is_empty():
  return
 var focused: Control = get_viewport().gui_get_focus_owner()
 var current := -1
 # Identity loop accepts any Control; no TypedArray[Button].find(Label) error.
 for i in range(choices.size()):
  if choices[i]==focused:
   current = i
   break
 if current<0:
  choices[choices.size()-1 if backward else 0].grab_focus()
  return
 var offset: int = -1 if backward else 1
 choices[posmod(current+offset,choices.size())].grab_focus()

func _input(event: InputEvent) -> void:
 if _closed or not is_visible_in_tree():
  return
 if event is InputEventKey:
  # This overlay has no editable fields: consume all keys from the old view.
  # Scroll navigation is presentation-only and never reaches a game shortcut.
  get_viewport().set_input_as_handled()
  if _closing or not event.pressed or event.echo:
   return
  if event.keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_ESCAPE]:
   finish_now()
  elif event.keycode==KEY_TAB:
   _cycle_focus(event.shift_pressed)
  elif is_instance_valid(_scroll):
   var bar: VScrollBar = _scroll.get_v_scroll_bar()
   match event.keycode:
    KEY_DOWN: bar.value += 32.0
    KEY_UP: bar.value -= 32.0
    KEY_PAGEDOWN: bar.value += bar.page
    KEY_PAGEUP: bar.value -= bar.page
    KEY_HOME: bar.value = bar.min_value
    KEY_END: bar.value = bar.max_value

func finish_now(animate: bool = true) -> void:
 if _closed or (_closing and animate):
  return
 if not is_inside_tree() or not is_visible_in_tree():
  abort()
  return
 _closing = true
 _stop_motion()
 # An immediate Skip may arrive before the deferred presentation start.
 _cover_once()
 if _closed or _aborted or not is_inside_tree():
  return
 if is_instance_valid(_ack):
  _ack.disabled = true
 if animate and not reduced_motion and is_inside_tree() and is_visible_in_tree():
  _close_motion = create_tween()
  _close_motion.tween_property(self,"modulate:a",0.0,0.15)
  _close_motion.tween_callback(_finish)
 else:
  _finish()

func _finish() -> void:
 if _closed or _aborted or not is_inside_tree() or not is_visible_in_tree():
  return
 _closed = true
 _stop_motion()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 hide()
 finished.emit()

func abort() -> void:
 if _closed:
  return
 _aborted = true
 _closed = true
 _stop_motion()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 if is_instance_valid(_ack):
  _ack.disabled = true
  if _ack.is_inside_tree():_ack.release_focus()
 hide()
 # No finished signal: hiding/freeing is not a second settled-show action.

func _stop_motion() -> void:
 for motion in [_timeline,_reveal_motion,_close_motion]:
  if is_instance_valid(motion):
   motion.kill()

func _visibility_changed() -> void:
 if _started and not is_visible_in_tree() and not _closed:
  abort()

func _exit_tree() -> void:
 abort()

func _text(value: Variant, fallback: String) -> String:
 return str(value) if value is String and not str(value).is_empty() else fallback

func _integer(value: Variant, fallback: int) -> int:
 if typeof(value)==TYPE_INT:
  return int(value)
 if typeof(value)==TYPE_FLOAT and is_finite(float(value)):
  return int(value)
 return fallback
