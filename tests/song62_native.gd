extends "res://tests/song57_craft_fairness.gd"
const Preparation=preload("res://experiments/playable_flightcase/song_preparation.gd")
var scene
var output := ""
var baseline := false
var images: Array=[]
var trace: Array=[]
var baseline_defects: Array[String]=[]
var deadline := 0
class CountedOwner extends Owner:
 var saves: int=0
 func _save_draft_owned() -> bool:
  saves+=1
  return super._save_draft_owned()
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--work-root="):work_root=arg.trim_prefix("--work-root=")
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
  if arg=="--baseline":baseline=true
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 deadline=Time.get_ticks_msec()+140000
 call_deferred("_run_native")
func check(ok: bool,message: String) -> bool:return _check(ok,message)
func _finish_native() -> void:
 print("SONG62_NATIVE "+JSON.stringify({"ok":failure_count==0,"checks":checks,"failures":failures,"images":images,"trace":trace,"actual_writing_settlements":owner_transactions,"baseline":baseline}))
 if is_instance_valid(scene):scene.queue_free()
 await process_frame
 quit(0 if failure_count==0 else 1)
func _mount(recap: bool=false) -> void:
 if is_instance_valid(scene):scene.queue_free();await process_frame
 scene=load("res://experiments/playable_flightcase/ui.gd").new()
 scene.game=owner.game;scene.opening_owner=owner;scene.practice_activity="tighten";scene.recap_expanded=recap;scene.reduced_motion=true
 root.add_child(scene);scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 await settle(10)
func _two_songs() -> bool:
 var originals: Array=_integration(false)
 if not check(originals.size()==2,"real completed original fixtures"):return false
 owner=CountedOwner.new()
 if not check(owner.restore(originals[-1]) and _available(),"actual available original career"):return false
 var recipe: Dictionary=Producer.recipe(0)
 var title: String="THE LAST TRAIN — ÉCHO APRÈS LA PLUIE"
 if not check(owner.begin_workbench(title,0,owner.workbench_expected(),recipe).ok,"second actual song begins"):return false
 for stage in range(3):
  if not check(_available(),"second song actual shared evening"):return false
  recipe.stage=stage
  if not check(owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":recipe,"title":title,"leader_index":0}).ok,"second actual musical direction"):return false
  var project: Dictionary=owner.workbench_view().project
  var offer: Dictionary=Producer.offer(project.fragment.producer_recipe,project.target.respondent_ref)
  if not check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok and _paid().ok,"actual second paid writing stage"):return false
 return check(_available() and Workbench.finished(owner.snapshot()).items.size()==2,"two canonical songs and actual availability")
func _run_native() -> void:
 if not check(work_root.is_absolute_path() and ProjectSettings.globalize_path(Owner.SAVE_PATH).begins_with(work_root+"/"),"private owner save root"):_finish_native();return
 if not _two_songs():_finish_native();return
 await _mount()
 if baseline:
  await capture("baseline-rehearsal")
  await _finish_native();return
 await _candidate()
 await _finish_native()
func _candidate() -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);var saves: int=owner.saves
 check(scene.rehearsal_reference.is_empty(),"general rehearsal explicit default")
 await capture("general-rehearsal")
 if not await activate("RehearsalSongNext",true):return
 check(root.gui_get_focus_owner()==named("RehearsalSongNext"),"selector retains actual keyboard focus after rebuild")
 # Space on the restored target, no grab_focus/re-tab between consecutive activations.
 for down in [true,false]:
  var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.physical_keycode=KEY_SPACE;key.pressed=down;Input.parse_input_event(key);await process_frame
 await settle(8)
 var choices: Array=Workbench.finished(owner.snapshot()).items
 var selected: Dictionary=choices[-1].reference.duplicate(true)
 check(Workbench._same(scene.rehearsal_reference,selected),"consecutive Enter/Space selects second actual original")
 check(scene._rehearsal_audio_song().id==selected.song_id,"preview uses chosen song rather than first catalogue item")
 check((named("RehearsalSongTitle") as Label).text.contains("ÉCHO"),"long Unicode song title present")
 await reveal(named("RehearsalSongTitle"));await capture("selected-long-title")
 if not await activate("RehearsalIntent_focus_listening",true):return
 if not await activate("RehearsalIntent_effort_push"):return
 check(scene.rehearsal_direction=={"focus":"listening","effort":"push"},"existing purpose and pace chosen")
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and owner.saves==saves,"free selection/purpose do not save or settle")
 await _scroll_proof()
 # Actual emulated touch selection, then restore second song with pointer.
 var button: Button=named("RehearsalSongPrevious") as Button
 if not await reveal(button):return
 var point: Vector2=root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size/2)
 for down in [true,false]:
  var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=down;Input.parse_input_event(touch);await process_frame
 await settle(8)
 check(scene.rehearsal_reference.song_id==choices[0].reference.song_id,"native emulated touch selects first actual song")
 if not await activate("RehearsalSongNext"):return
 # Explicit stale local-reference fixture; no career/stat changes.
 scene.rehearsal_reference.fragment_sha256="stale-fixture";scene._rebuild();await settle(8)
 if not await activate("RehearseAction"):return
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and owner.saves==saves,"stale arrangement refuses with no fallback/write/day")
 check(scene.rehearsal_reference.fragment_sha256=="stale-fixture","stale selection remains explicit")
 await reveal(named("RehearsalSongTitle"));await capture("stale-arrangement-held")
 if not await activate("RehearsalSongNext"):return
 if not await activate("RehearsalSongNext"):return
 check(Workbench._same(scene.rehearsal_reference,selected),"explicitly reselect valid second arrangement")
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"real paid save blocker")
 if not await activate("RehearseAction"):return
 check(Workbench._exact(owner.snapshot(),before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"real productionRootUI failed-save whole-owner/disk rollback")
 check(owner.saves==saves+1 and Workbench._same(scene.rehearsal_reference,selected) and scene.rehearsal_direction=={"focus":"listening","effort":"push"},"one attempted save and pending selection/purpose preserved")
 await reveal(named("RehearsalSongTitle"));await capture("failed-save-selection-retained")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated paid blocker")
 if not await activate("RehearseAction",true):return
 await _idle()
 var saved: Dictionary=owner.snapshot()
 check(saved.game.career.cash==before.game.career.cash-15 and saved.game.career.tour_day==before.game.career.tour_day+1 and saved.game.career.action_count==before.game.career.action_count+1,"productionselectedUI cost/day/action exactlyonce")
 check(owner.saves==saves+2,"exactly one failed attempt plus one successful original private-save call; no duplicate UI Finance/save")
 var ledger: Dictionary=owner.game.career[Preparation.KEY]
 check(ledger.receipts.size()==1 and ledger.receipts[0].song_id==selected.song_id and ledger.receipts[0].participants.size()==3,"actual selected revision/three people recorded")
 var label: Label=named("RehearsalSavedSong") as Label
 check(label!=null and label.text.contains("ÉCHO") and label.text.contains("Casey"),"recap joins actual saved song/action/people")
 if label!=null:await reveal(label);await capture("saved-song-rehearsal")
 scene._load_original();await settle(8)
 check(Workbench._exact(owner.snapshot(),saved),"real RootUI load handler typedreload entireowner")
 label=named("RehearsalSavedSong") as Label
 check(label!=null and label.text.contains("ÉCHO"),"reopened recap derives saved ledger context")
 # Local next selection cannot rewrite the displayed result.
 scene.rehearsal_reference=choices[0].reference.duplicate(true);scene._rebuild();await settle(8)
 check((named("RehearsalSavedSong") as Label).text.contains("ÉCHO"),"saved recap ignores current local next-song selection")
 await reveal(named("RehearsalSavedSong"));await capture("typed-reload-recap")
 # Explicit malformed-version guard fixture, restored in memory without writing.
 var actual_career: Dictionary=owner.game.career.duplicate(true)
 owner.game.career.song_catalogue[-1][Workbench.FRAGMENT_KEY].composition_identity_v1.revision_id+="changed"
 check(scene._rehearsal_saved_context(owner.game.career.last_rehearsal_outcome).contains("Previously saved arrangement"),"changed/invalid current version never lends title to old receipt")
 owner.game.career=actual_career
 # Advance actual Saturday/Sunday/Monday via original free informal-practice owners.
 for _day in range(3):
  if not _jam_day():return
 check(int(owner.game.career.tour_day)==16,"actual next Tuesday reached without date/stat edits")
 await _mount()
 if not await activate("RehearsalSongNext"):return
 var partial_before: Dictionary=owner.snapshot();disk=FileAccess.get_file_as_bytes(Owner.SAVE_PATH);saves=owner.saves
 if not await activate("RehearseAction"):return
 check(named("WorkConflictProceedAction")!=null,"original partial-attendance dialog opens")
 await capture("partial-attendance-review")
 if not await activate("WorkConflictBackAction",true):return
 check(Workbench._exact(owner.snapshot(),partial_before) and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk and owner.saves==saves,"cancel original conflict no paid effects")
 check(scene.rehearsal_reference.song_id==choices[0].reference.song_id,"cancel retains chosen first song")
 if not await activate("RehearseAction"):return
 if not await activate("WorkConflictProceedAction",true):return
 await _idle()
 check(owner.saves==saves+1 and owner.game.career.cash==partial_before.game.career.cash-15 and owner.game.career.action_count==partial_before.game.career.action_count+1,"original partial dialog delegates one selected-owner settlement")
 var second: Dictionary=owner.game.career[Preparation.KEY].receipts[-1]
 check(second.song_id==choices[0].reference.song_id and second.participants==["cast_zoe","cast_casey"],"actual Tuesday excludes unavailable Jack from chosen first song")
 var first_identity: Dictionary=Preparation.target(owner.snapshot(),choices[0].reference).identity
 check(not Preparation.evidence(owner.game.career,first_identity,"cast_jack").known,"absent member receives no first-song preparation")
 await reveal(named("RehearsalSavedSong"));await capture("partial-saved-song-rehearsal")
 # General route remains original, explicitly adds no song-specific record.
 await _mount()
 var count: int=owner.game.career[Preparation.KEY].receipts.size();var ordinary: Dictionary=owner.snapshot();saves=owner.saves
 if not await activate("RehearseAction"):return
 await _idle()
 check(owner.saves==saves+1 and owner.game.career[Preparation.KEY].receipts.size()==count and owner.game.career.cash==ordinary.game.career.cash-15,"explicit general rehearsal retains original single settlement with no fabricated song evidence")
 check(named("RehearsalSavedSong")==null,"ordinary result does not borrow earlier selected-song context")
 await capture("ordinary-rehearsal-result")

func _idle() -> void:
 var until: int=Time.get_ticks_msec()+6000
 while scene.session_busy and Time.get_ticks_msec()<until:await process_frame
 check(not scene.session_busy,"bounded original presentation finishes")
 await settle(8)
func _jam_day() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var attendance: Dictionary=Situation.inspect_rehearsal(before)
 if not check(attendance.ok and owner.game.informal_practice(attendance.attendee_indices).ok,"actual original free jam advances day"):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not check(tracked.ok,"original jam situation"):return false
 owner.game.career=Live.after_practice(before,tracked.state)
 var accounted: Dictionary=Finance.apply(before,owner.game.career,"practice:jam")
 if not check(accounted.ok,"original jam finance"):return false
 owner.game.career=accounted.state
 return check(owner.save_draft(),"original jam owner save")
func _scroll_proof() -> void:
 var scroll: ScrollContainer=named("PracticeScroll") as ScrollContainer
 if not check(scroll!=null,"real practice body scroll"):return
 var starting: int=scroll.scroll_vertical
 var point: Vector2=root.get_final_transform()*(scroll.get_global_rect().position+Vector2(20,scroll.size.y/2))
 for _step in range(5):
  for down in [true,false]:
   var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.pressed=down;wheel.position=point;wheel.global_position=point;Input.parse_input_event(wheel);await process_frame
 await settle(8)
 check(scroll.scroll_vertical>starting,"native wheel moves actual body down")
 var low: int=scroll.scroll_vertical
 for _step in range(5):
  for down in [true,false]:
   var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=down;wheel.position=point;wheel.global_position=point;Input.parse_input_event(wheel);await process_frame
 await settle(8)
 check(scroll.scroll_vertical<low,"native wheel returns actual body up")

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
 var revised_action: bool=name.begins_with("RehearsalSong") or name=="RehearseAction" or name.begins_with("Recording") or name.begins_with("DemoTrackNotes") or name.begins_with("SongSummary_book_") or name.begins_with("SongSummary_record_")
 if revised_action:
  var minimum: int=48 if name.begins_with("RehearsalSong") or name=="RehearseAction" else 44
  var target_ok: bool=physical.size.x>=minimum and physical.size.y>=minimum
  trace.append({"action":name,"physical_width":physical.size.x,"physical_height":physical.size.y,"required_minimum":minimum,"baseline":baseline})
  if baseline and not target_ok:
   baseline_defects.append("Original action %s measures %.2f x %.2f physical px; new SONG56 minimum is not a historical baseline pass." % [name,physical.size.x,physical.size.y])
  elif not baseline and not check(target_ok,"physical minimum revised action %s: %.2f x %.2f" % [name,physical.size.x,physical.size.y]):return false
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

