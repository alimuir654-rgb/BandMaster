extends SceneTree
## Real approved media; controlled presentation context, no saves/music fixtures.
const Fixture=preload("res://tests/crowd34_audio_fixture.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const MANIFEST="res://experiments/playable_flightcase/audio/crowd37/manifest.json"
const REVIEW="res://experiments/playable_flightcase/audio/crowd37/test-manifest.json"
var checks:=0
var failures: Array=[]
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
 var context: Dictionary={"allowed":true,"identity":"result:approved-pub-qa","source_token":"validated-qa"}
 fx.configure(func():return context);AudioServer.set_bus_mute(0,false)
 check(fx._effect_stream("boo")==null,"no rejected boo or invented negative fallback")
 check(raw.effects.has("cheer"),"real approved pub source acquired")
 for kind in raw.effects:
  var stream: AudioStream=fx._effect_stream(kind)
  check(stream is AudioStreamOggVorbis,"approved real stream: "+kind)
  check(stream!=null and stream.get_length()>0 and stream.get_length()<=9,"bounded duration: "+kind)
  check(stream!=null and absf(stream.get_length()-float(raw.effects[kind].duration_seconds))<0.05,"actual declared duration: "+kind)
  for field in ["sha256","license","authority","path","source_id","owner_source_listening_accepted","integration_review_accepted","source_sha256"]:
   var broken: Dictionary=raw.duplicate(true)
   broken.effects[kind][field]=false if field in ["integration_review_accepted","owner_source_listening_accepted"] else "invalid"
   write_review(broken);fx.manifest_path=REVIEW
   check(fx._effect_stream(kind)==null,"reject invalid "+field+": "+kind)
 fx.manifest_path=MANIFEST
 for field in ["attribution_path","attribution_sha256"]:
  var broken: Dictionary=raw.duplicate(true);broken.effects.cheer[field]="invalid"
  write_review(broken);fx.manifest_path=REVIEW
  check(fx._effect_stream("cheer")==null,"CC BY requires packaged credit: "+field)
 fx.manifest_path=MANIFEST
 # Controlled final presentation uses the actual approved stream, no settlement.
 fx.event_id=context.identity;fx.event_kind="cheer";fx._source_token=context.source_token
 fx._start_once(fx._queued,fx.event_id);await settle()
 check(fx._crowd.playing and fx.effect_available and fx._fade!=null,"real CC BY cheer starts with fade")
 await create_timer(3.0).timeout
 check(fx._crowd.playing,"final cheer no longer truncated by old1.5second hold")
 await create_timer(3.2).timeout
 check(not fx._crowd.playing and fx._crowd.stream==null,"full reaction still bounded/released")
 fx.event_id=context.identity;fx.event_kind="cheer";fx._source_token=context.source_token
 fx._start_once(fx._queued,fx.event_id);await settle()
 AudioServer.set_bus_mute(0,true);await create_timer(0.12).timeout
 check(not fx.playing(),"mute releases real stream")
 AudioServer.set_bus_mute(0,false);await settle();check(not fx.playing(),"unmute no replay")
 var before: Dictionary={Journey.KEY:{"active":{"id":"actual-fx-qa","phase":"backstage"}}}
 var after: Dictionary={Journey.KEY:{"active":{"id":"actual-fx-qa","phase":"performing","cursor":0,"plan":{"song_snapshots":[]}}}}
 context.identity=Crowd.saved_event(before,after,"take_stage").id
 fx.on_saved(before,after,"take_stage");await settle();var starts: int=fx.starts
 fx.on_saved(before,after,"take_stage");await settle();check(fx.starts==starts,"saved event cannot replay")
 fx.stop();fx.on_saved(before,after,"take_stage");await settle();check(fx.starts==starts,"stop then same saved event stays spent")
 fx.event_id=context.identity;fx.event_kind="cheer";fx._source_token=context.source_token
 fx._start_once(fx._queued,fx.event_id);await settle()
 context.source_token="changed";await create_timer(0.12).timeout
 check(not fx.playing(),"changed source stops real stream")
 fx.event_id=context.identity;fx.event_kind="cheer";fx._source_token=context.source_token
 fx._start_once(fx._queued,fx.event_id);await settle()
 fx._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not fx.playing(),"focus loss immediately stops")
 fx.event_id=context.identity;fx.event_kind="cheer";fx._source_token=context.source_token
 fx._start_once(fx._queued,fx.event_id);await settle()
 context.allowed=false;await create_timer(0.12).timeout
 check(not fx.playing(),"hidden/modal context stops")
 context.allowed=true;await settle();check(not fx.playing(),"returning context stays quiet")
 fx.free();await settle()
 check(FileAccess.get_file_as_bytes(MANIFEST)==original,"manifest unchanged by playback/negative checks")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(REVIEW))
 print("CROWD37_TEST "+JSON.stringify({"checks":checks,"failures":failures,"available_sources":raw.effects.size(),"bank_complete":raw.complete,"owner_source_acceptance":true,"mix_listening_here":false,"physical_device":false}))
 quit(0 if failures.is_empty() else 1)
