extends SceneTree
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
var failures := 0
func _initialize() -> void:
 var state := {"readiness":55,"morale":60,"tension":20}
 var tight: Dictionary = Gigs.approach_preview(state,"tight")
 var wild: Dictionary = Gigs.approach_preview(state,"wild")
 var crowd: Dictionary = Gigs.approach_preview(state,"crowd")
 _check(tight["quality_modifier"] == Gigs.APPROACHES["tight"]["quality"],"tight quality matches engine")
 _check(wild["fan_bonus"] == Gigs.APPROACHES["wild"]["fan_bonus"],"wild fan bonus matches engine")
 _check(crowd["tension_modifier"] == Gigs.APPROACHES["crowd"]["tension"],"crowd tension matches engine")
 _check(tight["quality_estimate"] - wild["quality_estimate"] == 16,"outlook preserves approach difference")
 _check(Gigs.approach_preview(state,"invalid").is_empty(),"unknown approach rejected")
 _check(state == {"readiness":55,"morale":60,"tension":20},"preview never mutates gameplay")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("Gigs.approach_preview(_state(),approach)"),"soundcheck uses game model")
 _check(source.contains("var approach_grid := GridContainer.new()"),"decision cards rendered")
 _check(source.contains("button.pressed.connect(func() -> void: _change_gig_strategy(approach))"),"selection applies existing event")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene loads")
 if failures == 0:
  print("V111 PERFORMANCE DECISIONS PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V111 DECISION FAILURE: "+reason)
