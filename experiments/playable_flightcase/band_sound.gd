extends RefCounted
## Confirmed creative direction; no inference from spelling, portraits or biography.
const KEY := "band_sound_v1"
const INTENTS := ["Raw","Dark","Playful","Dreamy"]
const VIBES := ["Unpolished","Nocturnal","Wry","Atmospheric"]

static func make(genre: String,intent: String,vibe: String) -> Dictionary:
 if intent not in INTENTS or vibe not in VIBES or genre.is_empty():return {}
 return {"genre":genre,"name_intent":intent,"vibe":vibe}

static func valid(value: Variant) -> bool:
 return value is Dictionary and value.size()==3 and value.get("genre") is String and not value.genre.is_empty() and value.get("name_intent") is String and value.name_intent in INTENTS and value.get("vibe") is String and value.vibe in VIBES

static func read(state: Dictionary) -> Dictionary:
 var value: Variant=state.get(KEY)
 return value.duplicate(true) if valid(value) else {}

static func supported(value: Variant) -> bool:
 return valid(value) and value.genre=="Indie rock" and (value.name_intent in ["Raw","Dark"] or value.vibe in ["Unpolished","Nocturnal"])

static func summary(value: Dictionary) -> String:
 return "%s · %s · %s" % [value.genre,value.name_intent,value.vibe] if valid(value) else "Sound direction not recorded"
