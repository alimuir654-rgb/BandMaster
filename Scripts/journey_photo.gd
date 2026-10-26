extends RefCounted
# Photographic scene routing. Only real, importable, scene-specific WebP files
# override the illustrated fallback. No remote image requests at runtime.
const SONG_SCENES := ["spark", "vibe", "jam", "songsheet"]
const SHOW_SCENES := ["load_van", "on_road", "venue_arrival", "soundcheck", "backstage"]

static func scene_path(journey: String, index: int, viewport_width: float) -> String:
 var names: Array = SONG_SCENES if journey == "songwriting" else (SHOW_SCENES if journey == "showday" else [])
 if index < 0 or index >= names.size():
  return ""
 var aspect := "wide" if viewport_width >= 960.0 else "portrait"
 var candidate := "res://Art/Photography/approved/%s_%s.webp" % [names[index], aspect]
 return candidate if ResourceLoader.exists(candidate) else ""

static func scene_or_fallback(journey: String, index: int, viewport_width: float, fallback: String) -> String:
 var photo := scene_path(journey, index, viewport_width)
 return photo if not photo.is_empty() else fallback
