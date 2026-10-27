extends RefCounted
## Scene-world palette contract. Never reads wall-clock time, saves or genre.

const FAMILIES := ["tour", "songwriting", "gig", "studio"]
const PHASES := ["day", "dusk", "night"]

static func resolve_phase(context: Dictionary) -> String:
	var explicit := str(context.get("phase", "")).to_lower()
	if PHASES.has(explicit):
		return explicit
	var beat := str(context.get("moment", "")).to_lower()
	if ["showtime", "performance", "encore", "aftershow", "late_recording"].has(beat):
		return "night"
	if ["soundcheck", "arrival", "evening_session", "pre_show", "sunset"].has(beat):
		return "dusk"
	if ["planning", "writing", "rehearsal", "load_in", "morning"].has(beat):
		return "day"
	if context.has("simulated_hour"):
		var hour := clampi(int(context["simulated_hour"]), 0, 23)
		if hour >= 20 or hour < 5:
			return "night"
		if hour >= 17 or hour < 7:
			return "dusk"
	return "day"

static func palette(family: String, phase: String) -> Dictionary:
	var safe_family := family if FAMILIES.has(family) else "studio"
	var safe_phase := phase if PHASES.has(phase) else "day"
	var result: Dictionary = {
		"family": safe_family,
		"phase": safe_phase,
		"accent": Color("#C58A38"),
		"action": Color("#E6AE55"),
		"action_ink": Color("#17252C"),
	}
	match safe_family:
		"tour":
			result["accent"] = Color("#A36B32")
		"songwriting":
			result["accent"] = Color("#8E684C")
		"gig":
			result["accent"] = Color("#B7783A")
		"studio":
			result["accent"] = Color("#4C817E")
	match safe_phase:
		"day":
			result.merge({
				"bg": Color("#ECE7DA"),
				"surface": Color("#F7F3E9"),
				"panel": Color("#E0D8C9"),
				"ink": Color("#17252C"),
				"muted": Color("#4B5860"),
				"border": Color("#B7A994"),
				"hero_veil": Color(0.10, 0.11, 0.12, 0.12),
				"material": "warm paper / daylight / brushed steel",
			})
		"dusk":
			result.merge({
				"bg": Color("#283941"),
				"surface": Color("#34464C"),
				"panel": Color("#1E2F36"),
				"ink": Color("#F5EEE3"),
				"muted": Color("#D7E1DC"),
				"border": Color("#72858B"),
				"hero_veil": Color(0.10, 0.12, 0.14, 0.24),
				"material": "petrol / sunset brass / road-worn steel",
			})
		"night":
			result.merge({
				"bg": Color("#0B1116"),
				"surface": Color("#182329"),
				"panel": Color("#101A20"),
				"ink": Color("#F5EEE3"),
				"muted": Color("#B9C7CC"),
				"border": Color("#4B626A"),
				"hero_veil": Color(0.01, 0.02, 0.04, 0.35),
				"material": "graphite / stage practicals / signal lamps",
			})
	return result

static func relative_luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)

static func contrast_ratio(a: Color, b: Color) -> float:
	var first := relative_luminance(a)
	var second := relative_luminance(b)
	return (maxf(first, second) + 0.05) / (minf(first, second) + 0.05)

static func _linear(v: float) -> float:
	if v <= 0.04045:
		return v / 12.92
	return pow((v + 0.055) / 1.055, 2.4)
