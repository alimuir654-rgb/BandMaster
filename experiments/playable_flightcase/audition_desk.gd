extends VBoxContainer
## One silent room/person/working sketch. Inspection never dispatches an action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
signal changed(result: Dictionary)
signal menu_requested
var owner_state
var reduced_motion := false
var fresh := false
var available_width := 390.0
var _view: Dictionary={}
var _expected: Dictionary={}
var _voice: Label
var _inspector: Label
var _board: GridContainer
var _prior_toggle: Button
var _notice: Label
var _bio: VBoxContainer
var _show_prior := false
var _busy := false
var _buttons: Array[Button]=[]

func _ready() -> void:
 name="AuditionEncounter"
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",8)
 _view=owner_state.audition_view()
 _expected=owner_state.audition_expected()
 _build()

func _label(words: String,points: int=16) -> Label:
 var label:=C.label(words,points)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return label

func _button(words: String,node_name: String,callback: Callable) -> Button:
 var button:=C.button(words)
 button.name=node_name
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.mouse_filter=Control.MOUSE_FILTER_PASS
 button.pressed.connect(callback)
 _buttons.append(button)
 return button

func _picture(path: String,node_name: String,minimum: Vector2) -> TextureRect:
 var picture:=TextureRect.new()
 picture.name=node_name
 picture.texture=load(path)
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.custom_minimum_size=minimum
 picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 picture.set_meta("source",path)
 picture.set_meta("full_source_contained",true)
 return picture

func _build() -> void:
 var wide: bool=available_width>=840.0
 var scroll:=ScrollContainer.new()
 scroll.name="AuditionBodyScroll"
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=false
 scroll.get_v_scroll_bar().focus_mode=Control.FOCUS_ALL
 add_child(scroll)
 var spread: BoxContainer=HBoxContainer.new() if wide else VBoxContainer.new()
 spread.name="AuditionSpread"
 spread.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 spread.add_theme_constant_override("separation",16 if wide else 8)
 scroll.add_child(spread)
 var place:=VBoxContainer.new()
 place.name="AuditionPlace"
 place.add_theme_constant_override("separation",8)
 if wide:place.custom_minimum_size.x=300
 spread.add_child(place)
 var person_row:=HBoxContainer.new()
 person_row.add_theme_constant_override("separation",10)
 if wide:
  place.add_child(_picture(str(_view["room"]),"AuditionRoom",Vector2(300,169)))
 else:
  person_row.add_child(_picture(str(_view["room"]),"AuditionRoom",Vector2(112,64)))
 person_row.add_child(_picture(str(_view["portrait"]),"AuditionPortrait",Vector2(56,60)))
 var identity:=VBoxContainer.new()
 identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 identity.add_theme_constant_override("separation",2)
 identity.add_child(_label("JACK · GUITAR",18))
 identity.add_child(_label("22 · Sheffield"))
 person_row.add_child(identity)
 place.add_child(person_row)
 _voice=Ink.new()
 _voice.name="AuditionHeldVoice"
 _voice.text=str(_view.get("message","")) if _view.get("held",false) else str(_view.get("voice",""))
 _voice.add_theme_color_override("font_color",Color("eee7d7"))
 place.add_child(_voice)
 if fresh and not _view.get("held",false):_voice.call_deferred("begin",reduced_motion)
 var work:=VBoxContainer.new()
 work.name="AuditionWork"
 work.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 work.add_theme_constant_override("separation",8)
 spread.add_child(work)
 var phase: String=str(_view.get("phase",""))
 if not _view.get("held",false) and phase!="arrival":
  work.add_child(_label("A FOUR-BAR REHEARSAL SKETCH",18))
  work.add_child(_label("Voice: a line in bars 1 and 3. Guitar: Jack’s part."))
  if phase in ["response","decision"]:
   _prior_toggle=_button("SHOW FIRST TRY","AuditionPriorToggle",_toggle_prior)
   work.add_child(_prior_toggle)
  _board=GridContainer.new()
  _board.name="AuditionPhraseBoard"
  _board.columns=4 if wide else 2
  _board.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _board.add_theme_constant_override("h_separation",8)
  _board.add_theme_constant_override("v_separation",8)
  work.add_child(_board)
  _fill_board()
  _inspector=_label("Tap a bar to inspect its written part.")
  _inspector.name="AuditionInspector"
  work.add_child(_inspector)
 elif phase=="arrival":
  work.add_child(_label("MEET THE PERSON BEHIND THE PART",18))
  work.add_child(_label("Jack has brought a short guitar idea. Look it over together, then ask him to try another approach."))
 var bio_button:=_button("JACK’S BACKGROUND","AuditionBiography",_toggle_bio)
 work.add_child(bio_button)
 _bio=VBoxContainer.new()
 _bio.name="AuditionBiographyBody"
 _bio.visible=false
 var person: Dictionary=_view["person"]
 for key in ["story","strength","friction","ambition"]:_bio.add_child(_label(str(person.get(key,""))))
 work.add_child(_bio)
 _notice=_label("")
 _notice.name="AuditionNotice"
 _notice.visible=false
 add_child(_notice)
 var actions:=VBoxContainer.new()
 actions.name="AuditionActions"
 actions.add_theme_constant_override("separation",6)
 add_child(actions)
 if not _view.get("held",false):
  if phase=="arrival":actions.add_child(_button("TRY THE PART","AuditionStartTryout",_act.bind("start_tryout","")))
  elif phase=="tryout":
   var requests:=GridContainer.new()
   requests.name="AuditionRequests"
   requests.columns=2 if wide else 1
   requests.add_theme_constant_override("h_separation",8)
   requests.add_theme_constant_override("v_separation",6)
   requests.add_child(_button("Give the vocal more room","AuditionRequestSpace",_act.bind("request","space_for_voice")))
   requests.add_child(_button("Show me an idea of your own","AuditionRequestOwn",_act.bind("request","own_part")))
   actions.add_child(requests)
  elif phase=="response":actions.add_child(_button("CONSIDER THE INVITATION","AuditionReview",_act.bind("review","")))
  elif phase=="decision":
   var price: int=Base.incremental_cost(owner_state.game.roster,owner_state.game.person_by_id("cast_jack"))
   actions.add_child(_label("%d TALENT · %d AVAILABLE" % [price,owner_state.remaining()]))
   var invite:=_button("INVITE JACK · %d TALENT" % price,"AuditionInvite",_invite)
   invite.disabled=not owner_state.can_recruit("cast_jack")
   invite.set_meta("permitted",not invite.disabled)
   actions.add_child(invite)
   actions.add_child(_button("PASS FOR NOW","AuditionPass",_act.bind("pass","")))
 var exits:=HBoxContainer.new()
 exits.add_theme_constant_override("separation",8)
 if _view.get("ok",false) and _view.get("active",false):exits.add_child(_button("CLOSE AUDITION","AuditionAbort",_act.bind("abort","")))
 exits.add_child(_button("MENU","AuditionMenu",_menu))
 actions.add_child(exits)

func _fill_board() -> void:
 for old in _board.get_children():
  _board.remove_child(old)
  old.queue_free()
 var bars: Array=_view["before_bars"] if _show_prior else _view["bars"]
 for index in range(bars.size()):
  var bar: Dictionary=bars[index]
  var button:=C.button("","flightcase","tab")
  button.name="AuditionBar_"+str(index+1)
  button.custom_minimum_size=Vector2(0,112)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.mouse_filter=Control.MOUSE_FILTER_PASS
  button.set_meta("bar",bar.duplicate(true))
  button.pressed.connect(_inspect.bind(index))
  var inset:=MarginContainer.new()
  inset.mouse_filter=Control.MOUSE_FILTER_IGNORE
  inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","top","right","bottom"]:inset.add_theme_constant_override("margin_"+side,10)
  button.add_child(inset)
  var words:=VBoxContainer.new()
  words.mouse_filter=Control.MOUSE_FILTER_IGNORE
  words.add_theme_constant_override("separation",3)
  inset.add_child(words)
  words.add_child(_label("BAR "+str(bar["number"])))
  words.add_child(_label(str(bar["vocal"])))
  words.add_child(_label(str(bar["guitar"])))
  _board.add_child(button)

func _inspect(index: int) -> void:
 if _busy:return
 var bars: Array=_view["before_bars"] if _show_prior else _view["bars"]
 var bar: Dictionary=bars[index]
 _inspector.text="Bar %d · %s. Guitar: %s." % [int(bar["number"]),str(bar["vocal"]),str(bar["guitar"])]
 _inspector.set_meta("inspected_bar",index+1)

func _toggle_prior() -> void:
 if _busy:return
 _show_prior=not _show_prior
 _prior_toggle.text="SHOW ADJUSTED TRY" if _show_prior else "SHOW FIRST TRY"
 _fill_board()
 _inspector.text="First try — the same four bars." if _show_prior else "Adjusted try — inspect what Jack changed."

func _toggle_bio() -> void:
 if not _busy:_bio.visible=not _bio.visible

func _finish_voice() -> bool:
 if is_instance_valid(_voice) and _voice.call("is_revealing"):
  _voice.call("finish_now")
  return true
 return false

func _set_busy(value: bool) -> void:
 _busy=value
 for button in _buttons:
  if is_instance_valid(button):button.disabled=value or not bool(button.get_meta("permitted",true))

func _act(action: String,request: String) -> void:
 if _busy or _finish_voice():return
 _set_busy(true)
 var result: Dictionary=owner_state.audition_action(action,_expected.duplicate(true),request)
 _returned(result)

func _invite() -> void:
 if _busy or _finish_voice():return
 _set_busy(true)
 var result: Dictionary=owner_state.invite_audition(_expected.duplicate(true))
 _returned(result)

func _returned(result: Dictionary) -> void:
 _set_busy(false)
 if result.get("ok",false):
  changed.emit(result)
  return
 _notice.text=str(result.get("message","This choice could not be saved."))
 _notice.visible=true

func _menu() -> void:
 if not _busy:menu_requested.emit()
