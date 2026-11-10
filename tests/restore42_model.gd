extends "res://tests/indie39_model.gd"
## Full recovered legacy bank, plus explicit separation from bound vocal recipes.
func run() -> void:
 if not check(fixture(),"real funded canonical band"):await finish_new();return
 var base: Dictionary=Recipe.recipe(Sound.read(owner.game.career))
 var stable: Dictionary=owner.snapshot()
 var legacy: Array=Bank.STEADY_HOOKS+Bank.REHEARSAL_HOOKS+Bank.DGAD_HOOKS+Bank.INDIE29_HOOKS
 check(legacy.size()==32 and Bank.HOOKS.size()==35,"32legacy plus3bound vocal sources")
 for hook in legacy:
  var value: Dictionary=base.duplicate(true);value.hook=hook
  check(Recipe.valid(value),"legacy version4 recipe valid "+hook)
  var entry: Dictionary=Bank.entry(value)
  if not check(not entry.is_empty(),"real recovered source "+hook):await finish_new();return
  check(entry.frames==Bank.frames(value) and entry.tempo==Bank.tempo(value),"registered original clock "+hook)
  for part in entry.parts:
   check(Bank.stream(entry.parts[part],int(entry.frames))!=null,"actual imported PCM pin "+hook+"/"+str(part))
  for stage in range(3):
   value.stage=stage
   check(Recipe.valid(value) and not Bank.entry(value).is_empty(),"each original stage keeps source "+hook)
 check(owner.snapshot()==stable,"source inspection has no paid or saved effect")
 for hook in New.HOOKS:
  var wrong: Dictionary=base.duplicate(true);wrong.hook=hook
  check(not Recipe.valid(wrong),"new vocal source cannot enter legacy recipe shape")
 var families: Array=[legacy[0],Bank.REHEARSAL_HOOKS[0],Bank.DGAD_HOOKS[0],Bank.INDIE29_HOOKS[0],Bank.INDIE29_HOOKS[6],Bank.INDIE29_HOOKS[12]]
 for hook in families:
  check(fixture(),"fresh isolated owner for actual paid source "+hook)
  selected=take(hook,2);selected.shape="burst";allowed=true
  var audio=Audio.new();audio.configure(func():return {"allowed":allowed,"recipe":selected});root.add_child(audio)
  check(audio.request_play() and audio._recorded_player.stream.stream_count==3,"actual recovered synchronized playback "+hook)
  audio.free();await process_frame
  var value: Dictionary=take(hook)
  if not check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),value).ok,"original legacy draft "+hook):await finish_new();return
  for stage in range(3):
   if not check(next_available_evening(),"original work availability"):await finish_new();return
   value.stage=stage
   if not await trial(value):await finish_new();return
   var before: Dictionary=owner.snapshot()
   check(not paid(true).ok and owner.snapshot()==before,"actual failed save whole rollback "+hook)
   if not check(paid().ok,"original paid source saved "+hook):await finish_new();return
   var restored=Owner.new()
   check(restored.load_draft() and restored.snapshot()==owner.snapshot(),"exact whole typed reload "+hook)
   restored=null
  var songs: Array=owner.game.career.song_catalogue
  check(songs.size()==1 and Song.recipe(songs[0]).hook==hook,"completed song retains exact old foundation "+hook)
  check(not Bank.available(owner.game.career,take(hook),"next-project"),"once-only original source use "+hook)
 await finish_new()
func finish_new() -> void:
 print("RESTORE42_MODEL "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 owner=null;await create_timer(0.2).timeout
 quit(0 if failures.is_empty() else 1)
