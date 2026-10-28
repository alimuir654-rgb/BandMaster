extends SceneTree
## Godot 4.7 offset transforms must animate without changing Container layout.
const Motion = preload("res://poc/ldtd_control_motion_47.gd")
var failures := 0

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  push_error("LDTD NATIVE 4.7 MOTION FAILURE: " + label)

func _run() -> void:
 var row := HBoxContainer.new()
 row.name = "LiveContainer"
 row.size = Vector2(800, 110)
 get_root().add_child(row)
 var left := TextureButton.new()
 left.name = "ImageBackedTransport"
 left.custom_minimum_size = Vector2(126, 60)
 left.focus_mode = Control.FOCUS_ALL
 row.add_child(left)
 var right := TextureButton.new()
 right.custom_minimum_size = Vector2(126, 60)
 row.add_child(right)
 await process_frame
 var original_position := left.position
 var original_size := left.size
 Motion.attach(left)
 Motion.attach(left)
 _check(left.offset_transform_enabled and left.offset_transform_visual_only, "native 4.7 visual-only offset enabled")
 _check(left.get_signal_connection_list("mouse_entered").size() == 1, "idempotent hook, one mouse-enter callback")
 _check(left.offset_transform_pivot_ratio == Vector2(0.5, 0.5), "scale pivots around button centre")
 left.mouse_entered.emit()
 await create_timer(0.25).timeout
 _check(left.offset_transform_scale.x > 1.015, "hover scale animates")
 _check(left.offset_transform_position.y < -0.5, "hover lifts hardware visually")
 row.queue_sort()
 await process_frame
 _check(left.position == original_position and left.size == original_size, "Container geometry stays put after sort")
 left.button_down.emit()
 await create_timer(0.14).timeout
 _check(left.offset_transform_scale.x < 0.99, "button press has tactile compression")
 Motion.reset(left)
 _check(left.offset_transform_scale == Vector2.ONE and left.offset_transform_position == Vector2.ZERO, "reset restores complete native appearance")
 _check(left.position == original_position and left.size == original_size, "reset cannot damage layout")
 row.queue_free()
 if failures == 0:
  print("LDTD GODOT 4.7 OFFSET-MOTION SANDBOX ALL TESTS PASSED")
 quit(0 if failures == 0 else 1)
