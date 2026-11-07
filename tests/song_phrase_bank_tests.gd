extends SceneTree
const Practice = preload("res://Scripts/practice_room.gd")
const Bank = preload("res://Scripts/song_phrase_bank.gd")
const Workbench = preload("res://Scripts/song_audio_workbench.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := {"cash":200,"tour_day":1,"morale":60,"reputation":10,"readiness":40,"tension":10,"van_health":80,"members":[{"name":"Jo","role":"Drummer","skill":50,"trait":"Reliable"},{"name":"Alex","role":"Guitarist","skill":50,"trait":"Creative"},{"name":"Sam","role":"Bassist","skill":50,"trait":"Reliable"}]}
	var mix := {"parts":{}}
	for role in Bank.ROLES:
		mix["parts"][role] = {"phrase":0,"level_db":-3.0,"breakdown":role=="guitar","solo":false}
	var original := JSON.stringify(state)
	var invalid := mix.duplicate(true)
	invalid["parts"]["bass"]["phrase"] = 99
	_check(not Practice.compose(state,"Riff","Loose Jam","FIRST",1,invalid)["ok"], "invalid phrase rejects entire session")
	_check(JSON.stringify(state)==original, "rejected session preserves input")
	for session in range(3):
		var result: Dictionary = Practice.compose(state,"Riff","Loose Jam","FIRST",1,mix)
		_check(result.get("ok",false), "draft can keep and refine its own used phrases")
		state = JSON.parse_string(JSON.stringify(result["state"]))
	_check(int(state["tour_day"])==4, "three commits use exactly three existing session days")
	_check(state["used_song_phrases"].size()==3, "refining a draft does not consume repeatedly")
	_check(state["song_catalogue"][-1]["audio_mix"]["parts"]["guitar"]["breakdown"], "completed song retains arrangement")
	_check(not Bank.choices(state,"guitar").has(0), "finished song's phrase unavailable to a new song")
	_check(not Practice.compose(state,"Riff","Loose Jam","SECOND",1,mix)["ok"], "used phrase rejected across songs")
	state["members"].reverse()
	_check(not Bank.choices(state,"guitar").has(0), "character bank survives roster reordering")
	for member in state["members"]:
		if member["role"]=="Guitarist":
			member["life_status"]="departed"
	state["members"].append({"name":"New guitarist","role":"Guitarist"})
	_check(Bank.choices(state,"guitar").has(0), "new character has an independent bank")
	if Bank.available():
		var desk = Workbench.new()
		desk.state = state.duplicate(true)
		desk.initial_mix = state["song_catalogue"][-1]["audio_mix"].duplicate(true)
		desk.read_only = true
		root.add_child(desk)
		await process_frame
		_check(not desk.play_button.disabled, "finished song can still load consumed phrases")
		for index in range(3):
			_check(desk.sync.get_sync_stream(index).data.size()==455040*4, "synchronized candidate has exact aligned frame count")
		desk._apply_levels(6)
		_check(is_inf(desk.sync.get_sync_stream_volume(0)), "breakdown silences guitar in second half")
		desk._apply_levels(0)
		_check(desk.sync.get_sync_stream_volume(0)==-3, "restart restores full arrangement")
		desk.free()
		await create_timer(.1).timeout
		var path := "user://tour_save.json"
		var existed := FileAccess.file_exists(path)
		var old := FileAccess.get_file_as_string(path) if existed else ""
		var fixture := state.duplicate(true)
		fixture["band"] = {"name":"Phrase Test Band", "members":state["members"].duplicate(true)}
		fixture["career_extra"] = state.duplicate(true)
		fixture["current_event"] = "aftershow"
		fixture["pending_next"] = ""
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(fixture))
		file.close()
		var hub = load("res://Scenes/CareerHub.tscn").instantiate()
		root.add_child(hub)
		hub.tab = "ACTIONS"
		hub.action_view = "JAM"
		hub._render()
		await process_frame
		var before := FileAccess.get_file_as_string(path)
		var audio
		for child in hub.find_children("*", "VBoxContainer", true, false):
			if child.get_script() == Workbench:
				audio = child
		_check(audio != null, "main songwriting screen exposes phrase workbench")
		if audio != null:
			audio.enabled.button_pressed = true
			audio.play_button.pressed.emit()
			await create_timer(.15).timeout
			_check(FileAccess.get_file_as_string(path)==before, "preview does not save or consume")
			hub.find_child("CommitSongSession", true, false).pressed.emit()
			var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			_check(int(saved["tour_day"])==5, "real UI commit spends one day")
			_check(saved["career_extra"]["used_song_phrases"].size()==6, "real UI commit saves consumption")
		hub.free()
		if existed:
			file = FileAccess.open(path, FileAccess.WRITE)
			file.store_string(old)
			file.close()
		else:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		await create_timer(.1).timeout
	if failures==0:
		print("SONG PHRASE BANK TESTS PASSED")
	quit(0 if failures==0 else 1)

func _check(ok: bool, reason: String) -> void:
	if not ok:
		failures+=1
		push_error(reason)
