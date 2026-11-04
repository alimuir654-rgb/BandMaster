extends RefCounted
## Exact authored profiles; never substitutes a different musician.
const Jack = preload("res://experiments/playable_flightcase/audition_content.gd")
const Arjun = preload("res://experiments/playable_flightcase/audition_arjun_content.gd")
const Zoe = preload("res://experiments/playable_flightcase/audition_zoe_content.gd")
const Marcus = preload("res://experiments/playable_flightcase/audition_marcus_content.gd")

static func supports(id: String) -> bool:
 return id in ["cast_jack","cast_arjun","cast_zoe","cast_marcus"]

static func content(id: String) -> Script:
 if id=="cast_jack":return Jack
 if id=="cast_arjun":return Arjun
 if id=="cast_zoe":return Zoe
 if id=="cast_marcus":return Marcus
 return null

static func audio_manifest(id: String) -> String:
 if id=="cast_jack":return "res://experiments/playable_flightcase/audio/audition_clips.json"
 if id=="cast_arjun":return "res://experiments/playable_flightcase/audio/arjun_clips.json"
 if id=="cast_zoe":return "res://experiments/playable_flightcase/audio/zoe_clips.json"
 return ""
