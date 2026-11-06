extends VBoxContainer
## The writing room: live native controls, a local take and one original paid owner.
const Recipe = preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Dial = preload("res://experiments/playable_flightcase/mixing_control.gd")
const Audio = preload("res://experiments/playable_flightcase/mixing_audio.gd")
const Rules = preload("res://experiments/playable_flightcase/song_workbench.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const Sound = preload("res://experiments/playable_flightcase/band_sound.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const FONT = preload("res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf")
const FACE = preload("res://experiments/playable_flightcase/art/mixing_desk/desk_surface.png")
signal write_requested(request: Dictionary)
signal exit_ready(destination: String)
signal sound_requested
signal closed
var owner_state
var reduced_motion := false
var _view: Dictionary={}
var _expected: Dictionary={}
var _recipe: Dictionary={}
var _decision: Dictionary={}
var _compare := false
var _leader_index := 0
var _busy := false
var _hydrating := false
var _audio
var _scroll: ScrollContainer
var _spread: GridContainer
var _grid: GridContainer
var _controls: Dictionary={}
var _title: LineEdit
var _band: Label
var _brief: Label
var _stages: Array[Label]=[]
var _hear: Button
var _commit: Button
var _sound: Button
var _cost: Label
var _notice: Label
var _note_panel: PanelContainer
var _member_name: Label
var _member_note: Label
var _portrait: TextureRect
var _response: Label
var _compare_button: Button
var _responses: Array[Button]=[]
var _themes: Array[Button]=[]
var _leader: Label
var _written: Label
var _buttons: Array[Button]=[]
var _dialog_layer: CanvasLayer
var _dialog: Control
var _dialog_error: Label
var _exit_destination := ""
var _exit_expected: Dictionary={}
var _exit_epoch := 0
var _layout := Vector2.ZERO
static var _surface: Texture2D
static var _plate: Texture2D

func configure(state_owner,reduced: bool=false) -> void:
 owner_state=state_owner;reduced_motion=reduced
 _view=owner_state.workbench_view();_expected=owner_state.workbench_expected()
 set_meta("mixing_desk",true)

static func _surface_style() -> StyleBoxTexture:
 if _surface==null:
  var image: Image=FACE.get_image()
  image.resize(600,400,Image.INTERPOLATE_LANCZOS)
  _surface=ImageTexture.create_from_image(image)
 var style:=StyleBoxTexture.new()
 style.texture=_surface;style.set_texture_margin_all(25);style.set_content_margin_all(16)
 return style

static func _plate_style(focus: bool=false) -> StyleBoxTexture:
 if _plate==null:
  # The independent raised cap supplies an action surface; the screw-ended
  # nameplate remains reserved for control captions.
  var image: Image=Dial.SOURCE.get_image().get_region(Rect2i(1050,193,423,199))
  image.resize(304,143,Image.INTERPOLATE_LANCZOS)
  _plate=ImageTexture.create_from_image(image)
 var style:=StyleBoxTexture.new()
 style.texture=_plate;style.set_texture_margin_all(18)
 style.content_margin_left=12;style.content_margin_right=12
 style.content_margin_top=8;style.content_margin_bottom=8
 style.modulate_color=Color(1.2,1.09,0.87) if focus else Color.WHITE
 return style

func _label(words: String,points: int=16,paper: bool=false) -> Label:
 var label: Label=C.label(words,points,"notepaper" if paper else "flightcase")
 label.add_theme_font_override("font",FONT)
 return label

func _button(words: String,id: String,callback: Callable,brass: bool=false) -> Button:
 var button: Button=C.button(words)
 button.name=id;button.custom_minimum_size.y=48
 button.add_theme_font_override("font",FONT)
 button.add_theme_font_size_override("font_size",17)
 button.mouse_filter=Control.MOUSE_FILTER_PASS
 if brass:
  for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,_plate_style(state in ["hover","pressed"]))
  button.add_theme_stylebox_override("focus",_plate_style(true))
  for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:button.add_theme_color_override(state,Color("21170f"))
 button.pressed.connect(callback);_buttons.append(button)
 return button

func _ready() -> void:
 name="MixingDesk"
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",6)
 _build();refresh_saved(false)
 resized.connect(_resized)
 visibility_changed.connect(func():
  if not is_visible_in_tree():
   _stop_audio();_cancel_controls()
   if is_instance_valid(_dialog):_close_dialog())
 call_deferred("_resized")

func _build() -> void:
 var header:=HBoxContainer.new();header.add_theme_constant_override("separation",4);add_child(header)
 var back: Button=_button("‹","MixingBack",request_exit.bind("career"));back.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;back.custom_minimum_size.x=48;header.add_child(back)
 var heading: Label=_label("THE WRITING ROOM",22);heading.name="MixingHeading";heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(heading)
 _sound=_button("♫ ON","MixingSound",func():_stop_audio();sound_requested.emit();_refresh_audio());_sound.size_flags_horizontal=Control.SIZE_SHRINK_END;_sound.custom_minimum_size.x=58;header.add_child(_sound)
 var menu: Button=_button("MENU","MixingMenu",request_exit.bind("menu"));menu.size_flags_horizontal=Control.SIZE_SHRINK_END;menu.custom_minimum_size.x=54;header.add_child(menu)
 var identity:=PanelContainer.new();identity.name="MixingProjectStrip";identity.add_theme_stylebox_override("panel",Paper.scorecard());identity.mouse_filter=Control.MOUSE_FILTER_PASS;add_child(identity)
 var identity_rows:=VBoxContainer.new();identity_rows.add_theme_constant_override("separation",1);identity.add_child(identity_rows)
 _band=_label("",20,true);_band.name="MixingBand";identity_rows.add_child(_band)
 _title=LineEdit.new();_title.name="MixingTitle";_title.placeholder_text="Name your original";_title.max_length=48;_title.custom_minimum_size.y=44
 _title.add_theme_font_override("font",FONT);_title.add_theme_font_size_override("font_size",23);_title.add_theme_color_override("font_color",Color("292015"));_title.add_theme_color_override("caret_color",Color("292015"));_title.add_theme_color_override("font_placeholder_color",Color("71614c"))
 _title.add_theme_stylebox_override("normal",StyleBoxEmpty.new());_title.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 _title.text_changed.connect(func(_words: String):
  if not _hydrating:_invalidate_response();_refresh())
 identity_rows.add_child(_title)
 _brief=_label("",16,true);_brief.name="MixingBrief";identity_rows.add_child(_brief)
 var stages:=HBoxContainer.new();stages.name="MixingStages";stages.add_theme_constant_override("separation",6);add_child(stages)
 for i in range(3):
  var label: Label=_label("%d  %s" % [i+1,["FEEL","BUILD","TAKE"][i]],17);label.name="MixingStage_%d" % i;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.custom_minimum_size.y=24;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stages.add_child(label);_stages.append(label)
 _scroll=ScrollContainer.new();_scroll.name="MixingBodyScroll";_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;_scroll.follow_focus=true;_scroll.get_v_scroll_bar().focus_mode=Control.FOCUS_ALL;add_child(_scroll)
 _spread=GridContainer.new();_spread.name="MixingSpread";_spread.columns=1;_spread.add_theme_constant_override("h_separation",14);_spread.add_theme_constant_override("v_separation",10);_spread.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_spread)
 var console:=PanelContainer.new();console.name="MixingConsole";console.size_flags_horizontal=Control.SIZE_EXPAND_FILL;console.mouse_filter=Control.MOUSE_FILTER_PASS;console.add_theme_stylebox_override("panel",_surface_style());_spread.add_child(console)
 var surface:=VBoxContainer.new();surface.add_theme_constant_override("separation",8);console.add_child(surface)
 _grid=GridContainer.new();_grid.name="MixingSoundControls";_grid.columns=2;_grid.add_theme_constant_override("h_separation",6);_grid.add_theme_constant_override("v_separation",8);surface.add_child(_grid)
 for i in range(4):_add_control(_grid,i,"rotary" if i<2 else "fader")
 var switches:=HBoxContainer.new();switches.add_theme_constant_override("separation",6);surface.add_child(switches)
 _add_control(switches,4,"switch");_add_control(switches,5,"switch")
 var lyric_title: Label=_label("LYRICAL DIRECTION",17);lyric_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;surface.add_child(lyric_title)
 var lyrical:=HBoxContainer.new();lyrical.name="MixingLyricalDirection";lyrical.add_theme_constant_override("separation",4);surface.add_child(lyrical)
 for i in range(3):
  var button: Button=_button(Recipe.LABELS[6][i],"MixingTheme_%d" % i,_choose.bind("theme",i));lyrical.add_child(button);_themes.append(button)
 _note_panel=PanelContainer.new();_note_panel.name="MixingMemberCard";_note_panel.mouse_filter=Control.MOUSE_FILTER_PASS;_note_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_note_panel.add_theme_stylebox_override("panel",Paper.scorecard());_spread.add_child(_note_panel)
 var note_body:=VBoxContainer.new();note_body.add_theme_constant_override("separation",6);_note_panel.add_child(note_body)
 var person:=HBoxContainer.new();person.add_theme_constant_override("separation",8);note_body.add_child(person)
 _portrait=TextureRect.new();_portrait.name="MixingMemberPortrait";_portrait.custom_minimum_size=Vector2(48,48);_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;person.add_child(_portrait)
 _member_name=_label("",20,true);_member_name.name="MixingMemberName";person.add_child(_member_name)
 _member_note=_label("",18,true);_member_note.name="MixingMemberNote";note_body.add_child(_member_note)
 var responses:=VBoxContainer.new();responses.name="MixingMemberResponses";responses.add_theme_constant_override("separation",4);note_body.add_child(responses)
 for pair in [["TRY THEIR IDEA","try"],["KEEP MY DIRECTION","keep"],["LEAVE UNANSWERED","dismiss"]]:
  var button: Button=_button(pair[0],"MixingResponse_"+pair[1],_respond.bind(pair[1]));responses.add_child(button);_responses.append(button)
 _response=_label("",16,true);_response.name="MixingResponseStatus";note_body.add_child(_response)
 _compare_button=_button("COMPARE THE TAKES","MixingCompare",_compare_take);note_body.add_child(_compare_button)
 _written=_label("",16,true);_written.name="MixingWrittenDirection";_written.visible=false;note_body.add_child(_written)
 note_body.add_child(_button("READ THE DIRECTION","MixingReadDirection",func():_written.visible=not _written.visible))
 var lead_row:=HBoxContainer.new();lead_row.add_theme_constant_override("separation",4);note_body.add_child(lead_row)
 var prev: Button=_button("‹","MixingLeaderPrevious",_change_leader.bind(-1));prev.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;prev.custom_minimum_size.x=48;lead_row.add_child(prev)
 _leader=_label("",16,true);_leader.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;lead_row.add_child(_leader)
 var next: Button=_button("›","MixingLeaderNext",_change_leader.bind(1));next.size_flags_horizontal=Control.SIZE_SHRINK_END;next.custom_minimum_size.x=48;lead_row.add_child(next)
 note_body.add_child(_button("PLAN OUR WEEK","MixingPlanWeek",request_exit.bind("planning")))
 var activities:=HBoxContainer.new();activities.add_theme_constant_override("separation",6);note_body.add_child(activities)
 activities.add_child(_button("REHEARSE","MixingRehearse",request_exit.bind("practice:tighten")))
 activities.add_child(_button("CLEAR AIR","MixingClearAir",request_exit.bind("practice:connect")))
 var history: Button=_button("FINISHED ORIGINALS","MixingHistory",request_exit.bind("finished"));note_body.add_child(history)
 _notice=_label("",16);_notice.name="MixingNotice";_notice.visible=false;add_child(_notice)
 var dock:=VBoxContainer.new();dock.name="MixingCommitDock";dock.add_theme_constant_override("separation",4);add_child(dock)
 _cost=_label("",16);_cost.name="MixingPublicCost";_cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;dock.add_child(_cost)
 var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);dock.add_child(actions)
 _hear=_button("▶ HEAR THE IDEA","MixingHear",_hear_take);actions.add_child(_hear)
 _commit=_button("COMMIT SESSION","MixingCommit",_request_commit,true);actions.add_child(_commit)
 _audio=Audio.new();_audio.name="MixingAudio";_audio.configure(_audio_context);add_child(_audio);_audio.status_changed.connect(_refresh_audio)

func _add_control(parent: Node,index: int,kind: String) -> void:
 var control=Dial.new();control.configure(Recipe.FIELDS[index],Recipe.TITLES[index],kind,Recipe.LABELS[index]);parent.add_child(control);_controls[Recipe.FIELDS[index]]=control
 control.value_changed.connect(func(value: float):_choose(Recipe.FIELDS[index],int(value)))
 control.gesture_started.connect(_stop_audio)

func _project() -> Dictionary:
 return _view.get("project",{})

func _target() -> Dictionary:
 var result: Dictionary=Rules._target(owner_state.game.career,_title.text,_leader_index)
 return result.get("target",{}) if result.get("ok",false) else {}

func _saved_recipe() -> Dictionary:
 var value: Dictionary=_project().get("fragment",{}).get("producer_recipe",{}).duplicate(true)
 if Recipe.valid(value):value.stage=int(owner_state.game.career.get("song_draft_progress",0))
 return value

func _saved_decision() -> Dictionary:
 var decision: Dictionary=_project().get("producer_decision",{})
 if not decision.is_empty() and decision.get("stage")==int(owner_state.game.career.get("song_draft_progress",0)) and Rules._same(decision.get("chosen_recipe"),_recipe):return {"choice":decision.choice,"base_recipe":decision.base_recipe.duplicate(true),"offer_id":decision.offer_id}
 return {}

func refresh_saved(preserve_local: bool=false) -> void:
 _stop_audio();_view=owner_state.workbench_view();_expected=owner_state.workbench_expected()
 if not is_instance_valid(_title):return
 if not preserve_local:
  _hydrating=true;_recipe=_saved_recipe();_decision={};_compare=false
  _title.text=str(_project().get("target",{}).get("title",""));_leader_index=int(_project().get("target",{}).get("leader_ref",{}).get("slot",0))
  _decision=_saved_decision();_hydrating=false
 _refresh()

func _payload() -> Dictionary:
 return {"recipe":_recipe.duplicate(true),"title":_title.text,"leader_index":_leader_index,"decision":_decision.duplicate(true)}

func has_local_edits() -> bool:
 if not is_instance_valid(_title) or not Recipe.valid(_recipe):return false
 var target: Dictionary=_project().get("target",{})
 return not Rules._same(_recipe,_saved_recipe()) or _title.text.strip_edges().to_upper()!=str(target.get("title","")) or _leader_index!=int(target.get("leader_ref",{}).get("slot",0)) or not Rules._same(_decision,_saved_decision())

func _invalidate_response() -> void:
 _stop_audio();_decision={};_compare=false

func _choose(field: String,index: int) -> void:
 if _hydrating or _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe):return
 var axis: int=Recipe.FIELDS.find(field)
 if axis<0 or index<0 or index>=Recipe.VALUES[axis].size() or _recipe[field]==Recipe.VALUES[axis][index]:return
 _invalidate_response();_recipe[field]=Recipe.VALUES[axis][index];_refresh()

func _change_leader(direction: int) -> void:
 if _busy or is_instance_valid(_dialog):return
 var members: Array=owner_state.game.career.get("members",[])
 for step in range(1,members.size()+1):
  var index: int=posmod(_leader_index+direction*step,members.size())
  if members[index].get("life_status","active")=="active":_leader_index=index;_invalidate_response();_refresh();return

func _offer_base() -> Dictionary:
 return _decision.get("base_recipe",_recipe).duplicate(true)

func _respond(choice: String) -> void:
 if _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe):return
 var target: Dictionary=_target()
 var base: Dictionary=_offer_base()
 var request: Dictionary=Recipe.offer(base,target.get("respondent_ref",{}))
 if request.is_empty():return
 _stop_audio();_compare=false;_recipe=base.duplicate(true)
 if choice=="try":_recipe[request.field]=request.value
 _decision={"choice":choice,"base_recipe":base,"offer_id":request.offer_id}
 _refresh()

func _previous() -> Dictionary:
 if Recipe.valid(_decision.get("base_recipe")) and not Rules._same(_recipe,_decision.base_recipe):return _decision.base_recipe.duplicate(true)
 var value: Dictionary=_project().get("prior_fragment",{}).get("producer_recipe",{})
 return value.duplicate(true) if Recipe.valid(value) and int(value.stage)<=int(_recipe.get("stage",0)) and not Rules._same(value,_recipe) else {}

func _compare_take() -> void:
 if _busy or is_instance_valid(_dialog) or _previous().is_empty():return
 _stop_audio();_compare=not _compare;_refresh()

func _audio_context() -> Dictionary:
 var live: Dictionary=owner_state.workbench_view()
 var selected: Dictionary=_previous() if _compare else _recipe
 var allowed: bool=is_visible_in_tree() and not _busy and not is_instance_valid(_dialog) and live.get("ok",false) and live.get("active",false) and not live.get("held",true) and Rules._same(_expected,owner_state.workbench_expected()) and Recipe.valid(selected)
 if allowed:allowed=Rules._same(selected.brief,Sound.read(owner_state.game.career)) and int(selected.stage)<=int(owner_state.game.career.get("song_draft_progress",0))
 return {"allowed":allowed,"recipe":selected.duplicate(true)}

func _hear_take() -> void:
 if _busy or is_instance_valid(_dialog):return
 if _audio.playing:_audio.stop()
 else:
  if not _audio.request_play():_show_notice(_audio.hint())
 _refresh_audio()

func _stop_audio() -> void:
 if is_instance_valid(_audio):_audio.stop()

func _cancel_controls() -> void:
 for control in _controls.values():control.cancel_gesture()

func _refresh_audio() -> void:
 if not is_instance_valid(_hear) or not is_instance_valid(_audio):return
 var master: int=AudioServer.get_bus_index("Master")
 var off: bool=master<0 or AudioServer.is_bus_mute(master)
 _sound.text="♫ OFF" if off else "♫ ON"
 _hear.text="■ STOP" if _audio.playing else ("SOUND OFF" if off else ("▶ HEAR EARLIER" if _compare else "▶ HEAR THE IDEA"))
 _hear.disabled=_busy or is_instance_valid(_dialog) or off or not _audio.available()
 _hear.tooltip_text=_audio.hint()

func _refresh() -> void:
 if not is_instance_valid(_title):return
 var valid: bool=Recipe.valid(_recipe) and _view.get("ok",false) and not _view.get("held",true)
 var modal: bool=is_instance_valid(_dialog)
 var stage: int=int(owner_state.game.career.get("song_draft_progress",0))
 _band.text=str(owner_state.game.career.get("band_name","YOUR BAND")).to_upper()
 _brief.text=Sound.summary(Sound.read(owner_state.game.career))+"  ·  DAY %d / £%d" % [int(owner_state.game.career.get("tour_day",1)),int(owner_state.game.career.get("cash",0))]
 _title.editable=not _busy and not modal and valid
 _title.focus_mode=Control.FOCUS_NONE if modal else Control.FOCUS_ALL
 for i in range(_stages.size()):_stages[i].add_theme_color_override("font_color",Color("f1c374") if i==stage else Color("aa9c83"))
 for key in _controls:
  var control=_controls[key]
  if valid:control.set_value_no_signal(Recipe.VALUES[Recipe.FIELDS.find(key)].find(_recipe[key]))
  control.set_locked(_busy or modal or not valid);control.queue_redraw()
 for i in range(_themes.size()):
  var selected: bool=valid and _recipe.theme==Recipe.VALUES[6][i]
  _themes[i].modulate=Color(1.0,0.77,0.4) if selected else Color.WHITE
 var target: Dictionary=_target() if valid else {}
 var respondent: Dictionary=target.get("respondent_ref",{})
 var note: Dictionary=Recipe.note(respondent,_offer_base(),{"day":int(owner_state.game.career.get("tour_day",1))}) if valid else {}
 _member_name.text=str(respondent.get("name","YOUR DIRECTION")).to_upper()
 _member_note.text=str(note.get("note",{}).get("text","Review the saved band and direction."))
 var portrait_path: String=""
 for source in Cast.combined_people():
  if source.get("id")==respondent.get("candidate_id"):portrait_path=str(source.get("portrait_preview",""));break
 _portrait.texture=load(portrait_path) if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path) else null
 _portrait.visible=_portrait.texture!=null;_portrait.set_meta("source",portrait_path)
 for button in _responses:button.visible=not respondent.is_empty()
 var person_name: String=str(respondent.get("name","THEIR")).to_upper()
 _responses[0].text="TRY "+person_name+"’S IDEA" if person_name.length()<=14 else "TRY THEIR IDEA"
 for i in range(_responses.size()):
  var chosen: bool=_decision.get("choice")==["try","keep","dismiss"][i]
  var button: Button=_responses[i]
  if i>0:button.text="KEEP MY DIRECTION" if i==1 else "LEAVE UNANSWERED"
  button.toggle_mode=true;button.set_pressed_no_signal(chosen)
  button.modulate=Color(1.0,0.77,0.4) if chosen else Color.WHITE
  if chosen:button.text="SELECTED · "+button.text
 _response.text="Choose how to answer before committing." if not respondent.is_empty() and _decision.is_empty() else ("Their idea is selected. Compare both takes freely." if _decision.get("choice")=="try" else ("You considered the idea and kept your direction." if _decision.get("choice")=="keep" else ("You chose to leave the idea unanswered." if _decision.get("choice")=="dismiss" else "Your direction is ready.")))
 _compare_button.visible=not _previous().is_empty();_compare_button.text="BACK TO CURRENT TAKE" if _compare else "COMPARE THE TAKES"
 _written.text=("EARLIER TAKE\n" if _compare else "CURRENT DIRECTION\n")+Recipe.written(_previous() if _compare else _recipe)+"\n"+_audio.hint()
 var members: Array=owner_state.game.career.get("members",[])
 _leader.text=(str(members[_leader_index].get("name",""))+" · SESSION LEAD") if _leader_index>=0 and _leader_index<members.size() else "REVIEW SESSION LEAD"
 var work: Dictionary=Situation.inspect_writing(owner_state.game.career)
 var available: bool=work.get("ok",false) and work.get("can_write",false)
 _cost.text="Uses 1 day · No studio hire · Session %d of 3" % (stage+1)
 if not work.get("ok",false):_cost.text=str(work.get("message","Review availability."))
 elif not available:_cost.text="UNAVAILABLE TODAY · "+str(work.get("unavailable_summary",work.get("work_names","Review commitments")))
 elif work.get("plan_status")=="due":_cost.text="1 day · No hire · Misses today's agreed rehearsal"
 for button in _buttons:button.disabled=_busy or modal or not valid
 _commit.text="COMMIT SESSION" if available else "BAND UNAVAILABLE"
 _commit.disabled=_busy or modal or not valid or not available
 _refresh_audio()

func _resized() -> void:
 if not is_inside_tree():return
 if _layout!=size:
  _stop_audio();_cancel_controls()
  if is_instance_valid(_dialog):_close_dialog();_show_notice("Layout changed. Your local direction is retained.")
 _layout=size
 var wide: bool=size.x>=840
 _spread.columns=2 if wide else 1
 _grid.columns=4 if wide and size.x>=1120 else 2
 _note_panel.custom_minimum_size.x=300 if wide else 0

func _show_notice(words: String) -> void:
 _notice.text=words;_notice.visible=not words.is_empty()

func show_commit_error(words: String) -> void:
 _show_notice(words)

func _request_commit() -> void:
 if _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe):return
 var respondent: Dictionary=_target().get("respondent_ref",{})
 if _decision.is_empty():
  if respondent.is_empty():_decision={"choice":"none","base_recipe":_recipe.duplicate(true),"offer_id":""}
  else:
   _show_notice(str(respondent.get("name","Your bandmate"))+" has an idea. Try it, keep your direction, or explicitly leave it unanswered.")
   _scroll.ensure_control_visible(_note_panel);_responses[0].grab_focus();return
 _stop_audio();_cancel_controls();_busy=true;_refresh()
 write_requested.emit({"expected":_expected.duplicate(true),"mixing_payload":_payload()})
 _busy=false
 _view=owner_state.workbench_view();_expected=owner_state.workbench_expected()
 _refresh()

func request_exit(destination: String) -> void:
 if _busy or is_instance_valid(_dialog):return
 _stop_audio();_cancel_controls()
 if not has_local_edits():exit_ready.emit(destination);return
 _exit_epoch+=1;_exit_destination=destination;_exit_expected=_expected.duplicate(true)
 _dialog_layer=CanvasLayer.new();_dialog_layer.layer=30;add_child(_dialog_layer)
 _dialog=Control.new();_dialog.name="MixingExitDialog";_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.mouse_filter=Control.MOUSE_FILTER_STOP;_dialog_layer.add_child(_dialog)
 var shade:=ColorRect.new();shade.color=Color(0,0,0,0.86);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.add_child(center)
 var panel:=PanelContainer.new();panel.name="MixingExitCard";panel.custom_minimum_size.x=minf(420,maxf(280,size.x-28));panel.add_theme_stylebox_override("panel",_surface_style());center.add_child(panel)
 var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);panel.add_child(body)
 body.add_child(_label("KEEP THIS DIRECTION?",22))
 _dialog_error=_label("Save the draft free, discard these local edits, or keep shaping. No writing day is used.",18);body.add_child(_dialog_error)
 var epoch: int=_exit_epoch
 body.add_child(_button("SAVE DRAFT FREE","MixingExitSave",_exit_choice.bind("save",epoch)))
 body.add_child(_button("DISCARD LOCAL EDITS","MixingExitDiscard",_exit_choice.bind("discard",epoch)))
 var keep: Button=_button("KEEP SHAPING","MixingExitKeep",_exit_choice.bind("keep",epoch));body.add_child(keep)
 _refresh();keep.disabled=false
 for button in body.get_children():
  if button is Button:button.disabled=false
 keep.call_deferred("grab_focus")

func _close_dialog() -> void:
 _exit_epoch+=1
 if is_instance_valid(_dialog_layer):remove_child(_dialog_layer);_dialog_layer.queue_free()
 _dialog_layer=null;_dialog=null;_dialog_error=null
 var retained: Array[Button]=[]
 for button in _buttons:
  if is_instance_valid(button) and not str(button.name).begins_with("MixingExit") :retained.append(button)
 _buttons=retained
 _refresh()

func _exit_choice(choice: String,epoch: int) -> void:
 if _busy or not is_instance_valid(_dialog) or epoch!=_exit_epoch:return
 if choice=="keep":_close_dialog();_controls.tone.grab_focus();return
 var destination: String=_exit_destination
 if choice=="save":
  _busy=true
  var result: Dictionary=owner_state.save_mixing_sketch(_exit_expected,_payload())
  _busy=false
  if not result.get("ok",false):
   _view=result.view;_expected=result.expected;_exit_expected=_expected.duplicate(true);_dialog_error.text=str(result.message);return
 elif choice!="discard":return
 _close_dialog();refresh_saved(false);exit_ready.emit(destination)

func _unhandled_key_input(event: InputEvent) -> void:
 if is_instance_valid(_dialog) and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  _exit_choice("keep",_exit_epoch);get_viewport().set_input_as_handled()
