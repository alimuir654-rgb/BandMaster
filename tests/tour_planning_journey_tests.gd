extends SceneTree
const Model = preload("res://Scripts/tour_planning_poc_model.gd")
const Itinerary = preload("res://Scripts/tour_itinerary.gd")
const Circuit = preload("res://Scripts/uk_gig_circuit.gd")
const Worlds = preload("res://Scripts/scene_world_theme.gd")
var failed := 0

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var state := Model.sample_state()
 var untouched := state.duplicate(true)
 var cardiff: Dictionary = Circuit.get_venue("cardiff")
 _check(not cardiff.is_empty(),"real circuit venue exists")
 var drive := Itinerary.preview(state,"cardiff",Itinerary.DRIVE)
 var room := Itinerary.preview(state,"cardiff",Itinerary.OVERNIGHT)
 _check(Model.options(state,"cardiff").size() == 2,"real engine offers drive and room")
 _check(int(room["total_cost"]) > int(drive["total_cost"]),"room costs more than drive")
 _check(int(room["fatigue_delta"]) < int(drive["fatigue_delta"]),"room reduces fatigue")
 _check(not bool(Model.preview(state,"cardiff",Itinerary.DRIVE,false).get("ok",false)),"unsecured van blocks preview")
 var preview := Model.preview(state,"cardiff",Itinerary.OVERNIGHT,true)
 _check(bool(preview.get("ok",false)),"secured and affordable room previews")
 _check(int(preview.get("cash_after_costs",-1)) == int(state["cash"])-int(room["total_cost"]),"cash preview from engine tariff")
 _check(int(preview.get("van_after",-1)) == int(state["van_health"])-int(room["van_wear"]),"van wear from engine")
 _check(state == untouched,"preview never mutates input")
 var broke := state.duplicate(true)
 broke["van_health"] = 1
 _check(not bool(Model.preview(broke,"cardiff",Itinerary.DRIVE,true).get("ok",false)),"low van condition rejected")
 broke = state.duplicate(true)
 broke["cash"] = 1
 _check(not bool(Model.preview(broke,"cardiff",Itinerary.OVERNIGHT,true).get("ok",false)),"insufficient cash rejected")
 _check(not bool(Model.preview(state,"bath",Itinerary.DRIVE,true).get("ok",false)),"invented venue rejected")
 var confirmed := Model.commit(state,"cardiff",Itinerary.OVERNIGHT,true)
 _check(bool(confirmed.get("ok",false)),"first commit works")
 var next: Dictionary = confirmed.get("state",{})
 _check(bool(next.get("booked_show",{}).get("plan_confirmed",false)),"confirmed plan recorded in local copy")
 _check(str(next["booked_show"]["travel_plan"]) == Itinerary.OVERNIGHT,"selected room retained")
 _check(int(next["cash"]) == int(state["cash"]) and int(next["van_health"]) == int(state["van_health"]) and int(next["tour_day"]) == int(state["tour_day"]),"confirmation does not prematurely charge show cost/day/wear")
 _check(state == untouched,"commit leaves source unchanged")
 _check(not bool(Model.commit(next,"cardiff",Itinerary.OVERNIGHT,true).get("ok",false)),"second commit rejected")
 _check(Worlds.resolve_phase({"moment":"planning"}) == "day" and Worlds.resolve_phase({"moment":"arrival"}) == "dusk","journey phases from simulation context")
 var packed: PackedScene = load("res://poc/tour_planning_journey.tscn")
 _check(packed != null,"Godot journey scene loads")
 if packed == null:
  quit(1)
  return
 var view: Control = packed.instantiate()
 get_root().add_child(view)
 for i in range(4):
  await process_frame
 _check(view.stage == "plan" and view.phase == "day","initial daylight planning")
 _check(view.venue_id == "cardiff","sample route selected")
 view.choose_plan(Itinerary.OVERNIGHT)
 view.review_journey()
 _check(view.stage == "plan" and view.message.contains("Secure"),"unsecured load cannot review")
 view.toggle_van()
 view.review_journey()
 _check(view.stage == "review" and view.phase == "day","review remains daylight")
 view.back_to_plan()
 _check(view.stage == "plan" and view.demo_state == Model.sample_state(),"cancel preserves sample cash and gear")
 view.review_journey()
 view.confirm_journey()
 _check(view.stage == "arrival" and view.phase == "dusk","confirmed arrival transitions to dusk")
 _check(int(view.demo_state["cash"]) == 135,"no cash spent on itinerary preview")
 var ticket: Label = view.find_child("JourneyTicketVenue",true,false)
 _check(ticket != null and ticket.text == "THE CELLAR STAGE","ticket uses actual UK circuit venue")
 view.confirm_journey()
 _check(int(view.demo_state["cash"]) == 135,"repeat confirm cannot charge")
 view.restart_demo()
 _check(view.stage == "plan" and view.phase == "day" and not view.van_ready,"reset returns to daylight")
 view.queue_free()
 if failed == 0:
  print("TOUR PLANNING JOURNEY TESTS PASSED")
 quit(0 if failed == 0 else 1)

func _check(ok: bool,detail: String) -> void:
 if not ok:
  failed += 1
  push_error("TOUR JOURNEY FAILURE: "+detail)
