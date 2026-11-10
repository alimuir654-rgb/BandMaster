extends SceneTree
## External harness: all preloads resolve against the actual exported APK payload ZIP.
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Recipe=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const Bank=preload("res://experiments/playable_flightcase/recorded_steady.gd")
const New=preload("res://experiments/playable_flightcase/recorded_vocal_keys.gd")
const Sound=preload("res://experiments/playable_flightcase/band_sound.gd")
const Rules=preload("res://experiments/playable_flightcase/song_workbench.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
const Live=preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance=preload("res://experiments/playable_flightcase/finance_policy.gd")
const Audio=preload("res://experiments/playable_flightcase/mixing_audio.gd")
const Song=preload("res://experiments/playable_flightcase/song_audio.gd")
var owner
var checks:=0
var failures: Array=[]
var selected: Dictionary={}
var allowed:=true
var packaged:=false
var scene
var output: String=""
var fixture_path: String=""
var fixture_bytes: PackedByteArray
var actual_cues: Array[String]=[]
var primary_taps:=0
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Incident=preload("res://experiments/playable_flightcase/gig_incident.gd")
func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 call_deferred("run")
func check(ok: bool,message: String) -> bool:
 checks+=1
 if not ok:failures.append(message);push_error(message)
 return ok

func settle() -> void:
 for _i in range(3):await process_frame

func capture(label: String) -> void:
 for _i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(output+"-"+label+".png")==OK,"native capture "+label)

func mount() -> void:
 if is_instance_valid(scene):scene.free()
 scene=load("res://experiments/playable_flightcase/opening.tscn").instantiate()
 scene.setup=owner;scene.showing_menu=false;scene.reduced_motion=true
 root.add_child(scene);await settle()

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

func advance_day() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var available: Dictionary=Situation.inspect_rehearsal(before)
 if not available.get("ok",false):return false
 var jam: Dictionary=owner.game.informal_practice(available.attendee_indices)
 if not jam.get("ok",false):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not tracked.get("ok",false):return false
 var result: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
 if not result.get("ok",false):return false
 owner.game.career=result.state
 return owner.save_draft()

func failure_action(button: String,label: String) -> void:
 var starts: int=scene._career_view._gig_audio.starts
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"isolated native failure "+label)
 await tap(button)
 check(owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole native memory/disk rollback "+label)
 await capture(label+"-save-error")
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated blocker "+label)

 check(scene._career_view._gig_audio.starts==starts,"failed save emits no audio")
func run() -> void:
 packaged=FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot")
 if not check(packaged,"actual exported binary native payload"):await finish_next_gig();return
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--fixture="):fixture_path=argument.trim_prefix("--fixture=")
 owner=Owner.new()
 if not check(not fixture_path.is_empty() and FileAccess.file_exists(fixture_path),"explicit actual paid version5 fixture"):await finish_next_gig();return
 fixture_bytes=FileAccess.get_file_as_bytes(fixture_path)
 var raw: Variant=JSON.parse_string(fixture_bytes.get_string_from_utf8())
 raw=owner.game._restore_integral_numbers(raw)
 if not check(raw is Dictionary and owner.restore(raw),"restore original saved song without rewriting input"):await finish_next_gig();return
 var songs: Array=owner.game.career.song_catalogue
 if not check(songs.size()==1 and Crowd.Song.recipe(songs[0]).get("version")==5,"actual finished Maya/Freya vocal source"):await finish_next_gig();return
 if not check(owner.save_draft(),"copy into isolated test user only"):await finish_next_gig();return
 await mount()
 scene._open_career_desk();await settle()
 if not await tap("PosterNav_gigs") or not await tap("BookingVenue_local") or not await tap("BookingPitch_fit") or not await tap("BookingOffer_standard"):finish_next_gig();return
 await capture("promoter-agreement")
 if not await tap("BookingCommitAction") or not await tap("BookingConfirmAction"):finish_next_gig();return
 for _day in range(3):check(await advance_day(),"real booked-night approach")
 scene._open_career_desk("gigs");await settle()
 primary_taps=0
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="soundcheck" and Incident.pending(Journey.active(owner.game.career)),"one action reaches saved promoter situation")
 check(scene.find_child("JourneyMainAction",true,false)==null,"no planner commitment shown behind unanswered situation")
 for id in ["GigAnswer_check","GigAnswer_go"]:
  var b: Control=scene.find_child(id,true,false)
  if not check(b!=null and not b.disabled and root.get_visible_rect().encloses(b.get_global_rect()),"actual choice enabled and visible without scrolling "+id):finish_next_gig();return
 await capture("soundcheck-situation")
 var before: Dictionary=owner.snapshot();var old_token: Dictionary=Journey.expected(owner.game.career);var old_generation: int=int(scene._career_view._render_generation)
 await failure_action("GigAnswer_check","saved promoter answer")
 check(owner.snapshot()==before,"failed answer retained whole owner")
 var error_label: Label=scene.find_child("JourneySaveNotice",true,false)
 check(error_label!=null and error_label.is_visible_in_tree() and error_label.text.contains("could not be saved"),"actual failed answer shows retry feedback")
 if not await act("GigAnswer_check"):finish_next_gig();return
 check(not Incident.pending(Journey.active(owner.game.career)),"choice saved in actual dispatcher")
 var answered: Dictionary=owner.snapshot()
 scene._career_view._commit_journey("soundcheck_answer",old_token,{"choice":"go"},old_generation);await settle()
 check(owner.snapshot()==answered,"stale original choice cannot replace answer")
 await capture("soundcheck-plan")
 scene._home();await settle();scene._continue();await settle();scene._open_career_desk("gigs");await settle()
 check(owner.snapshot()==answered and Journey.validate(owner.game.career).ok,"Menu/resume retains exact situation and result")
 await failure_action("JourneyMainAction","soundcheck frozen context")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="backstage","saved plan leaves original backstage decision")
 await capture("backstage-advice")
 await tap("SceneAdviceOwn")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="performing","no entrance Next screen")
 await capture("on-stage")
 if not await act("JourneyFinishSongAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="after_set","one original reaches aftermath")
 await capture("after-set")
 await tap("SceneHelp_northbound_static")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="wrap_ready","packing and lift carried through together")
 await capture("settlement")
 await failure_action("JourneyWrapAction","final once-only show settlement")
 if not await act("JourneyWrapAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).is_empty() and not Flow.last_receipt(owner.game.career).is_empty(),"one real original show receipt")
 var receipt: Dictionary=Flow.last_receipt(owner.game.career)
 check(receipt.journey_v1[Incident.KEY].choice=="check","whole-night receipt remembers promoter answer")
 var durable=Owner.new();check(durable.load_draft() and durable.snapshot()==owner.snapshot(),"whole recruitment-to-first-gig strict disk reload")
 check(primary_taps==7,"7 primary journey actions including new situation, previously9 connective path")
 await capture("night-result")
 finish_next_gig()
func act(node_name: String) -> bool:
 primary_taps+=1
 if not await tap(node_name):return false
 await settle()
 var audio=scene._career_view._gig_audio
 var visit: Dictionary=Journey.active(owner.game.career)
 if visit.get("phase")=="performing":
  check(audio._music.playing and audio._music._recorded_player.stream.stream_count==5,"real main-app five-part vocal arrangement plays on stage")
  check(audio._recipe==Crowd.Song.recipe(visit.plan.song_snapshots[visit.cursor]),"gig pins exact saved voice/keys recipe")
  check(audio.effect_available and audio._crowd.playing and audio.event_kind=="entrance","real approved entrance crowd overlaps saved song")
  actual_cues.append(audio.event_kind)
  var stable: Dictionary=owner.snapshot();var starts: int=audio.starts
  var original_stream=audio._music._recorded_player.stream
  scene._career_view._render();await settle()
  check(audio._music.playing and audio._music._recorded_player.stream==original_stream and audio.starts==starts,"free redraw retains same combined playback")
  await capture("combined-vocal-crowd-playing")
  owner.game.career[Journey.KEY].active.source_hash="invalid-current-source"
  scene._career_view._render();await create_timer(0.15).timeout
  check(not scene._career_view._gig_presentation_valid and not audio.playing(),"held source stops both real players")
  owner.game.career=stable.game.career.duplicate(true);scene._career_view._render();await settle()
  check(not audio.playing() and audio.starts==starts,"restored source cannot replay spent presentation")
  scene._home();await settle();scene._continue();await settle();scene._open_career_desk("gigs");await settle()
  check(not scene._career_view._gig_audio.playing(),"Menu Continue does not replay stage audio")
 if visit.get("phase")=="after_set":
  check(audio.event_kind=="courtesy" and audio.effect_available and audio._crowd.playing,"actual after-set uses approved courtesy recording")
  actual_cues.append(audio.event_kind)
 if node_name=="JourneyWrapAction":
  var receipt: Dictionary=Flow.last_receipt(owner.game.career)
  check(audio.event_kind==("cheer" if receipt.success else "boo"),"final cue follows saved original verdict")
  check(audio.effect_available==receipt.success,"approved cheer plays for success; rejected boo stays silent")
  actual_cues.append(audio.event_kind)
 return true
func finish_next_gig() -> void:
 if not fixture_path.is_empty():check(FileAccess.get_file_as_bytes(fixture_path)==fixture_bytes,"original paid-song fixture bytes unchanged")
 if is_instance_valid(scene) and failures.is_empty():
  var stable: Dictionary=owner.snapshot()
  scene._home();await settle();await capture("v24-menu")
  if await tap("SettingsAction"):
   var sheet=scene._settings_sheet
   var identity: Label=sheet.find_child("SettingsBuildIdentity",true,false)
   check(identity!=null and identity.text.contains("V24"),"compiled Settings identifies V24")
   await capture("v24-settings")
   var credits: Label=sheet.find_child("SettingsCrowdCredits",true,false)
   check(credits!=null and credits.text.contains("sandyrb") and credits.text.contains("creativecommons.org/licenses/by/4.0/"),"actual packaged CC BY credit")
   sheet._options_scroll.scroll_vertical=int(sheet._options_scroll.get_v_scroll_bar().max_value)
   await settle();await capture("v24-crowd-credits")
   check(owner.snapshot()==stable,"native settings inspection preserves saved band")
 print("BUILD43_COMPILED_NATIVE "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"actual_cues":actual_cues,"compiled_payload":packaged,"version5_main_app":true,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null;await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
