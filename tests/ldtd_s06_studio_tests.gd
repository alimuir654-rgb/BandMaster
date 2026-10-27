extends SceneTree
## S06 authoritative recording/release and inert read-only meter regression.
const Model = preload("res://Scripts/ldtd_studio_recording_preview.gd")
const Recording = preload("res://Scripts/recording_career.gd")
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _check(ok: bool,detail: String) -> void:
	if not ok:
		failures += 1
		push_error("S06 FAILURE: "+detail)
func _run() -> void:
	var original: Dictionary = Model.sample_state()
	var original_json: String = JSON.stringify(original)
	_check(bool(Model.can_record(original).get("ok",false)),"two originals and £185 allow demo")
	var insufficient: Dictionary = original.duplicate(true)
	insufficient["cash"] = 59
	_check(not bool(Model.can_record(insufficient).get("ok",false)),"£59 cannot pay for recording")
	var one_song: Dictionary = original.duplicate(true)
	one_song["song_catalogue"] = [one_song["song_catalogue"][0]]
	_check(not bool(Model.can_record(one_song).get("ok",false)),"one original cannot make a demo")
	var recording: Dictionary = Model.preview_record(original)
	_check(bool(recording.get("ok",false)),"authoritative Recording.record preview")
	var recorded: Dictionary = recording.get("state",{})
	_check(int(recording.get("cash_cost",0))==Recording.DEMO_COST,"recording uses real £60 cost")
	_check(int(recording.get("days",0))==Recording.RECORD_DAYS,"recording takes real two days")
	_check(int(recorded.get("cash",0))==125 and int(recorded.get("tour_day",0))==11,"cash/day state correct")
	_check(recorded.get("recordings",[]).size()==1 and recorded.get("recordings",[])[0].get("tracks",[]).size()==2,"two real tracks in demo")
	_check(int(recording.get("quality",0))==71,"song quality is authoritative, not fader-controlled")
	_check(not bool(Model.can_record(recorded).get("ok",false)),"same songs cannot be recorded twice")
	var release: Dictionary = Model.preview_release(recorded,0)
	_check(bool(release.get("ok",false)),"real Recording.release preview")
	var released: Dictionary = release.get("state",{})
	_check(int(release.get("cash_cost",0))==Recording.RELEASE_COST and int(release.get("days",0))==1,"real £25 and one day release")
	_check(bool(released.get("recordings",[])[0].get("released",false)),"released demo flagged")
	_check(int(released.get("fans",0))>int(recorded.get("fans",0)) and int(released.get("press",0))>int(recorded.get("press",0)),"real release reaches listeners")
	_check(not bool(Model.preview_release(released,0).get("ok",false)),"cannot release twice")
	_check(JSON.stringify(original)==original_json,"source deep copy never mutated")
	var scene: PackedScene = load("res://poc/ldtd_studio_recording.tscn")
	_check(scene!=null,"runnable studio scene imports")
	if scene==null:
		quit(1)
		return
	var view: Control = scene.instantiate()
	get_root().add_child(view)
	for i in range(9):
		await process_frame
	_check(view.stage=="ready" and view.phase=="day","genuine bright DAY first phase")
	var before: String = JSON.stringify(view.demo_state)
	view.set_monitor_level("guitar",0.0)
	view.set_monitor_level("vocal",100.0)
	view.set_monitor_level("headphones",20.0)
	_check(JSON.stringify(view.demo_state)==before,"faders and rotary do not edit career state")
	var meter = view._controls.get("meter")
	_check(meter!=null and meter.focus_mode==Control.FOCUS_NONE and meter.mouse_filter==Control.MOUSE_FILTER_IGNORE,"outcome meter inert")
	_check(int(meter.reading)==int(view.demo_state.get("readiness",0)),"meter reads authoritative readiness")
	view.record_demo()
	_check(view.stage=="ready" and view.record_count==0,"cannot record without transport arm")
	view.arm_transport(true)
	for i in range(5):
		await process_frame
	view.record_demo()
	for i in range(8):
		await process_frame
	_check(view.stage=="recorded" and view.phase=="dusk" and view.record_count==1,"two-day demo recorded once")
	_check(int(view.demo_state.get("cash",0))==125 and view.demo_state.get("recordings",[]).size()==1,"real local record outcome")
	view.record_demo()
	_check(view.record_count==1,"duplicate record prevented")
	view.release_demo()
	for i in range(8):
		await process_frame
	_check(view.stage=="released" and view.phase=="night" and view.release_count==1,"local release terminal")
	_check(int(view.demo_state.get("cash",0))==100,"£60 plus £25 charged once")
	var terminal: String = JSON.stringify(view.demo_state)
	view.release_demo()
	view.record_demo()
	_check(view.release_count==1 and view.record_count==1 and JSON.stringify(view.demo_state)==terminal,"no repeat settlement")
	_check(JSON.parse_string(terminal) is Dictionary,"result remains JSON-compatible")
	var source: String = FileAccess.get_file_as_string("res://poc/ldtd_studio_recording.gd")
	var executable: String = ""
	for line in source.split("\n"):
		var trimmed: String = line.strip_edges()
		if not trimmed.begins_with("#"):
			executable += trimmed+"\n"
	_check(not executable.contains("FileAccess.open(") and not executable.contains("user://") and not executable.contains("SaveService"),"no production save writes")
	view.queue_free()
	if failures>0:
		push_error("S06 FAILED: %d checks" % failures)
		quit(1)
	else:
		print("LDTD S06 STUDIO PHOTOGRAPHIC CONTROLS, REAL RECORD AND ONCE-ONLY RELEASE PASSED")
		quit(0)
