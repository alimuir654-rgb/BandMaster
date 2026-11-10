extends SceneTree
## Actual CC0 decoders/lifecycle. No synthetic stream and no save access.
const Fixture=preload("res://tests/crowd34_audio_fixture.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
var checks:=0
var failures: Array=[]
const MANIFEST="res://experiments/playable_flightcase/audio/crowd34/manifest.json"
const REVIEW="res://experiments/playable_flightcase/audio/crowd34/qa-review.json"
func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func write_review(raw: Dictionary) -> void:
 var file=FileAccess.open(REVIEW,FileAccess.WRITE);file.store_string(JSON.stringify(raw));file.close()
func settle() -> void:
 for _frame in range(4):await process_frame
func run() -> void:
 var original: PackedByteArray=FileAccess.get_file_as_bytes(MANIFEST)
 var raw: Dictionary=JSON.parse_string(original.get_string_from_utf8())
 var fx=Fixture.new();root.add_child(fx)
 var context: Dictionary={"allowed":true,"identity":"","source_token":"validated-qa"}
 fx.configure(func():return context)
 AudioServer.set_bus_mute(0,false)
 for kind in ["entrance","song","courtesy","cheer","boo"]:
  check(fx._effect_stream(kind)==null,"unheard shipping candidate held: "+kind)
 # Test-only review copy exercises the existing production gate. It is NOT
 # listening acceptance and must never be promoted/copied over the manifest.
 var reviewed: Dictionary=raw.duplicate(true)
 for kind in reviewed.effects:reviewed.effects[kind].integration_review_accepted=true
 write_review(reviewed);fx.manifest_path=REVIEW
 for kind in reviewed.effects:
  var stream: AudioStream=fx._effect_stream(kind)
  check(stream is AudioStreamOggVorbis,"real Vorbis decoding: "+kind)
  check(stream!=null and absf(stream.get_length()-float(reviewed.effects[kind].duration_seconds))<0.05,"bounded actual duration: "+kind)
  for field in ["sha256","license","authority","path","integration_review_accepted"]:
   var broken: Dictionary=reviewed.duplicate(true)
   broken.effects[kind][field]=false if field=="integration_review_accepted" else "invalid"
   write_review(broken)
   check(fx._effect_stream(kind)==null,"reject invalid "+field+": "+kind)
 write_review(reviewed)
 var before: Dictionary={Journey.KEY:{"active":{"id":"actual-fx-qa","phase":"backstage"}}}
 var after: Dictionary={Journey.KEY:{"active":{"id":"actual-fx-qa","phase":"performing","cursor":0,"plan":{"song_snapshots":[]}}}}
 var event: Dictionary=Crowd.saved_event(before,after,"take_stage")
 context.identity=event.id
 fx.on_saved(before,after,"take_stage");await settle()
 check(fx.effect_available and fx._crowd.playing and fx._fade!=null,"real entrance playback and fade")
 var starts: int=fx.starts
 fx.on_saved(before,after,"take_stage");await settle()
 check(fx.starts==starts,"same saved event no replay")
 await create_timer(3.0).timeout
 check(not fx._crowd.playing and fx._crowd.stream==null,"real effect fade releases bounded stream")
 var tail: Dictionary={Journey.KEY:{"active":{"id":"actual-fx-qa","phase":"after_set"}}}
 context.identity=Crowd.saved_event(after,tail,"finish_song").id
 fx.on_saved(after,tail,"finish_song");await settle()
 check(fx._crowd.playing,"real courtesy response after song")
 AudioServer.set_bus_mute(0,true);await create_timer(0.12).timeout
 check(not fx.playing(),"mute stops real recording")
 AudioServer.set_bus_mute(0,false);await settle()
 check(not fx.playing(),"unmute never replays")
 fx.free();await settle()
 var queued=Fixture.new();queued.manifest_path=REVIEW
 context.identity=event.id;queued.configure(func():return context);root.add_child(queued)
 queued.on_saved(before,after,"take_stage");queued.stop();await settle()
 check(queued.starts==0 and not queued.playing(),"cancel deferred real recording")
 queued.free();await settle()
 check(FileAccess.get_file_as_bytes(MANIFEST)==original,"shipping manifest remains byte exact and unaccepted")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(REVIEW))
 print("CROWD36_TEST "+JSON.stringify({"checks":checks,"failures":failures,"real_recordings_decoded":true,"listening":false,"physical_device":false}))
 quit(0 if failures.is_empty() else 1)
