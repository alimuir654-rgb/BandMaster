extends "res://tests/audio_creation_visual.gd"
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
const Live=preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance=preload("res://experiments/playable_flightcase/finance_policy.gd")
var normal_motion:=false

func reveal(button: Control) -> void:
 var parent: Node=button.get_parent()
 while parent!=null:
  if parent is ScrollContainer:parent.ensure_control_visible(button)
  parent=parent.get_parent()
 await settle()

func point_click(point: Vector2) -> void:
 for down in [true,false]:
  var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;event.global_position=point
  Input.parse_input_event(event);await process_frame
 await settle()

func tap(node_name: String) -> bool:
 var button: Button=scene.find_child(node_name,true,false) as Button
 if not check(button!=null and button.is_visible_in_tree() and not button.disabled,"native action available "+node_name):return false
 await reveal(button)
 var visible: bool=button.get_viewport_rect().encloses(button.get_global_rect())
 var parent: Node=button.get_parent()
 while parent!=null:
  if parent is ScrollContainer:visible=visible and parent.get_global_rect().encloses(button.get_global_rect())
  parent=parent.get_parent()
 if not check(visible,"actual target inside clips "+node_name):return false
 var point: Vector2=root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size/2)
 await point_click(point)
 return true

func audition(id: String,role_name: String,label: String) -> bool:
 await person(id,role_name)
 if not await tap("AuditionAction"):return false
 var desk: Control=scene.find_child("AuditionEncounter",true,false)
 check(desk.find_child("AuditionRoom",true,false)==null,"musician/instrument leads without competing room "+id)
 check(desk.find_child("AuditionPortrait",true,false).texture!=null,"real approved portrait "+id)
 await capture("audition-"+label+"-first")
 if normal_motion and desk._voice.is_revealing():
  var snapshot: Dictionary=owner.snapshot()
  await tap("AuditionTalk_working_style_shared")
  check(owner.snapshot()==snapshot,"first revealing click cannot answer")
 var first_button: Button=scene.find_child("AuditionTalk_working_style_shared",true,false)
 await reveal(first_button)
 var prior_point: Vector2=root.get_final_transform()*first_button.get_global_transform_with_canvas()*(first_button.size/2)
 if not await tap("AuditionTalk_working_style_shared"):return false
 var answered: Dictionary=owner.snapshot()
 await point_click(prior_point)
 check(owner.snapshot()==answered,"repeated same-coordinate question click cannot answer another question")
 if not await tap("AuditionTalk_commitment_dates"):return false
 check(owner.audition_view().conversation.answers.size()==2,"two real saved questions "+id)
 await reveal(desk.find_child("AuditionConversation",true,false))
 await capture("audition-"+label+"-questions")
 if not await tap("AuditionPlayFirst"):return false
 desk=scene.find_child("AuditionEncounter",true,false)
 check(desk._audio.playing,"original sample actual player "+id)
 desk._audio.stop()
 if not await tap("AuditionRequestSpace"):return false
 desk=scene.find_child("AuditionEncounter",true,false)
 if normal_motion:desk._voice.finish_now()
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 await tap("AuditionPlayAdjusted")
 check(desk._audio.playing and desk._audio._material.contains("space_for_voice"),"genuinely registered adjusted sample "+id)
 await tap("AuditionPlayFirst")
 check(desk._audio.playing and desk._audio._material.contains("original"),"explicit first/adjusted comparison "+id)
 await tap("AuditionStopTakes")
 check(not desk._audio.playing and owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"replay remains free/no rapport farm "+id)
 await reveal(desk.find_child("AuditionPlayFirst",true,false))
 await capture("audition-"+label+"-response")
 return await tap("AuditionInvite")

func ready_evening() -> bool:
 for _day in range(7):
  var view: Dictionary=Situation.inspect_rehearsal(owner.game.career)
  if view.ok and not view.conflict:return true
  var before: Dictionary=owner.game.career.duplicate(true)
  var jam: Dictionary=owner.game.informal_practice(view.attendee_indices)
  if not check(jam.ok,"canonical availability day"):return false
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not check(tracked.ok,"canonical situation day accounting"):return false
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
  if not check(accounted.ok,"canonical finance once"):return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return false

func edge_audio() -> void:
 await person("cast_arjun","Guitarist")
 if not await tap("AuditionAction"):return
 await tap("AuditionPlayFirst")
 var desk: Control=scene.find_child("AuditionEncounter",true,false)
 check(desk._audio.playing,"Arjun original supported sample plays")
 await tap("AuditionRequestOwn")
 desk=scene.find_child("AuditionEncounter",true,false)
 check(desk.find_child("AuditionPlayAdjusted",true,false).disabled,"Arjun alternate honestly written-only")
 await tap("AuditionPlayFirst");check(desk._audio.playing,"Arjun original remains available after request")
 await tap("AuditionReadPart");await reveal(desk.find_child("AuditionWrittenParts",true,false));await capture("arjun-written-fallback")
 await tap("AuditionAbort")
 scene.free();scene=null;owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Punk") and owner.to_recruit() and owner.begin_audition("cast_jack","Guitarist",true).ok,"supported written encounter in other style")
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true;root.add_child(scene);await settle()
 desk=scene.find_child("AuditionEncounter",true,false)
 check(desk.find_child("AuditionPlayFirst",true,false).disabled,"unsupported style cannot imply available audio")
 await reveal(desk.find_child("AuditionPlayFirst",true,false));await capture("other-style-written-fallback")

func run() -> void:
 normal_motion="--normal-motion" in OS.get_cmdline_user_args()
 owner=Owner.new()
 if not check(not output.is_empty() and owner.begin_new(),"isolated real formation"):finish_new();return
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate();scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=not normal_motion;root.add_child(scene);await settle()
 await tap("Genre_Indie_rock");await tap("GenreNextAction")
 if "--edge-audio" in OS.get_cmdline_user_args():
  await edge_audio();finish_new();return
 for candidate in [["cast_jack","Guitarist","guitar"],["cast_zoe","Bassist","bass"],["cast_marcus","Drummer","drums"]]:
  if not await audition(candidate[0],candidate[1],candidate[2]):finish_new();return
 var voices: OptionButton=scene.find_child("RecruitLeadVoice",true,false)
 for index in range(voices.item_count):
  if voices.get_item_metadata(index)=="cast_jack":voices.select(index);voices.item_selected.emit(index);break
 await settle();await tap("ReviewLineupAction");await tap("StartAction")
 var field: LineEdit=scene.find_child("FreeBandName",true,false);field.text="NIGHT BUS CLUB";field.text_changed.emit(field.text)
 await tap("NameSubmitAction");await tap("NameLockAction");await tap("IdentityFinishAction");await capture("band-formed")
 if not await tap("StartPlayAction"):finish_new();return
 check(owner.game.career[Connections.KEY].records.size()==3,"all3 actual invited conversations reach actual band")
 if not ready_evening():finish_new();return
 scene._return_from_career("tighten");await settle()
 var practice: Control=scene._practice_view
 await capture("practice-entry")
 var saved: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 await tap("RehearsalIntent_focus_listening");await tap("RehearsalIntent_effort_push")
 check(practice.rehearsal_direction=={"focus":"listening","effort":"push"} and owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"practice choices are free local preview")
 await reveal(scene.find_child("RehearsalIntent_focus_listening",true,false))
 await capture("practice-selected")
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"real isolated rehearsal save failure")
 await tap("RehearseAction")
 check(owner.snapshot()==saved and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole rehearsal/connections/finance rollback")
 check(practice.rehearsal_direction.effort=="push","failed save keeps local practice choices")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only harness failure blocker")
 await capture("practice-save-error")
 var action: Button=scene.find_child("RehearseAction",true,false)
 action.pressed.emit();var after: Dictionary=owner.snapshot()
 practice._rehearse()
 check(owner.snapshot()==after,"rapid duplicate practice cannot settle twice")
 await create_timer(0.5).timeout
 if is_instance_valid(practice._session_overlay):practice._session_overlay.finish_now()
 await settle();await capture("practice-saved")
 check(owner.game.career.cash==saved.game.career.cash-15 and owner.game.career.tour_day==saved.game.career.tour_day+1,"one real fee and day")
 check(owner.game.career.last_rehearsal_outcome.direction.focus=="listening","saved report has actual selected direction")
 await tap("RecapDetailsToggleAction");await capture("practice-full-notes")
 check(owner.game.career.last_rehearsal_outcome.reason.contains("audition"),"complete saved notes explain audition carry-through")
 var reloaded=Owner.new();check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"actual full new flow strict reload")
 finish_new()

func finish_new() -> void:
 print("CHARACTER_CONSEQUENCE_VISUAL "+JSON.stringify({"viewport":str(root.size),"normal_motion":normal_motion,"checks":checks,"failures":failures,"actual_entry":"opening.tscn","physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null
 var stopped: int=Time.get_ticks_usec()
 while Time.get_ticks_usec()-stopped<100000:await process_frame
 call_deferred("quit",0 if failures.is_empty() else 1)
