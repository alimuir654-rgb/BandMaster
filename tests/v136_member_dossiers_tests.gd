extends SceneTree
var failed := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _assert(source.contains('THE BAND\'S EQUIPMENT  /  ROAD CASES'),"member gear dossier exists")
 _assert(source.contains('No relevant purchased gear recorded'),"untracked gear is not invented")
 _assert(source.contains('Shared purchases are shown against relevant musicians'),"ownership limitation explicit")
 _assert(source.contains('var relationship_status := "CONNECTED"'),"relationships have actionable status")
 _assert(source.contains('SPEND TIME TOGETHER  ›'),"low bonds offer social resolution")
 _assert(not source.contains('_progress(connection_card,str(bond['),"repeated relationship bars removed")
 _assert(load("res://Scenes/CareerHub.tscn")!=null,"scene compiles")
 if failed == 0: print("V136 MEMBER DOSSIERS PASSED")
 quit(0 if failed==0 else 1)
func _assert(ok: bool,why: String) -> void:
 if not ok:
  failed+=1
  push_error("V136 FAILURE: "+why)
