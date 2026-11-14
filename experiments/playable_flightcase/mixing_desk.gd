extends VBoxContainer
## The writing room: live native controls, a local take and one original paid owner.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Recipe = preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Dial = preload("res://experiments/playable_flightcase/poster_choice.gd")
const Audio = preload("res://experiments/playable_flightcase/mixing_audio.gd")
const Rules = preload("res://experiments/playable_flightcase/song_workbench.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const DayNavigation=preload("res://experiments/playable_flightcase/day_navigation.gd")
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
var _collaborator_id := ""
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
var _voice_preview: Label
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
var _foundations: Array[Button]=[]
var _foundation_group:=ButtonGroup.new()
var _foundation_note: Label
var _bank_library: VBoxContainer
var _bank_more: Button
var _bank_open := false
var _demo_path: Label
var _pause_open := false
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
var _target_cache: Dictionary={}
var _target_key := ""
var _initial_view := false
var _shape_open := false
var _shape_axis := 0
var _review_ready_at := 0
var _console: PanelContainer
var _shape_toggle: Button
var _shape_steps: VBoxContainer
var _theme_heading: Label
var _lyrical: HBoxContainer
var _title_reading: Label
var _change_reply: Button
static var _surface: Texture2D
static var _plate: Texture2D

func configure(state_owner,reduced: bool=false,initial_view: Dictionary={}) -> void:
 owner_state=state_owner;reduced_motion=reduced
 _view=owner_state.workbench_view() if initial_view.is_empty() else initial_view
 _expected=_view.expected.duplicate(true);_initial_view=true
 set_meta("mixing_desk",true)

static func _surface_style() -> StyleBoxTexture:
 return Poster.stock(Poster.INK,16)

static func _plate_style(focus: bool=false) -> StyleBoxTexture:
 var style: StyleBoxTexture=Poster.control_stock(Poster.GOLD,12)
 if focus:style.modulate_color=Color(1.04,1.04,1.04)
 return style

func _label(words: String,points: int=16,paper: bool=false) -> Label:
 var label: Label=Poster.label(words,points,Poster.INK if paper else Poster.PAPER)
 label.add_theme_font_override("font",Poster.display_font() if points>=22 else FONT)
 return label

func _button(words: String,id: String,callback: Callable,brass: bool=false) -> Button:
 var button: Button=Poster.button(words,brass)
 if id in ["MixingBack","MixingSound","MixingPauseButton"]:
  button.free();button=Poster.quiet(words)
 button.name=id;button.custom_minimum_size.y=48
 button.add_theme_font_override("font",FONT)
 button.add_theme_font_size_override("font_size",17)
 button.mouse_filter=Control.MOUSE_FILTER_PASS
 if brass:
  for state in ["normal","hover","pressed","hover_pressed","disabled"]:button.add_theme_stylebox_override(state,_plate_style(state in ["hover","pressed"]))
  button.add_theme_stylebox_override("focus",_plate_style(true))
  for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:button.add_theme_color_override(state,Color("21170f"))
 button.pressed.connect(callback);_buttons.append(button)
 if id in ["MixingReadDirection","MixingPlanWeek","MixingHistory","MixingRehearse","MixingClearAir","MixingJam","MixingResponse_keep","MixingResponse_dismiss"]:
  preload("res://experiments/playable_flightcase/control_roles.gd").quiet(button,true)
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
 var back: Button=_button("BACK","MixingBack",_navigation_back)
 var menu: Button=_button("MENU","MixingPauseButton",_show_pause)
 preload("res://experiments/playable_flightcase/navigation_bar.gd").add(self,"WRITING",back,menu)
 _sound=_button("♫ ON","MixingSound",func():_stop_audio();sound_requested.emit();_refresh_audio());_sound.size_flags_horizontal=Control.SIZE_SHRINK_END;_sound.custom_minimum_size.x=58
 var identity:=PanelContainer.new();identity.name="MixingProjectStrip";identity.add_theme_stylebox_override("panel",StyleBoxEmpty.new());identity.mouse_filter=Control.MOUSE_FILTER_PASS;add_child(identity)
 var identity_rows:=VBoxContainer.new();identity_rows.add_theme_constant_override("separation",1);identity.add_child(identity_rows)
 _band=_label("",18,false);_band.name="MixingBand";identity_rows.add_child(_band)
 _title=LineEdit.new();_title.name="MixingTitle";_title.placeholder_text="Name your original";_title.max_length=48;_title.custom_minimum_size.y=44
 _title.add_theme_font_override("font",Poster.DISPLAY);_title.add_theme_font_size_override("font_size",38);_title.add_theme_color_override("font_color",Poster.PAPER);_title.add_theme_color_override("caret_color",Poster.PAPER);_title.add_theme_color_override("font_placeholder_color",Color("71614c"))
 _title.add_theme_stylebox_override("normal",StyleBoxEmpty.new());_title.add_theme_stylebox_override("focus",StyleBoxEmpty.new())
 _title.text_changed.connect(func(_words: String):
  if not _hydrating:_invalidate_response();_refresh())
 identity_rows.add_child(_title)
 _title_reading=_label("",24);_title_reading.name="MixingSongTitle";identity_rows.add_child(_title_reading)
 _brief=_label("",16,false);_brief.name="MixingBrief";identity_rows.add_child(_brief)
 _demo_path=_label("",16,false);_demo_path.name="MixingDemoPath";identity_rows.add_child(_demo_path)
 var stages:=HBoxContainer.new();stages.name="MixingStages";stages.add_theme_constant_override("separation",6);add_child(stages)
 for i in range(3):
  var label: Label=_label("%d  %s" % [i+1,["FEEL","BUILD","TAKE"][i]],17);label.name="MixingStage_%d" % i;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.custom_minimum_size.y=24;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stages.add_child(label);_stages.append(label)
 _scroll=ScrollContainer.new();_scroll.name="MixingBodyScroll";_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;_scroll.follow_focus=true;_scroll.get_v_scroll_bar().focus_mode=Control.FOCUS_ALL;add_child(_scroll)
 _spread=GridContainer.new();_spread.name="MixingSpread";_spread.columns=1;_spread.add_theme_constant_override("h_separation",14);_spread.add_theme_constant_override("v_separation",10);_spread.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_scroll.add_child(_spread)
 var console:=PanelContainer.new();_console=console;console.name="MixingConsole";console.size_flags_horizontal=Control.SIZE_EXPAND_FILL;console.mouse_filter=Control.MOUSE_FILTER_PASS;console.add_theme_stylebox_override("panel",_surface_style());_spread.add_child(console)
 var surface:=VBoxContainer.new();surface.add_theme_constant_override("separation",8);console.add_child(surface)
 _bank_more=Poster.button("");_bank_more.name="MixingBankMore"
 _bank_more.pressed.connect(_toggle_bank);_buttons.append(_bank_more);surface.add_child(_bank_more)
 _bank_library=VBoxContainer.new();_bank_library.add_theme_constant_override("separation",4);surface.add_child(_bank_library)
 var foundations:=HBoxContainer.new();foundations.name="MixingFoundations";foundations.add_theme_constant_override("separation",4);_bank_library.add_child(foundations)
 for i in range(Recipe.HOOKS.size()):
  var choice: Button=_button(["RIFF","BASS","PICKED"][i],"MixingFoundation_%d" % i,_choose_foundation.bind(i))
  Poster.choice_style(choice);choice.toggle_mode=true;choice.button_group=_foundation_group;_foundation_group.allow_unpress=false;foundations.add_child(choice);_foundations.append(choice)
 var recorded:=GridContainer.new();recorded.columns=2;recorded.name="MixingRecordedFoundations";recorded.add_theme_constant_override("h_separation",4);recorded.add_theme_constant_override("v_separation",4);_bank_library.add_child(recorded)
 for i in range(Recipe.Recorded.HOOKS.size()):
  var choice: Button=_button(Recipe.Recorded.LABELS[i],"MixingRecorded_%d" % i,_choose_foundation.bind(Recipe.HOOKS.size()+i))
  choice.visible=i<Recipe.Recorded.STEADY_HOOKS.size() or _bank_open
  Poster.choice_style(choice);choice.toggle_mode=true;choice.button_group=_foundation_group;recorded.add_child(choice);_foundations.append(choice)
 _foundation_note=_label("",16);_foundation_note.name="MixingFoundationNote";surface.add_child(_foundation_note)
 _grid=GridContainer.new();_grid.name="MixingSoundControls";_grid.columns=1;_grid.add_theme_constant_override("h_separation",6);_grid.add_theme_constant_override("v_separation",8);surface.add_child(_grid)
 for i in range(6):_add_control(_grid,i,"choice")
 var lyric_title: Label=_label("LYRICAL DIRECTION",17);lyric_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;surface.add_child(lyric_title);_theme_heading=lyric_title
 var lyrical:=HBoxContainer.new();lyrical.name="MixingLyricalDirection";lyrical.add_theme_constant_override("separation",4);surface.add_child(lyrical);_lyrical=lyrical
 for i in range(3):
  var button: Button=_button(Recipe.LABELS[6][i],"MixingTheme_%d" % i,_choose.bind("theme",i));Poster.choice_style(button);button.toggle_mode=true;lyrical.add_child(button);_themes.append(button)
 _note_panel=PanelContainer.new();_note_panel.name="MixingMemberCard";_note_panel.mouse_filter=Control.MOUSE_FILTER_PASS;_note_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_note_panel.add_theme_stylebox_override("panel",Poster.stock(Poster.PAPER,14));_spread.add_child(_note_panel)
 var note_body:=VBoxContainer.new();note_body.add_theme_constant_override("separation",6);_note_panel.add_child(note_body)
 var person:=HBoxContainer.new();person.add_theme_constant_override("separation",8);note_body.add_child(person)
 _portrait=TextureRect.new();_portrait.name="MixingMemberPortrait";_portrait.custom_minimum_size=Vector2(144,144);_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;person.add_child(_portrait)
 var speech:=VBoxContainer.new();speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL;speech.add_theme_constant_override("separation",8);person.add_child(speech)
 _member_name=_label("",20,true);_member_name.name="MixingMemberName";speech.add_child(_member_name)
 _member_note=_label("",20,true);_member_note.name="MixingMemberNote";speech.add_child(_member_note)
 var responses:=VBoxContainer.new();responses.name="MixingMemberResponses";responses.add_theme_constant_override("separation",4);note_body.add_child(responses)
 for pair in [["TRY THEIR IDEA","try"],["KEEP MY DIRECTION","keep"],["LEAVE UNANSWERED","dismiss"]]:
  var button: Button=_button(pair[0],"MixingResponse_"+pair[1],_respond.bind(pair[1]));preload("res://experiments/playable_flightcase/conversation_panel.gd").reply(button,true);responses.add_child(button);_responses.append(button)
 _change_reply=_button("CHANGE MY REPLY","MixingChangeReply",_change_answer);note_body.add_child(_change_reply)
 _response=_label("",16,true);_response.name="MixingResponseStatus";note_body.add_child(_response)
 _compare_button=_button("COMPARE THE TAKES","MixingCompare",_compare_take);note_body.add_child(_compare_button)
 var options:=VBoxContainer.new();options.name="MixingExtraOptions";options.visible=false;options.add_theme_constant_override("separation",6)
 var more: Button=_button("PEOPLE & SESSION OPTIONS","MixingMoreOptions",func():options.visible=not options.visible);surface.add_child(more);surface.add_child(options)
 options.add_child(_button("CHANGE IDEA PARTNER","MixingCollaboratorNext",_change_collaborator))
 _written=_label("",16,true);_written.name="MixingWrittenDirection";_written.visible=false;options.add_child(_written)
 options.add_child(_button("READ THE DIRECTION","MixingReadDirection",func():_written.visible=not _written.visible))
 var lead_row:=HBoxContainer.new();lead_row.add_theme_constant_override("separation",4);options.add_child(lead_row)
 var prev: Button=_button("‹","MixingLeaderPrevious",_change_leader.bind(-1));prev.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;prev.custom_minimum_size.x=48;lead_row.add_child(prev)
 _leader=_label("",16,true);_leader.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;lead_row.add_child(_leader)
 var next: Button=_button("›","MixingLeaderNext",_change_leader.bind(1));next.size_flags_horizontal=Control.SIZE_SHRINK_END;next.custom_minimum_size.x=48;lead_row.add_child(next)
 options.add_child(_button("PLAN OUR WEEK","MixingPlanWeek",request_exit.bind("planning")))
 var activities:=HBoxContainer.new();activities.add_theme_constant_override("separation",6);options.add_child(activities)
 activities.add_child(_button("REHEARSE","MixingRehearse",request_exit.bind("practice:tighten")))
 activities.add_child(_button("CLEAR AIR","MixingClearAir",request_exit.bind("practice:connect")))
 options.add_child(_button("FREE JAM / SOLO PRACTICE · 1 DAY","MixingJam",request_exit.bind("practice:jam")))
 var history: Button=_button("FINISHED ORIGINALS","MixingHistory",request_exit.bind("finished"));options.add_child(history)
 _shape_steps=VBoxContainer.new();_shape_steps.name="MixingShapeSteps";_shape_steps.add_theme_constant_override("separation",6);surface.add_child(_shape_steps)
 var setting_steps:=HBoxContainer.new();setting_steps.add_theme_constant_override("separation",6);_shape_steps.add_child(setting_steps)
 setting_steps.add_child(_button("PREVIOUS","MixingShapePrevious",_shape_next.bind(-1)))
 setting_steps.add_child(_button("NEXT SETTING","MixingShapeNext",_shape_next.bind(1)))
 _shape_steps.add_child(_button("USE THIS DIRECTION","MixingShapeDone",_toggle_shape))
 _spread.move_child(_note_panel,0)
 _shape_toggle=_button("SHAPE THE SONG","MixingShapeAction",_toggle_shape);add_child(_shape_toggle)
 _notice=_label("",16);_notice.name="MixingNotice";_notice.visible=false;add_child(_notice)
 var dock:=VBoxContainer.new();dock.name="MixingCommitDock";dock.add_theme_constant_override("separation",4);add_child(dock)
 _voice_preview=_label("",16);_voice_preview.name="MixingVoicePreview";dock.add_child(_voice_preview)
 _cost=_label("",16);_cost.name="MixingPublicCost";_cost.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;dock.add_child(_cost)
 var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);dock.add_child(actions)
 _hear=_button("▶ HEAR THE IDEA","MixingHear",_hear_take);actions.add_child(_hear);actions.add_child(_sound)
 _commit=_button("COMMIT SESSION","MixingCommit",_request_commit,true);actions.add_child(_commit)
 _audio=Audio.new();_audio.name="MixingAudio";_audio.live_audition=true;_audio.configure(_audio_context);add_child(_audio);_audio.status_changed.connect(_refresh_audio)

func _add_control(parent: Node,index: int,kind: String) -> void:
 var control=Dial.new();control.configure(Recipe.FIELDS[index],Recipe.TITLES[index],kind,Recipe.LABELS[index]);parent.add_child(control);_controls[Recipe.FIELDS[index]]=control
 control.value_changed.connect(func(value: float):_choose(Recipe.FIELDS[index],int(value)))

func _project() -> Dictionary:
 return _view.get("project",{})

func _target() -> Dictionary:
 var key: String=_title.text+":"+str(_leader_index)+":"+_collaborator_id
 if key==_target_key:return _target_cache
 var result: Dictionary=Rules._target(owner_state.game.career,_title.text,_leader_index,_collaborator_id)
 _target_key=key;_target_cache=result.get("target",{}) if result.get("ok",false) else {}
 return _target_cache

func _saved_recipe() -> Dictionary:
 var value: Dictionary=_project().get("fragment",{}).get("producer_recipe",{}).duplicate(true)
 if Recipe.valid(value):value.stage=int(owner_state.game.career.get("song_draft_progress",0))
 return value

func _saved_decision() -> Dictionary:
 var decision: Dictionary=_project().get("producer_decision",{})
 if not decision.is_empty() and decision.get("stage")==int(owner_state.game.career.get("song_draft_progress",0)) and Rules._same(decision.get("chosen_recipe"),_recipe) and Rules._same(decision.get("member"),_target().get("respondent_ref",{})):return {"choice":decision.choice,"base_recipe":decision.base_recipe.duplicate(true),"offer_id":decision.offer_id}
 return {}

func refresh_saved(preserve_local: bool=false) -> void:
 _stop_audio()
 if not _initial_view:_view=owner_state.workbench_view()
 _initial_view=false;_expected=_view.expected.duplicate(true);_target_key="";_target_cache={}
 if not is_instance_valid(_title):return
 if not preserve_local:
  _hydrating=true;_recipe=_saved_recipe();_decision={};_compare=false
  _title.text=str(_project().get("target",{}).get("title",""));_leader_index=int(_project().get("target",{}).get("leader_ref",{}).get("slot",0))
  var partner: String=str(_project().get("target",{}).get("respondent_ref",{}).get("candidate_id",""))
  _collaborator_id=partner if not partner.is_empty() and Rules._target(owner_state.game.career,_title.text,_leader_index,partner).get("ok",false) else ""
  _decision=_saved_decision();_hydrating=false
 _refresh()

func _payload() -> Dictionary:
 var payload: Dictionary={"recipe":_recipe.duplicate(true),"title":_title.text,"leader_index":_leader_index,"decision":_decision.duplicate(true)}
 if not _collaborator_id.is_empty():payload.collaborator_id=_collaborator_id
 return payload

func has_local_edits() -> bool:
 if not is_instance_valid(_title) or not Recipe.valid(_recipe):return false
 var target: Dictionary=_project().get("target",{})
 return not Rules._same(_recipe,_saved_recipe()) or _title.text.strip_edges().to_upper()!=str(target.get("title","")) or _leader_index!=int(target.get("leader_ref",{}).get("slot",0)) or _collaborator_id!=str(target.get("respondent_ref",{}).get("candidate_id","")) or not Rules._same(_decision,_saved_decision())

func _invalidate_response() -> void:
 _decision={};_compare=false

func _navigation_back() -> void:
 if _shape_open:_toggle_shape()
 else:request_exit("home")

func _toggle_shape() -> void:
 if _busy or is_instance_valid(_dialog):return
 _stop_audio();_cancel_controls();_shape_open=not _shape_open
 _refresh();_scroll.set_deferred("scroll_vertical",0)

func _shape_next(direction: int) -> void:
 if _busy or is_instance_valid(_dialog):return
 _shape_axis=posmod(_shape_axis+direction,Recipe.FIELDS.size());_refresh()

func _change_answer() -> void:
 if _busy or is_instance_valid(_dialog) or Time.get_ticks_msec()<_review_ready_at:return
 _recipe=_offer_base();_invalidate_response();_refresh();_scroll.set_deferred("scroll_vertical",0)

func _unlock_review() -> void:
 if is_inside_tree():
  _refresh()
  var current: Control=get_viewport().gui_get_focus_owner()
  if current==null or not current.is_visible_in_tree():_restore_visible_focus()

func _restore_visible_focus() -> void:
 var choices: Array=[_title] if _shape_open else (_responses+[_hear,_change_reply,_shape_toggle])
 for control in choices:
  if is_instance_valid(control) and control.is_visible_in_tree() and control.focus_mode!=Control.FOCUS_NONE and (not control is Button or not control.disabled):control.grab_focus();return


func _toggle_bank() -> void:
 if _busy or is_instance_valid(_dialog):return
 _bank_open=not _bank_open
 _refresh_bank()

func _refresh_bank() -> void:
 _bank_library.visible=_bank_open
 for choice in _foundations:choice.visible=true
 _bank_more.text=Recipe.foundation(_recipe)+(" · CLOSE" if _bank_open else " · CHANGE")
 _bank_more.tooltip_text="Choose a different song foundation. Recorded phrases retain their original playing."

func _choose_foundation(index: int) -> void:
 var hooks: Array=Recipe.HOOKS+Recipe.Recorded.HOOKS
 if _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe) or _recipe.version not in [4,5] or int(_recipe.stage)!=0 or index<0 or index>=hooks.size():return
 if _recipe.hook==hooks[index]:return
 _stop_audio();_invalidate_response();_recipe=Recipe.Recorded.VocalKeys.select(_recipe,hooks[index])
 if Recipe.Recorded.has_hook(_recipe):_recipe.pace="driving";_recipe.groove="straight";_recipe.originality="familiar"
 _refresh()

func _choose(field: String,index: int) -> void:
 if _hydrating or _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe) or not Recipe.adjustable(_recipe,field):return
 var axis: int=Recipe.FIELDS.find(field)
 if axis<0 or index<0 or index>=Recipe.VALUES[axis].size():return
 if _recipe[field]==Recipe.VALUES[axis][index]:_refresh();return
 _invalidate_response();_recipe[field]=Recipe.VALUES[axis][index];_refresh()
 _audio.notify_controls_changed()

func _change_leader(direction: int) -> void:
 if _busy or is_instance_valid(_dialog):return
 var members: Array=owner_state.game.career.get("members",[])
 for step in range(1,members.size()+1):
  var index: int=posmod(_leader_index+direction*step,members.size())
  if members[index].get("life_status","active")=="active":_leader_index=index;_invalidate_response();_refresh();return

func _change_collaborator() -> void:
 if _busy or is_instance_valid(_dialog):return
 var choices: Array[String]=[]
 for member in owner_state.game.career.get("members",[]):
  var id: String=str(member.get("candidate_id",""))
  if not id.is_empty() and Rules._target(owner_state.game.career,_title.text,_leader_index,id).get("ok",false):choices.append(id)
 if choices.is_empty():_show_notice("No other active idea partner is available.");return
 _collaborator_id=choices[posmod(choices.find(_collaborator_id)+1,choices.size())]
 _stop_audio();_invalidate_response();_target_key="";_refresh()

func _offer_base() -> Dictionary:
 return _decision.get("base_recipe",_recipe).duplicate(true)

func _respond(choice: String) -> void:
 if _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe) or not _decision.is_empty() or Time.get_ticks_msec()<_review_ready_at:return
 var target: Dictionary=_target()
 var base: Dictionary=_offer_base()
 var request: Dictionary=Recipe.offer(base,target.get("respondent_ref",{}))
 if request.is_empty():return
 _compare=false;_recipe=base.duplicate(true)
 if choice=="try":_recipe[request.field]=request.value
 _decision={"choice":choice,"base_recipe":base,"offer_id":request.offer_id}
 _shape_open=false;_review_ready_at=Time.get_ticks_msec()+350
 _refresh();_scroll.set_deferred("scroll_vertical",0)
 get_tree().create_timer(0.35).timeout.connect(_unlock_review)

func _previous() -> Dictionary:
 if Recipe.valid(_decision.get("base_recipe")) and not Rules._same(_recipe,_decision.base_recipe):return _decision.base_recipe.duplicate(true)
 var value: Dictionary=_project().get("prior_fragment",{}).get("producer_recipe",{})
 return value.duplicate(true) if Recipe.valid(value) and int(value.stage)<=int(_recipe.get("stage",0)) and not Rules._same(value,_recipe) else {}

func _compare_take() -> void:
 if _busy or is_instance_valid(_dialog) or _previous().is_empty() or Time.get_ticks_msec()<_review_ready_at:return
 _compare=not _compare;_refresh()

func _audio_context() -> Dictionary:
 # An equal authoritative token proves the validated saved owner is unchanged.
 var live: Dictionary=_view
 var selected: Dictionary=_previous() if _compare else _recipe
 var allowed: bool=is_visible_in_tree() and not _busy and not is_instance_valid(_dialog) and live.get("ok",false) and live.get("active",false) and not live.get("held",true) and Rules._same(_expected,owner_state.workbench_expected()) and Recipe.valid(selected)
 if allowed:allowed=Rules._same(selected.brief,Sound.read(owner_state.game.career)) and int(selected.stage)<=int(owner_state.game.career.get("song_draft_progress",0))
 if allowed and selected.get("version")==5:allowed=Recipe.Recorded.VocalKeys.active_pair(owner_state.game.career,selected)
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
 var selected: Dictionary=_previous() if _compare else _recipe
 _hear.disabled=_busy or is_instance_valid(_dialog) or off or not _view.get("ok",false) or _view.get("held",true) or not _audio.available_for(selected)
 _hear.tooltip_text=_audio.hint_for(selected)

func _refresh() -> void:
 if not is_instance_valid(_title):return
 var valid: bool=Recipe.valid(_recipe) and _view.get("ok",false) and not _view.get("held",true)
 var modal: bool=is_instance_valid(_dialog)
 var stage: int=int(owner_state.game.career.get("song_draft_progress",0))
 _band.text=str(owner_state.game.career.get("band_name","YOUR BAND")).to_upper()+" · DAY %d / £%d" % [int(owner_state.game.career.get("tour_day",1)),int(owner_state.game.career.get("cash",0))]
 _brief.visible=false
 _demo_path.visible=false
 _brief.text=Sound.summary(Sound.read(owner_state.game.career))+"  ·  DAY %d / £%d" % [int(owner_state.game.career.get("tour_day",1)),int(owner_state.game.career.get("cash",0))]
 var originals: int=preload("res://experiments/playable_flightcase/recording_rules.gd").songs(owner_state.game.career).size()
 _demo_path.text="DEMO PATH · %d / 3 ORIGINALS · RECORD → RELEASE → RADIO" % mini(originals,3)
 _foundation_note.text=("RECORDED IDEA · "+Recipe.Recorded.tempo_caption(_recipe)+" · FIXED PLAYING" if Recipe.Recorded.has_hook(_recipe) else "COMPOSED IDEA · CHOOSE YOUR DIRECTION") if valid else "Review the saved foundation."
 _title.visible=_shape_open
 _title_reading.visible=not _shape_open;_title_reading.text=_title.text
 _console.visible=_shape_open;_note_panel.visible=not _shape_open
 _shape_toggle.text="BACK TO THE IDEA" if _shape_open else "SHAPE THE SONG"
 _title.editable=not _busy and not modal and valid
 _title.focus_mode=Control.FOCUS_NONE if modal else Control.FOCUS_ALL
 for i in range(_stages.size()):_stages[i].add_theme_color_override("font_color",Color("f1c374") if i==stage else Color("aa9c83"))
 for key in _controls:
  var control=_controls[key]
  var fixed: bool=valid and not Recipe.adjustable(_recipe,key)
  control.fixed_hint="FIXED RECORDING" if fixed else ""
  control.labels=Recipe.LABELS[Recipe.FIELDS.find(key)].duplicate()
  if fixed:control.labels.fill(Recipe.label(_recipe,key))
  if valid:control.set_value_no_signal(Recipe.VALUES[Recipe.FIELDS.find(key)].find(_recipe[key]))
  control._update_caption()
  control.set_locked(_busy or modal or not valid or fixed);control.queue_redraw()
  control.visible=Recipe.FIELDS[_shape_axis]==key and not fixed
  if key=="originality":control.tooltip_text="SIMPLE keeps the main phrase; LAYERED brings in the answering part when you make the finished take." if valid and _recipe.hook!="low_riff_v1" else ""
  if fixed:control.tooltip_text="Fixed in this recording. Different playing needs another recorded phrase."
 _theme_heading.visible=_shape_axis==6;_lyrical.visible=_shape_axis==6
 for i in range(_themes.size()):
  var selected: bool=valid and _recipe.theme==Recipe.VALUES[6][i]
  _themes[i].text=("✓ " if selected else "")+Recipe.LABELS[6][i]
  _themes[i].set_pressed_no_signal(selected)
 var target: Dictionary=_target() if valid else {}
 var respondent: Dictionary=target.get("respondent_ref",{})
 var note: Dictionary=Recipe.note(respondent,_offer_base(),{"day":int(owner_state.game.career.get("tour_day",1))}) if valid else {}
 _member_name.text=str(respondent.get("name","CHOOSE AN IDEA PARTNER")).to_upper()+" · "+str(respondent.get("role",""))
 _member_note.text="Choose an idea partner other than the session lead." if target.is_empty() and not _collaborator_id.is_empty() else str(note.get("note",{}).get("text","Review the saved band and direction."))
 if _view.get("held",false):
  _member_name.text="DRAFT NEEDS REVIEW"
  _member_note.text=str(_view.get("message","Review the saved draft."))
 _voice_preview.text="";_voice_preview.visible=false
 var portrait_path: String=""
 for source in Cast.combined_people():
  if source.get("id")==respondent.get("candidate_id"):portrait_path=str(source.get("portrait_preview",""));break
 _portrait.texture=load(portrait_path) if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path) else null
 _portrait.visible=_portrait.texture!=null;_portrait.set_meta("source",portrait_path)
 for button in _responses:button.visible=not respondent.is_empty() and _decision.is_empty()
 var person_name: String=str(respondent.get("name","THEIR")).to_upper()
 _responses[0].text="TRY "+person_name+"’S IDEA" if person_name.length()<=14 else "TRY THEIR IDEA"
 for i in range(_responses.size()):
  var chosen: bool=_decision.get("choice")==["try","keep","dismiss"][i]
  var button: Button=_responses[i]
  if i>0:button.text="KEEP MY DIRECTION" if i==1 else "LEAVE UNANSWERED"
  button.toggle_mode=true;button.set_pressed_no_signal(chosen)
  button.modulate=Color.WHITE
  button.add_theme_color_override("font_focus_color",Poster.INK if chosen else Poster.PAPER)
  if chosen:button.text="✓ "+button.text
 _response.text="Choose how to answer before committing." if not respondent.is_empty() and _decision.is_empty() else ("Their idea is selected. Compare both takes freely." if _decision.get("choice")=="try" else ("You considered the idea and kept your direction." if _decision.get("choice")=="keep" else ("You chose to leave the idea unanswered." if _decision.get("choice")=="dismiss" else "Your direction is ready.")))
 _response.visible=not _decision.is_empty();_change_reply.visible=not _decision.is_empty()
 _compare_button.visible=not _previous().is_empty() and not _decision.is_empty();_compare_button.text="BACK TO CURRENT TAKE" if _compare else "COMPARE THE TAKES"
 _written.text=("EARLIER TAKE\n" if _compare else "CURRENT DIRECTION\n")+Recipe.written(_previous() if _compare else _recipe)+"\n"+_audio.hint_for(_previous() if _compare else _recipe)
 var members: Array=owner_state.game.career.get("members",[])
 _leader.text=(str(members[_leader_index].get("name",""))+" · SESSION LEAD") if _leader_index>=0 and _leader_index<members.size() else "REVIEW SESSION LEAD"
 var work: Dictionary=Situation.inspect_writing(owner_state.game.career)
 var available: bool=work.get("ok",false) and work.get("can_write",false)
 _cost.text="Uses 1 day · No studio hire · Session %d of 3" % (stage+1)
 if not work.get("ok",false):_cost.text=str(work.get("message","Review availability."))
 elif not available:_cost.text="UNAVAILABLE TODAY · "+str(work.get("unavailable_summary",work.get("work_names","Review commitments")))
 elif work.get("plan_status")=="due":_cost.text="1 day · No hire · Misses today's agreed rehearsal"
 for button in _buttons:button.disabled=_busy or modal or (not valid and button.name not in ["MixingBack","MixingPauseButton"])
 for i in range(_foundations.size()):
  var hook: String=(Recipe.HOOKS+Recipe.Recorded.HOOKS)[i]
  var selection: Dictionary=Recipe.Recorded.VocalKeys.select(_recipe,hook)
  var source_available: bool=Recipe.Recorded.available(owner_state.game.career,selection,str(_project().get("id","")))
  _foundations[i].disabled=_busy or modal or not valid or stage>0 or _recipe.get("version") not in [4,5]
  _foundations[i].tooltip_text=""
  if not source_available:
   _foundations[i].disabled=true
   _foundations[i].tooltip_text="Requires the named singer and keyboardist in this band, with this phrase unused." if Recipe.Recorded.VocalKeys.has_hook(selection) else "Already used by a member of this band. Its saved song can still play."
  _foundations[i].set_pressed_no_signal(valid and _recipe.hook==hook)
  _foundations[i].modulate=Color.WHITE
 _refresh_bank()
 var free_people: Array=work.get("attendee_indices",[])
 _commit.text="COMMIT SESSION" if available else DayNavigation.preview_label(free_people.size())
 _commit.disabled=_busy or modal or not valid or not work.get("ok",false)
 if not available and work.get("ok",false):
  _cost.text+="\n"+("A £0 practice day is still possible." if not free_people.is_empty() else "A quiet evening can move you to tomorrow. No room hire.")
 if available and valid and not Recipe.Recorded.available(owner_state.game.career,_recipe,str(_project().get("id",""))):
  _commit.disabled=true;_cost.text="PHRASE UNAVAILABLE · Choose another foundation"
 if available and target.is_empty() and not _collaborator_id.is_empty():
  _commit.disabled=true;_cost.text="Choose an idea partner other than the session lead."
 if _view.get("held",false):_cost.text="Draft retained · Use Back or Menu to leave this review."
 _commit.visible=not _view.get("held",false) and not _shape_open and (not _decision.is_empty() or respondent.is_empty())
 _commit.disabled=_commit.disabled or Time.get_ticks_msec()<_review_ready_at
 _change_reply.disabled=_change_reply.disabled or Time.get_ticks_msec()<_review_ready_at
 _compare_button.disabled=_compare_button.disabled or Time.get_ticks_msec()<_review_ready_at
 for button in _buttons:
  if is_instance_valid(button):preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(button,self)
 for control in _controls.values():
  for choice in control.find_children("Choice_*","Button",true,false):preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(choice,self)
  if control.get_child_count()>0:control.custom_minimum_size.y=maxf(76.0,(control.get_child(0) as Control).get_combined_minimum_size().y)
 _refresh_audio()

func _resized() -> void:
 if not is_inside_tree():return
 var heading: Label=find_child("MixingHeading",true,false) as Label
 if heading!=null:heading.add_theme_font_size_override("font_size",20 if size.x<430 else 24)
 if _layout!=size:
  _stop_audio();_cancel_controls()
  if is_instance_valid(_dialog):_close_dialog();_show_notice("Layout changed. Your local direction is retained.")
 _layout=size
 var wide: bool=size.x>=840
 _spread.columns=1
 _grid.columns=1
 _note_panel.custom_minimum_size.x=300 if wide else 0

func _show_notice(words: String) -> void:
 _notice.text=words;_notice.visible=not words.is_empty()

func show_commit_error(words: String) -> void:
 _show_notice(words)

func _request_commit() -> void:
 if _busy or is_instance_valid(_dialog) or not Recipe.valid(_recipe) or _shape_open or Time.get_ticks_msec()<_review_ready_at:return
 var availability: Dictionary=Situation.inspect_writing(owner_state.game.career)
 if not availability.get("ok",false):_show_notice(str(availability.get("message","Review availability.")));return
 if not availability.get("can_write",false):
  request_exit("practice:jam")
  return
 var respondent: Dictionary=_target().get("respondent_ref",{})
 if _decision.is_empty():
  if respondent.is_empty():_decision={"choice":"none","base_recipe":_recipe.duplicate(true),"offer_id":""}
  else:
   _show_notice(str(respondent.get("name","Your bandmate"))+" has an idea. Try it, keep your direction, or explicitly leave it unanswered.")
   _scroll.ensure_control_visible(_note_panel);_responses[0].grab_focus();return
 _stop_audio();_cancel_controls();_busy=true;_refresh()
 write_requested.emit({"expected":_expected.duplicate(true),"mixing_payload":_payload()})
 _busy=false
 _view=owner_state.workbench_view();_expected=_view.expected.duplicate(true);_target_key="";_target_cache={}
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

func _show_pause() -> void:
 if _busy or is_instance_valid(_dialog):return
 _stop_audio();_cancel_controls();_pause_open=true
 _dialog_layer=CanvasLayer.new();_dialog_layer.layer=30;add_child(_dialog_layer)
 _dialog=Control.new();_dialog.name="MixingPause";_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.mouse_filter=Control.MOUSE_FILTER_STOP;_dialog_layer.add_child(_dialog)
 var shade:=ColorRect.new();shade.color=Color(0,0,0,0.86);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_dialog.add_child(center)
 var card:=PanelContainer.new();card.custom_minimum_size.x=minf(380,maxf(280,size.x-28));card.add_theme_stylebox_override("panel",_surface_style());center.add_child(card)
 var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);card.add_child(body)
 body.add_child(_label("PAUSED",24));body.add_child(_label("Your local direction is retained. Resume here, or return to the title screen.",18))
 var resume: Button=_button("RESUME WRITING","MixingPauseResume",_close_dialog);body.add_child(resume)
 body.add_child(_button("RETURN TO TITLE","MixingPauseExitTitle",func():_close_dialog();request_exit("menu")))
 _refresh();resume.disabled=false;(body.get_child(body.get_child_count()-1) as Button).disabled=false
 resume.call_deferred("grab_focus")

func _close_dialog() -> void:
 var resume_pause: bool=_pause_open
 _pause_open=false
 _exit_epoch+=1
 if is_instance_valid(_dialog_layer):remove_child(_dialog_layer);_dialog_layer.queue_free()
 _dialog_layer=null;_dialog=null;_dialog_error=null
 var retained: Array[Button]=[]
 for button in _buttons:
  if is_instance_valid(button) and not str(button.name).begins_with("MixingExit") and not str(button.name).begins_with("MixingPauseResume") and not str(button.name).begins_with("MixingPauseExitTitle"):retained.append(button)
 _buttons=retained
 _refresh()
 if resume_pause:call_deferred("_restore_pause_focus",_exit_epoch)

func _restore_pause_focus(epoch: int) -> void:
 if epoch!=_exit_epoch or _busy or is_instance_valid(_dialog) or not is_inside_tree() or not is_visible_in_tree():return
 var invoker: Button=find_child("MixingPauseButton",true,false) as Button
 if invoker!=null and invoker.is_visible_in_tree() and not invoker.disabled:invoker.grab_focus()

func _exit_choice(choice: String,epoch: int) -> void:
 if _busy or not is_instance_valid(_dialog) or epoch!=_exit_epoch:return
 if choice=="keep":_close_dialog();_restore_visible_focus();return
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
  if _pause_open:_close_dialog()
  else:_exit_choice("keep",_exit_epoch)
  get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
 if not is_visible_in_tree() or is_instance_valid(_dialog) or _busy:return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  _navigation_back();get_viewport().set_input_as_handled()
