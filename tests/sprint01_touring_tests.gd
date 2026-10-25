extends SceneTree
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
var failures := 0

func _initialize() -> void:
 var state := {"cash":180,"tour_day":5,"morale":60,"tension":10,"readiness":80,"van_health":80,"reputation":45,"fans":80,"songs":3,"members":[{"name":"Lee","role":"drummer","life_status":"active","fatigue":40},{"name":"Jo","role":"guitarist","life_status":"active","fatigue":40}],"gig_history":[]}
 var options: Array = Tour.choices(state,"bristol")
 _check(options.size()==2,"regional venue has two touring choices")
 _check(int(options[1]["accommodation_cost"])==32,"tier 1 room has deterministic £32 tariff")
 _check(int(options[1]["total_cost"])==int(options[0]["total_cost"])+32,"room is additive to travel")
 _check(Tour.choices(state,"local").size()==1,"hometown has no overnight room")
 _check(Tour.preview(state,"local",Tour.OVERNIGHT).is_empty(),"hometown cannot book a room")
 _check(Tour.preview(state,"bristol","invented").is_empty(),"unknown plan rejected")
 var booked: Dictionary = Promoter.book(state,"bristol","standard",false,Tour.OVERNIGHT)
 _check(bool(booked.get("ok",false)),"promoter can book overnight journey")
 if not bool(booked.get("ok",false)):
  quit(1)
  return
 var next: Dictionary = booked["state"]
 _check(str(next["booked_show"]["travel_plan"])==Tour.OVERNIGHT,"booking persists plan")
 _check(next["cash"]==state["cash"],"booking is not charged prematurely")
 _check(Tour.timeline(next).size()==4,"calendar has 3 prep days plus show day")
 var changed: Dictionary = Calendar.replan(next,Tour.DRIVE)
 _check(bool(changed.get("ok",false)),"can change plan without spending a day")
 _check(int(changed["state"]["tour_day"])==5,"replanning does not advance clock")
 _check(str(next["booked_show"]["travel_plan"])==Tour.OVERNIGHT,"replan leaves input untouched")
 var low := state.duplicate(true)
 low["cash"] = 30
 _check(not bool(Calendar.book(low,"bristol","tight",false,Tour.OVERNIGHT).get("ok",true)),"unaffordable room blocked at booking")
 _check(bool(Calendar.book(low,"bristol","tight",false,Tour.DRIVE).get("ok",false)),"affordable day trip allowed")
 low["van_health"] = 1
 _check(not bool(Calendar.book(low,"bristol").get("ok",true)),"unsafe van blocked")
 var night := next.duplicate(true)
 night["tour_day"] = int(night["booked_show"]["day"])
 night["gig_night_phase"] = "arrival"
 _check(bool(Calendar.replan(night,Tour.DRIVE).get("ok",false)),"arrival can replan")
 night["gig_night_phase"] = "soundcheck"
 _check(not bool(Calendar.replan(night,Tour.DRIVE).get("ok",true)),"cannot replan after arrival")
 var played: Dictionary = Calendar.perform(night)
 _check(bool(played.get("ok",false)),"overnight show performs")
 if bool(played.get("ok",false)):
  var settled: Dictionary = played["state"]
  var history: Dictionary = settled["gig_history"].back()
  _check(int(history["accommodation_cost"])==32,"hotel charged exactly once in history")
  _check(str(history["travel_plan"])==Tour.OVERNIGHT,"history records chosen plan")
  _check(int(settled["members"][0]["fatigue"])==35,"overnight reduces musician fatigue")
  _check(settled["booked_show"].is_empty(),"show cannot be replayed")
  _check(not bool(Calendar.perform(settled).get("ok",true)),"second settlement rejected")
 var day_trip: Dictionary = changed["state"].duplicate(true)
 day_trip["tour_day"] = int(day_trip["booked_show"]["day"])
 var drive: Dictionary = Calendar.perform(day_trip)
 _check(bool(drive.get("ok",false)),"drive-home show performs")
 if bool(drive.get("ok",false)) and bool(played.get("ok",false)):
  _check(int(drive["state"]["cash"])==int(played["state"]["cash"])+32,"overnight costs exactly the room tariff")
  _check(int(drive["state"]["members"][0]["fatigue"])==47,"late drive increases fatigue")
  _check(int(played["state"]["morale"])>int(drive["state"]["morale"]),"overnight recovers morale")
 var legacy := next.duplicate(true)
 legacy["booked_show"].erase("travel_plan")
 legacy["tour_day"] = int(legacy["booked_show"]["day"])
 var old: Dictionary = Calendar.perform(legacy)
 _check(bool(old.get("ok",false)),"legacy booking without plan still works")
 if bool(old.get("ok",false)):
  _check(not old["state"]["gig_history"].back().has("accommodation_cost"),"legacy booking has no invented hotel bill")
 var broke := night.duplicate(true)
 broke["cash"] = 35
 _check(not bool(Calendar.perform(broke).get("ok",true)),"can't run overnight without room money")
 _check(int(broke["cash"])==35,"failed show leaves input untouched")
 var stranded := night.duplicate(true)
 stranded["cash"] = 0
 var cancelled: Dictionary = Calendar.cancel(stranded)
 _check(bool(cancelled.get("ok",false)),"stranded band can cancel a booked show")
 if bool(cancelled.get("ok",false)):
  _check(cancelled["state"]["booked_show"].is_empty(),"cancellation clears booking")
 var ui_source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(ui_source.contains('source != "booking_cancel"'),"show-day guard permits emergency cancellation")
 _check(ui_source.contains('func _open_itinerary_editor() -> void:'),"dedicated travel editor exists")
 _check(ui_source.contains('overlay.name = "TourItineraryEditor"'),"travel editor has independent overlay")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career scene compiles")
 if failures == 0:
  print("SPRINT 01 TOURING TESTS PASSED")
 quit(0 if failures==0 else 1)

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT 01: "+reason)
