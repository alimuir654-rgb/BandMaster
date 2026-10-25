extends SceneTree
const View = preload("res://Scripts/band_roster_view.gd")
var failed := 0
func _initialize() -> void:
 var members := [
  {"name":"Jo","skill":65,"fatigue":92,"loyalty":40},
  {"name":"Alex","skill":90,"fatigue":15,"loyalty":75},
  {"name":"Sam","skill":65,"fatigue":55,"loyalty":95}
 ]
 _check(View.sorted_indices(members,"LINEUP")==[0,1,2],"canonical lineup")
 _check(View.sorted_indices(members,"SKILL")==[1,0,2],"skill with stable ties")
 _check(View.sorted_indices(members,"FATIGUE")==[0,2,1],"fatigued first")
 _check(View.sorted_indices(members,"LOYALTY")==[2,1,0],"loyalty ordering")
 _check(members[0]["name"]=="Jo" and members[1]["name"]=="Alex","never mutate canonical member order")
 _check(View.sorted_indices(members,"INVALID")==[0,1,2],"invalid preference safe")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("roster_sort = sort_mode"),"sorting controls change UI state")
 _check(source.contains("RosterView.sorted_indices(members,roster_sort)"),"roster uses view indices")
 _check(source.contains("var index := i"),"member actions keep original IDs")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"career loads")
 if failed == 0:
  print("V103 ROSTER SORT PASSED")
 quit(0 if failed == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failed += 1
  push_error("V103 ROSTER FAILURE: "+reason)
