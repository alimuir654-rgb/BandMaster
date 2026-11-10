extends "res://tests/next32_gig_visual.gd"
## Read-only actual paid version5 fixture; native saved gig events and real crowd.
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
var fixture_path: String=""
var fixture_bytes: PackedByteArray
var actual_cues: Array[String]=[]
func run() -> void:
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
func failure_action(button: String,label: String) -> void:
 var starts: int=scene._career_view._gig_audio.starts
 await super.failure_action(button,label)
 check(scene._career_view._gig_audio.starts==starts,"failed save emits no audio event "+label)
func act(node_name: String) -> bool:
 if not await super.act(node_name):return false
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
 print("CROWD40_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"actual_cues":actual_cues,"version5_main_app":true,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free();scene=null
 owner=null;await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
