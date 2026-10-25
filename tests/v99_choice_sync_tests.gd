extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _actions() -> void:")
 var b := source.find("func _recording_studio() -> void:",a)
 _check(a>=0 and b>a,"Studio implementation")
 if a>=0 and b>a:
  var studio := source.substr(a,b-a)
  _check(studio.contains("var choice_repaints: Array[Callable] = []"),"shared repaint callbacks")
  _check(studio.contains("choice_repaints.append(repaint)"),"each card registered")
  _check(studio.count("for repaint_card in choice_repaints:") == 2,"Remix and Restore redraw")
  _check(studio.contains("SongLab.restore(saved_take,ideas,forms,titles,leads)"),"take restoration")
  _check(studio.contains("SongLab.remix(ideas,forms,titles,leads)"),"remix action")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub loads")
 if failures==0:
  print("V99 CHOICE CARD SYNC PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,detail: String) -> void:
 if not ok:
  failures+=1
  push_error("V99 SYNC FAILURE: "+detail)
