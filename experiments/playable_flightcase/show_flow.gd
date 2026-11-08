extends RefCounted
## Owned S53 local-show policy. No LiveBridge dependency, file IO or saving.
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Chemistry = preload("res://Scripts/song_chemistry.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const FLOW_KEY := "show_flow_v1"
const RECORDS_KEY := "show_receipts_v1"
const RESULT_KEY := "show_policy_v1"
const ROUTE := "LOCAL_LIFT"
const VERSION := 1
const RECORD_LIMIT := 80
const MOOD_SCORES := {"strained":3,"steady":6,"positive":9}

static func _whole(value: Variant) -> bool:
 return (value is int or value is float) and float(value)==floor(float(value))

static func _number(value: Variant, low: int = 0, high: int = 2147483647) -> bool:
 return _whole(value) and int(value)>=low and int(value)<=high

static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func _fail(state: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":state.duplicate(true),"message":message}

static func managed(state: Dictionary) -> bool:
 var raw: Variant = state.get("booked_show",{})
 return raw is Dictionary and raw.has(FLOW_KEY)

static func version_of(state: Dictionary) -> int:
 var booking: Dictionary=Calendar.pending(state)
 var raw: Variant=booking.get(FLOW_KEY,{})
 return int(raw.get("version",0)) if raw is Dictionary and Booking.whole(raw.get("version",0)) else 0

static func _route(booking: Dictionary) -> String:
 return "ORIGINAL:%s:%s" % [str(booking.get("venue_id","")),str(booking.get("travel_plan",""))]

static func receipt_v2_valid(receipt: Variant) -> bool:
 if not receipt is Dictionary or receipt.get("version")!=2 or not Booking.finite_tree(receipt) or not Booking.terms_valid(receipt.get(Booking.TERMS)):return false
 var t: Dictionary=receipt[Booking.TERMS]
 if receipt.get("commitment_id")!=t["commitment_id"] or receipt.get("venue_id")!=t["venue_snapshot"]["id"] or receipt.get("venue")!=t["venue_snapshot"]["venue"] or receipt.get("city")!=t["venue_snapshot"]["city"]:return false
 if receipt.get("scheduled_day")!=t["day"] or receipt.get("completed_day")!=t["next_available_day"] or receipt.get("trip_days")!=t["tariff"]["duration"]:return false
 if not _pinned_plan_valid(receipt.get("plan")) or not _projection_valid(receipt.get("projection")) or not receipt.get("expenses") is Dictionary:return false
 var plan: Dictionary=receipt["plan"];var projection: Dictionary=receipt["projection"]
 var count: int=plan["song_ids"].size()
 if projection["selected_count"]!=count or receipt.get("originals_played")!=count or projection["intensity_value"]!=plan["intensity"] or projection["originals_modifier"]!=[-22,-10,-4,2][count]:return false
 var expenses: Dictionary=receipt["expenses"]
 for key in ["travel_paid","accommodation_paid","session_paid"]:
  if not Booking.whole(expenses.get(key)):return false
 if not Booking.whole(receipt.get("cash_before")) or not Booking.whole(receipt.get("cash_after")) or not Booking.whole(receipt.get("settled_fee")):return false
 var expected_travel: int=mini(int(t["tariff"]["travel"]),int(receipt["cash_before"])) if receipt["venue_id"]=="local" else int(t["tariff"]["travel"])
 if expenses["travel_paid"]!=expected_travel or expenses["accommodation_paid"]!=t["tariff"]["accommodation"] or expenses["session_paid"]!=(25 if t["session_drummer"] else 0):return false
 return int(receipt["cash_after"])==int(receipt["cash_before"])+int(receipt["settled_fee"])-int(expenses["travel_paid"])-int(expenses["accommodation_paid"])-int(expenses["session_paid"])

static func booking_id(booking: Dictionary) -> String:
 if not booking.get("venue_id") is String or str(booking["venue_id"]).is_empty() or not _number(booking.get("day",0),1):return ""
 return "s53:booking:%s:%d" % [str(booking["venue_id"]),int(booking["day"])]

static func _records_view(state: Dictionary) -> Dictionary:
 var raw: Variant = state.get(RECORDS_KEY,{})
 var data: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
 for field in {"version":VERSION,"seq":0,"seen_ids":{},"records":[]}:
  if not data.has(field):
   data[field] = {"version":VERSION,"seq":0,"seen_ids":{},"records":[]}[field]
 return data

static func _pinned_plan_valid(plan: Variant) -> bool:
 if not plan is Dictionary or not plan.get("approach") is String or not Gigs.APPROACHES.has(plan["approach"]) or not _number(plan.get("intensity",-1),0,100):return false
 if not plan.get("song_ids") is Array or plan["song_ids"].size()>3 or not plan.get("song_snapshots") is Array or plan["song_snapshots"].size()!=plan["song_ids"].size():return false
 if str(plan.get("shoutout","")) not in ["none","thankvenue"] or not plan.get("shoutout_venue_id") is String:return false
 var seen: Dictionary = {}
 for i in range(plan["song_ids"].size()):
  var id: Variant = plan["song_ids"][i]
  var song: Variant = plan["song_snapshots"][i]
  if not id is String or str(id).is_empty() or seen.has(id) or not song is Dictionary or song.get("id")!=id or not song.get("title") is String or not _number(song.get("quality",-1),0,100):return false
  seen[id]=true
 return true

static func _projection_valid(raw: Variant) -> bool:
 if not raw is Dictionary or not raw.get("legacy") is bool or bool(raw["legacy"]):return false
 for field in ["selected_count","intensity_value","intensity_quality","set_shape_quality","shoutout_quality","quality_modifier","successful_extra_fans","extra_fatigue","extra_tension","originals_modifier","chemistry_bonus","gear_penalty","journey_bonus","effective_readiness","quality_estimate","threshold","reliability_margin"]:
  if not raw.has(field) or not _whole(raw[field]):return false
 if not _number(raw["selected_count"],0,3) or not _number(raw["intensity_value"],0,100) or not _number(raw["set_shape_quality"],-2,2) or not _number(raw["effective_readiness"],0,100) or int(raw["threshold"])!=52 or int(raw["reliability_margin"])!=int(raw["quality_estimate"])-52:return false
 var value: int = int(raw["intensity_value"])
 var band: String = "CONTROLLED" if value<35 else ("STEADY" if value<70 else "ALL_OUT")
 if raw.get("intensity_band")!=band or int(raw["intensity_quality"])!=(4 if value<35 else (0 if value<70 else -4)) or int(raw["extra_fatigue"])!=(0 if value<35 else (3 if value<70 else 8)) or int(raw["extra_tension"])!=(3 if value>=70 else 0):return false
 return int(raw["quality_modifier"])==int(raw["intensity_quality"])+int(raw["set_shape_quality"])+int(raw["shoutout_quality"])

static func _projection_matches(raw: Variant, expected: Dictionary) -> bool:
 if not _projection_valid(raw):return false
 for field in expected:
  if raw.get(field)!=expected[field]:return false
 return true

static func _draft_structure(booking: Dictionary, draft: Dictionary) -> Dictionary:
 if not draft.get("approach") is String or not Gigs.APPROACHES.has(draft["approach"]) or not _number(draft.get("intensity",-1),0,100):return _bad("Choose a valid approach and intensity from 0 to 100.")
 var ids: Variant = draft.get("song_ids")
 if not ids is Array or ids.size()>3:return _bad("Choose up to three unique completed originals.")
 var seen: Dictionary = {}
 for id in ids:
  if not id is String or str(id).is_empty() or seen.has(id):return _bad("Each selected original must have a unique completed-song ID.")
  seen[id]=true
 if not draft.get("shoutout") is String or draft["shoutout"] not in ["none","thankvenue"] or not draft.get("shoutout_venue_id") is String:return _bad("Choose a valid venue acknowledgment.")
 if draft["shoutout"]=="thankvenue" and ((not booking.has(Booking.TERMS) and str(booking.get("venue_id",""))!="local") or draft["shoutout_venue_id"]!=str(booking.get("venue_id",""))):return _bad("The acknowledgment must name this actual booked venue.")
 if draft.has("song_snapshots"):
  if not draft["song_snapshots"] is Array:return _bad("Selected-song snapshots must be an array when supplied.")
  for song in draft["song_snapshots"]:
   if not song is Dictionary or not song.get("id") is String or str(song["id"]).is_empty() or not song.get("title") is String or not _number(song.get("quality",-1),0,100):return _bad("A supplied selected-song snapshot is invalid.")
 return {"ok":true,"message":""}

static func _receipt_facts_valid(receipt: Dictionary) -> bool:
 # S53 optional factual snapshots. Older receipts remain valid without them;
 # unknown extensions in the receipt, containers and each row remain untouched.
 if receipt.has("effects"):
  var effects: Variant = receipt["effects"]
  if not effects is Dictionary:return false
  for field in ["readiness","morale","tension","reputation","fans"]:
   var row: Variant = effects.get(field)
   var maximum: int = 100 if field!="fans" else 2147483647
   if not row is Dictionary or not _number(row.get("before",-1),0,maximum) or not _number(row.get("after",-1),0,maximum) or not _whole(row.get("delta")):return false
   if float(row["delta"])!=float(int(row["after"])-int(row["before"])):return false
 if receipt.has("expenses"):
  var expenses: Variant = receipt["expenses"]
  if not expenses is Dictionary or not _number(expenses.get("travel_paid",-1)) or not _number(expenses.get("session_paid",-1)):return false
  # This owned flow is hometown/local_lift only. Read the unchanged original
  # venue tariff; do not invent a route, charge or a historical session fee.
  var venue: Dictionary = Gigs.get_venue(str(receipt.get("venue_id","")))
  if str(receipt.get("venue_id",""))!="local" or venue.is_empty() or not _number(receipt.get("cash_before",-1)) or not _number(venue.get("travel",-1)):return false
  if int(expenses["travel_paid"])!=mini(int(venue["travel"]),int(receipt["cash_before"])):return false
 return true

static func _validate_records_v2(state: Dictionary) -> Dictionary:
 var raw: Variant=state.get(RECORDS_KEY)
 if not raw is Dictionary or raw.get("version")!=2 or not raw.get("records") is Array:return _bad("The saved regional show receipts need validation.")
 var shadow: Dictionary=state.duplicate(true)
 shadow[RECORDS_KEY]["version"]=1
 for index in range(raw["records"].size()):
  var row: Variant=raw["records"][index]
  if not row is Dictionary:return _bad("A saved show receipt is invalid.")
  if row.get("version")==2:
   if not receipt_v2_valid(row):return _bad("A saved regional show receipt has invalid agreement facts.")
   shadow[RECORDS_KEY]["records"][index]["version"]=1
   shadow[RECORDS_KEY]["records"][index].erase("expenses")
  elif row.get("version")!=1:return _bad("A saved show receipt requires a compatible version.")
 return _validate_records(shadow)

static func _validate_records(state: Dictionary) -> Dictionary:
 if not state.has(RECORDS_KEY):return {"ok":true,"message":""}
 if state[RECORDS_KEY] is Dictionary and state[RECORDS_KEY].get("version")==2:return _validate_records_v2(state)
 var raw: Variant = state[RECORDS_KEY]
 if not raw is Dictionary or not _number(raw.get("version",0),1,1) or not _number(raw.get("seq",-1)) or not raw.get("seen_ids") is Dictionary or not raw.get("records") is Array or raw["records"].size()>RECORD_LIMIT:return _bad("The saved show receipt metadata needs validation.")
 var seq: int = int(raw["seq"])
 for id in raw["seen_ids"]:
  if not id is String or str(id).is_empty() or not _number(raw["seen_ids"][id],1,seq):return _bad("A saved show receipt identifier is invalid.")
 var prior := 0
 var retained: Dictionary = {}
 for receipt in raw["records"]:
  if not receipt is Dictionary:return _bad("A saved show receipt is invalid.")
  for field in ["id","booking_id","venue_id","venue","city","message"]:
   if not receipt.get(field) is String:return _bad("A saved show receipt has invalid text.")
  var id: String = str(receipt["id"])
  if id!=receipt["booking_id"] or retained.has(id) or not raw["seen_ids"].has(id) or not _number(receipt.get("seq",0),1,seq) or int(receipt["seq"])!=int(raw["seen_ids"][id]) or int(receipt["seq"])<=prior:return _bad("A saved show receipt has an invalid checkpoint.")
  if not _number(receipt.get("version",0),1,1) or not receipt.get("success") is bool or not _pinned_plan_valid(receipt.get("plan")) or not _projection_valid(receipt.get("projection")):return _bad("A saved show receipt has invalid performance facts.")
  if int(receipt["projection"]["selected_count"])!=receipt["plan"]["song_ids"].size() or int(receipt["projection"]["intensity_value"])!=int(receipt["plan"]["intensity"]):return _bad("The saved receipt plan and projection disagree.")
  for field in ["scheduled_day","completed_day","day_before","day_after"]:
   if not _number(receipt.get(field,0),1):return _bad("A saved show receipt has an invalid day.")
  for field in ["cash_before","cash_after","settled_fee","originals_played"]:
   if not _number(receipt.get(field,-1)):return _bad("A saved show receipt has an invalid amount.")
  if not _receipt_facts_valid(receipt):return _bad("A saved show receipt has invalid optional effects or expenses.")
  if int(receipt["completed_day"])!=int(receipt["day_after"]) or int(receipt["scheduled_day"])!=int(receipt["day_before"]) or int(receipt["completed_day"])<=int(receipt["scheduled_day"]):return _bad("A saved show receipt has inconsistent days.")
  if not receipt.get("responses") is Array or receipt["responses"].size()!=3:return _bad("A saved show response summary is invalid.")
  for point in receipt["responses"]:
   if not point is Dictionary:return _bad("A saved modelled response point is invalid.")
   for field in ["id","title","text","mood","kind"]:
    if not point.get(field) is String:return _bad("A saved modelled response point has invalid text.")
   if point["kind"]!="modelled_summary":return _bad("A saved response must identify itself as a modelled summary.")
   if not MOOD_SCORES.has(point["mood"]) or not _number(point.get("meter_score",-1),0,10) or int(point["meter_score"])!=int(MOOD_SCORES[point["mood"]]):return _bad("A saved modelled summary must use its explicit three-band ordinal meter.")
  retained[id]=true
  prior=int(receipt["seq"])
 if (seq==0 and (not raw["seen_ids"].is_empty() or not raw["records"].is_empty())) or (seq>0 and (raw["records"].is_empty() or prior!=seq)):return _bad("The latest saved show receipt checkpoint is missing.")
 return {"ok":true,"message":""}

static func validate(state: Dictionary) -> Dictionary:
 var receipts: Dictionary = _validate_records(state)
 if not bool(receipts.get("ok",false)):return receipts
 if not managed(state):return {"ok":true,"message":""}
 var booking: Dictionary = state["booked_show"]
 var raw: Variant = booking[FLOW_KEY]
 var id: String = booking_id(booking)
 if raw is Dictionary and raw.get("version")==2:
  var agreement: Dictionary=Booking.validate(state)
  if not bool(agreement.get("ok",false)):return agreement
  if not Booking.modern(state) or id.is_empty() or raw.get("booking_id")!=id or raw.get("route")!=_route(booking) or raw.get("transport_mode")!=booking.get("travel_plan"):return _bad("The saved room and trip do not match their agreement.")
 else:
  if Booking.modern(state):return _bad("A new booking needs its known regional journey version.")
  if id.is_empty() or str(booking.get("venue_id",""))!="local" or not raw is Dictionary or not _number(raw.get("version",0),1,1) or raw.get("booking_id")!=id or raw.get("route")!=ROUTE or raw.get("transport_mode")!="local_lift":return _bad("This saved local-show journey needs validation; the original cancellation remains available.")
 if not raw.get("travel_acknowledged") is bool or not raw.get("plan_committed") is bool or not raw.get("plan") is Dictionary:return _bad("The saved show journey progress is invalid.")
 # Saved defaults are not a committed set. Catalogue trimming during later
 # writing must not prevent the player from choosing a replacement plan.
 var structural: Dictionary = _draft_structure(booking,raw["plan"])
 if not bool(structural.get("ok",false)):return structural
 if bool(raw["plan_committed"]):
  var checked: Dictionary = _normal_plan(state,raw["plan"])
  if not bool(checked.get("ok",false)):return checked
  if not bool(raw["travel_acknowledged"]) or not _pinned_plan_valid(raw["plan"]):return _bad("The saved soundcheck plan is incomplete.")
  if raw["plan"].get("approach")!=booking.get("approach"):return _bad("The agreed approach and saved plan disagree.")
  for i in range(raw["plan"]["song_snapshots"].size()):
   var stored: Dictionary = raw["plan"]["song_snapshots"][i]
   var actual: Dictionary = checked["plan"]["song_snapshots"][i]
   for field in ["id","title","quality"]:
    if stored.get(field)!=actual.get(field):return _bad("A saved selected-song snapshot no longer matches its completed original.")
 var original: String = str(Night.stage(state).get("phase","none"))
 if original in ["soundcheck","stage"] and not bool(raw["travel_acknowledged"]):return _bad("The saved journey was not acknowledged before arrival.")
 if original=="stage" and not bool(raw["plan_committed"]):return _bad("The saved stage has no committed soundcheck plan.")
 return {"ok":true,"message":""}

static func phase(state: Dictionary) -> String:
 if not bool(validate(state).get("ok",false)):return "invalid"
 var original: String = str(Night.stage(state).get("phase","none"))
 if managed(state) and original=="arrival" and not bool(state["booked_show"][FLOW_KEY]["travel_acknowledged"]):return "travel"
 return original

static func set_limit(state: Dictionary) -> int:
 var bill: Dictionary=Booking.terms(state).get("scene_bill_v1",{})
 return int(bill.get("set_limit",3)) if int(bill.get("version",1))==2 else 3

static func default_plan(state: Dictionary) -> Dictionary:
 var ids: Array = []
 var seen: Dictionary = {}
 var catalogue: Variant = state.get("song_catalogue",[])
 if catalogue is Array:
  for song in catalogue:
   if song is Dictionary and song.get("id") is String and not str(song["id"]).is_empty() and not seen.has(song["id"]) and song.get("title") is String and _number(song.get("quality",-1),0,100):
    ids.append(str(song["id"]))
    seen[song["id"]]=true
    if ids.size()==set_limit(state):break
 return {"approach":"tight","intensity":50,"song_ids":ids,"shoutout":"none","shoutout_venue_id":""}

static func new_booking(state: Dictionary) -> Dictionary:
 var after: Dictionary = state.duplicate(true)
 var booking: Dictionary = Calendar.pending(after)
 if booking.is_empty() or booking.has(FLOW_KEY) or booking_id(booking).is_empty() or (not Booking.modern(after) and str(booking.get("venue_id",""))!="local"):return after
 if Booking.modern(after):
  if not bool(Booking.validate(after).get("ok",false)):return state.duplicate(true)
  booking[FLOW_KEY]={"version":2,"booking_id":booking_id(booking),"route":_route(booking),"transport_mode":str(booking["travel_plan"]),"travel_acknowledged":false,"plan_committed":false,"plan":default_plan(after)}
 else:booking[FLOW_KEY]={"version":VERSION,"booking_id":booking_id(booking),"route":ROUTE,"transport_mode":"local_lift","travel_acknowledged":false,"plan_committed":false,"plan":default_plan(after)}
 after["booked_show"]=booking
 return after

static func depart(state: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(state)
 if not bool(valid.get("ok",false)):return _fail(state,str(valid["message"]))
 if not managed(state) or phase(state)!="travel":return _fail(state,"This local journey is not awaiting departure.")
 var after: Dictionary = state.duplicate(true)
 after["booked_show"][FLOW_KEY]["transport_mode"]=str(after["booked_show"]["travel_plan"]) if version_of(state)==2 else "local_lift"
 after["booked_show"][FLOW_KEY]["travel_acknowledged"]=true
 if version_of(state)==2:return {"ok":true,"state":after,"message":"The agreed trip to %s is under way. Costs and career days settle when the night is wrapped." % str(after["booked_show"].get("city","the venue"))}
 return {"ok":true,"state":after,"message":"The local lift reaches "+str(after["booked_show"].get("venue","the venue"))+". No money or day has been spent; travel settles with the show."}

static func _normal_plan(state: Dictionary, draft: Dictionary) -> Dictionary:
 var booking: Dictionary = Calendar.pending(state)
 if booking.is_empty():return _bad("Book a show before planning its soundcheck.")
 if not draft.get("approach") is String or not Gigs.APPROACHES.has(draft["approach"]) or not _number(draft.get("intensity",-1),0,100):return _bad("Choose a valid approach and intensity from 0 to 100.")
 var raw_ids: Variant = draft.get("song_ids")
 if not raw_ids is Array or raw_ids.size()>set_limit(state):return _bad("Choose up to %d unique completed original(s), as agreed with the promoter." % set_limit(state))
 if not draft.get("shoutout") is String or draft["shoutout"] not in ["none","thankvenue"] or not draft.get("shoutout_venue_id") is String:return _bad("Choose a valid venue acknowledgment.")
 if draft["shoutout"]=="thankvenue" and ((not booking.has(Booking.TERMS) and str(booking.get("venue_id",""))!="local") or draft["shoutout_venue_id"]!=str(booking.get("venue_id",""))):return _bad("The acknowledgment must name this actual booked venue.")
 var catalogue: Variant = state.get("song_catalogue",[])
 if not catalogue is Array:return _bad("The completed-song catalogue cannot be read safely.")
 var ids: Array = []
 var snapshots: Array = []
 var seen: Dictionary = {}
 var prior_snapshots: Variant = draft.get("song_snapshots",[])
 if not prior_snapshots is Array:return _bad("Selected-song snapshots must be an array when supplied.")
 for prior in prior_snapshots:
  if not prior is Dictionary:return _bad("A supplied selected-song snapshot is invalid.")
 for id in raw_ids:
  if not id is String or str(id).is_empty() or seen.has(id):return _bad("Each selected original must have a unique completed-song ID.")
  var found: Dictionary = {}
  var count := 0
  for song in catalogue:
   if song is Dictionary and song.get("id")==id:
    found=song.duplicate(true)
    count+=1
  if count!=1 or not found.get("title") is String or not _number(found.get("quality",-1),0,100):return _bad("A selected song is missing, ambiguous or unfinished.")
  for prior in prior_snapshots:
   if prior.get("id")==id:
    var merged: Dictionary = prior.duplicate(true)
    merged.merge(found,true)
    found=merged
    break
  ids.append(str(id))
  snapshots.append(found)
  seen[id]=true
 var plan: Dictionary = draft.duplicate(true)
 plan["intensity"]=int(draft["intensity"])
 plan["song_ids"]=ids
 plan["song_snapshots"]=snapshots
 if plan["shoutout"]=="none":plan["shoutout_venue_id"]=""
 return {"ok":true,"plan":plan,"projection":_projection(state,plan),"message":""}

static func _projection(state: Dictionary, plan: Dictionary) -> Dictionary:
 var value: int = int(plan["intensity"])
 var band: String = "CONTROLLED" if value<35 else ("STEADY" if value<70 else "ALL_OUT")
 var intensity_quality: int = 4 if value<35 else (0 if value<70 else -4)
 var extra_fans: int = -3 if value<35 else (0 if value<70 else 4)
 var fatigue: int = 0 if value<35 else (3 if value<70 else 8)
 var tension: int = 3 if value>=70 else 0
 var count: int = plan["song_ids"].size()
 var shape := 0
 if count>0:
  var songs: Array = plan["song_snapshots"]
  shape=clampi(int(floor(((float(songs.front()["quality"])+2.0*float(songs.back()["quality"]))/3.0-50.0)/20.0)),-2,2)
 var shout: bool = plan["shoutout"]=="thankvenue"
 var shout_quality: int = -1 if shout else 0
 var quality_mod: int = intensity_quality+shape+shout_quality
 var originals_mod: int = -22 if count==0 else (-10 if count==1 else (-4 if count==2 else 2))
 var chemistry: int = int(Chemistry.calculate(state).get("bonus",0))
 var gear: int = Gear.readiness_penalty(state)
 var booking: Dictionary = Calendar.pending(state)
 var journey: Dictionary = Tour.preview(state,str(booking.get("venue_id","")),str(booking.get("travel_plan",Tour.DRIVE)))
 var journey_bonus: int = int(journey.get("quality_bonus",0))
 var readiness: int = clampi(int(state.get("readiness",0))+quality_mod+originals_mod+chemistry+gear+journey_bonus,0,100)
 var approach: Dictionary = Gigs.APPROACHES[plan["approach"]]
 var quality: int = readiness+int(float(state.get("morale",0))/4.0)-int(float(state.get("tension",0))/4.0)-(8 if bool(booking.get("session_drummer",false)) else 0)+int(approach["quality"])
 return {"legacy":false,"selected_count":count,"intensity_value":value,"intensity_band":band,"intensity_quality":intensity_quality,"set_shape_quality":shape,"shoutout_quality":shout_quality,"quality_modifier":quality_mod,"successful_extra_fans":extra_fans+(2 if shout else 0) if count>0 else 0,"extra_fatigue":fatigue,"extra_tension":tension,"originals_modifier":originals_mod,"chemistry_bonus":chemistry,"gear_penalty":gear,"journey_bonus":journey_bonus,"effective_readiness":readiness,"quality_estimate":quality,"threshold":52,"reliability_margin":quality-52}

static func check_plan(state: Dictionary, draft: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(state)
 if not bool(valid.get("ok",false)):return valid
 return _normal_plan(state,draft)

static func soundcheck(state: Dictionary, draft: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(state)
 if not bool(valid.get("ok",false)):return _fail(state,str(valid["message"]))
 if not managed(state) or phase(state)!="soundcheck":return _fail(state,"Commit the managed plan during soundcheck.")
 var checked: Dictionary = _normal_plan(state,draft)
 if not bool(checked.get("ok",false)):return _fail(state,str(checked["message"]))
 var result: Dictionary = Night.choose_set(state,str(checked["plan"]["approach"]))
 if not bool(result.get("ok",false)):return _fail(state,str(result.get("message","The approach could not be chosen.")))
 var advanced: Dictionary = Night.advance(result["state"])
 if not bool(advanced.get("ok",false)):return _fail(state,str(advanced.get("message","The stage is unavailable.")))
 var after: Dictionary = advanced["state"]
 after["booked_show"][FLOW_KEY]["plan"]=checked["plan"].duplicate(true)
 after["booked_show"][FLOW_KEY]["plan_committed"]=true
 return {"ok":true,"state":after,"message":str(result.get("message","Soundcheck agreed.")),"plan":checked["plan"],"projection":checked["projection"]}

static func prepare_performance(state: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(state)
 if not bool(valid.get("ok",false)):return _fail(state,str(valid["message"]))
 if not managed(state):return {"ok":true,"state":state.duplicate(true),"plan":{},"projection":{"legacy":true},"message":""}
 if phase(state)!="stage":return _fail(state,"The held stage and saved soundcheck must be ready before performing.")
 var plan: Dictionary = state["booked_show"][FLOW_KEY]["plan"].duplicate(true)
 var projected: Dictionary = _projection(state,plan)
 var after: Dictionary = state.duplicate(true)
 # No early clamp: Calendar owns its existing combined performance clamp.
 after["readiness"]=int(state.get("readiness",0))+int(projected["quality_modifier"])
 after["songs"]=int(projected["selected_count"])
 return {"ok":true,"state":after,"plan":plan,"projection":projected,"message":""}

static func _new_show(before: Dictionary, after: Dictionary) -> Dictionary:
 var booking: Dictionary = Calendar.pending(before)
 var history: Variant = after.get("gig_history",[])
 var previous: Variant = before.get("gig_history",[])
 if booking.is_empty() or not history is Array or history.is_empty() or not previous is Array or not history.back() is Dictionary:return _bad("No newly settled original show is available.")
 var show: Dictionary = history.back()
 var remaining: Variant = after.get("booked_show")
 if not remaining is Dictionary or not remaining.is_empty() or show.get("venue_id")!=booking.get("venue_id") or not _number(show.get("day",0),1) or not _number(after.get("tour_day",0),1) or int(show["day"])!=int(after["tour_day"]) or int(before.get("tour_day",0))!=int(booking.get("day",-1)) or int(show["day"])<=int(booking.get("day",0)) or not show.get("success") is bool or not _number(show.get("fee",-1)) or not _number(after.get("cash",-1)):return _bad("The completed original show does not match this booking.")
 for field in ["venue","city"]:
  if not show.get(field) is String or (booking.has(field) and show[field]!=booking[field]):return _bad("The completed venue facts do not match the booking.")
 var expected: Array = previous.duplicate(true)
 expected.append(show.duplicate(true))
 if expected.size()>50:expected.pop_front()
 if expected!=history:return _bad("The history is not one newly completed original show.")
 return {"ok":true,"show":show.duplicate(true),"message":""}

static func after_original_settlement(before: Dictionary, after: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(before)
 if not bool(valid.get("ok",false)):return _fail(before,str(valid["message"]))
 if not managed(before):return {"ok":true,"state":after.duplicate(true),"message":""}
 var prepared: Dictionary = prepare_performance(before)
 if not bool(prepared.get("ok",false)):return _fail(before,str(prepared["message"]))
 var fresh: Dictionary = _new_show(before,after)
 if not bool(fresh.get("ok",false)):return _fail(before,str(fresh["message"]))
 var show: Dictionary = fresh["show"]
 var id: String = str(before["booked_show"][FLOW_KEY]["booking_id"])
 var prior: Variant = show.get(RESULT_KEY)
 if prior!=null:
  if prior is Dictionary and prior.get("version")==version_of(before) and prior.get("booking_id")==id and prior.get("plan")==prepared["plan"] and _projection_matches(prior.get("projection"),prepared["projection"]) and _number(prior.get("fee_before_cap",-1)) and prior.get("fee_after_cap")==show.get("fee"):return {"ok":true,"state":after.duplicate(true),"message":""}
  return _fail(before,"The saved owned show policy marker is invalid.")
 var plan: Dictionary = prepared["plan"]
 var projection: Dictionary = prepared["projection"]
 if int(show.get("originals_played",-1))!=int(projection["selected_count"]) or show.get("approach")!=plan["approach"] or int(after.get("readiness",0))!=int(prepared["state"]["readiness"]):return _fail(before,"The original show was not resolved from its committed projection.")
 var result: Dictionary = after.duplicate(true)
 result["songs"]=int(before.get("songs",0))
 result["readiness"]=int(before.get("readiness",0))
 var row: Dictionary = result["gig_history"].back()
 var old_fee: int = int(row["fee"])
 var fee: int = mini(5,old_fee) if int(projection["selected_count"])==0 else old_fee
 var reduction: int = old_fee-fee
 if int(result.get("cash",0))<reduction:return _fail(before,"The capped fee cannot reconcile to the original cash settlement.")
 result["cash"]=int(result.get("cash",0))-reduction
 row["fee"]=fee
 if bool(row["success"]) and int(projection["selected_count"])>0:
  result["fans"]=maxi(int(before.get("fans",0)),int(result.get("fans",0))+int(projection["successful_extra_fans"]))
 result["tension"]=clampi(int(result.get("tension",0))+int(projection["extra_tension"]),0,100)
 var original_members: Variant = before.get("members",[])
 var members: Variant = result.get("members",[])
 if not original_members is Array or not members is Array or original_members.size()!=members.size():return _fail(before,"The performer roster changed during settlement.")
 for i in range(original_members.size()):
  if not original_members[i] is Dictionary or not members[i] is Dictionary:return _fail(before,"A performer record is invalid.")
  var identity: String = str(original_members[i].get("candidate_id",original_members[i].get("id",original_members[i].get("name",""))))
  if str(members[i].get("candidate_id",members[i].get("id",members[i].get("name",""))))!=identity:return _fail(before,"The performer identities changed during settlement.")
  if str(original_members[i].get("life_status","active"))=="active":members[i]["fatigue"]=clampi(int(members[i].get("fatigue",0))+int(projection["extra_fatigue"]),0,100)
 row[RESULT_KEY]={"version":version_of(before),"booking_id":id,"plan":plan.duplicate(true),"projection":projection.duplicate(true),"fee_before_cap":old_fee,"fee_after_cap":fee}
 return {"ok":true,"state":result,"plan":plan,"projection":projection,"message":"No originals selected: the final gross fee is capped at £5." if int(projection["selected_count"])==0 else ""}

static func _responses(receipt: Dictionary) -> Array:
 var count: int = int(receipt["originals_played"])
 var plan: Dictionary = receipt["plan"]
 var projection: Dictionary = receipt["projection"]
 var success: bool = bool(receipt["success"])
 var points: Array = [
  {"id":"opening","title":"THE PLANNED SET","text":"%d completed original(s), in the saved order. Approach: %s." % [count,str(plan["approach"])],"mood":"steady","kind":"modelled_summary"},
  {"id":"room","title":"MODELLED WHOLE-SHOW RESPONSE","text":("The saved result records a good reception. " if success else "The saved result records a difficult reception. ")+"Intensity: "+str(projection["intensity_band"])+". This is an illustrative summary, not measured audio, attendance or individual song reactions.","mood":"positive" if success else "strained","kind":"modelled_summary"},
  {"id":"finish","title":"THE SETTLEMENT","text":"Settled fee £%d. Cash £%d → £%d. %s" % [int(receipt["settled_fee"]),int(receipt["cash_before"]),int(receipt["cash_after"]),"No originals: the gross fee cap is £5." if count==0 else "All original travel and session charges are retained."],"mood":"steady","kind":"modelled_summary"}
 ]
 for point in points:
  point["meter_score"]=int(MOOD_SCORES[point["mood"]])
  point["meter_label"]="MODELLED SUMMARY (THREE BANDS)"
 return points

static func record(before: Dictionary, after: Dictionary, msg: String) -> Dictionary:
 var valid: Dictionary = validate(before)
 if not bool(valid.get("ok",false)):return _fail(before,str(valid["message"]))
 valid=validate(after)
 if not bool(valid.get("ok",false)):return _fail(before,str(valid["message"]))
 if not managed(before):return {"ok":true,"state":after.duplicate(true),"message":""}
 var id: String = str(before["booked_show"][FLOW_KEY]["booking_id"])
 var old: Dictionary = _records_view(before)
 var data: Dictionary = _records_view(after)
 if data["seen_ids"].has(id):return {"ok":true,"state":after.duplicate(true),"message":""}
 if old["seen_ids"].has(id):return _fail(before,"The settlement discarded an existing saved show receipt.")
 if before.has(RECORDS_KEY) and not after.has(RECORDS_KEY):return _fail(before,"The settlement discarded saved show receipt metadata.")
 for field in ["seq","seen_ids","records"]:
  if old[field]!=data[field]:return _fail(before,"The show receipt checkpoint changed before recording this result.")
 var fresh: Dictionary = _new_show(before,after)
 if not bool(fresh.get("ok",false)):return _fail(before,str(fresh["message"]))
 var show: Dictionary = fresh["show"]
 var applied: Variant = show.get(RESULT_KEY)
 if not applied is Dictionary or applied.get("booking_id")!=id or applied.get("version")!=version_of(before):return _fail(before,"The completed show is missing its owned policy result.")
 var raw_plan: Variant = applied.get("plan")
 var raw_projection: Variant = applied.get("projection")
 if not _pinned_plan_valid(raw_plan) or not _projection_valid(raw_projection):return _fail(before,"The completed show plan or projection cannot be read safely.")
 var plan: Dictionary = raw_plan.duplicate(true)
 var projection: Dictionary = raw_projection.duplicate(true)
 if not _projection_matches(projection,_projection(before,plan)):return _fail(before,"The completed show projection does not match its saved inputs.")
 var booking: Dictionary = Calendar.pending(before)
 var seq: int = int(data["seq"])+1
 var receipt: Dictionary = {"version":version_of(before),"id":id,"booking_id":id,"seq":seq,"venue_id":str(booking["venue_id"]),"venue":str(show.get("venue",booking.get("venue",""))),"city":str(show.get("city",booking.get("city",""))),"scheduled_day":int(booking["day"]),"completed_day":int(show["day"]),"day_before":int(before.get("tour_day",1)),"day_after":int(after.get("tour_day",1)),"cash_before":int(before.get("cash",0)),"cash_after":int(after.get("cash",0)),"settled_fee":int(show["fee"]),"success":bool(show["success"]),"originals_played":int(show.get("originals_played",0)),"plan":plan,"projection":projection,"message":msg}
 var effects: Dictionary = {}
 for field in ["readiness","morale","tension","reputation","fans"]:
  var maximum: int = 100 if field!="fans" else 2147483647
  # Original Gigs/Calendar read absent counters as0, including reputation in a
  # genuine first C27 career. Snapshot that meaning without seeding career data;
  # malformed PRESENT values still refuse rather than being coerced or clamped.
  if not _number(before.get(field,0),0,maximum) or not _number(after.get(field,0),0,maximum):return _fail(before,"The original before/after show effects cannot be recorded safely.")
  var previous: int = int(before.get(field,0))
  var current: int = int(after.get(field,0))
  effects[field]={"before":previous,"after":current,"delta":current-previous}
 var venue: Dictionary = Gigs.get_venue(str(booking["venue_id"]))
 if (version_of(before)==1 and str(booking["venue_id"])!="local") or not _number(before.get("cash",-1)) or venue.is_empty() or not _number(venue.get("travel",-1)) or not _number(show.get("session_fee",-1)):return _fail(before,"The original show expenses cannot be recorded safely.")
 receipt["effects"]=effects
 receipt["expenses"]={"travel_paid":mini(int(venue["travel"]),int(before["cash"])),"session_paid":int(show["session_fee"])}
 if version_of(before)==2:
  var t: Dictionary=Booking.terms(before)
  receipt["commitment_id"]=t["commitment_id"]
  receipt[Booking.TERMS]=t
  receipt["trip_days"]=int(t["tariff"]["duration"])
  receipt["expenses"]["travel_paid"]=mini(int(venue["travel"]),int(before["cash"])) if str(booking["venue_id"])=="local" else int(venue["travel"])
  receipt["expenses"]["accommodation_paid"]=int(t["tariff"]["accommodation"])
  data["version"]=2
 receipt["responses"]=_responses(receipt)
 data["seq"]=seq
 data["seen_ids"][id]=seq
 data["records"].append(receipt)
 while data["records"].size()>RECORD_LIMIT:data["records"].pop_front()
 var result: Dictionary = after.duplicate(true)
 result[RECORDS_KEY]=data
 valid=validate(result)
 if not bool(valid.get("ok",false)):return _fail(before,str(valid["message"]))
 return {"ok":true,"state":result,"receipt":receipt.duplicate(true),"message":msg}

static func last_receipt(state: Dictionary) -> Dictionary:
 if not bool(_validate_records(state).get("ok",false)):return {}
 var records: Array = _records_view(state)["records"]
 return {} if records.is_empty() else records.back().duplicate(true)
