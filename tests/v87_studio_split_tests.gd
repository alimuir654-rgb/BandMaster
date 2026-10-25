extends SceneTree
var failures := 0
func _initialize() -> void:
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 var first := source.find("func _actions() -> void:")
 var last := source.find("func _recording_studio() -> void:",first)
 _check(first>=0 and last>first,"studio view")
 if first>=0 and last>first:
  var studio := source.substr(first,last-first)
  _check(studio.contains("var wide_workspace := get_viewport_rect().size.x >= 960.0"),"landscape breakpoint")
  _check(studio.contains("decision_column.size_flags_stretch_ratio = 1.8"),"decision workspace prioritised")
  _check(studio.contains("context_column.size_flags_stretch_ratio = 1.0"),"context sidebar")
  _check(studio.contains("content = context_column"),"scene and status in context")
  _check(studio.contains("content = decision_column"),"gameplay in primary workspace")
  _check(studio.contains("content = full_content"),"parent restored for subsequent navigation")
  _check(studio.contains("Practice.compose(_state()"),"songwriting still commits")
 _check(load("res://Scenes/CareerHub.tscn")!=null,"CareerHub imports")
 if failures==0:
  print("STUDIO SPLIT WORKSPACE PASSED")
 quit(0 if failures==0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("STUDIO WORKSPACE FAILURE: "+reason)
