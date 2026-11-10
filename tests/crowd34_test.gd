extends SceneTree
const Owner=preload("res://experiments/playable_flightcase/opening_state.gd")
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Fixture=preload("res://tests/crowd34_audio_fixture.gd")
var failures: Array=[]
var checks:=0
var fixture_path: String=""
func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--fixture="):fixture_path=arg.trim_prefix("--fixture=")
 call_deferred("run")
func check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:failures.append(label);push_error(label)
 return ok
func visit(phase: String,cursor: int,songs: Array) -> Dictionary:
 return {Journey.KEY:{"version":2,"sequence":1,"active":{"id":"QA-saved-journey","phase":phase,"cursor":cursor,"plan":{"song_snapshots":songs},"feedback":[]}}}
func settle() -> void:
 for _frame in range(4):await process_frame
func run() -> void:
 if not check(FileAccess.file_exists(fixture_path),"explicit prior actual recorded-song QA save"):await done();return
 var owner=Owner.new();var original: PackedByteArray=FileAccess.get_file_as_bytes(fixture_path)
 var raw: Variant=JSON.parse_string(original.get_string_from_utf8());raw=owner.game._restore_integral_numbers(raw)
 if not check(raw is Dictionary and owner.restore(raw),"actual original paid song/first-show snapshot accepted"):await done();return
 var stable: Dictionary=owner.snapshot();var career: Dictionary=owner.game.career
 var songs: Array=career.song_catalogue
 if not check(songs.size()==1 and not Crowd.Song.recipe(songs[0]).is_empty(),"real supported finished frozen arrangement"):await done();return
 var backstage: Dictionary=visit("backstage",0,songs);var performing: Dictionary=visit("performing",0,songs)
 var entry: Dictionary=Crowd.saved_event(backstage,performing,"take_stage")
 check(entry.kind=="entrance" and entry.recipe==Crowd.Song.recipe(songs[0]),"entry pins actual saved song, not generic music")
 var multi: Array=[songs[0].duplicate(true),songs[0].duplicate(true),songs[0].duplicate(true)]
 multi[1].id="qa-second";multi[2].id="qa-third"
 # Event identities are tested independently; no invented song is launched.
 var second: Dictionary=visit("performing",1,multi);var third: Dictionary=visit("performing",2,multi)
 var changed: Dictionary=Crowd.saved_event(second,third,"finish_song")
 check(changed.kind=="song" and changed.id!=Crowd.identity(Journey.active(second)),"same-phase cursor advancement emits next-song event")
 check(Crowd.saved_event(performing,performing,"redraw").is_empty(),"redraw has no event")
 check(Crowd.live({"feedback":[]})=="watching" and Crowd.live({"feedback":[{"vibe":40}]})=="watching","normal initial40 is not poor-show rejection")
 check(Crowd.live({"feedback":[{"vibe":43}]})=="enjoying" and Crowd.live({"feedback":[{"vibe":37}]})=="restless","room follows saved change without predicting final verdict")
 check(Crowd.live({"cursor":1,"feedback":[{"vibe":41}],"vibe":43})=="enjoying","liveintent uses actual saved room after intent effect")
 check(Crowd.finale({"success":true})=="enjoying" and Crowd.finale({"success":false})=="displeased" and Crowd.finale({"success":"false"})=="watching","finale requires typed actual outcome")
 var after_set: Dictionary=visit("after_set",1,songs)
 check(Crowd.saved_event(performing,after_set,"finish_song").kind=="courtesy","pre-wrap final-note tail is not final boos")
 var before_wrap: Dictionary=career.duplicate(true);before_wrap.erase(Flow.RECORDS_KEY)
 var final_event: Dictionary=Crowd.saved_event(before_wrap,career,"wrap")
 check(final_event.kind==("cheer" if Flow.last_receipt(career).success else "boo"),"final cue uses newly recorded original result")
 for variant in Crowd.CAPTIONS:
  var texture: Texture2D=Crowd.texture(variant)
  check(texture!=null and texture.get_size()==Vector2(768,512),"actual atlas cell "+variant)
 var context: Dictionary={"allowed":true,"identity":entry.id,"source_token":"validated-fixture-source"}
 var audio=Fixture.new();audio.configure(func():return context);root.add_child(audio)
 AudioServer.set_bus_mute(0,false)
 audio.on_saved(backstage,performing,"take_stage");await settle()
 check(audio._music.playing and audio._music._recorded_player.stream is AudioStreamSynchronized,"actual current recorded parts share one clock during gig")
 check(not audio.effect_available and not audio._crowd.playing,"missing real crowd files never claim crowd playback")
 var starts: int=audio.starts
 audio.on_saved(backstage,performing,"take_stage");await settle();check(audio.starts==starts,"identical saved event cannot replay")
 # Harmless redraw preserves current music and stream identity.
 var stream=audio._music._recorded_player.stream
 audio.on_saved(performing,performing,"redraw");await settle()
 check(audio._music.playing and audio._music._recorded_player.stream==stream,"free redraw neither stops nor restarts music")
 AudioServer.set_bus_mute(0,true);await create_timer(0.12).timeout
 check(not audio.playing(),"master mute stops current presentation")
 AudioServer.set_bus_mute(0,false);await settle();check(not audio.playing() and audio.starts==starts,"unmute does not replay spent event")
 context.identity=changed.id;audio.on_saved(second,third,"finish_song");await settle();check(audio.starts==starts+1,"new cursor remains a new event after prior stop")
 context.source_token="changed-source";await create_timer(0.12).timeout;check(not audio.playing(),"samecursor changed source token stops cached playback")
 context.allowed=false;await create_timer(0.12).timeout;check(not audio.playing(),"hidden/menu/modal context stops")
 context.allowed=true;await settle();check(not audio.playing(),"returning context never automatically resumes")
 audio.free();await settle();stream=null
 # Separate synthetic silent test stream proves fade/stop mechanics, not crowd quality.
 var fx=Fixture.new();fx.use_synthetic_effect=true;context.identity=final_event.id
 fx.configure(func():return context);root.add_child(fx)
 fx.on_saved(before_wrap,career,"wrap");await settle()
 check(fx._crowd.playing and fx.effect_available and fx._fade!=null,"test-only effect has bounded fade lifecycle")
 fx._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);check(not fx.playing() and fx._crowd.stream==null,"focus loss releases effect immediately")
 fx.free();await settle()
 var queued=Fixture.new();queued.use_synthetic_effect=true;queued.configure(func():return context);root.add_child(queued)
 queued.on_saved(before_wrap,career,"wrap");queued.stop();await settle()
 check(queued.starts==0 and not queued.playing(),"queued start cancelled before next frame cannot fire")
 queued.free();await settle()
 check(owner.snapshot()==stable and FileAccess.get_file_as_bytes(fixture_path)==original,"all event/audio inspection leaves actual save and source bytes unchanged")
 owner=null
 await done()
func done() -> void:
 print("CROWD34_TEST "+JSON.stringify({"checks":checks,"failures":failures,"real_crowd_recordings_loaded":false,"synthetic_fixture_only_for_lifecycle":true,"listening":false,"physical_device":false}))
 await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
