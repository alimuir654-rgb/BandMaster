extends RefCounted
## One physical-display to viewport content boundary. No gameplay or saving.
## The OS may already inset the window: intersection makes that a zero inset,
## rather than adding a guessed notch spacer a second time.

static func content_rect(viewport_bounds: Rect2, screen_safe: Rect2, viewport_to_screen: Transform2D) -> Rect2:
 if not viewport_bounds.is_finite() or viewport_bounds.size.x<=0.0 or viewport_bounds.size.y<=0.0:
  return viewport_bounds
 if not screen_safe.is_finite() or screen_safe.size.x<=0.0 or screen_safe.size.y<=0.0:
  return viewport_bounds
 if not viewport_to_screen.is_finite() or absf(viewport_to_screen.determinant())<0.000001:
  return viewport_bounds
 var safe: Rect2 = (viewport_to_screen.affine_inverse()*screen_safe).intersection(viewport_bounds)
 if safe.size.x<=0.0 or safe.size.y<=0.0:
  return viewport_bounds
 # Round into the safe area, never back out across a physical cutout edge.
 var start := Vector2(ceilf(safe.position.x),ceilf(safe.position.y))
 var end := Vector2(floorf(safe.end.x),floorf(safe.end.y))
 if end.x<=start.x or end.y<=start.y:
  return viewport_bounds
 return Rect2(start,end-start)


static func for_root(host: Control) -> Rect2:
 var bounds: Rect2 = host.get_viewport_rect()
 # Explicit native-test sample; no player preference, project override or save.
 # The same physical conversion is used for the fixture and mobile OS sample.
 var sample: Variant = host.get_meta("safe_area_test_sample",null)
 if sample is Dictionary:
  var safe: Variant = sample.get("screen_safe_rect",Rect2())
  var transform: Variant = sample.get("viewport_to_screen",host.get_viewport().get_screen_transform())
  if (safe is Rect2 or safe is Rect2i) and transform is Transform2D:
   return content_rect(bounds,Rect2(safe),transform)
  return bounds
 # Desktop usable-screen rectangles describe taskbars/workareas, not a mobile
 # cutout. They must not shrink our larger-than-screen native test windows.
 if not OS.has_feature("mobile"):
  return bounds
 return content_rect(bounds,Rect2(DisplayServer.get_display_safe_area()),host.get_viewport().get_screen_transform())
