extends "res://tests/recorded_steady_test.gd"
const New=preload("res://experiments/playable_flightcase/recorded_vocal_keys.gd")
const Song=preload("res://experiments/playable_flightcase/song_audio.gd")
func fixture() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_tom","cast_ben","cast_ellis","cast_maya","cast_freya"]:
  var result: Dictionary=owner.recruit(id)
  if not result.get("ok",false):print("FORMATION "+str(result));return false
 return owner.choose_vocal("cast_maya").get("ok",false) and owner.confirm_lineup(true).get("ok",false) and owner.submit_name("SOURCE WINDOW","Raw").get("ok",false) and owner.lock_name(true).get("ok",false) and owner.finish_identity().get("ok",false) and owner.start_playing()
func run() -> void:
 if not check(fixture(),"actual funded Maya/Freya five-person band"):await finish_new();return
 var base: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 check(Bank.HOOKS.size()==35,"32old hooks retained plus3approved new hooks")
 for hook in New.HOOKS:
  var value: Dictionary=New.select(base,hook)
  check(Recipe.valid(value) and Producer_valid(value),"version5 routes through original producer: "+hook)
  var i: int=New.index(value)
  var pair: Dictionary={"members":[{"candidate_id":New.SINGERS[i],"role":"Singer"},{"candidate_id":New.KEYS[i],"role":"Keyboardist"}]}
  check(New.active_pair(pair,value),"canonical exact pair: "+hook)
  pair.members[0].candidate_id="cast_nina";check(not New.active_pair(pair,value),"no Nina voice substitution")
  var entry: Dictionary=Bank.entry(value)
  if not check(not entry.is_empty(),"actual immutable five-part source: "+hook):await finish_new();return
  for part in New.PARTS:check(New.stream(entry.parts[part],int(entry.frames))!=null,"actual PCM fingerprint: "+hook+part)
  var invalid: Dictionary=value.duplicate(true);invalid.keys="cast_dan" if value.keys!="cast_dan" else "cast_freya"
  check(not Recipe.valid(invalid),"cross-keyboard source binding refused")
  invalid=value.duplicate(true);invalid.version=4
  check(not Recipe.valid(invalid),"new vocal source cannot masquerade as old instrumental version")
 var value: Dictionary=New.select(base,New.HOOKS[0])
 check(New.active_pair(owner.game.career,value),"real current band has bound singer and keyboardist")
 var before: Dictionary=owner.snapshot()
 var wrong: Dictionary=New.select(base,New.HOOKS[1])
 check(not owner.begin_workbench("Steady at last",0,owner.workbench_expected(),wrong).get("ok",false) and owner.snapshot()==before,"real owner refuses wrong pair before draft save")
 if not check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),value).get("ok",false),"real version5 draft begins"):await finish_new();return
 for stage in range(3):
  if not check(next_available_evening(),"available original evening"):await finish_new();return
  value.stage=stage
  if not await trial(value):await finish_new();return
  before=owner.snapshot()
  var failed: Dictionary=paid(true)
  if not check(not failed.get("ok",false) and owner.snapshot()==before,"whole owner rollback on actual save failure stage"+str(stage)):await finish_new();return
  var result: Dictionary=paid()
  if not check(result.get("ok",false),"actual paid stage saved once"+str(stage)):await finish_new();return
  var restored=Owner.new()
  var loaded: bool=restored.load_draft()
  print("RELOAD "+JSON.stringify({"stage":stage,"loaded":loaded,"deltas":diff(owner.snapshot(),restored.snapshot(),"")}))
  check(loaded and restored.snapshot()==owner.snapshot(),"exact typed version5 reload stage"+str(stage));restored=null
  if stage==0:
   var ids: Array=[]
   for row in owner.game.career[Bank.USES].records:ids.append(row.candidate_id)
   check(ids.has("cast_maya") and ids.has("cast_freya") and ids.size()==5,"one first-paid cohort includes actual singer/keys")
 var songs: Array=owner.game.career.song_catalogue
 if not check(songs.size()==1,"one actual completed saved song"):await finish_new();return
 var frozen: Dictionary=Song.recipe(songs[0])
 check(frozen.get("version")==5 and frozen.voice=="cast_maya" and frozen.keys=="cast_freya","saved final receipt resolves original voice and keys")
 var draft: Dictionary=frozen.duplicate(true);draft.stage=0
 check(not Bank.available(owner.game.career,draft,"other-project"),"no second original using consumed cohort phrase")
 var old_records: Array=owner.game.career[Bank.USES].records.duplicate(true)
 check(old_records.size()==5,"later sessions never duplicate consumed phrase records")
 selected=frozen.duplicate(true);allowed=true
 var audio=Audio.new();audio.configure(func():return {"allowed":allowed,"recipe":selected});root.add_child(audio)
 check(audio.request_play(),"saved final source actually plays")
 var sync: AudioStreamSynchronized=audio._recorded_player.stream
 check(sync!=null and sync.stream_count==5,"five actual stems share one clock")
 var voice=sync.get_sync_stream(0)
 var volume: float=sync.get_sync_stream_volume(0)
 audio.live_audition=true;selected.energy="open";selected.shape="burst";audio.notify_controls_changed()
 await process_frame
 check(audio._recorded_player.stream.get_sync_stream(0)==voice and audio._recorded_player.stream.get_sync_stream_volume(0)==volume,"backing changes retain identical vocal object and level")
 # A completed recording retains its historical voice even if the live lineup changes.
 var shadow: Dictionary=owner.game.career.duplicate(true)
 for member in shadow.members:
  if member.candidate_id=="cast_maya":member.life_status="departed"
 check(not Bank.available(shadow,draft,"other-project") and not Song.recipe(songs[0]).is_empty(),"changed live cohort held; original saved recording retained")
 AudioServer.set_bus_mute(0,true);await create_timer(0.2).timeout
 check(not audio.playing,"mute releases version5 playback")
 AudioServer.set_bus_mute(0,false);allowed=false;audio.free();voice=null;sync=null
 await process_frame
 await finish_new()
func Producer_valid(value: Dictionary) -> bool:return preload("res://experiments/playable_flightcase/producer_recipe.gd").valid(value)
func finish_new() -> void:
 print("INDIE39_MODEL "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"new_listening":false}))
 owner=null
 await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)

func diff(a: Variant,b: Variant,path: String) -> Array:
 var result: Array=[]
 if typeof(a)!=typeof(b):return [path+" TYPE "+str(typeof(a))+"/"+str(typeof(b))]
 if a is Dictionary:
  for key in a:
   if not b.has(key):result.append(path+"/"+str(key)+" missing")
   else:result.append_array(diff(a[key],b[key],path+"/"+str(key)))
 elif a is Array:
  if a.size()!=b.size():result.append(path+" size")
  else:
   for i in a.size():result.append_array(diff(a[i],b[i],path+"/"+str(i)))
 elif a!=b:result.append(path+" "+str(a)+"/"+str(b))
 return result
