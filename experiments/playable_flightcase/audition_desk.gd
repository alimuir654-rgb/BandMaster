extends VBoxContainer
## One silent room/person/working sketch. Inspection never dispatches an action.
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Base = preload("res://experiments/character_cast/vendor/recruitment_catalogue_v3.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const AudioPart = preload("res://experiments/playable_flightcase/audition_audio.gd")
const Profiles = preload("res://experiments/playable_flightcase/audition_profiles.gd")
const PersonalContext = preload("res://experiments/playable_flightcase/personal_context.gd")
const BACKING_MANIFEST := "res://experiments/playable_flightcase/audio/jack_backing_clips_v1.json"
const BACKING_FILES := {"jack_four_bars_original_v1":"res://experiments/playable_flightcase/audio/jack_backing_original_v1.ogg","jack_four_bars_space_for_voice_v1":"res://experiments/playable_flightcase/audio/jack_backing_space_v1.ogg","jack_four_bars_own_part_v1":"res://experiments/playable_flightcase/audio/jack_backing_own_v1.ogg"}
var backing_manifest_path := BACKING_MANIFEST
var _backing_catalogue: Dictionary={}
var _solo_catalogue: Dictionary={}
var _use_backing := false
var _audio_slot: VBoxContainer
var _mode_buttons: Dictionary={}
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
var _question_box: VBoxContainer
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
 if _has_backing_choice():
  _backing_catalogue=_read_audio_catalogue(backing_manifest_path)
  _solo_catalogue=_read_audio_catalogue(Profiles.audio_manifest("cast_jack"))
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
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:button.add_theme_color_override(state,Color("29241f") if paper else Color("eee8d8"))
 return button

func _identity() -> VBoxContainer:
 var identity:=VBoxContainer.new()
 identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 identity.add_theme_constant_override("separation",4)
 var person: Dictionary=_view["person"]
 identity.add_child(_label(str(person["name"]).to_upper(),22))
 identity.add_child(_label("%s · %d · %s" % [person["role"],int(person["age"]),person["town"]]))
 return identity

func _add_voice(host: Control) -> void:
 _voice=Ink.new()
 _voice.name="AuditionHeldVoice"
 _voice.text=str(_view.get("message","")) if _view.get("held",false) else str(_view.get("voice",""))
 if _view.get("phase")=="tryout" and not _view.get("held",false):
  var full: String=_voice.text
  var sentence: int=full.find(".")
  if sentence>=0:_voice.text=full.substr(0,sentence+1)
 _voice.add_theme_color_override("font_color",Color("eee7d7"))
 host.add_child(_voice)
 if fresh and not _view.get("held",false):_voice.call_deferred("begin",reduced_motion)

func _build() -> void:
 var wide: bool=available_width>=840.0
 var phase: String=str(_view.get("phase",""))
 var arrival: bool=phase=="arrival"
 var scroll:=ScrollContainer.new()
 scroll.name="AuditionBodyScroll"
 scroll.scroll_deadzone=12
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
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
 # Keep the approved person/instrument preview as the main image. No new crop
 # or invented full-resolution portrait; room art no longer competes with it.
 place.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if wide:place.custom_minimum_size.x=280
 var portrait_row:=HBoxContainer.new();portrait_row.alignment=BoxContainer.ALIGNMENT_CENTER;place.add_child(portrait_row)
 var preview: Vector2=Vector2(240,226) if wide else Vector2(210,198)
 portrait_row.add_child(_picture(str(_view["portrait"]),"AuditionPortrait",preview))
 place.add_child(_identity())
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
  notes.add_child(C.paper_label("HEAR "+str(_view["person"]["name"]).to_upper()+" PLAY",18))
  var version_label:=C.paper_label("ORIGINAL PART" if phase=="tryout" else "ADJUSTED PART",16)
  version_label.name="AuditionCurrentVersion"
  notes.add_child(version_label)
  if _has_backing_choice():
   var modes:=HBoxContainer.new()
   modes.name="AuditionListeningModes"
   modes.add_theme_constant_override("separation",8)
   notes.add_child(modes)
   for key in ["solo","backing"]:
    var button: Button=_quiet_button("SOLO PART" if key=="solo" else "WITH BACKING","AuditionMode_"+key,_choose_audio_mode.bind(key=="backing"),true)
    button.custom_minimum_size.y=48.0
    button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    button.toggle_mode=true
    button.add_theme_stylebox_override("hover_pressed",button.get_theme_stylebox("pressed"))
    button.focus_entered.connect(_reveal_audio_mode.bind(button))
    _mode_buttons[key]=button
    modes.add_child(button)
   _audio_slot=VBoxContainer.new()
   _audio_slot.name="AuditionAudioSlot"
   notes.add_child(_audio_slot)
   _refresh_listening_audio()
  else:
   notes.add_child(C.paper_label("Voice: a line in bars 1 and 3. "+_instrument()+": "+str(_view["person"]["name"])+"’s part."))
   _audio=AudioPart.new()
   _audio.controls_visible=false
   _audio.manifest_path=Profiles.audio_manifest(str(_view["candidate_id"]))
   _audio.configure(_audio_context)
   notes.add_child(_audio)
   _audio.set_clip(_content.material_id(str(_view.get("request",""))))
  var takes:=HBoxContainer.new();takes.add_theme_constant_override("separation",5);notes.add_child(takes)
  var audio_supported: bool=owner_state.game.genre=="Indie rock"
  var first_take: Button=_button("▶ FIRST TAKE" if audio_supported else "WRITTEN EXAMPLE","AuditionPlayFirst",_hear_version.bind(true))
  first_take.disabled=not audio_supported;first_take.set_meta("permitted",audio_supported);takes.add_child(first_take)
  if not audio_supported:notes.add_child(C.paper_label("Audio samples are not available for this style. Read the written part below.",16))
  if phase in ["response","decision"]:
   var has_audio: bool=str(_view.get("candidate_id"))!="cast_arjun" and owner_state.game.genre=="Indie rock"
   var adjusted: Button=_button("▶ NEW TAKE" if has_audio else "WRITTEN ONLY","AuditionPlayAdjusted",_hear_version.bind(false))
   adjusted.disabled=not has_audio;adjusted.set_meta("permitted",has_audio);takes.add_child(adjusted)
  var stop: Button=_quiet_button("STOP","AuditionStopTakes",_stop_takes,true)
  notes.add_child(stop)
  var written:=VBoxContainer.new();written.name="AuditionWrittenParts";written.visible=false
  notes.add_child(_quiet_button("READ THE FOUR BARS","AuditionReadPart",func():written.visible=not written.visible,true))
  notes.add_child(written)
  _board=GridContainer.new()
  _board.name="AuditionPhraseBoard"
  _board.columns=4 if wide else 2
  _board.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  _board.add_theme_constant_override("h_separation",8)
  _board.add_theme_constant_override("v_separation",4)
  written.add_child(_board)
  _fill_board()
  _inspector=C.paper_label("Tap a bar to inspect its written part.")
  _inspector.name="AuditionInspector"
  written.add_child(_inspector)
  written.add_child(C.paper_label(str(_view.get("voice","")),16))
  if _has_backing_choice():
   var voice_hint: Label=C.paper_label("Voice: a line in bars 1 and 3. Guitar: Jack’s part.")
   voice_hint.name="AuditionVoicePlacement"
   notes.add_child(voice_hint)
   var context_hint: Label=C.paper_label("Backing is an arranged bass-and-drum example, not your recruited band’s performance.")
   context_hint.name="AuditionBackingDisclosure"
   notes.add_child(context_hint)
 if not _view.get("held",false) and not arrival:
  _question_box=VBoxContainer.new();_question_box.name="AuditionConversation";_question_box.add_theme_constant_override("separation",5);work.add_child(_question_box);_questions(_question_box)
 var practical:=VBoxContainer.new()
 practical.name="AuditionPracticalContext"
 practical.add_theme_constant_override("separation",4)
 var background: Dictionary=PersonalContext.for_candidate(str(_view["person"]["id"]))
 practical.add_child(_label("WORK · "+background["work"]))
 practical.add_child(_label("OUTSIDE THE BAND · "+background["outside_commitment"]))
 practical.add_child(_label(background["availability"]))
 practical.add_child(_label(background["starting_availability"]))
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
  var steps: Dictionary={"arrival":"MEET "+str(_view["person"]["name"]).to_upper(),"tryout":"HEAR THE FIRST PART","response":"COMPARE · INVITE OR PASS","decision":"INVITE OR PASS"}
  var hints: Dictionary={"arrival":"Start when you are ready to try the sketch together.","tryout":"Listen or read, then ask "+str(_view["person"]["name"])+" to try one change.","response":"Compare the original if useful. Their story and commitments are here before you choose.","decision":"Read about "+str(_view["person"]["name"])+" before choosing. Inviting costs the talent shown."}
  var progress:=_label(str(steps.get(phase,"AUDITION")),14)
  progress.name="AuditionProgress"
  actions.add_child(progress)
  var guidance:=_label(str(hints.get(phase,"")),14)
  guidance.name="AuditionNextStep"
  guidance.visible=false
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
  elif phase in ["response","decision"]:
   var price: int=Base.incremental_cost(owner_state.game.roster,owner_state.game.person_by_id(str(_view["person"]["id"])))
   actions.add_child(_label("%d TALENT · %d AVAILABLE" % [price,owner_state.remaining()]))
   var invite:=_button("INVITE %s · %d TALENT" % [str(_view["person"]["name"]).to_upper(),price],"AuditionInvite",_invite)
   invite.disabled=not owner_state.can_recruit(str(_view["person"]["id"]))
   invite.set_meta("permitted",not invite.disabled)
   actions.add_child(invite)
   actions.add_child(_button("PASS FOR NOW","AuditionPass",_pass))
 var exits:=HBoxContainer.new()
 exits.add_theme_constant_override("separation",8)
 if _view.get("ok",false) and _view.get("active",false):exits.add_child(_button("END AUDITION","AuditionAbort",_act.bind("abort","")))
 exits.add_child(_button("PAUSE / MENU","AuditionMenu",_menu))
 actions.add_child(exits)

func _questions(parent: Node) -> void:
 var answers: Dictionary=_view.get("conversation",{}).get("answers",{})
 for key in ["working_style","commitment"]:
  if answers.has(key):parent.add_child(_label("✓ "+str(Connections.LABELS[answers[key]]),16))
 for key in ["commitment","working_style"]:
  if answers.has(key):
   parent.add_child(_label(str(_view.person.name)+" · "+Connections.reply(str(_view.candidate_id),key,str(answers[key])),16));break
 for key in ["working_style","commitment"]:
  if answers.has(key):continue
  parent.add_child(_label(Connections.TITLES[key],17))
  for choice in Connections.QUESTIONS[key]:
   var button: Button=_button(Connections.LABELS[choice],"AuditionTalk_"+key+"_"+str(choice),_act.bind("talk",key+":"+str(choice)))
   Poster.choice_style(button);parent.add_child(button)
  break

func _stop_takes() -> void:
 if is_instance_valid(_audio):_audio.stop()

func _hear_version(first: bool) -> void:
 if _busy or _finish_voice():return
 var wanted: bool=first and _view.get("phase") in ["response","decision"]
 if _show_prior!=wanted:_toggle_prior()
 if is_instance_valid(_audio):
  _audio.request_play()
  if not _audio.playing:
   _notice.text="SOUND OFF · Use Pause / Menu to enable audio." if _audio._muted() else "This sample is unavailable. The written part is still here."
   _notice.visible=true

func _fit_bar(button: Button,inset: MarginContainer) -> void:
 if not is_instance_valid(button) or not is_instance_valid(inset):return
 if button.is_queued_for_deletion() or inset.is_queued_for_deletion() or not button.is_inside_tree() or not inset.is_inside_tree():return
 var minimum: float=maxf(88,inset.get_combined_minimum_size().y)
 if not is_equal_approx(button.custom_minimum_size.y,minimum):button.custom_minimum_size.y=minimum

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
  words.add_child(C.paper_label(_part(bar)))
  inset.minimum_size_changed.connect(_fit_bar.bind(button,inset))
  _fit_bar.call_deferred(button,inset)
  _board.add_child(button)

func _inspect(index: int) -> void:
 if _busy:return
 var bars: Array=_view["before_bars"] if _show_prior else _view["bars"]
 var bar: Dictionary=bars[index]
 _inspector.text="Bar %d · %s. %s: %s." % [int(bar["number"]),str(bar["vocal"]),_instrument(),_part(bar)]
 _inspector.set_meta("inspected_bar",index+1)

func _instrument() -> String:
 if _view.get("person",{}).get("role","")=="Drummer":return "Drums"
 return "Bass" if _view.get("person",{}).get("role","")=="Bassist" else "Guitar"

func _part(bar: Dictionary) -> String:
 return str(bar.get("part",bar.get("guitar","")))

func _toggle_prior() -> void:
 if _busy:return
 _show_prior=not _show_prior
 if _has_backing_choice():_refresh_listening_audio()
 elif is_instance_valid(_audio):_audio.set_clip(_content.material_id("" if _show_prior else str(_view.get("request",""))))
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
 if action=="talk" and result.get("ok",false) and is_instance_valid(_question_box):
  _view=result.view;_expected=result.expected
  for child in _question_box.get_children():
   _question_box.remove_child(child);child.queue_free()
  _set_busy(false);_questions(_question_box)
  return
 _returned(result)

func _invite() -> void:
 if _busy or _finish_voice():return
 _set_busy(true)
 var result: Dictionary=owner_state.resolve_audition_response("invite",_expected.duplicate(true)) if _view.get("phase")=="response" else owner_state.invite_audition(_expected.duplicate(true))
 _returned(result)

func _pass() -> void:
 if _busy or _finish_voice():return
 _set_busy(true)
 var result: Dictionary=owner_state.resolve_audition_response("pass",_expected.duplicate(true)) if _view.get("phase")=="response" else owner_state.audition_action("pass",_expected.duplicate(true))
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

func _has_backing_choice() -> bool:
 return str(_view.get("candidate_id",""))=="cast_jack" and owner_state!=null and owner_state.game.genre=="Indie rock" and not _view.get("held",false) and _view.get("active",false) and _view.get("phase","") in ["tryout","response","decision"]

func _read_audio_catalogue(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):return {}
 var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
 return value if value is Dictionary else {}

static func _audio_strings_match(left: Variant,right: Variant) -> bool:
 if typeof(left)!=TYPE_STRING or typeof(right)!=TYPE_STRING:return false
 return left==right

func _backing_entry() -> Dictionary:
 if not _has_backing_choice() or not _audio_context().get("allowed",false):return {}
 var version: Variant=_backing_catalogue.get("schema_version")
 if typeof(version) not in [TYPE_INT,TYPE_FLOAT] or version!=1:return {}
 if typeof(_backing_catalogue.get("content_version"))!=TYPE_STRING or _backing_catalogue.content_version!=_content.VERSION:return {}
 if not _audio_strings_match(_backing_catalogue.get("content_source"),"res://experiments/playable_flightcase/audition_content.gd") or not _audio_strings_match(_backing_catalogue.get("content_sha256"),_solo_catalogue.get("content_sha256","")):return {}
 var registry_sha: Variant=_backing_catalogue.get("solo_registry_sha256")
 if typeof(registry_sha)!=TYPE_STRING or registry_sha.length()!=64 or FileAccess.get_sha256(Profiles.audio_manifest("cast_jack"))!=registry_sha:return {}
 var material: String=_content.material_id("" if _show_prior else str(_view.get("request","")))
 var materials: Variant=_backing_catalogue.get("materials")
 var solos: Variant=_solo_catalogue.get("materials")
 if not materials is Dictionary or not solos is Dictionary:return {}
 var entry: Variant=materials.get(material)
 var solo: Variant=solos.get(material)
 if not entry is Dictionary or not solo is Dictionary or not AudioPart.entry_approved(entry):return {}
 if typeof(entry.get("owner_listening_accepted"))!=TYPE_BOOL or entry.owner_listening_accepted!=false:return {}
 if not _audio_strings_match(entry.get("source_solo_OGG_sha256"),solo.get("sha256","")) or not _audio_strings_match(entry.get("path"),BACKING_FILES.get(material,"")):return {}
 var path: String=str(entry.get("path",""))
 var digest: Variant=entry.get("sha256")
 if typeof(digest)!=TYPE_STRING or digest.length()!=64 or not ResourceLoader.exists(path):return {}
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=digest:return {}
 return entry

func _choose_audio_mode(backing: bool) -> void:
 if _busy or not _has_backing_choice() or (backing and _backing_entry().is_empty()):return
 _use_backing=backing
 _refresh_listening_audio()

func _refresh_listening_audio() -> void:
 if not is_instance_valid(_audio_slot):return
 if is_instance_valid(_audio):
  _audio.release_stream()
  if _audio.get_parent()!=null:_audio.get_parent().remove_child(_audio)
  _audio.queue_free()
 var available: bool=not _backing_entry().is_empty()
 if _use_backing and not available:_use_backing=false
 var solo: Button=_mode_buttons.get("solo")
 var backing: Button=_mode_buttons.get("backing")
 solo.set_pressed_no_signal(not _use_backing)
 backing.set_pressed_no_signal(_use_backing)
 backing.text="WITH BACKING" if available else "NO BACKING"
 backing.disabled=_busy or not available
 backing.set_meta("permitted",available)
 backing.tooltip_text="Hear the same revealed guitar with an arranged bass-and-drum backing." if available else "Backing example unavailable. The solo part and complete written sketch remain available."
 _audio=AudioPart.new()
 _audio.manifest_path=backing_manifest_path if _use_backing else Profiles.audio_manifest("cast_jack")
 _audio.controls_visible=false
 _audio.play_caption="PLAY WITH BACKING" if _use_backing else "PLAY SOLO PART"
 _audio.available_hint="Same revealed guitar part; arranged accompaniment is an illustration." if _use_backing else "Hear the unchanged solo guitar part."
 _audio.configure(_audio_context)
 _audio.set_clip(_content.material_id("" if _show_prior else str(_view.get("request",""))))
 _audio_slot.add_child(_audio)
 set_meta("listening_mode","backing" if _use_backing else "solo")

func _reveal_audio_mode(button: Button) -> void:
 var parent: Node=button.get_parent()
 while parent!=null and not parent is ScrollContainer:parent=parent.get_parent()
 if parent is ScrollContainer:parent.ensure_control_visible(button)

func _exit_tree() -> void:
 if is_instance_valid(_audio):_audio.release_stream()
