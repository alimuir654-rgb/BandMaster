extends SceneTree
const Sheet = preload("res://Scripts/scene_sheet.gd")
var failures := 0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var root := Control.new()
 root.custom_minimum_size = Vector2(390,844)
 root.size = Vector2(390,844)
 get_root().add_child(root)
 var data: Dictionary = Sheet.build(root,"Meet the Promoter","Choose a deal based on risk, travel and trust.","res://not-a-real-artwork.png")
 _check(data.has("overlay") and data.has("body") and data.has("actions"),"sheet exposes reusable slots")
 var triggered := [0]
 var primary := Sheet.add_choice(data,"CONFIRM",func() -> void: triggered[0] += 1,true)
 _check(primary.custom_minimum_size.y >= 44.0,"accessible touch target")
 _check(primary.focus_mode == Control.FOCUS_ALL,"keyboard focus enabled")
 _check((data["overlay"] as Control).mouse_filter == Control.MOUSE_FILTER_STOP,"overlay blocks underlying clicks")
 _check((data["body"] as Control).get_node_or_null("SceneSheetArt") == null,"missing art handled without fabricated image")
 primary.pressed.emit()
 _check(triggered[0] == 1,"choice callback fires once")
 Sheet.dismiss(data)
 await process_frame
 _check(not is_instance_valid(data["overlay"]),"dismiss disposes sheet")
 root.queue_free()
 if failures == 0: print("SCENE SHEET PRIMITIVE PASSED")
 quit(0 if failures == 0 else 1)
func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures+=1
  push_error("SCENE SHEET FAILURE: "+reason)
