extends SceneTree
const Chemistry = preload("res://Scripts/song_chemistry.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
var failures := 0
func _initialize() -> void:
 var base := {"members":[{"name":"A","life_status":"active"},{"name":"B","life_status":"active"}],"relationships":{"0_1":90},"tension":0,"song_catalogue":[{"title":"UNTITLED","quality":50}],"current_song_draft":{"title":"TEST SONG","form":"Verse / Chorus","idea":"Riff","leader":"A","sessions":[]}}
 var before := JSON.stringify(base)
 var strong: Dictionary = Chemistry.calculate(base)
 _check(int(strong["bonus"])==3,"strong chemistry earns maximum bonus")
 var good: Dictionary = Workshop.finish(base)
 _check(int(good["song_catalogue"][0]["quality"]) == 56,"chemistry and arrangement rewards stack")
 _check(int(good["song_catalogue"][0]["chemistry_bonus"])==3,"song credits preserve chemistry")
 var friction := base.duplicate(true)
 friction["relationships"]["0_1"]=20
 friction["tension"]=80
 _check(int(Chemistry.calculate(friction)["bonus"])==0,"poor relationships remove chemistry bonus")
 var unavailable := base.duplicate(true)
 unavailable["members"][1]["life_status"]="resting"
 _check(int(Chemistry.calculate(unavailable)["bonus"])==0,"inactive member excluded")
 _check(JSON.stringify(base)==before,"original save remains unchanged")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene imports")
 if failures==0:
  print("V40 SONG CHEMISTRY TESTS PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V40 SONG CHEMISTRY FAILURE: "+detail)
