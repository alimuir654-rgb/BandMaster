extends "res://tests/song62_native.gd"
## Actual packaged entry/controllers, isolated owner and real native input.
const Career=preload("res://experiments/playable_flightcase/career_desk.gd")
const RootUI=preload("res://experiments/playable_flightcase/ui.gd")
var nav_rects: Array=[]
var normal_motion: bool=OS.get_environment("UX70_NORMAL_MOTION")=="1"

func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg=="--baseline":baseline=true
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 deadline=Time.get_ticks_msec()+175000
 call_deferred("_run_native")

func _finish_native() -> void:
 if not baseline and not nav_rects.is_empty():
  var anchor: Array=nav_rects[0].rect
  for frame in nav_rects:
   check(frame.rect==anchor,"fixed navigation inset and size "+str(frame.frame))
 var result: Dictionary={"pass":failure_count==0,"viewport":[root.size.x,root.size.y],"checks":checks,"failures":failures,"images":images,"trace":trace,"navigation":nav_rects,"baseline":baseline,"reduced_motion":not normal_motion,"actual_entry":"experiments/playable_flightcase/opening.tscn","physical_device":false,"listening":false}
 var file:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if file!=null:file.store_string(JSON.stringify(result,"  ")+"\n");file.close()
 print("UX70_NATIVE "+JSON.stringify(result))
 if is_instance_valid(scene):scene.queue_free()
 await process_frame
 quit(0 if failure_count==0 else 1)

func _release_scene() -> void:
 if is_instance_valid(scene):scene.queue_free();scene=null
 await settle()

func _mount_career() -> void:
 await _release_scene()
 scene=Career.new();scene.game=owner.game;scene.opening_owner=owner;scene.reduced_motion=not normal_motion
 root.add_child(scene);scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 await settle(10)

func _mount_practice(activity: String) -> void:
 await _release_scene()
 scene=RootUI.new();scene.game=owner.game;scene.opening_owner=owner;scene.practice_activity=activity;scene.recap_expanded=false;scene.reduced_motion=not normal_motion
 root.add_child(scene);scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 await settle(10)

func _record_frame(label: String) -> void:
 await _normal_words()
 var visible: Array=[]
 for node in scene.find_children("*","Button",true,false):
  if node.is_visible_in_tree() and clipped_rect(node).encloses(node.get_global_rect()):
   visible.append({"name":str(node.name),"text":str(node.text),"rect":[node.global_position.x,node.global_position.y,node.size.x,node.size.y]})
 trace.append({"frame":label,"visible_buttons":visible})
 var bars: Array=[]
 for bar in scene.find_children("NavigationBar","Control",true,false):
  if bar.is_visible_in_tree():bars.append(bar);nav_rects.append({"frame":label,"rect":[bar.global_position.x,bar.global_position.y,bar.size.x,bar.size.y]})
 if not baseline:check(bars.size()==1,"one fixed navigation row "+label)
 await capture(label)

func _run_native() -> void:
 if not check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"private owner save root"):_finish_native();return
 if not _two_songs():_finish_native();return
 var band: Dictionary=owner.snapshot().duplicate(true)
 if not baseline:
  await _career_routes()
  if failure_count>0:_finish_native();return
 await _mount_career()
 await _record_frame("home")
 scene._navigate("songs");await settle(10);await _record_frame("songbook")
 scene._open_musician_chat("cast_jack");await settle(10);await _record_frame("musician")
 scene._open_booking({});await settle(10)
 if named("BookingVenue_local")!=null:
  await activate("BookingVenue_local");await _record_frame("promoter")
 await _mount_practice("tighten")
 await _record_frame("rehearsal-entry")
 await activate("RehearsalSongNext",true);await activate("RehearsalSongNext")
 await _record_frame("rehearsal-selected")
 if not baseline:
  await _candidate_rehearsal()
  if failure_count>0:_finish_native();return
 await _release_scene()
 check(owner.restore(band) and owner.save_draft(),"restore only isolated canonical fixture")
 check(owner.begin_workbench("THE LAST TRAIN — ÉCHO",0,owner.workbench_expected(),Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"})).ok,"begin original musical draft")
 if baseline:await _mount_practice("create")
 else:await _mount_opening(false)
 await _record_frame("writing-entry")
 if not baseline:
  await _candidate_writing()
  if failure_count>0:_finish_native();return
 await _release_scene()
 owner=CountedOwner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"canonical new audition fixture")
 check(owner.begin_audition("cast_jack","Guitarist",true).ok,"original direct audition entry")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=not normal_motion;root.add_child(scene)
 await settle(10);await _record_frame("audition-entry")
 if baseline:
  await activate("AuditionTalk_working_style_shared");await _record_frame("audition-second-question")
  await activate("AuditionRequestSpace");await _record_frame("audition-response")
 else:await _candidate_audition()
 await _finish_native()


func _mount_opening(landing: bool=true) -> void:
 await _release_scene()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=not normal_motion;scene._career_landing=landing
 root.add_child(scene);await settle(10)

func _free(before: Dictionary,disk: PackedByteArray,saves: int,label: String) -> void:
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and owner.saves==saves,label+" is free and does not save")

func _ready_turn() -> void:
 await create_timer(0.38).timeout
 await settle(3)
 await _normal_words()

func _normal_words() -> void:
 if not normal_motion:return
 # Observe the real reveal without cancelling it or changing gameplay state.
 var until: int=Time.get_ticks_msec()+4500
 while Time.get_ticks_msec()<until:
  var revealing: bool=false
  for note in get_nodes_in_group("bandmaster_notes"):
   if note.is_visible_in_tree() and note.is_revealing():revealing=true
  if not revealing:return
  await process_frame
 check(false,"normal-motion words finish within original reveal bound")

func _key(code: int) -> void:
 for down in [true,false]:
  var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
  Input.parse_input_event(event);await process_frame
 await settle(3)

func _visible_focus(label: String) -> void:
 var current: Control=root.gui_get_focus_owner()
 trace.append({"focus":label,"name":str(current.name) if current!=null else "NONE","visible":current!=null and current.is_visible_in_tree(),"disabled":current is Button and current.disabled})
 check(current!=null and current.is_visible_in_tree() and current.focus_mode!=Control.FOCUS_NONE and (not current is Button or not current.disabled),label+" visible enabled focus")

func _rapid(name: String,limit: int) -> void:
 var target: Button=named(name) as Button
 if not check(target!=null and not target.disabled,"rapid input target "+name):return
 if not await reveal(target):return
 var point: Vector2=root.get_final_transform()*target.get_global_transform_with_canvas()*(target.size/2)
 var start: int=Time.get_ticks_msec()
 for repeat in range(2):
  for down in [true,false]:
   var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
   Input.parse_input_event(event)
  if repeat==0:await RenderingServer.frame_post_draw
 var elapsed: int=Time.get_ticks_msec()-start
 check(elapsed<limit,"two real same-coordinate clicks within guard "+name)
 trace.append({"rapid":name,"elapsed_ms":elapsed,"guard_ms":limit,"physical_point":[point.x,point.y]})
 await settle(3)

func _first_fold(names: Array,label: String) -> void:
 for id in names:
  var control: Control=named(str(id))
  check(control!=null and clipped_rect(control).grow(0.5).encloses(control.get_global_rect()),label+" first fold "+str(id))

func _targets(label: String) -> void:
 var count: int=0
 for button in scene.find_children("*","Button",true,false):
  if not button.is_visible_in_tree():continue
  var id: String=str(button.name)
  if not (button.has_meta("global_navigation") or id.begins_with("RehearsalIntent_") or id.begins_with("AuditionTalk_") or id.begins_with("Mixing") or id.begins_with("Choice_") or id.begins_with("ChatReply_") or id in ["ChatTopicsAction","ChatHistoryAction","BookingAboutPromoter","PracticeDetailsAction"]):continue
  var rect: Rect2=root.get_final_transform()*button.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,button.size)
  check(rect.size.x>=47.99 and rect.size.y>=47.99,"physical 48px "+label+" "+id)
  count+=1
 trace.append({"physical_targets":label,"count":count,"minimum":48})

func _career_routes() -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 await _mount_opening()
 if not await activate("PosterActivitiesAction"):return
 if not await activate("CareerLauncherGroup_people"):return
 if not await activate("CareerHome_band"):return
 check(scene._career_view.page=="band","real opening launcher reaches Band leaf")
 if not await activate("CareerTalk_cast_jack"):return
 _first_fold(["MusicianChatPortrait","ChatReply_write_together","ChatReply_prepare_set","ChatReply_listen"],"musician")
 _visible_focus("musician route")
 if not await activate("ChatHistoryAction"):return
 check(scene._career_view.chat_history_open,"fresh musician commitments disclosed before answer")
 if not await activate("ChatHistoryAction"):return
 if not await activate("ChatTopicsAction"):return
 if not await activate("ChatTopic_time"):return
 _visible_focus("changed topic")
 if not await activate("ChatBack"):return
 check(scene._career_view.page=="band","retained musician Back route")
 if not await activate("CareerNav_home"):return
 if not await activate("CareerMenuAction"):return
 if not await activate("CareerPauseResume",true):return
 _visible_focus("career Menu Resume")
 if not await activate("CareerMenuAction"):return
 if not await activate("CareerPauseExitTitle"):return
 check(named("ContinueAction")!=null,"fixed Menu reaches actual title")
 if not await activate("ContinueAction"):return
 _free(before,disk,saves,"launcher, musician topics and Menu/Continue")
 await _record_frame("real-home-return")

func _rehearsal_review() -> void:
 if not await activate("RehearsalNextAction"):return
 await _ready_turn()
 if not await activate("RehearsalIntent_focus_listening"):return
 await _ready_turn()
 if not await activate("RehearsalIntent_effort_push"):return
 await _ready_turn()

func _candidate_rehearsal() -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 var choices: Array=Workbench.finished(before).items
 var selected: Dictionary=choices[-1].reference.duplicate(true)
 check(Workbench._same(scene.rehearsal_reference,selected),"selected exact second original")
 if not await activate("RehearsalNextAction",true):return
 await _ready_turn()
 _visible_focus("rehearsal focus question")
 check(str(root.gui_get_focus_owner().name).begins_with("RehearsalIntent_focus_"),"product restores next question focus")
 _targets("rehearsal focus");await _record_frame("rehearsal-focus")
 await _rapid("RehearsalIntent_focus_listening",300)
 if not check(scene.rehearsal_step==2,"rapid repeat advances only one rehearsal stage") or failure_count>0:return
 _free(before,disk,saves,"song and focus")
 await _ready_turn()
 _visible_focus("rehearsal pace question")
 check(str(root.gui_get_focus_owner().name).begins_with("RehearsalIntent_effort_"),"product restores pace focus without helper grab")
 await _key(KEY_SPACE)
 await _ready_turn()
 check(scene.rehearsal_step==3,"continuous keyboard reaches review")
 _free(before,disk,saves,"pace and review")
 await _record_frame("rehearsal-review")
 if not await activate("CareerDeskAction",true):return
 await _ready_turn()
 check(scene.rehearsal_step==2,"top Back revisits prior choice")
 if not await activate("RehearsalIntent_effort_push"):return
 await _ready_turn()
 _free(before,disk,saves,"back and rechoose")
 scene.rehearsal_reference.fragment_sha256="stale-fixture";scene._rebuild();await settle(8)
 if not await activate("RehearseAction"):return
 _free(before,disk,saves,"stale arrangement refusal")
 check(scene.rehearsal_reference.fragment_sha256=="stale-fixture","invalid arrangement remains explicit")
 scene.rehearsal_reference=selected.duplicate(true);scene._rebuild();await settle(8)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"real rehearsal save blocker")
 if not await activate("RehearseAction"):return
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"rehearsal failure restores whole owner and disk")
 check(owner.saves==saves+1 and Workbench._same(scene.rehearsal_reference,selected) and scene.rehearsal_direction=={"focus":"listening","effort":"push"} and scene.rehearsal_step==3,"failed rehearsal retains exact free choices and phase")
 await _record_frame("rehearsal-save-failure")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated rehearsal blocker")
 if not await activate("RehearseAction",true):return
 await _idle()
 check(owner.saves==saves+2 and owner.game.career.cash==before.game.career.cash-15 and owner.game.career.tour_day==before.game.career.tour_day+1 and owner.game.career.action_count==before.game.career.action_count+1,"rehearsal retry one save/15 pounds/day/action")
 var saved: Dictionary=owner.snapshot()
 check(owner.game.career[Preparation.KEY].receipts[-1].song_id==selected.song_id,"receipt records exact selected original")
 scene._load_original();await settle(8)
 check(Workbench._exact(owner.snapshot(),saved),"rehearsal actual load exact typed owner")
 await reveal(named("RehearsalSavedSong"));await _record_frame("rehearsal-saved-song")
 for _day in range(3):
  if not _jam_day():return
 check(int(owner.game.career.tour_day)==16,"original owners reach Tuesday")
 await _mount_practice("tighten")
 if not await activate("RehearsalSongNext"):return
 await _rehearsal_review()
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 if not await activate("RehearseAction"):return
 check(named("WorkConflictProceedAction")!=null,"original partial-attendance review")
 await _record_frame("rehearsal-attendance")
 if not await activate("WorkConflictBackAction",true):return
 _free(before,disk,saves,"attendance cancel")
 if not await activate("RehearseAction"):return
 if not await activate("WorkConflictProceedAction",true):return
 await _idle()
 var partial: Dictionary=owner.game.career[Preparation.KEY].receipts[-1]
 check(owner.saves==saves+1 and partial.song_id==choices[0].reference.song_id and partial.participants==["cast_zoe","cast_casey"],"partial rehearsal original one save and exact present people")
 await _mount_practice("tighten")
 var count: int=owner.game.career[Preparation.KEY].receipts.size();before=owner.snapshot();saves=owner.saves
 await _rehearsal_review()
 if not await activate("RehearseAction"):return
 await _idle()
 check(owner.saves==saves+1 and owner.game.career.cash==before.game.career.cash-15 and owner.game.career[Preparation.KEY].receipts.size()==count,"general rehearsal original single save without invented song receipt")

func _practice_idle(practice) -> void:
 var until: int=Time.get_ticks_msec()+6000
 while is_instance_valid(practice) and practice.session_busy and Time.get_ticks_msec()<until:await process_frame
 check(is_instance_valid(practice) and not practice.session_busy,"actual writing presentation completes")
 await settle(8)

func _candidate_writing() -> void:
 var seed: Dictionary=owner.snapshot().duplicate(true)
 var practice=scene._practice_view
 var desk=practice._workbench_desk
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 _first_fold(["MixingMemberPortrait","MixingMemberName","MixingMemberNote","MixingResponse_try","MixingResponse_keep","MixingResponse_dismiss"],"writing")
 _targets("writing entry")
 if not await activate("MixingShapeAction"):return
 var title: LineEdit=named("MixingTitle") as LineEdit
 if not await reveal(title):return
 title.grab_focus();await _key(KEY_END)
 for down in [true,false]:
  var typed:=InputEventKey.new();typed.keycode=KEY_Z;typed.physical_keycode=KEY_Z;typed.unicode=90;typed.pressed=down;Input.parse_input_event(typed);await process_frame
 await settle(3)
 var edited: String=title.text;var caret: int=title.caret_column
 check(edited.ends_with("Z") and desk.has_local_edits(),"actual title keystroke is local and dirty")
 var viewport: Vector2i=root.size
 root.size=viewport+Vector2i(48,32);await settle(8)
 root.size=viewport;await settle(8)
 practice=scene._practice_view;desk=practice._workbench_desk
 check(desk._title.text==edited and desk._title.caret_column==caret,"resize retains local title and caret")
 var visible: int=0
 for control in desk._controls.values():
  if control.is_visible_in_tree():visible+=1
 check(visible==1,"Shape shows one editable axis after caption refresh")
 _targets("writing Shape")
 await _record_frame("writing-shape")
 if not await activate("MixingShapeNext"):return
 visible=0
 for control in desk._controls.values():
  if control.is_visible_in_tree():visible+=1
 check(visible==1,"next Shape setting still one axis")
 if not await activate("MixingMoreOptions"):return
 if not await activate("MixingCollaboratorNext"):return
 check(desk._target().respondent_ref.candidate_id=="cast_casey","explicit Casey partner")
 if not await activate("MixingLeaderNext"):return
 if not await activate("MixingLeaderNext"):return
 check(desk._target().is_empty(),"self partner conflict stays explicit")
 if not await activate("MixingCollaboratorNext"):return
 check(desk._target().respondent_ref.candidate_id=="cast_jack","explicit former leader as partner")
 if not await activate("MixingLeaderNext"):return
 check(desk._target().is_empty(),"reverse self partner conflict explicit")
 if not await activate("MixingCollaboratorNext"):return
 if not await activate("MixingCollaboratorNext"):return
 check(desk._target().respondent_ref.candidate_id=="cast_casey","explicit intended Casey restored")
 await _key(KEY_ESCAPE)
 check(not desk._shape_open and not is_instance_valid(desk._dialog),"Escape matches local Shape Back")
 _visible_focus("writing Shape Escape")
 await _record_frame("writing-shape-escape")
 if failure_count>0:return
 if not await activate("MixingShapeAction",true):return
 if not await activate("MixingShapeDone",true):return
 _visible_focus("writing Shape Done")
 if failure_count>0:return
 _free(before,disk,saves,"Shape and partner choices")
 await _rapid("MixingResponse_try",350)
 check(desk._decision.get("choice")=="try","rapid reply repeat cannot undo or commit")
 await _ready_turn();_visible_focus("writing review")
 _free(before,disk,saves,"writing reply and review")
 await _record_frame("writing-reply")
 if not await activate("MixingChangeReply"):return
 _visible_focus("writing Change Reply")
 if failure_count>0:return
 if not await activate("MixingResponse_keep"):return
 await _ready_turn()
 check(desk._decision.get("choice")=="keep","original Keep reply")
 if not await activate("MixingChangeReply"):return
 if not await activate("MixingResponse_dismiss"):return
 await _ready_turn()
 check(desk._decision.get("choice")=="dismiss","original leave unanswered reply")
 if not await activate("MixingPauseButton"):return
 check(named("MixingPauseResume")!=null,"top Menu pauses writing with local work")
 if not await activate("MixingPauseResume",true):return
 check(desk._decision.get("choice")=="dismiss","Pause Resume retains reply")
 if not await activate("MixingBack"):return
 if not await activate("MixingExitKeep",true):return
 _visible_focus("dirty Keep")
 check(desk._collaborator_id=="cast_casey" and desk._decision.get("choice")=="dismiss" and desk._title.text==edited and desk._title.caret_column==caret,"Keep retains local title/caret, partner and reply")
 if not await activate("MixingBack"):return
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"true free writing save blocker")
 if not await activate("MixingExitSave"):return
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"free save failure exact rollback")
 check(not desk._dialog_error.text.is_empty() and desk._collaborator_id=="cast_casey","visible failed save and local partner retained")
 await _record_frame("writing-save-failure")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only writing blocker")
 if not await activate("MixingExitSave",true):return
 check(owner.workbench_view().project.target.respondent_ref.candidate_id=="cast_casey","free Save stores selected partner")
 var a: Dictionary=before.game.duplicate(true);a.career.erase(Workbench.KEY)
 var b: Dictionary=owner.snapshot().game.duplicate(true);b.career.erase(Workbench.KEY)
 check(Workbench._exact(a,b),"free sketch save does not spend day/cash")
 if not await activate("CareerMenuAction"):return
 if not await activate("CareerPauseExitTitle"):return
 if not await activate("ContinueAction"):return
 if not await activate("PosterActivitiesAction"):return
 if not await activate("CareerLauncherGroup_music"):return
 if not await activate("PosterWriteAction"):return
 practice=scene._practice_view;desk=practice._workbench_desk
 check(desk._collaborator_id=="cast_casey" and desk._title.text==edited,"actual Continue and writing route retain saved partner/title")
 var retained: Dictionary=owner.snapshot();var retained_disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var retained_saves: int=owner.saves
 if not await activate("MixingShapeAction"):return
 title=named("MixingTitle") as LineEdit
 if not await reveal(title):return
 title.grab_focus();await _key(KEY_END);await _key(KEY_BACKSPACE)
 check(desk._title.text!=edited,"second local title edit exists before discard")
 if not await activate("MixingBack"):return
 if not await activate("MixingPauseButton"):return
 if not await activate("MixingPauseExitTitle"):return
 if not await activate("MixingExitDiscard",true):return
 if not await activate("ContinueAction"):return
 _free(retained,retained_disk,retained_saves,"discard local title and Continue")
 if not await activate("PosterActivitiesAction"):return
 if not await activate("CareerLauncherGroup_music"):return
 if not await activate("PosterWriteAction"):return
 practice=scene._practice_view;desk=practice._workbench_desk
 check(desk._title.text==edited and desk._collaborator_id=="cast_casey","discard preserves prior saved title and person")
 if not desk._decision.is_empty():
  if not await activate("MixingChangeReply"):return
 if not await activate("MixingResponse_try"):return
 await _ready_turn()
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"true paid writing save blocker")
 if not await activate("MixingCommit"):return
 await _practice_idle(practice)
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"paid writing failure exact rollback")
 check(desk._decision.get("choice")=="try" and desk._collaborator_id=="cast_casey","paid failure retains intended response and person")
 check(DirAccess.remove_absolute(blocker)==OK,"remove paid writing blocker")
 if not await activate("MixingCommit",true):return
 await _practice_idle(practice)
 check(owner.saves==saves+2 and owner.game.career.tour_day==before.game.career.tour_day+1 and owner.game.career.action_count==before.game.career.action_count+1,"writing retry exactly one original day/action through original accounting")
 var loaded=Owner.new()
 check(loaded.load_draft() and Workbench._exact(loaded.snapshot(),owner.snapshot()),"writing complete typed reload")
 await _record_frame("writing-saved-stage")
 await _held_workbench(seed)

func _candidate_audition() -> void:
 _first_fold(["AuditionPortrait","AuditionSpeaker","AuditionHeldVoice","AuditionCurrentQuestion","AuditionTalk_working_style_shared","AuditionTalk_working_style_direct","AuditionHearPart"],"audition")
 _targets("audition entry")
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 await _rapid("AuditionTalk_working_style_shared",350)
 var answers: Dictionary=owner.audition_view().get("conversation",{}).get("answers",{})
 if not check(answers.size()==1 and answers.get("working_style")=="shared" and owner.saves==saves+1,"rapid audition reply saves exactly one authored answer"):return
 await _ready_turn()
 _visible_focus("audition next question")
 await _record_frame("audition-second-question")
 _first_fold(["AuditionPortrait","AuditionSpeaker","AuditionHeldVoice","AuditionCurrentQuestion","AuditionTalk_commitment_dates","AuditionTalk_commitment_regular"],"second audition question")
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"real audition answer save blocker")
 if not await activate("AuditionTalk_commitment_dates"):return
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and named("AuditionTalk_commitment_dates")!=null,"failed answer retains exact state and question")
 check(DirAccess.remove_absolute(blocker)==OK,"remove audition answer blocker")
 if not await activate("AuditionTalk_commitment_dates"):return
 await _ready_turn()
 check(owner.audition_view().conversation.answers.size()==2 and owner.saves==saves+2,"answer retry one attempted and one successful save")
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 if not await activate("AuditionHearPart"):return
 _free(before,disk,saves,"Hear part stage")
 AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),false)
 if not await activate("AuditionPlayFirst"):return
 var encounter=named("AuditionEncounter")
 check(encounter._audio.playing,"actual Jack first sample plays")
 if not await activate("AuditionStopTakes"):return
 check(not encounter._audio.playing,"actual audio stops")
 if not await activate("AuditionBiography"):return
 if not await activate("AuditionReadPart"):return
 check(named("AuditionWrittenParts")!=null,"written bars disclosed")
 if not await activate("AuditionBiography"):return
 check(named("AuditionWrittenParts")==null,"Details close collapses written bars")
 _free(before,disk,saves,"playback and disclosures")
 if not await activate("AuditionRequestSpace"):return
 await _record_frame("audition-response")
 _first_fold(["AuditionPortrait","AuditionSpeaker","AuditionHeldVoice","AuditionPlayFirst","AuditionPlayAdjusted","AuditionStopTakes"],"audition response with playback")
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 if not await activate("AuditionPlayAdjusted"):return
 encounter=named("AuditionEncounter")
 check(encounter._audio.playing and str(encounter._audio._material).contains("space_for_voice"),"actual registered adjusted take plays")
 if not await activate("AuditionMenu"):return
 if not await activate("ContinueAction"):return
 _free(before,disk,saves,"audition Menu Continue")
 var members: int=owner.game.roster.size();var budget: int=owner.remaining()
 var price: int=owner.game.incremental_cost(owner.game.person_by_id("cast_jack"))
 var token: Dictionary=owner.audition_expected().duplicate(true)
 _first_fold(["AuditionTalentBalance","AuditionInvite","AuditionPass"],"audition explicit commitment")
 if not await activate("AuditionInvite"):return
 check(owner.game.roster.size()==members+1 and owner.saves==saves+1 and owner.remaining()==budget-price,"original invitation recruits, charges talent and saves once")
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 check(not owner.resolve_audition_response("invite",token).ok,"old invitation token rejected")
 _free(before,disk,saves,"duplicate invitation refusal")
 var loaded=Owner.new();check(loaded.load_draft() and Workbench._exact(loaded.snapshot(),owner.snapshot()),"invitation exact typed reload")
 await _record_frame("audition-invited")
 # A second independent canonical audition proves optional replies and Arjun's
 # authorized recorded-player path with Details closed, never a synthetic clip.
 await _release_scene();owner=CountedOwner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit() and owner.begin_audition("cast_arjun","Guitarist",true).ok,"canonical optional Arjun fixture")
 await _mount_opening(false)
 before=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 if not await activate("AuditionHearPart"):return
 if not await activate("AuditionPlayFirst"):return
 encounter=named("AuditionEncounter")
 var ideas=named("CharacterRecordedIdeas")
 if not check(ideas!=null and ideas.playing and not encounter._audio.playing and not encounter._details_open,"Arjun primary recorded player works with Details closed"):return
 _free(before,disk,saves,"optional skip and Arjun playback")
 await _record_frame("arjun-default-recording")
 _first_fold(["AuditionPortrait","AuditionSpeaker","AuditionPlayFirst","AuditionStopTakes"],"Arjun playback with Details closed")
 if not await activate("AuditionStopTakes"):return
 check(not ideas.playing,"Arjun stop reaches primary owner")
 if not await activate("AuditionPlayFirst"):return
 if not await activate("AuditionMenu"):return
 if not await activate("ContinueAction"):return
 encounter=named("AuditionEncounter");ideas=encounter.find_child("CharacterRecordedIdeas",true,false)
 check(not ideas.playing,"Arjun Menu stops audio and Continue does not autoplay")
 if named("AuditionHearPart")!=null:
  if not await activate("AuditionHearPart"):return
 if not await activate("AuditionRequestSpace"):return
 check(owner.audition_view().conversation.answers.is_empty(),"musical request valid with zero optional answers")
 await _record_frame("arjun-written-response")
 _first_fold(["AuditionPlayFirst","AuditionStopTakes","AuditionWrittenResponse","AuditionTalentBalance","AuditionInvite","AuditionPass"],"Arjun written response")
 check(named("AuditionPlayAdjusted")==null,"unavailable adjusted audio is a fact, not a visible action")
 if not await activate("AuditionInvite"):return
 check(owner.game.roster.size()==1,"audition remains completable without optional answers")

func _held_workbench(seed: Dictionary) -> void:
 # Explicit stale saved-binding recovery fixture, not a newly produced event.
 var held: Dictionary=seed.duplicate(true)
 held.game.career[Workbench.KEY].project.binding.original_song_sequence=int(held.game.career.get("original_song_sequence",held.game.career.get("songs",0)))+1
 var view: Dictionary=Workbench.view(held)
 if not check(Workbench.validate(held).ok and view.ok and view.active and view.held and view.priority=="review" and Mixing.valid(view.project.fragment.producer_recipe),"well-formed stale modern saved binding"):return
 await _release_scene()
 if not check(owner.restore(held) and owner.save_draft() and owner.load_draft(),"real held fixture save and load"):return
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=true;scene.reduced_motion=not normal_motion;root.add_child(scene);await settle(8)
 if not await activate("ContinueAction"):return
 var desk=scene._practice_view._workbench_desk
 check(desk._view.held and not desk.has_local_edits(),"actual Continue opens clean held modern view")
 check(not desk._audio_context().allowed and desk._commit.disabled,"held audio and commit remain blocked")
 check(named("MixingBack")!=null and not (named("MixingBack") as Button).disabled and not (named("MixingPauseButton") as Button).disabled,"held top navigation usable")
 await _record_frame("writing-held-review")
 if not await activate("MixingPauseButton"):return
 if not await activate("MixingPauseResume",true):return
 _free(before,disk,saves,"held Pause Resume")
 if not await activate("MixingPauseButton"):return
 if not await activate("MixingPauseExitTitle"):return
 if not await activate("ContinueAction"):return
 check(scene._practice_view._workbench_desk._view.held,"Continue retains exact held review")
 _free(before,disk,saves,"held title Continue")
 if not await activate("MixingBack"):return
 check(scene._career_view!=null and scene._career_view.is_visible_in_tree() and scene._career_view.page=="home","held Back reaches actual Home")
 _free(before,disk,saves,"held Back")
