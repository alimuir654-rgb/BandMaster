extends SceneTree
const Chemistry = preload("res://Scripts/band_chemistry_presentation.gd")
var failures := 0
func _initialize() -> void:
 var roster := [{"name":"Alex"},{"name":"Jo"},{"name":"Pat","life_status":"away"}]
 var relations := {"0_1":82,"0_2":10}
 var before := JSON.stringify(relations)
 var pairs: Array = Chemistry.connections(roster,relations)
 _check(pairs.size() == 1,"unavailable member omitted")
 _check(int(pairs[0]["score"]) == 82 and str(pairs[0]["label"]) == "CREATIVE SPARK","strong bond")
 _check(JSON.stringify(relations) == before,"no state mutations")
 _check(Chemistry.connections([{"name":"A"},{"name":"B"}],{} )[0]["score"] == 50,"missing legacy relationship defaults")
 _check(Chemistry.connections([{"name":"A"},{"name":"B"}],{"0_1":-90})[0]["score"] == 0,"values clamped")
 _check(not Chemistry.summary([]).is_empty(),"empty relationship hint")
 if failures == 0:
  print("V24 BAND CHEMISTRY MAP TESTS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool, detail: String) -> void:
 if not ok:
  failures += 1
  push_error("V24 CHEMISTRY MAP FAILURE: "+detail)
