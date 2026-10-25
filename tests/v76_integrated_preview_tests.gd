extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var a := source.find("func _actions() -> void:")
 var b := source.find("func _recording_studio() -> void:",a)
 _check(a >= 0 and b > a,"studio exists")
 if a>=0 and b>a:
  var studio := source.substr(a,b-a)
  _check(studio.contains("workshop.add_child(preview_panel)"),"preview embedded in controls")
  _check(studio.contains("YOUR SONG  /  LIVE PREVIEW"),"clear preview label")
  _check(studio.contains("item_selected.connect"),"live updates preserved")
  _check(studio.contains("COMMIT TO THIS SONG"),"action remains")
  _check(not studio.contains("_card(\"SONG DIRECTION"),"duplicate section removed")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career scene imports")
 if failures==0:
  print("V76 INTEGRATED SONG PREVIEW PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("V76 PREVIEW FAILURE: "+reason)
