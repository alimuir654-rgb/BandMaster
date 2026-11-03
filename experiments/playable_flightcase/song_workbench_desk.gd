extends VBoxContainer
## The actual same two-line leaf. Typing, inspection and focus remain local.
const Rules = preload("res://experiments/playable_flightcase/song_workbench.gd")
const Content = preload("res://experiments/playable_flightcase/song_fragment_content.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
signal write_requested(expected: Dictionary)
signal exit_ready(destination: String)
signal closed
var owner_state
var reduced_motion := false
var _view: Dictionary={}
var _expected: Dictionary={}
var _text: TextEdit
var _title: LineEdit
var _leader: Label
var _badge: Label
var _notice: Label
var _notice_kind := "info"
var _note
var _note_box: VBoxContainer
var _respondent: Label
var _respondent_portrait: TextureRect
var _skip_note: Button
var _preview: Label
var _use_take: Button
var _write: Button
var _refrains: Array[Button]=[]
var _buttons: Array[Button]=[]
var _spread: GridContainer
var _place: VBoxContainer
var _paper_body: VBoxContainer
var _room: TextureRect
var _portrait: TextureRect
var _identity: Label
var _busy := false
var _wide := false
var _layout_size := Vector2.ZERO
var _refrain := "hook:2"
var _leader_index := 0
var _preview_kind := ""
var _exit_layer: CanvasLayer
var _exit_dialog: Control
var _exit_generation := 0
var _exit_destination := ""
var _exit_token: Dictionary={}
var _exit_message: Label

func configure(state_owner,reduced: bool=false) -> void:
 owner_state=state_owner
 reduced_motion=reduced
 _view=owner_state.workbench_view()
 _expected=owner_state.workbench_expected()

func _ready() -> void:
 name="SongWorkbench"
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 size_flags_vertical=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",6)
 _build()
 resized.connect(_on_resized)
 visibility_changed.connect(_on_visibility_changed)
 refresh_saved(false)
 call_deferred("_on_resized")

func _label(words: String,points: int=16,paper: bool=false) -> Label:
 var label: Label=C.paper_label(words,points) if paper else C.label(words,points)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 return label

func _button(words: String,id: String,callback: Callable) -> Button:
 var button: Button=C.button(words)
 button.name=id
 button.custom_minimum_size.y=48
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.pressed.connect(callback)
 _buttons.append(button)
 return button

func _quiet_skin(button: Button,paper: bool) -> void:
 var background:=StyleBoxFlat.new()
 background.bg_color=Color(0.2,0.16,0.11,0.06) if paper else Color(1,1,1,0.04)
 var focus:=StyleBoxFlat.new()
 focus.bg_color=Color.TRANSPARENT
 focus.set_border_width_all(2)
 focus.border_color=Color("695c4b") if paper else Color("f0c78b")
 for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,background)
 button.add_theme_stylebox_override("focus",focus)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:button.add_theme_color_override(state,Color("29241f") if paper else Color("eee7d7"))

func _quiet(words: String,id: String,callback: Callable,paper: bool=false) -> Button:
 var button:=_button(words,id,callback)
 _quiet_skin(button,paper)
 return button

func _picture(path: String,id: String,minimum: Vector2) -> TextureRect:
 var picture:=TextureRect.new()
 picture.name=id
 picture.custom_minimum_size=minimum
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if not path.is_empty() and ResourceLoader.exists(path):picture.texture=load(path)
 picture.set_meta("source",path)
 picture.set_meta("full_source_contained",true)
 return picture

func _edit_style() -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=Color(1,1,1,0.15)
 style.set_content_margin_all(8)
 return style

func _build() -> void:
 var scroll:=ScrollContainer.new()
 scroll.name="WorkbenchBodyScroll"
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.follow_focus=false
 scroll.get_v_scroll_bar().focus_mode=Control.FOCUS_ALL
 add_child(scroll)
 _spread=GridContainer.new()
 _spread.name="WorkbenchSpread"
 _spread.columns=1
 _spread.add_theme_constant_override("h_separation",24)
 _spread.add_theme_constant_override("v_separation",8)
 _spread.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.add_child(_spread)
 _place=VBoxContainer.new()
 _place.name="WorkbenchPlace"
 _place.add_theme_constant_override("separation",8)
 _spread.add_child(_place)
 var pictures:=HBoxContainer.new()
 pictures.alignment=BoxContainer.ALIGNMENT_CENTER
 pictures.add_theme_constant_override("separation",12)
 _place.add_child(pictures)
 _room=_picture("res://Art/Backgrounds/shared/formation.webp","WorkbenchRoom",Vector2(200,112))
 pictures.add_child(_room)
 _portrait=_picture("","WorkbenchLeaderPortrait",Vector2(100,94))
 pictures.add_child(_portrait)
 _identity=_label("",17)
 _identity.name="WorkbenchLeaderIdentity"
 _place.add_child(_identity)
 var history:=_quiet("FINISHED SKETCHES","WorkbenchHistory",request_exit.bind("finished"))
 history.visible=not Rules.finished(owner_state.snapshot()).items.is_empty()
 _place.add_child(history)
 var paper:=PanelContainer.new()
 paper.name="SketchPaper"
 paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 paper.add_theme_stylebox_override("panel",Paper.scorecard())
 _spread.add_child(paper)
 _paper_body=VBoxContainer.new()
 _paper_body.add_theme_constant_override("separation",6)
 paper.add_child(_paper_body)
 _badge=_label("",16,true)
 _badge.name="WorkbenchSavedState"
 _paper_body.add_child(_badge)
 _title=LineEdit.new()
 _title.name="WorkbenchTitle"
 _title.placeholder_text="Name your original"
 _title.max_length=48
 _title.custom_minimum_size.y=48
 _title.add_theme_font_size_override("font_size",20)
 _title.add_theme_color_override("font_color",Color("29241f"))
 _title.add_theme_color_override("font_placeholder_color",Color("695c4b"))
 _title.add_theme_color_override("caret_color",Color("29241f"))
 _title.add_theme_stylebox_override("normal",_edit_style())
 _title.text_changed.connect(func(_value: String):_refresh_local())
 _paper_body.add_child(_title)
 var leader_row:=HBoxContainer.new()
 leader_row.add_theme_constant_override("separation",8)
 leader_row.add_child(_quiet("‹","WorkbenchLeaderPrevious",_change_leader.bind(-1),true))
 _leader=_label("",16,true)
 _leader.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _leader.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 leader_row.add_child(_leader)
 leader_row.add_child(_quiet("›","WorkbenchLeaderNext",_change_leader.bind(1),true))
 leader_row.get_child(0).size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 leader_row.get_child(2).size_flags_horizontal=Control.SIZE_SHRINK_END
 leader_row.get_child(0).custom_minimum_size.x=48
 leader_row.get_child(2).custom_minimum_size.x=48
 _paper_body.add_child(leader_row)
 _text=TextEdit.new()
 _text.name="WorkbenchLyrics"
 _text.custom_minimum_size=Vector2(0,164)
 _text.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
 _text.set_scroll_past_end_of_file_enabled(false)
 _text.add_theme_font_size_override("font_size",21)
 _text.add_theme_color_override("font_color",Color("29241f"))
 _text.add_theme_color_override("caret_color",Color("29241f"))
 _text.add_theme_color_override("selection_color",Color(0.61,0.44,0.19,0.28))
 _text.add_theme_stylebox_override("normal",_edit_style())
 var edit_focus:=_edit_style()
 edit_focus.set_border_width_all(2)
 edit_focus.border_color=Color("8d6d3d")
 _text.add_theme_stylebox_override("focus",edit_focus)
 _text.text_changed.connect(_refresh_local)
 _paper_body.add_child(_text)
 var refrains:=HBoxContainer.new()
 refrains.add_theme_constant_override("separation",8)
 for index in range(2):
  var button:=_quiet("REFRAIN: LINE %d" % (index+1),"WorkbenchRefrain_%d" % (index+1),_choose_refrain.bind("hook:%d" % (index+1)),true)
  refrains.add_child(button)
  _refrains.append(button)
 _paper_body.add_child(refrains)
 var tools:=HBoxContainer.new()
 tools.add_theme_constant_override("separation",6)
 tools.add_child(_quiet("PREVIOUS","WorkbenchPrior",_inspect.bind("prior"),true))
 tools.add_child(_quiet("SEED A","WorkbenchSeed",_inspect.bind("seed"),true))
 tools.add_child(_quiet("TAKE B","WorkbenchAlternate",_inspect.bind("alternate"),true))
 _paper_body.add_child(tools)
 _preview=_label("",18,true)
 _preview.name="WorkbenchMaterialPreview"
 _preview.visible=false
 _paper_body.add_child(_preview)
 _use_take=_quiet("USE THIS TAKE · SAVE FREE","WorkbenchUseTake",_use_preview,true)
 _use_take.visible=false
 _paper_body.add_child(_use_take)
 _note_box=VBoxContainer.new()
 _note_box.name="WorkbenchWrittenNote"
 _note_box.add_theme_constant_override("separation",6)
 var note_identity:=HBoxContainer.new()
 note_identity.add_theme_constant_override("separation",10)
 _respondent_portrait=_picture("","WorkbenchRespondentPortrait",Vector2(80,76))
 note_identity.add_child(_respondent_portrait)
 _respondent=_label("",16)
 _respondent.name="WorkbenchRespondent"
 _respondent.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 note_identity.add_child(_respondent)
 _note_box.add_child(note_identity)
 _note=Ink.new()
 _note.name="WorkbenchNote"
 _note_box.add_child(_note)
 _skip_note=_quiet("SHOW FULL NOTE","WorkbenchSkipNote",_finish_note,true)
 _note_box.add_child(_skip_note)
 _paper_body.add_child(_note_box)
 var archive:=_quiet("ARCHIVE SKETCH","WorkbenchArchive",_archive,true)
 archive.tooltip_text="Keep the original song draft and completed days; record this closed sketch."
 _paper_body.add_child(archive)
 _notice=_label("",16)
 _notice.name="WorkbenchNotice"
 _notice.visible=false
 add_child(_notice)
 var free_actions:=HBoxContainer.new()
 free_actions.add_theme_constant_override("separation",8)
 free_actions.add_child(_button("SAVE SKETCH","WorkbenchSave",_free.bind("save_sketch")))
 free_actions.add_child(_button("TRY THIS TAKE","WorkbenchTry",_free.bind("try")))
 add_child(free_actions)
 var cost:=_label("Try and edit free · Writing uses 1 day · No room fee",16)
 cost.name="WorkbenchPublicCost"
 add_child(cost)
 _write=_button("WRITE SESSION","WorkbenchWrite",_request_write)
 add_child(_write)
 var exits:=HBoxContainer.new()
 exits.add_theme_constant_override("separation",8)
 exits.add_child(_button("BACK TO MENU","WorkbenchMenu",request_exit.bind("menu")))
 exits.add_child(_button("CAREER DESK ›","WorkbenchCareer",request_exit.bind("career")))
 add_child(exits)

func _on_resized() -> void:
 if not is_inside_tree():return
 if _layout_size!=size and is_instance_valid(_exit_dialog):
  _close_exit()
  _show_notice("The layout changed. Your local words are retained; review the exit again.")
 _layout_size=size
 var wide: bool=size.x>=840
 if _spread==null:return
 _spread.columns=2 if wide else 1
 _place.custom_minimum_size.x=340 if wide else 0
 _room.custom_minimum_size=Vector2(220,124) if wide else Vector2(200,112)
 _text.custom_minimum_size.y=210 if wide else 164
 if _wide!=wide:
  _wide=wide
  if _note_box.get_parent()!=(_place if wide else _paper_body):
   _note_box.get_parent().remove_child(_note_box)
   (_place if wide else _paper_body).add_child(_note_box)
 for label in [_respondent,_note]:label.add_theme_color_override("font_color",Color("eee7d7") if wide else Color("29241f"))
 _quiet_skin(_skip_note,not wide)

func _project() -> Dictionary:
 return _view.get("project",{})

func _saved_payload() -> Dictionary:
 var project:=_project()
 if project.is_empty():return {}
 return {"text":"%s\n%s" % [project.fragment.lines[0].text,project.fragment.lines[1].text],"refrain_line_id":project.fragment.refrain_line_id,"title":project.target.title,"leader_index":int(project.target.leader_ref.slot)}

func _payload() -> Dictionary:
 return {"text":_text.text,"refrain_line_id":_refrain,"title":_title.text,"leader_index":_leader_index}

func has_local_edits() -> bool:
 if not is_instance_valid(_text):return false
 var saved:=_saved_payload()
 if saved.is_empty():return false
 var current:=_payload()
 current.title=str(current.title).strip_edges().to_upper()
 return not Rules._same(current,saved)

func refresh_saved(preserve_local: bool=false) -> void:
 _view=owner_state.workbench_view()
 _expected=owner_state.workbench_expected()
 if not is_instance_valid(_text):return
 var history: Button=find_child("WorkbenchHistory",true,false) as Button
 if history!=null:history.visible=not Rules.finished(owner_state.snapshot()).items.is_empty()
 if not preserve_local:
  var payload:=_saved_payload()
  if not payload.is_empty():
   _text.text=payload.text
   _title.text=payload.title
   _refrain=payload.refrain_line_id
   _leader_index=int(payload.leader_index)
 var project:=_project()
 var trial: Dictionary=project.get("last_trial",{})
 var respondent: Dictionary={}
 if trial.is_empty():
  var source: String=str(project.get("fragment",{}).get("source_kind",""))
  _respondent.text="YOUR SAVED REVISION · NO NOTE YET" if source=="player" else ("SAVED TAKE B · NO NOTE YET" if source=="alternate" else "SAVED SEED · NO NOTE YET")
  _note.text="Your revised words are saved. Try this take for a written response; a writing day starts only when you choose WRITE." if source=="player" else "A two-line seed to work on. Try it as written, change the refrain, or rewrite a line before using a writing day."
  if source=="seed" and project.get("phase")=="seed":_note.text="%s offers a two-line seed. Try it as written, change the refrain, or rewrite a line before using a writing day." % str(project.target.leader_ref.name)
  if project.is_empty():
   _respondent.text="SAVED LYRIC METADATA HELD"
   _note.text=str(_view.get("message","This saved sketch needs compatible review."))
 else:
  respondent=trial.target.respondent_ref
  var current_note: bool=Rules._same(trial.fragment_snapshot,Rules._material(project.fragment)) and Rules._same(trial.target,project.target)
  _respondent.text="%s · %s · DAY %d" % [str(respondent.get("name","No bandmate response")),"WRITTEN NOTE" if current_note else "EARLIER SAVED NOTE",int(trial.immutable_context.day)]
  _note.text=str(trial.note.text)
 var path: String=""
 for person in Cast.combined_people():
  if not respondent.is_empty() and str(person.get("id",""))==str(respondent.get("candidate_id","")):path=str(person.get("portrait_preview",""));break
 _respondent_portrait.texture=load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
 _respondent_portrait.visible=not path.is_empty()
 _respondent_portrait.set_meta("source",path)
 _note.visible_characters=-1
 _preview.visible=false
 _use_take.visible=false
 _preview_kind=""
 _refresh_local()

func _refresh_local() -> void:
 if not is_instance_valid(_text):return
 var project:=_project()
 var held: bool=project.is_empty() or bool(_view.get("held",false))
 _text.editable=not held and not _busy
 _title.editable=not held and not _busy
 var stage: int=int(owner_state.game.career.get("song_draft_progress",0))+1
 var local_edits: bool=has_local_edits()
 _badge.text=("LOCAL EDITS · " if local_edits else "SAVED TAKE · ")+"SESSION %d / 3" % stage
 if local_edits and _notice_kind!="error":
  _show_notice("LOCAL EDITS · These words are not saved. Try this exact take before writing.","local")
 elif not local_edits and _notice_kind=="local":_show_notice("")
 _write.text="WRITE SESSION %d OF 3" % stage
 var modal: bool=is_instance_valid(_exit_dialog)
 _write.disabled=_busy or modal or held or has_local_edits() or not bool(_view.get("can_write",false))
 var retained: Array[Button]=[]
 for button in _buttons:
  if not is_instance_valid(button):continue
  retained.append(button)
  if str(button.name).begins_with("WorkbenchExit"):button.disabled=_busy
  elif button.name in ["WorkbenchMenu","WorkbenchCareer","WorkbenchSkipNote","WorkbenchHistory"]:button.disabled=_busy or modal
  elif button.name=="WorkbenchArchive":button.disabled=_busy or modal or not _view.get("ok",false) or project.is_empty() or _view.get("priority") not in ["workbench","review"]
  elif button.name!="WorkbenchWrite":button.disabled=_busy or held or modal
 _buttons=retained
 for index in range(_refrains.size()):
  _refrains[index].text=("● " if _refrain=="hook:%d" % (index+1) else "")+"REFRAIN %d" % (index+1)
 var members: Array=owner_state.game.career.get("members",[])
 if _leader_index>=0 and _leader_index<members.size():
  var person: Dictionary=members[_leader_index]
  _leader.text=str(person.get("name","Musician"))+" · LEADER"
  _identity.text="SESSION LEADER · "+str(person.get("name","the selected leader"))
  var path: String=""
  for source in Cast.combined_people():
   if str(source.get("id",""))==str(person.get("candidate_id","")):path=str(source.get("portrait_preview",""));break
  if not path.is_empty() and ResourceLoader.exists(path):_portrait.texture=load(path)
  else:_portrait.texture=null
  _portrait.set_meta("source",path)
 if held and _notice_kind!="error":_show_notice(str(_view.get("message","This saved sketch needs compatible review; its data is retained.")))
 _set_event_metadata()

func _set_event_metadata() -> void:
 for button in _buttons:
  if is_instance_valid(button):
   button.set_meta("workbench_expected",_expected.duplicate(true))
   button.set_meta("workbench_project_id",str(_expected.get("project_id","")))
   button.set_meta("workbench_revision",int(_expected.get("wrapper_revision",-1)))

func _finish_note() -> void:
 if is_instance_valid(_note):_note.finish_now()

func _reveal_only() -> bool:
 if _note.is_revealing():
  _note.finish_now()
  return true
 return false

func _show_notice(words: String,kind: String="info") -> void:
 _notice_kind=kind
 _notice.text=words
 _notice.visible=not words.is_empty()

func _choose_refrain(id: String) -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 _refrain=id
 _refresh_local()

func _change_leader(direction: int) -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 var members: Array=owner_state.game.career.get("members",[])
 if members.is_empty():return
 for step in range(1,members.size()+1):
  var index: int=posmod(_leader_index+direction*step,members.size())
  if members[index].get("life_status","active")=="active":_leader_index=index;break
 _refresh_local()

func _free(action: String) -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 _busy=true
 _refresh_local()
 var result: Dictionary=owner_state.workbench_action(action,_expected.duplicate(true),_payload())
 _busy=false
 refresh_saved(true) # Actual saved text matches the payload; keep native caret/selection.
 _show_notice(str(result.message),"saved" if result.get("ok",false) else "error")
 if result.get("ok",false) and action=="try" and result.get("changed",false):_note.begin(reduced_motion)

func _archive() -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 if has_local_edits():_show_notice("Save your local words before archiving. Archiving keeps the original song draft and completed days.");return
 _busy=true
 var result: Dictionary=owner_state.workbench_action("archive",_expected.duplicate(true),{"reason":"user_archive"})
 _busy=false
 if result.get("ok",false):closed.emit()
 else:refresh_saved(true);_show_notice(result.message,"error")

func _request_write() -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 if has_local_edits() or not _view.get("can_write",false):
  _show_notice("Try these exact words, title and leader before using a writing day.")
  return
 write_requested.emit(_expected.duplicate(true))

func _inspect(kind: String) -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 var project:=_project()
 var material: Dictionary=project.get("prior_fragment",{}) if kind=="prior" else Content.material(kind).material
 if material.is_empty():_show_notice("There is no earlier edited take recorded yet.");return
 _preview_kind=kind
 _preview.text="%s\n%s\n%s\nRefrain: line %s" % ["PREVIOUS SAVED TAKE" if kind=="prior" else ("SEED A" if kind=="seed" else "TAKE B"),material.lines[0].text,material.lines[1].text,str(material.refrain_line_id).trim_prefix("hook:")]
 _preview.visible=true
 _use_take.visible=true
 _use_take.text="RESTORE LOCALLY" if kind=="prior" else "USE THIS TAKE · SAVE FREE"

func _use_preview() -> void:
 if _busy or is_instance_valid(_exit_dialog) or _reveal_only():return
 if has_local_edits():_show_notice("Save or try your local edits before selecting another take. Inspection has kept your words and caret.");return
 if _preview_kind=="prior":
  var material: Dictionary=_project().get("prior_fragment",{})
  if material.is_empty():return
  _text.text="%s\n%s" % [material.lines[0].text,material.lines[1].text]
  _refrain=material.refrain_line_id
  _refresh_local()
  return
 if _preview_kind not in ["seed","alternate"]:return
 _busy=true
 var result: Dictionary=owner_state.workbench_action("use_alternate",_expected.duplicate(true),{"kind":_preview_kind})
 _busy=false
 refresh_saved(not result.get("ok",false))
 _show_notice(result.message,"saved" if result.get("ok",false) else "error")

func request_exit(destination: String) -> void:
 if _busy or is_instance_valid(_exit_dialog):return
 if _reveal_only():return
 if not has_local_edits():exit_ready.emit(destination);return
 _exit_generation+=1
 var epoch: int=_exit_generation
 _exit_destination=destination
 _exit_token=_expected.duplicate(true)
 _exit_layer=CanvasLayer.new()
 _exit_layer.layer=30
 add_child(_exit_layer)
 _exit_dialog=Control.new()
 _exit_dialog.name="WorkbenchExitDialog"
 _exit_layer.add_child(_exit_dialog)
 _exit_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _exit_dialog.mouse_filter=Control.MOUSE_FILTER_STOP
 var shade:=ColorRect.new()
 shade.color=Color(0,0,0,0.8)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _exit_dialog.add_child(shade)
 var center:=CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 _exit_dialog.add_child(center)
 var panel:=PanelContainer.new()
 panel.custom_minimum_size.x=minf(420,maxf(260,size.x-28))
 center.add_child(panel)
 var body:=VBoxContainer.new()
 body.add_theme_constant_override("separation",10)
 panel.add_child(body)
 body.add_child(_label("KEEP YOUR LOCAL WORDS?",20))
 _exit_message=_label("Save this sketch free, discard only these local edits, or keep editing. No writing day is used.")
 body.add_child(_exit_message)
 body.add_child(_button("SAVE SKETCH FREE","WorkbenchExitSave",_exit_choice.bind("save",epoch)))
 body.add_child(_button("DISCARD LOCAL EDITS","WorkbenchExitDiscard",_exit_choice.bind("discard",epoch)))
 var keep:=_button("KEEP EDITING","WorkbenchExitKeep",_exit_choice.bind("keep",epoch))
 body.add_child(keep)
 _refresh_local()
 keep.call_deferred("grab_focus")

func _close_exit() -> void:
 _exit_generation+=1
 if is_instance_valid(_exit_layer):
  remove_child(_exit_layer)
  _exit_layer.queue_free()
 _exit_layer=null
 _exit_dialog=null
 _exit_message=null
 _refresh_local()

func _exit_choice(choice: String,epoch: int) -> void:
 if not is_instance_valid(_exit_dialog) or epoch!=_exit_generation or _busy:return
 if choice=="keep":_close_exit();_text.grab_focus();return
 var destination: String=_exit_destination
 if choice=="save":
  _busy=true
  var result: Dictionary=owner_state.workbench_action("save_sketch",_exit_token.duplicate(true),_payload())
  _busy=false
  if not result.get("ok",false):
   _view=result.view
   _expected=result.expected
   _exit_token=_expected.duplicate(true)
   _exit_message.text=str(result.message)
   _refresh_local()
   return
 elif choice!="discard":return
 _close_exit()
 refresh_saved(false)
 exit_ready.emit(destination)

func _unhandled_key_input(event: InputEvent) -> void:
 # TextEdit/LineEdit consume their own Space/Enter/IME. Only Escape in this
 # local modal is handled here; typing never finishes a global Ink or pays.
 if is_instance_valid(_exit_dialog) and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  _exit_choice("keep",_exit_generation)
  get_viewport().set_input_as_handled()

func _on_visibility_changed() -> void:
 if not is_visible_in_tree() and is_instance_valid(_exit_dialog):_close_exit()
