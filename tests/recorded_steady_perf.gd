extends "res://tests/recorded_steady_test.gd"
## Real formation plus an explicit synthetic legacy catalogue from the original pure resolver.
## Timings are desktop measurements, not phone claims.
func run() -> void:
 if not check(fixture(),"formation"):finish();return
 var synthetic: Dictionary=owner.game.career.duplicate(true)
 for song in range(3):
  for _stage in range(3):
   var developed: Dictionary=preload("res://Scripts/practice_room.gd").compose(synthetic,"Riff","Verse / Chorus","PROFILE SONG "+str(song),0)
   if not check(developed.ok,"original pure catalogue fixture"):finish();return
   synthetic=developed.state
 owner.game.career.song_catalogue=synthetic.song_catalogue.duplicate(true)
 owner.game.career.songs=synthetic.songs
 check(owner.game.career.song_catalogue.size()==3,"synthetic legacy catalogue has three originals")
 if not check(owner.begin_workbench("Steady at last",0,owner.workbench_expected(),take("steady_later_v1")).ok,"recorded draft"):finish();return
 var before: Dictionary=owner.snapshot()
 var Desk=load("res://experiments/playable_flightcase/mixing_desk.gd")
 var start: int=Time.get_ticks_usec()
 var desk=Desk.new();desk.configure(owner,true);root.add_child(desk)
 var opening: float=(Time.get_ticks_usec()-start)/1000.0
 var samples: Array=[]
 for i in range(21):
  start=Time.get_ticks_usec();desk._choose("tone",i%3);samples.append((Time.get_ticks_usec()-start)/1000.0)
 samples.sort()
 check(owner.snapshot()==before,"local control edits preserve mature owner")
 print("WRITING_PERF "+JSON.stringify({"songs":owner.game.career.song_catalogue.size(),"opening_ms":opening,"detent_median_ms":samples[10],"detent_p95_ms":samples[19],"detent_max_ms":samples[20],"failures":failures}))
 desk.queue_free();await process_frame
 finish()
