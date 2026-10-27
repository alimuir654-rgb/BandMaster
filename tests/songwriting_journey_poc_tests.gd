extends SceneTree
const Model = preload("res://Scripts/songwriting_journey_preview.gd")
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var seed: Dictionary = Model.sample_state()
	var original: String = JSON.stringify(seed)
	var bad_title: Dictionary = Model.simulate(seed, "Lyric", "Verse / Chorus", "NO", 0)
	_check(not bool(bad_title.get("ok", false)), "title length rejected before any time charge")
	var unavailable: Dictionary = seed.duplicate(true)
	unavailable["members"][0]["life_status"] = "away"
	var invalid_lead: Dictionary = Model.simulate(unavailable, "Lyric", "Verse / Chorus", "LATE TRAIN", 0)
	_check(not bool(invalid_lead.get("ok", false)), "inactive musician rejected before spending a day")
	var unknown: Dictionary = Model.simulate(seed, "Unknown", "Verse / Chorus", "LATE TRAIN", 0)
	_check(not bool(unknown.get("ok", false)), "unknown creative idea rejected")
	var s1: Dictionary = Model.simulate(seed, "Lyric", "Verse / Chorus", "LATE TRAIN", 0)
	_check(bool(s1.get("ok", false)) and int(s1.get("days", -1)) == 1 and int(s1.get("cash", 999)) == 0, "first writing session costs one day, no cash")
	_check(int(s1.get("progress", 0)) == 1 and not bool(s1.get("finished", true)), "first session is a draft")
	_check(JSON.stringify(seed) == original, "preview never mutates original input")
	var s2: Dictionary = Model.simulate(s1["state"], "Lyric", "Slow Build", "LATE TRAIN", 1)
	_check(bool(s2.get("ok", false)) and int(s2.get("progress", 0)) == 2, "second writing session advances draft")
	var s3: Dictionary = Model.simulate(s2["state"], "Groove", "Verse / Chorus", "LATE TRAIN", 2)
	_check(bool(s3.get("ok", false)) and bool(s3.get("finished", false)), "third session finishes a real original")
	var final_state: Dictionary = s3["state"]
	var catalogue: Array = final_state.get("song_catalogue", [])
	_check(catalogue.size() == 1 and int(final_state.get("song_draft_progress", -1)) == 0, "finished song in real catalogue, progress reset")
	if not catalogue.is_empty():
		var song: Dictionary = catalogue[0]
		_check(str(song.get("title", "")) == "LATE TRAIN", "original keeps chosen title")
		_check(str(song.get("lead_writer", "")) == "Kit", "last session lead recorded from actual roster")
		_check(song.get("writing_sessions", []).size() == 3, "all three writing sessions preserved")
	var duplicate: Dictionary = Model.simulate(final_state, "Riff", "Loose Jam", "LATE TRAIN", 0)
	_check(not bool(duplicate.get("ok", false)), "finished song title duplicate rejected before day spend")
	_check(int(final_state.get("tour_day", 0)) == 10, "exactly three writing days elapsed")
	_check(JSON.stringify(final_state).contains("writing_sessions"), "finished state JSON-serializable")

	var packed: PackedScene = load("res://poc/songwriting_journey_poc.tscn")
	_check(packed != null, "journey scene imports")
	if packed == null:
		quit(1)
		return
	var journey: Control = packed.instantiate()
	get_root().add_child(journey)
	for i in range(4):
		await process_frame
	_check(journey.stage == 0 and journey.phase == "day", "daylight spark is first stage")
	_check(journey.local_state.get("song_catalogue", []).is_empty(), "isolated scene starts without songs")
	journey.set_phase("dusk")
	journey.set_phase("day")
	_check(journey.title == "LATE TRAIN, LAST CHANCE", "day/dusk roundtrip preserves typed title")
	journey.set_title("LATE TRAIN")
	journey.advance()
	_check(journey.stage == 1, "spark advances to arrangement")
	journey.choose_form("Slow Build")
	journey.choose_leader(1)
	journey.choose_feel("SWELL")
	journey.set_bpm(138)
	journey.choose_part("BRIDGE")
	journey.append_part()
	journey.set_phase("dusk")
	_check(journey.stage == 1 and journey.sections.size() == 5 and journey.bpm == 138 and journey.form == "Slow Build", "arrangement controls survive phase change")
	journey.advance()
	_check(journey.stage == 2, "arrangement advances to songsheet")
	var before_day := int(journey.local_state.get("tour_day", 0))
	var preview: Dictionary = journey.session_preview()
	_check(bool(preview.get("ok", false)) and int(journey.local_state.get("tour_day", 0)) == before_day, "review previews actual rules without charging")
	journey.go_back()
	_check(journey.stage == 1 and journey.form == "Slow Build", "back preserves selection")
	journey.advance()
	journey.commit_session()
	_check(journey.stage == 0 and journey.commits == 1 and int(journey.local_state.get("tour_day", 0)) == before_day + 1, "first commit charges one day locally")
	for i in range(2):
		journey.advance()
		journey.advance()
		journey.commit_session()
	_check(journey.stage == 3 and journey.commits == 3, "three sessions produce song sleeve")
	_check(journey.local_state.get("song_catalogue", []).size() == 1, "journey uses real song catalogue")
	var result_title: Label = journey.find_child("ResultTitle", true, false)
	_check(result_title != null and result_title.text == "LATE TRAIN", "result shows real finished song")
	journey.commit_session()
	_check(journey.commits == 3, "repeated commit on result does not charge another day")
	journey.advance()
	_check(journey.stage == 0 and journey.phase == "day" and journey.local_state.get("song_catalogue", []).size() == 1, "new song preserves finished local catalogue")
	journey.set_title("LATE TRAIN")
	journey.advance()
	journey.advance()
	var dup_preview: Dictionary = journey.session_preview()
	_check(not bool(dup_preview.get("ok", false)), "duplicate new-song title blocks review commit")
	_check(Worlds.relative_luminance(Worlds.palette("songwriting", "day")["bg"]) > Worlds.relative_luminance(Worlds.palette("songwriting", "dusk")["bg"]) * 7.0, "day is substantially lighter than dusk")
	journey.queue_free()
	if failures == 0:
		print("SONGWRITING JOURNEY TESTS PASSED")
	quit(0 if failures == 0 else 1)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error("SONGWRITING JOURNEY FAILURE: " + detail)
