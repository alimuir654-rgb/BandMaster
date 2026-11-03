extends RefCounted
## Exact authored profiles; never substitutes a different musician.
const Jack = preload("res://experiments/playable_flightcase/audition_content.gd")
const Arjun = preload("res://experiments/playable_flightcase/audition_arjun_content.gd")

static func supports(id: String) -> bool:
 return id in ["cast_jack","cast_arjun"]

static func content(id: String) -> Script:
 if id=="cast_jack":return Jack
 if id=="cast_arjun":return Arjun
 return null

static func audio_manifest(id: String) -> String:
 if id=="cast_jack":return "res://experiments/playable_flightcase/audio/audition_clips.json"
 if id=="cast_arjun":return "res://experiments/playable_flightcase/audio/arjun_clips.json"
 return ""
