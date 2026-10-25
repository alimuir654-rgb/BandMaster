extends SceneTree
const Gear = preload("res://Scripts/gear_shop.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
var failures := 0

func _initialize() -> void:
 var band := {"cash":350,"tour_day":5,"readiness":65,"gear":0,"van_health":90,"reputation":45,"fans":80,"morale":60,"tension":10,"songs":3,"members":[{"name":"Jo","role":"guitarist","life_status":"active","fatigue":30},{"name":"Lee","role":"drummer","life_status":"active","fatigue":30}],"owned_equipment":[],"gig_history":[]}
 _check(not bool(Gear.buy(band,"invented").get("ok",true)),"unknown item rejected")
 var purchased: Dictionary = Gear.buy(band,"amp")
 _check(bool(purchased.get("ok",false)),"used amp can be bought")
 if not bool(purchased.get("ok",false)):
  quit(1)
  return
 var owned: Dictionary = purchased["state"]
 _check(int(owned["gear_records"]["amp"]["condition"]) == 77,"used condition recorded from catalogue")
 _check(str(owned["gear_records"]["amp"]["provenance"]).contains("day 5"),"purchase provenance records original day")
 _check(int(owned["cash"]) == 285 and int(owned["tour_day"]) == 6,"purchase charges once and consumes one day")
 _check(not band.has("gear_records"),"purchase never mutates input")
 _check(not bool(Gear.buy(owned,"amp").get("ok",true)),"duplicate purchase rejected")
 _check(not bool(Gear.assign(owned,"amp",1).get("ok",true)),"drummer cannot take guitar amp")
 var assigned: Dictionary = Gear.assign(owned,"amp",0)
 _check(bool(assigned.get("ok",false)),"guitarist can receive amp")
 var using: Dictionary = assigned["state"]
 _check(int(using["gear_records"]["amp"]["holder_index"]) == 0,"member-specific holder persisted")
 _check(int(using["tour_day"]) == 6 and int(using["cash"]) == 285,"assignment is free and instant")
 _check(int(owned["gear_records"]["amp"]["holder_index"]) == -1,"assignment leaves old state unchanged")
 var replacement := using.duplicate(true)
 replacement["members"][0]["name"] = "New Guitarist"
 _check(Gear.holder_index(replacement,Gear.record(replacement,"amp")) == -1,"replacement musician cannot inherit previous owner's gear")
 _check(Gear.readiness_penalty(replacement) == 0,"stale ownership does not affect live readiness")
 var worn := using.duplicate(true)
 worn["gear_records"]["amp"]["condition"] = 33
 _check(Gear.readiness_penalty(worn) == -5,"worn assigned amp reduces live readiness")
 var serviced: Dictionary = Gear.service(worn,"amp")
 _check(bool(serviced.get("ok",false)),"worn equipment can be serviced")
 if bool(serviced.get("ok",false)):
  var fixed: Dictionary = serviced["state"]
  _check(int(fixed["gear_records"]["amp"]["condition"]) == 58,"service restores 25 condition")
  _check(int(fixed["cash"]) == 260 and int(fixed["tour_day"]) == 7,"service charges £25 and one day")
  _check(Gear.readiness_penalty(fixed) == 0,"service removes live performance penalty")
  _check(int(worn["gear_records"]["amp"]["condition"]) == 33,"service leaves input untouched")
 var legacy := band.duplicate(true)
 legacy["owned_equipment"] = ["amp"]
 var old: Dictionary = Gear.record(legacy,"amp")
 _check(int(old["condition"]) == -1 and int(old["holder_index"]) == -1,"legacy gear condition and owner unknown")
 _check(not legacy.has("gear_records"),"legacy inspection read is non-mutating")
 var old_service: Dictionary = Gear.service(legacy,"amp")
 _check(bool(old_service.get("ok",false)),"legacy gear can be assessed by service")
 if bool(old_service.get("ok",false)):
  _check(int(old_service["state"]["gear_records"]["amp"]["condition"]) == 80,"assessment establishes condition without inventing history")
 var poor := worn.duplicate(true)
 poor["cash"] = 0
 _check(not bool(Gear.service(poor,"amp").get("ok",true)),"no cash cannot service")
 _check(int(poor["tour_day"]) == 6,"failed service spends no time")
 var saved: String = JSON.stringify(using)
 var loaded = JSON.parse_string(saved)
 _check(loaded is Dictionary and int(loaded["gear_records"]["amp"]["holder_index"]) == 0,"gear survives JSON save/reload")
 var booked := using.duplicate(true)
 booked["booked_show"] = {"venue_id":"local","venue":"Home Room","day":6,"approach":"tight","session_drummer":false,"travel_plan":"drive_home"}
 booked["gig_night_phase"] = "arrival"
 var gig: Dictionary = Calendar.perform(booked)
 _check(bool(gig.get("ok",false)),"gig with assigned equipment completes")
 if bool(gig.get("ok",false)):
  var after: Dictionary = gig["state"]
  _check(int(after["gear_records"]["amp"]["condition"]) == 74,"completed show wears gear exactly 3")
  _check(after["booked_show"].is_empty(),"show booking cleared after payout")
  _check(not bool(Calendar.perform(after).get("ok",true)),"cannot replay show to exploit wear or payouts")
 _check(int(booked["gear_records"]["amp"]["condition"]) == 77,"gig does not mutate source state")
 var source := FileAccess.get_file_as_string("res://Scripts/career_hub.gd")
 _check(source.contains("SERVICE & ASSESS") and source.contains("ASSIGN TO"),"real gear controls present")
 _check(ResourceLoader.exists("res://Art/UI/Icons/wrench.svg"),"curated Lucide repair icon available")
 _check(load("res://Scenes/CareerHub.tscn") != null,"career UI compiles")
 if failures == 0:
  print("SPRINT 02 MEMBER EQUIPMENT PASSED")
 quit(0 if failures == 0 else 1)

func _check(ok: bool,reason: String) -> void:
 if not ok:
  failures += 1
  push_error("SPRINT 02 FAILURE: "+reason)
