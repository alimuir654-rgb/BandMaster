extends "res://tests/song57_craft_fairness.gd"
const Desk=preload("res://experiments/playable_flightcase/mixing_desk.gd")
const SongAudio=preload("res://experiments/playable_flightcase/song_audio.gd")
var scene: Control
var desk
var output := ""
var baseline := false
var images: Array=[]
var trace: Array=[]
var baseline_defects: Array[String]=[]
var deadline := 0
var fail_next := false
var last_native: Dictionary={}
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg=="--baseline":baseline=true
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 deadline=Time.get_ticks_msec()+120000
 call_deferred("_run_native")
func check(ok: bool,message: String) -> bool:
 return _check(ok,message)
func _finish_native() -> void:
 print("SONG60_NATIVE "+JSON.stringify({"ok":failure_count==0,"checks":checks,"failures":failures,"images":images,"trace":trace,"successful_paid_settlements":owner_transactions,"baseline":baseline}))
 if is_instance_valid(scene):scene.queue_free()
 await process_frame
 quit(0 if failure_count==0 else 1)
func _mount() -> void:
 if is_instance_valid(scene):scene.queue_free();await process_frame
 scene=MarginContainer.new();root.add_child(scene);scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["margin_left","margin_right","margin_top","margin_bottom"]:scene.add_theme_constant_override(side,12)
 desk=Desk.new();desk.configure(owner,root.size.x>=1000);scene.add_child(desk)
 desk.write_requested.connect(_write)
 desk.sound_requested.connect(func():
  var master: int=AudioServer.get_bus_index("Master")
  var muted: bool=not AudioServer.is_bus_mute(master)
  AudioServer.set_bus_mute(master,muted)
  preload("res://experiments/playable_flightcase/audio_preferences.gd").write_muted(muted)
  desk.refresh_saved(true))
 await settle()
func _write(request: Dictionary) -> void:
 last_native={"ok":false}
 var ticket: Dictionary=owner.begin_workbench_commit(request.expected,request.mixing_payload)
 if not check(ticket.get("ok",false),"native request original owner ticket: "+str(ticket.get("message",""))):return
 var p: Dictionary=ticket.prepared
 var result: Dictionary=owner.game.write_session_prepared(p.args.idea,p.args.form,p.args.title,p.args.leader_index,p)
 if not check(result.ok and owner.complete_workbench_original(ticket.transaction_id,result).ok,"original writing and reconciliation"):return
 var tracked: Dictionary=Situation.after_action(ticket.before_game.career,owner.game.career)
 if not check(tracked.ok,"actual situation accounting"):return
 owner.game.career=Live.after_practice(ticket.before_game.career,tracked.state)
 var accounted: Dictionary=Finance.apply(ticket.before_game.career,owner.game.career,"practice:create")
 if not check(accounted.ok,"original Finance owner"):return
 owner.game.career=accounted.state
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 if fail_next:check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"actual native paid failure blocker")
 last_native=owner.finish_workbench_commit(ticket.transaction_id)
 if fail_next:check(DirAccess.remove_absolute(blocker)==OK,"remove only QA blocker")
 if last_native.ok:
  owner_transactions+=1
  var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
  check(not owner.finish_workbench_commit(ticket.transaction_id).ok,"duplicate native settlement refused")
  check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"duplicate no state/disk change")
 if not last_native.ok:desk.show_commit_error(str(last_native.get("message","Save failed; your local direction is retained.")))
func _run_native() -> void:
 if not check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"private owner save root"):_finish_native();return
 if not check(_fixture() and _available(),"original public formation and availability"):_finish_native();return
 check(owner.begin_workbench("THE LAST TRAIN — ÉCHO",0,owner.workbench_expected(),Mixing.recipe({"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"})).ok,"begin original draft")
 await _mount()
 if baseline:
  await reveal(named("MixingMemberName"));await capture("baseline-writing-card");await _finish_native();return
 var start: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 if not await activate("MixingCollaboratorNext"):_finish_native();return
 check(desk._target().respondent_ref.candidate_id=="cast_casey","choose actual second bandmate")
 check(owner.snapshot()==start and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"selection local until Save/Commit")
 check(desk.has_local_edits(),"selection contributes to dirty state")
 await activate("MixingSound")
 check((named("MixingSound") as Button).text.contains("OFF"),"actual master mute reflected by writing controls")
 check(preload("res://experiments/playable_flightcase/audio_preferences.gd").read_settings().muted,"original device preference saved muted")
 check(desk._collaborator_id=="cast_casey" and owner.snapshot()==start and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"mute preserves pending person and whole game/disk")
 await capture("sound-off-pending-person")
 await activate("MixingSound",true)
 check(not preload("res://experiments/playable_flightcase/audio_preferences.gd").read_settings().muted,"original preference restored")
 # Current local lead/partner swaps remain pending and never silently substitute.
 await activate("MixingLeaderNext");await activate("MixingLeaderNext")
 check(desk._target().is_empty(),"self-partner requires explicit choice")
 await activate("MixingCollaboratorNext")
 check(desk._target().leader_ref.candidate_id=="cast_casey" and desk._target().respondent_ref.candidate_id=="cast_jack","former lead can be pending idea partner")
 await capture("local-role-swap")
 await activate("MixingLeaderNext")
 check(desk._target().is_empty(),"reverse swap also requires explicit partner")
 await activate("MixingCollaboratorNext");await activate("MixingCollaboratorNext")
 check(desk._target().respondent_ref.candidate_id=="cast_casey","explicitly restore intended Casey choice")
 check(owner.snapshot()==start and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"pending pair swaps have no saved effects")
 # Native wheel down/up with releases and positive movement, no action callback.
 var scroll: ScrollContainer=named("MixingBodyScroll") as ScrollContainer
 scroll.scroll_vertical=0;await settle()
 var point: Vector2=root.get_final_transform()*(scroll.get_global_rect().position+Vector2(20,40))
 for _event in range(4):
  for down in [true,false]:
   var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=down;wheel.position=point;wheel.global_position=point;Input.parse_input_event(wheel);await process_frame
 await settle();var moved: int=scroll.scroll_vertical
 check(moved>0,"native real wheel scroll positive")
 for _event in range(4):
  for down in [true,false]:
   var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=down;wheel.position=point;wheel.global_position=point;Input.parse_input_event(wheel);await process_frame
 await settle();check(scroll.scroll_vertical<moved,"native wheel reversal")
 # Actual emulated screen touch selects the visible partner button once.
 var touch_button: Button=named("MixingCollaboratorNext") as Button
 await reveal(touch_button)
 var touch_point: Vector2=root.get_final_transform()*touch_button.get_global_transform_with_canvas()*(touch_button.size/2)
 for down in [true,false]:
  var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=touch_point;touch.pressed=down;Input.parse_input_event(touch);await process_frame
 await settle();check(desk._target().respondent_ref.candidate_id=="cast_zoe","native emulated touch changed actual choice")
 await activate("MixingCollaboratorNext")
 await reveal(named("MixingMemberName"));await capture("chosen-casey")
 if not await activate("MixingResponse_try",true):_finish_native();return
 if not await activate("MixingCollaboratorNext",true):_finish_native();return
 check(desk._decision.is_empty(),"changing person clears old response")
 if not await activate("MixingCollaboratorNext"):_finish_native();return
 # Dirty exit saves choice free; inject a real filesystem failure and retry.
 if not await activate("MixingBack"):_finish_native();return
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"free native save blocker")
 await activate("MixingExitSave")
 check(owner.snapshot()==start and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"free failure restores exact owner and disk")
 await capture("free-save-failure")
 check(DirAccess.remove_absolute(blocker)==OK,"remove free blocker")
 await activate("MixingExitSave",true)
 check(owner.workbench_view().project.target.respondent_ref.candidate_id=="cast_casey","native free-save selected canonical person")
 var game_before: Dictionary=start.game.duplicate(true);game_before.career.erase(Workbench.KEY)
 var game_after: Dictionary=owner.snapshot().game.duplicate(true);game_after.career.erase(Workbench.KEY)
 check(Workbench._exact(game_before,game_after),"free save no game/day/cash/Finance effects")
 var restored=Owner.new();check(restored.load_draft(),"native saved choice reload");owner=restored
 await _mount()
 for stage in range(3):
  check(_available(),"actual shared writing evening")
  desk.refresh_saved()
  if not await activate("MixingResponse_try" if stage==0 else "MixingResponse_keep",stage==1):_finish_native();return
  if stage==2:
   var before: Dictionary=owner.snapshot();var old_disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
   fail_next=true;await activate("MixingCommit");fail_next=false
   check(not last_native.get("ok",true),"native actual paid save failure")
   check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==old_disk,"native paid rollback exact")
   await capture("paid-save-failure")
  await activate("MixingCommit",stage==1)
  if not check(last_native.get("ok",false),"native paid commit succeeds"):_finish_native();return
  if stage<2:desk.refresh_saved()
  var loaded=Owner.new();check(loaded.load_draft() and loaded.snapshot()==owner.snapshot(),"full typed paid reload");owner=loaded
  if stage<2:await _mount()
 var song: Dictionary=owner.game.career.song_catalogue[-1]
 check(song[Workbench.FRAGMENT_KEY].co_writing_v1.retained.size()==1,"one adopted retained idea after full three days")
 if is_instance_valid(scene):scene.queue_free();await process_frame
 scene=load("res://experiments/playable_flightcase/ui.gd").new()
 scene.game=owner.game;scene.opening_owner=owner;scene.practice_activity="create";scene.recap_expanded=false
 scene._workbench_finished=true;scene._workbench_finished_ref=Workbench.finished(owner.snapshot()).items[0].reference
 root.add_child(scene)
 await settle()
 var caption: Label=named("SavedCoWriting") as Label
 check(caption!=null and caption.text.contains("Casey") and caption.text.contains("energy"),"saved actual person/field callback")
 if caption!=null:await reveal(caption);await capture("retained-idea-after-reload")
 await _finish_native()

func settle(count: int=5) -> void:
 for _i in range(count):
  if Time.get_ticks_msec()>deadline:
   check(false,"bounded native deadline");return
  await process_frame


func named(name: String, allow_hidden: bool=false) -> Control:
 if not is_instance_valid(scene):return null
 for raw in scene.find_children(name,"Control",true,false):
  var control: Control=raw
  if control.is_visible_in_tree():return control
  if allow_hidden and control.get_parent() is CanvasItem and control.get_parent().is_visible_in_tree():return control
 return null


func clipped_rect(control: Control) -> Rect2:
 var rect: Rect2=control.get_global_rect().intersection(control.get_viewport_rect())
 var parent: Node=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer or (parent is Control and parent.clip_contents):rect=rect.intersection(parent.get_global_rect())
  parent=parent.get_parent()
 return rect


func reveal(control: Control) -> bool:
 if not check(control!=null and control.is_visible_in_tree(),"visible native reveal target"):return false
 var parent: Node=control.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(control)
  parent=parent.get_parent()
 # Observe completed layout; never emit pressed/toggled signals to make a test pass.
 await settle()
 return check(clipped_rect(control).size.x>4 and clipped_rect(control).size.y>4,"reveal has a visible clipped area")


func activate(name: String, keyboard: bool=false) -> bool:
 var target: Button=named(name) as Button
 if not check(target!=null and not target.disabled,"real enabled target "+name):return false
 if not await reveal(target):return false
 var rect: Rect2=target.get_global_rect()
 if not check(clipped_rect(target).encloses(rect),"whole target inside actual clips "+name):return false
 var physical: Rect2=root.get_final_transform()*target.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,target.size)
 var revised_action: bool=name.begins_with("Recording") or name.begins_with("DemoTrackNotes") or name.begins_with("SongSummary_book_") or name.begins_with("SongSummary_record_")
 if revised_action:
  var target_ok: bool=physical.size.x>=44 and physical.size.y>=44
  trace.append({"action":name,"physical_width":physical.size.x,"physical_height":physical.size.y,"SONG56_minimum":44,"baseline":baseline})
  if baseline and not target_ok:
   baseline_defects.append("Original action %s measures %.2f x %.2f physical px; new SONG56 minimum is not a historical baseline pass." % [name,physical.size.x,physical.size.y])
  elif not baseline and not check(target_ok,"physical 44px revised action %s: %.2f x %.2f" % [name,physical.size.x,physical.size.y]):return false
 if keyboard:
  target.grab_focus()
  await process_frame
  if not check(root.gui_get_focus_owner()==target,"actual keyboard focus "+name):return false
  for down in [true,false]:
   var key:=InputEventKey.new();key.keycode=KEY_ENTER;key.physical_keycode=KEY_ENTER;key.pressed=down
   Input.parse_input_event(key);await process_frame
 else:
  var point: Vector2=root.get_final_transform()*target.get_global_transform_with_canvas()*(target.size/2)
  for down in [true,false]:
   var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.pressed=down;mouse.position=point;mouse.global_position=point
   Input.parse_input_event(mouse);await process_frame
 await settle()
 return true


func capture(label: String) -> bool:
 await settle()
 await RenderingServer.frame_post_draw
 var texture: Texture2D=root.get_texture()
 if not check(texture!=null,"rendered native viewport texture"):return false
 var pixels: Image=texture.get_image()
 if not check(pixels!=null and not pixels.is_empty(),"actual drawn pixels "+label):return false
 var path: String=output+"/"+label+".png"
 if not check(not FileAccess.file_exists(path),"preserve existing capture "+label):return false
 if not check(pixels.save_png(path)==OK,"write original capture "+label):return false
 images.append({"path":path,"width":pixels.get_width(),"height":pixels.get_height(),"state":label})
 return true

