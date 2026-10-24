extends SceneTree
const Chemistry = preload("res://Scripts/band_chemistry_presentation.gd")
var failures := 0
func _initialize() -> void:
 var roster := [{"name":"Jo"},{"name":"Alex"},{"name":"Sam","life_status":"away"}]
 var relations := {"0_1":82,"0_2":20,"1_2":10}
 var original := JSON.stringify(relations)
 var pairs: Array = Chemistry.connections(roster,relations)
 _check(pairs.size() == 1,"away musician excluded")
 if pairs.size() == 1:
  _check(str(pairs[0]["mood"]) == "CLOSE" and int(pairs[0]["value"]) == 82,"pair score")
 _check(JSON.stringify(relations) == original,"no mutation")
 _check(Chemistry.connections([{"name":"A"},{"name":"B"}],{"1_0":12})[0]["mood"] == "STRAINED","reverse legacy key")
 _check(Chemistry.connections([{"name":"A"},{"name":"B"}],{}).is_empty(),"no invented relationships")
 if failures == 0:
  print("V24 CHEMISTRY PRESENTATION PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 CHEMISTRY UI FAILURE: "+detail)
