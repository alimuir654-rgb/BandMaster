extends SceneTree
const Model = preload("res://Scripts/ldtd_tour_planning_preview.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		push_error("S04 FAILURE: " + reason)

func _run() -> void:
	var state: Dictionary = Model.sample_state()
	var before: String = JSON.stringify(state)
	_check(Model.options(state,"bristol").size()==2, "real regional venue offers two journeys")
	_check(Model.options(state,"cardiff").size()==2, "second real venue offers two journeys")
	_check(Model.options(state,"unknown").is_empty(), "unknown venue rejected")
	_check(int(Tour.preview(state,"bristol",Tour.OVERNIGHT).get("accommodation_cost",-1))==32, "tier-one room is real £32 gameplay tariff")
	_check(not bool(Model.preview(state,"bristol",Tour.DRIVE,false).get("ok",true)), "unsecured load prevents booking")
	var day: Dictionary = Model.preview(state,"bristol",Tour.DRIVE,true)
	var room: Dictionary = Model.preview(state,"bristol",Tour.OVERNIGHT,true)
	_check(bool(day.get("ok",false)) and bool(room.get("ok",false)), "both routes validate with secured load")
	_check(int(room.get("cash_after_costs",-1))==int(day.get("cash_after_costs",-1))-32, "overnight preview includes room once")
	_check(int(day.get("van_after",-1))==24, "route reflects real van wear 6")
	_check(int(room.get("gear_condition",-1))==74, "amp condition from actual GearShop record")
	_check(int(day.get("show_day",-1))==8, "calendar uses three prep days")
	_check(JSON.stringify(state)==before, "all previews leave caller unmodified")
	var booked: Dictionary = Model.commit(state,"bristol",Tour.OVERNIGHT,true)
	_check(bool(booked.get("ok",false)), "authoritative calendar accepts confirmed journey")
	if bool(booked.get("ok",false)):
		var next: Dictionary = booked["state"]
		_check(int(next.get("cash",-1))==135 and int(next.get("tour_day",-1))==5 and int(next.get("van_health",-1))==30, "booking does not charge travel or advance time or damage van")
		_check(next.get("gig_history",[]).is_empty(), "planning does not play gig")
		_check(int(next.get("booked_show",{}).get("day",-1))==8, "real Calendar lead days not invented two-day booking")
		_check(str(next.get("booked_show",{}).get("travel_plan",""))==Tour.OVERNIGHT, "real booking retains selected plan")
		_check(not bool(Model.commit(next,"bristol",Tour.OVERNIGHT,true).get("ok",true)), "repeat booking rejected")
		_check(JSON.stringify(state)==before, "commit deep copies source state")
		var changed: Dictionary = Calendar.replan(next,Tour.DRIVE)
		_check(bool(changed.get("ok",false)) and int(changed.get("state",{}).get("cash",-1))==135, "future replan can change travel without charging")
	var broke: Dictionary = state.duplicate(true)
	broke["cash"] = 20
	_check(not bool(Model.preview(broke,"bristol",Tour.OVERNIGHT,true).get("ok",true)), "unaffordable overnight blocked")
	broke["cash"] = 135
	broke["van_health"] = 1
	_check(not bool(Model.commit(broke,"bristol",Tour.DRIVE,true).get("ok",true)), "unsafe van cannot be booked")
	var scene: PackedScene = load("res://poc/ldtd_tour_planning.tscn")
	_check(scene != null, "S04 actual Godot scene imports")
	if scene == null:
		quit(1)
		return
	var view: Control = scene.instantiate()
	get_root().add_child(view)
	for i in range(12):
		await process_frame
	_check(view.stage=="planning" and view.commits==0, "starts unbooked")
	var cork: TextureRect = view.find_child("PhotographedTourCork",true,false)
	var photo: TextureRect = view.find_child("RepoBackedTourHomePhoto",true,false)
	var sheet: TextureRect = view.find_child("OriginalClippedItinerarySheet",true,false)
	var primary: TextureButton = view.find_child("TourConfirmBooking",true,false)
	var stats: Label = view.find_child("ReadOnlyTourStats",true,false)
	_check(cork!=null and cork.texture!=null and photo!=null and photo.texture!=null, "source-backed photographed cork and repo photo")
	_check(sheet!=null and sheet.texture!=null, "original clipped itinerary sheet is imported")
	_check(primary!=null and primary.texture_normal!=null and primary.texture_hover!=null and primary.texture_disabled!=null, "original purpose-made booking stamp texture states")
	_check(stats!=null and stats.focus_mode==Control.FOCUS_NONE, "stats cannot be edited")
	_check(view._choice_buttons.has("VenueBristol") and view._choice_buttons.has("Journeyovernight") and view._choice_buttons.has("SecureVanLoad"), "real venue route and van choices rendered")
	_check(primary.disabled, "booking disabled before securing van")
	view.choose_plan(Tour.OVERNIGHT)
	for i in range(3):
		await process_frame
	view.toggle_load()
	for i in range(4):
		await process_frame
	primary = view.find_child("TourConfirmBooking",true,false)
	_check(primary!=null and not primary.disabled, "valid route enables native booking stamp")
	var chosen: TextureButton = view._choice_buttons.get("Journeyovernight")
	_check(chosen!=null and chosen.texture_hover==chosen.texture_normal, "selected journey remains latched on hover")
	view.commit_plan()
	for i in range(7):
		await process_frame
	_check(view.stage=="confirmed" and view.commits==1, "booking confirms exactly once")
	_check(int(view.local_state.get("cash",-1))==135 and int(view.local_state.get("tour_day",-1))==5, "scene did not charge or advance calendar")
	var confirmed: String = JSON.stringify(view.local_state)
	view.commit_plan()
	_check(view.commits==1 and JSON.stringify(view.local_state)==confirmed, "second press cannot rebook")
	var source: String = FileAccess.get_file_as_string("res://poc/ldtd_tour_planning.gd")
	_check(not source.contains("FileAccess.open(") and not source.contains("Calendar.perform("), "scene has no production persistence or show settlement")
	view.queue_free()
	if failures>0:
		push_error("S04 FAILED: %d checks" % failures)
		quit(1)
	else:
		print("LDTD S04 TOUR MODEL, VAN LOAD AND ONCE-ONLY BOOKING TESTS PASSED")
		quit(0)
