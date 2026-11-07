extends SceneTree
const Bank = preload("res://Scripts/song_phrase_bank.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Workbench = preload("res://Scripts/song_audio_workbench.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_cmdline_user_args().has("--require-assets"):
		_check(Bank.available("steady-early-v1") and Bank.available("steady-later-v1") and Bank.available(Bank.LEGACY), "all new and archived assets must be installed")
	var state := {"tour_day":1, "cash":200, "members":[{"name":"G","role":"Guitarist"},{"name":"B","role":"Bassist"},{"name":"D","role":"Drummer"}], "unknown_future_field":{"keep":true}}
	var mix := {"source":"steady-early-v1", "parts":{}}
	for role in Bank.ROLES:
		mix["parts"][role] = {"phrase":0, "level_db":-3.0, "breakdown":role == "guitar", "solo":false}
	var result: Dictionary = Practice.compose(state,"Riff","Loose Jam","EARLY SONG",0,mix)
	_check(result.get("ok",false), "first family commits")
	state = JSON.parse_string(JSON.stringify(result["state"]))
	var stored: Dictionary = state["current_song_draft"]["audio_mix"]
	_check(Practice.compose(state,"Riff","Loose Jam","EARLY SONG",0,stored).get("ok",false), "JSON numeric types can refine saved current family")
	_check(state["unknown_future_field"]["keep"], "unknown save fields preserved")
	_check(state["used_song_phrases"].size()==3, "one consumption record per instrument")
	var new_song := state.duplicate(true)
	new_song["current_song_draft"] = {}
	_check(not Bank.choices(new_song,"guitar","steady-early-v1").has(0), "early consumed for another song")
	_check(Bank.choices(new_song,"guitar","steady-later-v1").has(0), "later independent of early with same phrase index")
	_check(Bank.choices(new_song,"guitar").size()==3, "old bank remains untouched")
	var bad := mix.duplicate(true)
	bad["source"] = "unavailable-source"
	var before := JSON.stringify(state)
	_check(not Practice.compose(state,"Riff","Loose Jam","EARLY SONG",0,bad).get("ok",true), "unknown source rejected")
	_check(JSON.stringify(state)==before, "rejection consumes nothing")
	_check(Bank.asset("guitar",0)=="res://Audio/Songwriting/Rehearsam/guitar_0.wav", "legacy asset path unchanged")
	_check(Bank.usage_key("owner","guitar",0)=="owner|guitar:0", "legacy consumption key unchanged")
	if Bank.available("steady-early-v1"):
		print("Testing imported Steady Hundred audio and family selector")
		var desk = Workbench.new()
		desk.state = state.duplicate(true)
		desk.initial_mix = stored.duplicate(true)
		root.add_child(desk)
		await process_frame
		_check(desk.source_id=="steady-early-v1", "draft restores exact source")
		for i in range(3):
			_check(desk.sync.get_sync_stream(i).data.size()==460800*4, "new family imports exact aligned frame count")
		desk._apply_levels(4.77)
		_check(desk.sync.get_sync_stream_volume(0)==-3, "new breakdown does not use legacy midpoint")
		desk._apply_levels(4.81)
		_check(is_inf(desk.sync.get_sync_stream_volume(0)), "new breakdown follows 9.6-second family")
		for i in range(desk.family_selector.item_count):
			if desk.family_selector.get_item_metadata(i)=="steady-later-v1":
				desk.family_selector.select(i)
				desk.family_selector.item_selected.emit(i)
		_check(desk.selection()["source"]=="steady-later-v1", "selector updates committed source")
		_check(is_equal_approx(desk.player.stream.get_length(),9.6), "new family transport duration")
		desk.free()
		await create_timer(.1).timeout
	if failures==0:
		print("STEADY PHRASE TESTS PASSED")
	quit(0 if failures==0 else 1)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures+=1
		push_error(message)
