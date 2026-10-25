extends SceneTree
# Guards the shared career header design and its narrow/wide layout rules.
var failures := 0

func _initialize() -> void:
 var script := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(not script.is_empty(),"career script available")
 _check(script.contains('{"title":"CASH"') and script.contains('{"title":"FANS"') and script.contains('{"title":"REPUTATION"'),"all three live metrics present")
 _check(script.contains('var wide := get_viewport_rect().size.x >= 960.0'),"responsive breakpoint retained")
 _check(script.contains('metric_panel.custom_minimum_size.y = 78 if wide else 62'),"responsive tap-safe height")
 _check(script.contains('metric_panel.tooltip_text = str(entry["detail"])'),"semantic metric help")
 _check(script.contains('value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS'),"large numbers cannot overflow")
 _check(script.contains('var metric_icon := _label('),"icon-led desktop presentation")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career hub scene loads")
 if failures == 0:
  print("V106 CAREER METRIC HEADER PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool, reason: String) -> void:
 if not ok:
  failures += 1
  push_error("V106 HEADER FAILURE: " + reason)
