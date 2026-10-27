extends RefCounted
## Godot 4.7 isolated game-UI motion experiment.
## A real TextureButton retains its Container-controlled size and input rect.
## Animation only modifies Control.offset_transform_*; no old flat helpers.
## No plugin, no timers, no save writes, no autoloads.

const HOVER_SCALE := Vector2(1.025, 1.025)
const REST_SCALE := Vector2.ONE
const PRESS_SCALE := Vector2(0.975, 0.975)

static func attach(button: TextureButton) -> void:
 if button.has_meta("_ldtd_offset_motion"):
  return
 button.set_meta("_ldtd_offset_motion", true)
 button.offset_transform_enabled = true
 button.offset_transform_visual_only = true
 button.offset_transform_pivot_ratio = Vector2(0.5, 0.5)
 button.offset_transform_scale = REST_SCALE
 button.offset_transform_position = Vector2.ZERO
 button.mouse_entered.connect(func() -> void:
  if not button.disabled:
   _animate(button, HOVER_SCALE, Vector2(0.0, -1.0), 0.11)
 )
 button.mouse_exited.connect(func() -> void:
  if not button.disabled:
   _animate(button, HOVER_SCALE if button.has_focus() else REST_SCALE, Vector2(0.0, -1.0) if button.has_focus() else Vector2.ZERO, 0.13)
 )
 button.focus_entered.connect(func() -> void:
  if not button.disabled:
   _animate(button, HOVER_SCALE, Vector2(0.0, -1.0), 0.11)
 )
 button.focus_exited.connect(func() -> void:
  if not button.disabled:
   _animate(button, REST_SCALE, Vector2.ZERO, 0.13)
 )
 button.button_down.connect(func() -> void:
  if not button.disabled:
   _animate(button, PRESS_SCALE, Vector2(0.0, 1.0), 0.045)
 )
 button.button_up.connect(func() -> void:
  if not button.disabled:
   _animate(button, HOVER_SCALE if button.has_focus() else REST_SCALE, Vector2(0.0, -1.0) if button.has_focus() else Vector2.ZERO, 0.10)
 )

static func reset(button: TextureButton) -> void:
 var previous: Variant = (button.get_meta("_ldtd_motion_tween") if button.has_meta("_ldtd_motion_tween") else null)
 if previous is Tween and previous.is_valid():
  previous.kill()
 button.offset_transform_position = Vector2.ZERO
 button.offset_transform_scale = REST_SCALE

static func _animate(button: TextureButton, target_scale: Vector2, target_position: Vector2, duration: float) -> void:
 if not is_instance_valid(button) or not button.is_inside_tree():
  return
 var previous: Variant = (button.get_meta("_ldtd_motion_tween") if button.has_meta("_ldtd_motion_tween") else null)
 if previous is Tween and previous.is_valid():
  previous.kill()
 var tween := button.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
 tween.tween_property(button, "offset_transform_scale", target_scale, duration)
 tween.tween_property(button, "offset_transform_position", target_position, duration)
 button.set_meta("_ldtd_motion_tween", tween)
