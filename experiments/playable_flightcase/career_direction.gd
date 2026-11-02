extends RefCounted
## Read-only direction over the original chapters and already-saved show inputs.
## No actions, chapter claims, rewards, IO, state writes or presentation callbacks.
const Chapters = preload("res://Scripts/career_chapters.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const MAXIMUM := 2147483647
const V1_ORIGINALS_MODIFIERS := [-22,-10,-4,2]
const LABELS := {"songs":"Originals","rehearse":"Rehearsals","gigs":"Shows","fans":"Fans","readiness":"Readiness","day":"Days"}
const ROUTES := {"songs":"create","rehearse":"tighten","readiness":"tighten","gigs":"gigs","fans":"gigs","day":"calendar"}
const ROUTE_LABELS := {"create":"OPEN SONGWRITING","tighten":"OPEN REHEARSAL","gigs":"OPEN LIVE DESK","calendar":"OPEN CALENDAR"}
const ROUTE_HINTS := {"create":"OPEN FREE · 3 SESSIONS PER ORIGINAL","tighten":"OPEN FREE · SESSION £15 / 1 DAY","gigs":"OPEN FREE · CHOOSE YOUR SHOW TERMS","calendar":"READ ONLY · NO DAY ADVANCED"}
const PROJECTION_NUMBERS := ["selected_count","intensity_value","intensity_quality","set_shape_quality","shoutout_quality","quality_modifier","successful_extra_fans","extra_fatigue","extra_tension","originals_modifier","chemistry_bonus","gear_penalty","journey_bonus","effective_readiness","quality_estimate","threshold","reliability_margin"]

static func _whole(value: Variant, low: int = 0, high: int = MAXIMUM) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(low) and float(value)<=float(high)

static func _held(message: String) -> Dictionary:
 return {"ok":false,"message":message,"id":"","title":"NEXT BAND GOAL","description":"","done":false,"ready":false,"requirements":[],"route":"","route_label":"","route_hint":""}

static func current(state: Dictionary) -> Dictionary:
 for field in ["songs","fans","readiness"]:
  if state.has(field) and not _whole(state[field]):return _held("The saved goal progress needs validation.")
 if state.has("tour_day") and not _whole(state["tour_day"],1):return _held("The saved career day needs validation.")
 if state.has("career_chapters_claimed") and not state["career_chapters_claimed"] is Dictionary:return _held("The saved chapter history needs validation.")
 if state.has("gig_history") and not state["gig_history"] is Array:return _held("The saved show history needs validation.")
 if state.has("action_counters"):
  if not state["action_counters"] is Dictionary:return _held("The saved preparation history needs validation.")
  if state["action_counters"].has("rehearse") and not _whole(state["action_counters"]["rehearse"]):return _held("The saved rehearsal count needs validation.")
 var original: Dictionary=Chapters.progress(state)
 var result: Dictionary={"ok":true,"message":"","id":str(original.get("id","")),"title":str(original.get("title","NEXT BAND GOAL")),"description":str(original.get("description","")),"done":bool(original.get("done",false)),"ready":bool(original.get("ready",false)),"requirements":[],"route":"","route_label":"","route_hint":""}
 for raw in original.get("requirements",[]):
  var key: String=str(raw["label"])
  var row: Dictionary={"key":key,"label":str(LABELS.get(key,key.capitalize())),"current":int(raw["current"]),"target":int(raw["target"])}
  result["requirements"].append(row)
  if str(result["route"]).is_empty() and int(row["current"])<int(row["target"]):result["route"]=str(ROUTES.get(key,""))
 if bool(result["ready"]) or bool(result["done"]):result["route"]=""
 var route: String=str(result["route"])
 result["route_label"]=str(ROUTE_LABELS.get(route,""))
 result["route_hint"]=str(ROUTE_HINTS.get(route,""))
 return result

static func booking_guard(state: Dictionary) -> Dictionary:
 if state.has("tour_day") and not _whole(state["tour_day"],1):return {"ok":false,"due":false,"message":"The saved career day needs validation."}
 if not state.has("booked_show"):return {"ok":true,"due":false,"message":""}
 var booking: Variant=state["booked_show"]
 if not booking is Dictionary:return {"ok":false,"due":false,"message":"The saved booking needs validation."}
 if booking.is_empty():return {"ok":true,"due":false,"message":""}
 if not _whole(booking.get("day"),1):return {"ok":false,"due":false,"message":"The saved show date needs validation."}
 return {"ok":true,"due":int(booking["day"])<=int(state.get("tour_day",1)),"message":""}

static func factors(saved: Variant) -> Array:
 if not saved is Dictionary or not _whole(saved.get("version"),1,1):return []
 if not saved.get("id") is String or str(saved["id"]).is_empty() or saved.get("booking_id")!=saved["id"]:return []
 if not _whole(saved.get("originals_played"),0,3):return []
 var projection: Variant=saved.get("projection")
 if not projection is Dictionary:return []
 # The protected validator owns policy. Guard every numeric value it consumes
 # before calling it: INF can otherwise equal floor(INF) before an int cast.
 for field in PROJECTION_NUMBERS:
  if not _whole(projection.get(field),-MAXIMUM,MAXIMUM):return []
 if not Flow._projection_valid(projection):return []
 if int(projection["selected_count"])!=int(saved["originals_played"]):return []
 var count: int=int(saved["originals_played"])
 var readiness: int=int(projection["originals_modifier"])
 # Version1 integrity only: do not present a tampered count/modifier pair as a
 # saved performance fact. The value displayed below still comes from receipt.
 if readiness!=V1_ORIGINALS_MODIFIERS[count]:return []
 var quality: int=int(projection["intensity_quality"])
 var intensity: String=str({"CONTROLLED":"Controlled","STEADY":"Steady","ALL_OUT":"All-out"}.get(str(projection["intensity_band"]),""))
 return [{"kind":"originals","value":readiness,"text":"%d original%s: %+d readiness input" % [count,"" if count==1 else "s",readiness]},
  {"kind":"intensity","value":quality,"text":"%s: %+d quality input" % [intensity,quality]}]
