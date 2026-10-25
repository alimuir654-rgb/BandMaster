extends SceneTree
const Songbook = preload("res://Scripts/songbook_presentation.gd")
var failures := 0
func _initialize() -> void:
 var state := {"song_catalogue":[{"title":"Late Bus","quality":82,"lead_writer":"Alex","arrangement":"Slow Build"},{"title":"Garage Echo","quality":32},{"title":"Live Tune","quality":61,"live_reception":"Great crowd response"}]}
 var list: Array = Songbook.entries(state)
 _check(list.size()==3,"all completed songs listed")
 _check(list[0]["verdict"]=="SETLIST READY","quality judgement")
 _check(list[1]["verdict"]=="NEEDS WORK","low quality identified")
 _check(list[0]["reception"]=="NOT RECORDED","missing reception never invented")
 _check(list[2]["reception"]=="Great crowd response","real recorded reception surfaced")
 _check(list[0]["writer"]=="Alex","real writer displayed")
 _check(not state["song_catalogue"][0].has("live_reception"),"view is nonmutating")
 var src := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(src.contains("Songbook.entries(_state())"),"career view bound to real catalogue")
 _check(src.contains("var song_list_scroll := ScrollContainer.new()"),"songbook scrolls")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub loads")
 if failures==0:
  print("V114 SONGBOOK PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V114 SONGBOOK FAILURE: "+reason)
