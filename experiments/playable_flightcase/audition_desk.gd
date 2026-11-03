extends VBoxContainer
## One silent room/person/working sketch. Inspection never dispatches an action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const AudioPart = preload("res://experiments/playable_flightcase/audition_audio.gd")
const Profiles = preload("res://experiments/playable_flightcase/audition_profiles.gd")
const PersonalContext = preload("res://experiments/playable_flightcase/personal_context.gd")
var _content: Script
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
var _audio
var _buttons: Array[Button]=[]

func _ready() -> void:
 name="AuditionEncounter"
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",8)
 _view=owner_state.audition_view()
 _content=Profiles.content(str(_view.get("candidate_id","")))
 if _content==null:return
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

func _quiet_button(words: String,node_name: String,callback: Callable,paper: bool=false) -> Button:
 var button:=_button(words,node_name,callback)
 button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 var empty:=StyleBoxEmpty.new()
 var hover:=StyleBoxFlat.new()
 hover.bg_color=Color(0.18,0.14,0.1,0.08) if paper else Color(1,1,1,0.06)
 var pressed:=hover.duplicate() as StyleBoxFlat
 pressed.bg_color=Color(0.18,0.14,0.1,0.14) if paper else Color(1,1,1,0.12)
 var focus:=StyleBoxFlat.new()
 focus.bg_color=Color.TRANSPARENT
 focus.set_border_width_all(2)
 focus.border_color=Color("695c4b") if paper else Color("f0c78b")
 for state in ["normal","disabled"]:button.add_theme_stylebox_override(state,empty)
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",pressed)
 button.add_theme_stylebox_override("focus",focus)
 if paper:
  for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:button.add_theme_color_override(state,Color("29241f"))
 return button

func _identity() -> VBoxContainer:
 var identity:=VBoxContainer.new()
 identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 identity.add_theme_constant_override("separation",4)
 var person: Dictionary=_view["person"]
 identity.add_child(_label(str(person["name"]).to_upper(),22))
 identity.add_child(_label("%s · %s · %s" % [person["role"],person["age"],person["town"]]))
 return identity

func _add_voice(host: Control) -> void:
 _voice=Ink.new()
 _voice.name="AuditionHeldVoice"
 _voice.text=str(_view.get("message","")) if _view.get("held",false) else str(_view.get("voice",""))
 _voice.add_theme_color_override("font_color",Color("eee7d7"))
 host.add_child(_voice)
 if fresh and not _view.get("held",false):_voice.call_deferred("begin",reduced_motion)

func _build() -> void:
 var wide: bool=available_width>=840.0
 var phase: String=str(_view.get("phase",""))
 var arrival: bool=phase=="arrival"
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
 spread.add_theme_constant_override("separation",24 if wide else 10)
 scroll.add_child(spread)
 var place:=VBoxContainer.new()
 place.name="AuditionPlace"
 place.add_theme_constant_override("separation",10)
 if wide:place.custom_minimum_size.x=520 if arrival else 380
 spread.add_child(place)
 var work:=VBoxContainer.new()
 work.name="AuditionWork"
 work.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 work.add_theme_constant_override("separation",8)
 if wide:work.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 spread.add_child(work)
 if arrival:
  var room_width: float=520 if wide else maxf(240,available_width-24)
  place.add_child(_picture(str(_view["room"]),"AuditionRoom",Vector2(room_width,room_width*900.0/1599.0)))
  var introduction:=HBoxContainer.new()
  introduction.add_theme_constant_override("separation",16)
  introduction.add_child(_picture(str(_view["portrait"]),"AuditionPortrait",Vector2(160,151) if wide else Vector2(112,106)))
  introduction.add_child(_identity())
  if wide:
   work.add_child(introduction)
   _add_voice(work)
  else:
   place.add_child(introduction)
   _add_voice(place)
  work.add_child(_label(str(_view["person"]["name"])+" has brought a short guitar idea. Look it over together, then ask him to try another approach."))
 else:
  if wide:
   place.add_child(_picture(str(_view["room"]),"AuditionRoom",Vector2(380,214)))
   var person_row:=HBoxContainer.new()
   person_row.add_theme_constant_override("separation",14)
   person_row.add_child(_picture(str(_view["portrait"]),"AuditionPortrait",Vector2(112,106)))
   person_row.add_child(_identity())
   place.add_child(person_row)
  else:
   var pictures:=HBoxContainer.new()
   pictures.alignment=BoxContainer.ALIGNMENT_CENTER
   pictures.add_theme_constant_override("separation",12)
   pictures.add_child(_picture(str(_view["room"]),"AuditionRoom",Vector2(200,112)))
   pictures.add_child(_picture(str(_view["portrait"]),"AuditionPortrait",Vector2(112,106)))
   place.add_child(pictures)
   var person: Dictionary=_view["person"]
   place.add_child(_label(("%s · %s · %s · %s" % [person["name"],person["role"],person["age"],person["town"]]).to_upper(),18))
  _add_voice(place)
 var tools:=HBoxContainer.new()
 tools.name="AuditionInspectionTools"
 tools.add_theme_constant_override("separation",12)
 tools.add_child(_quiet_button("ABOUT "+str(_view["person"]["name"]).to_upper(),"AuditionBiography",_toggle_bio))
 var spacer:=Control.new()
 spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
 spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 tools.add_child(spacer)
 if not _view.get("held",false) and phase in ["response","decision"]:
  _prior_toggle=_quiet_button("VIEW ORIGINAL PART","AuditionPriorToggle",_toggle_prior)
  tools.add_child(_prior_toggle)
 work.add_child(tools)
 if not _view.get("held",false) and not arrival:
  var paper:=PanelContainer.new()
  paper.name="AuditionSketchPaper"
  paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  paper.mouse_filter=Control.MOUSE_FILTER_PASS
  paper.add_theme_stylebox_override("panel",Paper.scorecard())
  work.add_child(paper)
  var notes:=VBoxContainer.new()
  notes.add_theme_constant_override("separation",6)
  paper.add_child(notes)
  notes.add_child(C.paper_label("A FOUR-BAR REHEARSAL SKETCH",18))
  var version_label:=C.paper_label("ORIGINAL PART" if phase=="tryout" else "ADJUSTED PART",16)
  version_label.name="AuditionCurrentVersion"
  notes.add_child(version_label)
  notes.add_child(C.paper_label("Voice: a line in bars 1 and 3. Guitar: "+str(_view["person"]["name"])+"’s part."))
  _audio=AudioPart.new()
  _audio.manifest_path=Profiles.audio_manifest(str(_view["candidate_id"]))
  _audio.configure(_audio_context)
  notes.add_child(_audio)
  _audio.set_clip(_content.material_id(str(_view.get("request",""))))
  _board=GridContainer.new()
  _board.name="AuditionPhraseBoard"
  _board.columns=4 if wide else 2
  _board.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _board.add_theme_constant_override("h_separation",8)
  _board.add_theme_constant_override("v_separation",4)
  notes.add_child(_board)
  _fill_board()
  _inspector=C.paper_label("Tap a bar to inspect its written part.")
  _inspector.name="AuditionInspector"
  notes.add_child(_inspector)
 var practical:=VBoxContainer.new()
 practical.name="AuditionPracticalContext"
 practical.add_theme_constant_override("separation",4)
 var background: Dictionary=PersonalContext.for_candidate(str(_view["person"]["id"]))
 practical.add_child(_label("WORK · "+background["work"]))
 practical.add_child(_label("OUTSIDE THE BAND · "+background["outside_commitment"]))
 practical.add_child(_label(background["availability"]))
 work.add_child(practical)
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
  var steps: Dictionary={"arrival":"1 / 4 · MEET "+str(_view["person"]["name"]).to_upper(),"tryout":"2 / 4 · HEAR THE FIRST PART","response":"3 / 4 · COMPARE THE ADJUSTMENT","decision":"4 / 4 · INVITE OR PASS"}
  var hints: Dictionary={"arrival":"Start when you are ready to try the sketch together.","tryout":"Listen or read, then ask "+str(_view["person"]["name"])+" to try one change.","response":"Compare the original if useful, then review the invitation.","decision":"Read about "+str(_view["person"]["name"])+" before choosing. Inviting costs the talent shown."}
  var progress:=_label(str(steps.get(phase,"AUDITION")),14)
  progress.name="AuditionProgress"
  actions.add_child(progress)
  var guidance:=_label(str(hints.get(phase,"")),14)
  guidance.name="AuditionNextStep"
  actions.add_child(guidance)
  if phase=="arrival":actions.add_child(_button("START AUDITION","AuditionStartTryout",_act.bind("start_tryout","")))
  elif phase=="tryout":
   var requests:=GridContainer.new()
   requests.name="AuditionRequests"
   requests.columns=2 if wide else 1
   requests.add_theme_constant_override("h_separation",8)
   requests.add_theme_constant_override("v_separation",6)
   requests.add_child(_button("Give the vocal more room","AuditionRequestSpace",_act.bind("request","space_for_voice")))
   requests.add_child(_button("Show me an idea of your own","AuditionRequestOwn",_act.bind("request","own_part")))
   actions.add_child(requests)
  elif phase=="response":actions.add_child(_button("NEXT: INVITE OR PASS","AuditionReview",_act.bind("review","")))
  elif phase=="decision":
   var price: int=Base.incremental_cost(owner_state.game.roster,owner_state.game.person_by_id(str(_view["person"]["id"])))
   actions.add_child(_label("%d TALENT · %d AVAILABLE" % [price,owner_state.remaining()]))
   var invite:=_button("INVITE %s · %d TALENT" % [str(_view["person"]["name"]).to_upper(),price],"AuditionInvite",_invite)
   invite.disabled=not owner_state.can_recruit(str(_view["person"]["id"]))
   invite.set_meta("permitted",not invite.disabled)
   actions.add_child(invite)
   actions.add_child(_button("PASS FOR NOW","AuditionPass",_act.bind("pass","")))
 var exits:=HBoxContainer.new()
 exits.add_theme_constant_override("separation",8)
 if _view.get("ok",false) and _view.get("active",false):exits.add_child(_button("END AUDITION","AuditionAbort",_act.bind("abort","")))
 exits.add_child(_button("PAUSE / MENU","AuditionMenu",_menu))
 actions.add_child(exits)

func _fill_board() -> void:
 var current_version: Label=find_child("AuditionCurrentVersion",true,false) as Label
 if current_version!=null:
  current_version.text="ORIGINAL PART" if _show_prior or _view.get("phase")=="tryout" else "ADJUSTED PART"
 for old in _board.get_children():
  if old is Button:_buttons.erase(old)
  _board.remove_child(old)
  old.queue_free()
 var bars: Array=_view["before_bars"] if _show_prior else _view["bars"]
 for index in range(bars.size()):
  var bar: Dictionary=bars[index]
  var button:=_quiet_button("","AuditionBar_"+str(index+1),_inspect.bind(index),true)
  button.custom_minimum_size=Vector2(0,88)
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.set_meta("bar",bar.duplicate(true))
  var inset:=MarginContainer.new()
  inset.mouse_filter=Control.MOUSE_FILTER_IGNORE
  inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  for side in ["left","top","right","bottom"]:inset.add_theme_constant_override("margin_"+side,6)
  button.add_child(inset)
  var words:=VBoxContainer.new()
  words.mouse_filter=Control.MOUSE_FILTER_IGNORE
  words.add_theme_constant_override("separation",3)
  inset.add_child(words)
  words.add_child(C.paper_label("BAR "+str(bar["number"]),16,true))
  words.add_child(C.paper_label(str(bar["vocal"])))
  words.add_child(C.paper_label(str(bar["guitar"])))
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
 if is_instance_valid(_audio):_audio.set_clip(_content.material_id("" if _show_prior else str(_view.get("request",""))))
 _prior_toggle.text="VIEW ADJUSTED PART" if _show_prior else "VIEW ORIGINAL PART"
 _fill_board()
 _inspector.text="First try — the same four bars." if _show_prior else "Adjusted try — inspect what "+str(_view["person"]["name"])+" changed."

func _toggle_bio() -> void:
 if not _busy:_bio.visible=not _bio.visible

func _finish_voice() -> bool:
 if is_instance_valid(_voice) and _voice.call("is_revealing"):
  if is_instance_valid(_audio):_audio.stop()
  _voice.call("finish_now")
  var guidance: Label=find_child("AuditionNextStep",true,false) as Label
  if guidance!=null:guidance.text="Words revealed. Choose the action again to continue."
  return true
 return false

func _set_busy(value: bool) -> void:
 if value and is_instance_valid(_audio):_audio.stop()
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
 if is_instance_valid(_audio):_audio.stop()
 if not _busy:menu_requested.emit()

func _audio_context() -> Dictionary:
 var live: Dictionary=owner_state.audition_view()
 var allowed: bool=is_visible_in_tree() and owner_state.audition_expected()==_expected and not _busy and live.get("ok",false) and live.get("active",false) and not live.get("held",false) and live.get("phase","") in ["tryout","response","decision"] and owner_state.game.genre=="Indie rock"
 for key in ["id","revision","phase","request"]:
  allowed=allowed and live.get(key)==_view.get(key)
 return {"content_version":_content.VERSION,"allowed":allowed,"material_id":_content.material_id("" if _show_prior else str(live.get("request","")))}
