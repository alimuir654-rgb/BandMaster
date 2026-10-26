extends RefCounted
# Reusable two-leg fade for art-led journeys. The layer must survive the scene swap.
static func play(layer: ColorRect, swap: Callable, finished: Callable, reduced_motion: bool = false) -> void:
 if not is_instance_valid(layer):
  return
 layer.mouse_filter = Control.MOUSE_FILTER_STOP
 layer.color = Color(0,0,0,0)
 if reduced_motion:
  swap.call()
  layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
  finished.call()
  return
 var tween: Tween = layer.create_tween()
 tween.tween_property(layer,"color:a",1.0,0.22)
 tween.tween_callback(swap)
 tween.tween_property(layer,"color:a",0.0,0.22)
 tween.tween_callback(func() -> void:
  if is_instance_valid(layer):
   layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
  finished.call()
 )
