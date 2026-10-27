extends SceneTree
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check(ResourceLoader.exists("res://Art/UI/Tour/road_case_surface.svg"), "road case image-backed surface")
	_check(ResourceLoader.exists("res://Art/UI/Tour/ticket_stock.svg"), "ticket paper image-backed surface")
	var packed: PackedScene = load("res://poc/tour_controls_lab.tscn")
	_check(packed != null, "tour lab scene loads")
	if packed == null:
		quit(1)
		return
	var lab: Control = packed.instantiate()
	get_root().add_child(lab)
	for frame in range(3):
		await process_frame
	_check(lab.stop_id == "bristol", "initial stop is Bristol")
	_check(lab.phase == "day", "initial phase is daylight")
	_check(not lab.van_ready, "van initially unsecured")
	lab.select_stop("cardiff")
	_check(lab.stop_id == "cardiff", "route selection changes stop")
	lab.toggle_van()
	_check(lab.van_ready, "latch toggles state")
	lab.set_context("dusk")
	_check(lab.phase == "dusk" and lab.stop_id == "cardiff" and lab.van_ready, "phase preserves route and latch")
	var dusk_button: Button = lab.find_child("PhaseDusk", true, false)
	_check(dusk_button != null, "dusk control exists")
	if dusk_button != null:
		var style: StyleBoxFlat = dusk_button.get_theme_stylebox("normal")
		var text_ink: Color = dusk_button.get_theme_color("font_color")
		_check(Worlds.contrast_ratio(text_ink, style.bg_color) >= 4.5, "selected dusk button contrast")
	lab.set_context("night")
	_check(lab.phase == "night", "night phase supported")
	lab.set_context("not-a-phase")
	_check(lab.phase == "day", "invalid phase safely defaults to daylight")
	lab.select_stop("not-a-stop")
	_check(lab.stop_id == "cardiff", "invalid route ignored")
	for frame in range(3):
		await process_frame
	var ticket: Label = lab.find_child("TicketDestination", true, false)
	_check(ticket != null and ticket.text == "CARDIFF", "Godot ticket text follows selection")
	var latch: Button = lab.find_child("VanLatch", true, false)
	_check(latch != null and latch.text == "UNLATCH VAN", "hardware latch label follows state")
	lab.preview_plan()
	var status: Label = lab.find_child("TourLabStatus", true, false)
	_check(status != null and status.text.contains("NO SAVE CHANGES"), "preview is explicitly non-mutating")
	_check(Worlds.relative_luminance(Worlds.palette("tour", "day")["bg"]) >
		Worlds.relative_luminance(Worlds.palette("tour", "night")["bg"]) * 7.0, "day visibly brighter")
	lab.queue_free()
	if failed == 0:
		print("TOUR CONTROL LAB TESTS PASSED")
	quit(0 if failed == 0 else 1)

func _check(ok: bool, detail: String) -> void:
	if not ok:
		failed += 1
		push_error("TOUR CONTROL LAB FAILURE: " + detail)
