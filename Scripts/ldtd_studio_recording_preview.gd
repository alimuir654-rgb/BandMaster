extends RefCounted
## S06 local-only studio adapter. Real Recording.record/release mechanics.
## Fader/rotary levels are audition-monitor preferences, not fictional output stats.
const Recording = preload("res://Scripts/recording_career.gd")

static func sample_state() -> Dictionary:
	return {
		"band_name":"The Feedback", "tour_day":9, "cash":185,
		"readiness":61, "morale":63, "tension":11, "fans":18,
		"buzz":34, "press":3, "demos":0, "recordings":[],
		"song_catalogue":[
			{"title":"LATE TRAIN","quality":67,"idea":"Lyric","form":"Verse / Chorus"},
			{"title":"SIDE STREET","quality":74,"idea":"Riff","form":"Slow Build"}
		],
		"career_journal":[], "members":[{"name":"Jo","life_status":"active","skill":66}]
	}

static func can_record(state: Dictionary) -> Dictionary:
	return Recording.can_record(state.duplicate(true))

static func preview_record(state: Dictionary) -> Dictionary:
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = Recording.record(before)
	if not bool(result.get("ok",false)):
		return {"ok":false,"message":str(result.get("message","Recording unavailable."))}
	var next: Dictionary = result["state"]
	var sessions: Array = next.get("recordings",[])
	return {
		"ok":true, "message":str(result.get("message","")),
		"cash_cost":int(state.get("cash",0))-int(next.get("cash",0)),
		"days":int(next.get("tour_day",0))-int(state.get("tour_day",0)),
		"readiness_delta":int(next.get("readiness",0))-int(state.get("readiness",0)),
		"quality":int(sessions.back().get("quality",0)) if not sessions.is_empty() else 0,
		"state":next
	}

static func preview_release(state: Dictionary, index: int) -> Dictionary:
	var before: Dictionary = state.duplicate(true)
	var result: Dictionary = Recording.release(before,index)
	if not bool(result.get("ok",false)):
		return {"ok":false,"message":str(result.get("message","Release unavailable."))}
	var next: Dictionary = result["state"]
	return {
		"ok":true, "message":str(result.get("message","")),
		"cash_cost":int(state.get("cash",0))-int(next.get("cash",0)),
		"days":int(next.get("tour_day",0))-int(state.get("tour_day",0)),
		"fans_delta":int(next.get("fans",0))-int(state.get("fans",0)),
		"press_delta":int(next.get("press",0))-int(state.get("press",0)),
		"state":next
	}
