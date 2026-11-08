extends RefCounted
## Owned booking commitments. Pure leaf: original models + protected guard leaves.
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Circuit = preload("res://experiments/playable_flightcase/scene_circuit.gd")
const KEY := "gig_commitments_v1"
const TERMS := "booking_terms_v1"
const MAX_DAY := 2147483647
const JOURNEY := "gig_journey_v1"
const VENUES := ["local","bristol","cardiff","birmingham","manchester","london"]

static func whole(value: Variant, low: int = 0, high: int = MAX_DAY) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=float(low) and float(value)<=float(high)

static func finite_tree(value: Variant) -> bool:
 if value is float:return is_finite(value)
 if value is Dictionary:
  for key in value:
   if not finite_tree(value[key]):return false
 if value is Array:
  for item in value:
   if not finite_tree(item):return false
 return true

static func _context_guard(state: Dictionary) -> Dictionary:
 if not whole(state.get("tour_day"),1) or not whole(state.get("cash")):return _bad("The saved career day or cash needs validation.")
 for field in ["reputation","fans","morale","tension","readiness","van_health","songs"]:
  if not whole(state.get(field,0),0,100 if field in ["morale","tension","readiness","van_health","reputation"] else MAX_DAY):return _bad("The saved band's preparation or accounts need validation.")
 var members: Variant=state.get("members")
 if not members is Array:return _bad("The saved band line-up needs validation.")
 for person in members:
  if not person is Dictionary:return _bad("A saved band member cannot be read safely.")
  for field in ["fatigue","morale","loyalty","skill","available_day"]:
   if person.has(field) and not whole(person[field],0,MAX_DAY if field=="available_day" else 100):return _bad("A saved band member's condition needs validation.")
 var songs: Variant=state.get("song_catalogue",[])
 if not songs is Array:return _bad("The finished-song catalogue cannot be read.")
 for song in songs:
  if song is Dictionary and song.has("quality") and not whole(song["quality"],0,100):return _bad("A saved original has invalid quality data.")
 return {"ok":true,"message":""}

static func canonical(value: Variant) -> Variant:
 if value is Dictionary:
  var keys: Array=value.keys()
  keys.sort_custom(func(a: Variant,b: Variant) -> bool:return str(a)<str(b))
  var rows: Array=[]
  for key in keys:rows.append([str(key),canonical(value[key])])
  return ["dictionary",rows]
 if value is Array:
  var rows: Array=[]
  for item in value:rows.append(canonical(item))
  return ["array",rows]
 return [typeof(value),value]

static func fingerprint(value: Variant) -> String:
 return var_to_bytes(canonical(value)).hex_encode().sha256_text()

static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func memory(state: Dictionary) -> Dictionary:
 return state[KEY].duplicate(true) if state.get(KEY) is Dictionary else {"version":1,"sequence":0,"seen_slots":{},"records":[],"venues":{}}

static func modern(state: Dictionary) -> bool:
 return state.get("booked_show") is Dictionary and state["booked_show"].has(TERMS)

static func terms(state: Dictionary) -> Dictionary:
 return state["booked_show"][TERMS].duplicate(true) if modern(state) and state["booked_show"][TERMS] is Dictionary else {}

static func _identity(id: Variant) -> Dictionary:
 if not id is String:return {}
 var parts: PackedStringArray=id.split(":")
 if parts.size()!=4 or parts[0]!="gig-commitment" or not parts[1].is_valid_int() or not parts[3].is_valid_int() or not VENUES.has(parts[2]):return {}
 var sequence: int=int(parts[1]);var day: int=int(parts[3])
 if not whole(sequence,1) or not whole(day,1) or id!="gig-commitment:%d:%s:%d" % [sequence,parts[2],day]:return {}
 return {"sequence":sequence,"venue_id":str(parts[2]),"day":day,"slot":"%s:%d" % [parts[2],day]}

static func terms_valid(raw: Variant) -> bool:
 if not raw is Dictionary or raw.get("version")!=1 or raw.get("policy_version")!=1 or raw.get("cancellation_version")!=1:return false
 var identity: Dictionary=_identity(raw.get("commitment_id"))
 if identity.is_empty() or not whole(raw.get("day"),1) or identity["day"]!=raw["day"] or not whole(raw.get("created_day"),1) or not raw.get("session_drummer") is bool:return false
 if not raw.get("offer_id") is String or not Promoter.OFFERS.has(raw["offer_id"]) or not raw.get("travel_plan") is String:return false
 var venue: Dictionary=Gigs.get_venue(str(identity["venue_id"]))
 if raw.has(Circuit.BILL) and (not Circuit.bill_valid(raw[Circuit.BILL]) or raw[Circuit.BILL].venue_id!=identity.venue_id or raw[Circuit.BILL].offer_id!=raw.offer_id):return false
 if not raw.get("venue_snapshot") is Dictionary or not raw.get("tariff") is Dictionary:return false
 for key in venue:
  if raw["venue_snapshot"].get(key)!=venue[key]:return false
 var cost: Dictionary=raw["tariff"]
 var accommodation: int=20+12*int(venue["tier"]) if raw["travel_plan"]==Tour.OVERNIGHT else 0
 if raw["travel_plan"] not in [Tour.DRIVE,Tour.OVERNIGHT] or (identity["venue_id"]=="local" and raw["travel_plan"]!=Tour.DRIVE):return false
 for key in ["fee","travel","accommodation","duration","wear"]:
  if not whole(cost.get(key),1 if key=="duration" else 0):return false
 if cost["fee"]!=venue["fee"] or cost["travel"]!=venue["travel"] or cost["accommodation"]!=accommodation or cost["duration"]!=venue["days"] or cost["wear"]!=(0 if identity["venue_id"]=="local" else venue["wear"]):return false
 if int(raw["created_day"])>MAX_DAY-14 or int(raw["day"])<int(raw["created_day"])+3 or int(raw["day"])>int(raw["created_day"])+14 or int(raw["day"])>MAX_DAY-int(cost["duration"]):return false
 return whole(raw.get("next_available_day"),1) and int(raw["next_available_day"])==int(raw["day"])+int(cost["duration"])

static func validate(state: Dictionary) -> Dictionary:
 var scene_guard: Dictionary=Circuit.validate(state)
 if not scene_guard.get("ok",false):return scene_guard
 # Structural dispatch only: no Flow import/backedge. A missing terms wrapper
 # cannot make a regional/future owned booking become a cheap legacy action.
 var show_marker: Variant=state.get("booked_show",{})
 if show_marker is Dictionary and show_marker.has("show_flow_v1"):
  var marker: Variant=show_marker["show_flow_v1"]
  if not marker is Dictionary or not whole(marker.get("version"),1,2):return _bad("The saved show journey requires a compatible agreement version.")
  if marker["version"]==2 and not show_marker.has(TERMS):return _bad("The regional show is missing its saved booking terms. Its data is retained.")
  if marker["version"]==1 and show_marker.has(TERMS):return _bad("The saved booking terms and journey version disagree.")
 if state.has(KEY):
  var raw: Variant=state[KEY]
  if not raw is Dictionary or raw.get("version")!=1 or not whole(raw.get("sequence")) or not raw.get("seen_slots") is Dictionary or not raw.get("records") is Array or raw["records"].size()>80 or not raw.get("venues") is Dictionary:return _bad("The saved booking commitments need a compatible version. Their data is retained.")
  var sequences: Dictionary={}
  for slot in raw["seen_slots"]:
   var identity: Dictionary=_identity(raw["seen_slots"][slot])
   if not slot is String or identity.is_empty() or identity["slot"]!=slot or int(identity["sequence"])>int(raw["sequence"]) or sequences.has(identity["sequence"]):return _bad("A saved booking commitment identity is invalid.")
   sequences[identity["sequence"]]=true
  if raw["seen_slots"].size()!=int(raw["sequence"]) or (int(raw["sequence"])>0 and not sequences.has(int(raw["sequence"]))):return _bad("The durable booking sequence is incomplete.")
  var seen: Dictionary={}
  for receipt in raw["records"]:
   if not receipt is Dictionary or receipt.get("version")!=1 or receipt.get("kind") not in ["cancelled","missed","completed"]:return _bad("A saved commitment result is unreadable.")
   var identity: Dictionary=_identity(receipt.get("commitment_id"))
   if identity.is_empty() or seen.has(receipt["commitment_id"]) or raw["seen_slots"].get(identity["slot"])!=receipt["commitment_id"] or receipt.get("venue_id")!=identity["venue_id"] or not whole(receipt.get("day"),1) or not terms_valid(receipt.get("terms")):return _bad("A saved commitment result does not match its agreement.")
   if receipt["terms"]["commitment_id"]!=receipt["commitment_id"]:return _bad("A saved agreement result has changed identity.")
   if receipt["kind"] in ["cancelled","missed"]:
    for field in ["cash_before","cash_after","fee_paid","travel_paid","waived","base_band","effective_band","day_before","day_after","reputation_before","reputation_after","morale_before","morale_after","blocked_until_day"]:
     if not whole(receipt.get(field)):return _bad("A saved cancelled agreement has invalid accounts.")
    if receipt["base_band"]>3 or receipt["effective_band"]>3 or int(receipt["cash_before"])-int(receipt["cash_after"])!=int(receipt["fee_paid"])+int(receipt["travel_paid"]) or receipt["day"]!=receipt["day_after"]:return _bad("A saved cancelled agreement does not reconcile.")
   if receipt["kind"]=="completed" and receipt["day"]!=receipt["terms"]["next_available_day"]:return _bad("A completed agreement has an invalid return day.")
   seen[receipt["commitment_id"]]=true
  for venue_id in raw["venues"]:
   var row: Variant=raw["venues"][venue_id]
   if not VENUES.has(venue_id) or not row is Dictionary or row.get("version")!=1 or not whole(row.get("last_cancellation_day"),1) or not whole(row.get("blocked_until_day"),1) or not row.get("terminal_ids") is Array:return _bad("The saved venue agreement history is invalid.")
   if int(row["blocked_until_day"])<int(row["last_cancellation_day"]) or row["terminal_ids"].is_empty():return _bad("The saved venue restriction has no terminal agreement.")
   var ids: Dictionary={}
   for id in row["terminal_ids"]:
    var identity: Dictionary=_identity(id)
    if identity.is_empty() or identity["venue_id"]!=venue_id or ids.has(id) or raw["seen_slots"].get(identity["slot"])!=id:return _bad("A saved venue restriction has an invalid commitment.")
    ids[id]=true
 if modern(state):
  var context: Dictionary=_context_guard(state)
  if not bool(context.get("ok",false)):return context
  if not state.has(KEY) or not terms_valid(state["booked_show"][TERMS]):return _bad("The saved show agreement needs validation. It has been retained.")
  var t: Dictionary=terms(state);var show: Dictionary=state["booked_show"]
  if not state.get("promoter_offer") is Dictionary:return _bad("The saved promoter agreement cannot be read.")
  var identity: Dictionary=_identity(t["commitment_id"])
  if memory(state)["seen_slots"].get(identity["slot"])!=t["commitment_id"]:return _bad("The saved show has no durable commitment identity.")
  for row in memory(state)["records"]:
   if row["commitment_id"]==t["commitment_id"]:return _bad("That booking already has a terminal result.")
  if memory(state)["venues"].get(identity["venue_id"],{}).get("terminal_ids",[]).has(t["commitment_id"]):return _bad("That cancelled agreement cannot be reopened.")
  for key in ["day","travel_plan","session_drummer"]:
   if show.get(key)!=t[key]:return _bad("The booking and its saved agreement disagree.")
  if show.get("venue_id")!=identity["venue_id"] or show.get("venue")!=t["venue_snapshot"]["venue"] or show.get("city")!=t["venue_snapshot"]["city"] or state.get("promoter_offer",{}).get("venue_id")!=show["venue_id"] or state.get("promoter_offer",{}).get("offer_id")!=t["offer_id"]:return _bad("The room or promoter agreement changed after booking.")
 return {"ok":true,"message":""}

static func guard_metadata(state: Dictionary) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return valid
 if state.has(JOURNEY):
  var raw: Variant=state[JOURNEY]
  if not raw is Dictionary or raw.get("version") not in [1,2] or not whole(raw.get("sequence")) or not raw.get("active") is Dictionary or not raw["active"].is_empty():return _bad("Finish or cancel the saved gig before changing band commitments or recorded context.")
 return {"ok":true,"message":""}

static func guard_commitment(state: Dictionary, _action: String, duration: int = 0) -> Dictionary:
 var guard: Dictionary=guard_metadata(state)
 if not bool(guard["ok"]):return guard
 guard=validate(state)
 if not bool(guard["ok"]) or not modern(state):return guard
 if not whole(state.get("tour_day"),1) or not whole(duration):return _bad("The current career date cannot be read safely.")
 var today: int=int(state["tour_day"]);var date: int=int(terms(state)["day"])
 if today>=date:return _bad("The booked show comes first. Open its saved night or acknowledge the missed commitment.")
 if duration>0 and (today>MAX_DAY-duration or today+duration>date):return _bad("That activity would run past the booked show. Prepare within the days you have.")
 return {"ok":true,"message":""}

static func expected(state: Dictionary) -> Dictionary:
 return {"source_hash":fingerprint(state),"sequence":int(memory(state).get("sequence",0)),"pending_commitment_id":str(terms(state).get("commitment_id",""))}

static func _token(state: Dictionary, token: Dictionary) -> bool:
 return token==expected(state)

static func _lineup(state: Dictionary, hire: bool) -> bool:
 if not state.get("members") is Array:return false
 var count: int=0;var drummer: bool=false
 for person in state["members"]:
  if not person is Dictionary:return false
  if str(person.get("life_status","active"))=="active":
   count+=1
   if str(person.get("role","")).to_lower().contains("drum"):drummer=true
 return count>=1 and not (count>=2 and drummer) if hire else count>=2 and drummer

static func options(state: Dictionary) -> Dictionary:
 for field in ["tour_day","cash","reputation","fans","van_health"]:
  if not whole(state.get(field,1 if field=="tour_day" else 0),1 if field=="tour_day" else 0):return _bad("The saved booking context needs validation.")
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return valid
 var today: int=int(state.get("tour_day",1)) if whole(state.get("tour_day"),1) else 0
 var rooms: Array=[]
 var available: Array=Gigs.available(int(state.get("reputation",0)),int(state.get("fans",0)))
 for venue in Gigs.VENUES:
  var blocked: int=int(memory(state)["venues"].get(venue["id"],{}).get("blocked_until_day",0))
  var trips: Array=[]
  for plan in Tour.choices(state,str(venue["id"])):
   trips.append({"id":str(plan["id"]),"label":"HEAD HOME" if plan["id"]==Tour.DRIVE else "STAY OVERNIGHT","available":bool(plan["available"]),"transport":int(plan["travel_cost"]),"accommodation":int(plan["accommodation_cost"]),"total":int(plan["total_cost"]),"duration":int(venue["days"])})
  rooms.append({"id":str(venue["id"]),"venue":str(venue["venue"]),"city":str(venue["city"]),"listed_fee":int(venue["fee"]),"duration":int(venue["days"]),"available":available.has(venue) and today>=blocked,"message":"The promoter is ready to talk." if available.has(venue) and today>=blocked else ("This venue needs time before another booking." if today<blocked else "Build your name before asking for this room."),"trips":trips})
 return {"ok":true,"rooms":rooms,"today":today,"first_day":today+3 if today>0 and today<=MAX_DAY-14 else 0,"last_day":today+14 if today>0 and today<=MAX_DAY-14 else 0}

static func prepare(state: Dictionary, request: Dictionary, token: Dictionary) -> Dictionary:
 var context: Dictionary=_context_guard(state)
 if not bool(context.get("ok",false)):return context
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return valid
 valid=guard_metadata(state)
 if not bool(valid["ok"]):return valid
 if not _token(state,token):return _bad("The band or booking changed. Review the current agreement.")
 if not state.get("booked_show",{}) is Dictionary or not state.get("booked_show",{}).is_empty():return _bad("Finish the existing booking before agreeing another show.")
 if not whole(state.get("tour_day"),1) or not whole(state.get("cash")) or not state.get("career_journal",[]) is Array:return _bad("The current career accounts or journal cannot be read safely.")
 for key in ["venue_id","offer_id","travel_plan"]:
  if not request.get(key) is String:return _bad("Choose a real room, promoter agreement and trip.")
 if not VENUES.has(request["venue_id"]) or not Promoter.OFFERS.has(request["offer_id"]) or not request.get("session_drummer") is bool or not whole(request.get("day"),1):return _bad("That room, date or trip is unsupported.")
 if request.has(Circuit.BILL):
  var proposed: Variant=request[Circuit.BILL]
  if not Circuit.bill_valid(proposed):return _bad("The promoter's proposal needs validation.")
  var live_offer: Dictionary=Circuit.proposal(state,request.venue_id,proposed.pitch,proposed.asked)
  if not live_offer.get("ok",false) or fingerprint(live_offer.bill)!=fingerprint(proposed) or request.offer_id!=proposed.offer_id:return _bad("The band's standing or this promoter offer changed. Talk through the room again.")
 if state.has("radio_visit_v1"):
  var radio: Variant=state["radio_visit_v1"]
  if not radio is Dictionary or radio.get("version")!=1 or not radio.get("active") is Dictionary or not radio["active"].is_empty():return _bad("Finish or cancel the radio visit before another booking.")
 var financial: Dictionary=Finance.guard(state)
 if not bool(financial.get("ok",false)):return financial
 var offer_guard: Dictionary=Reviews.eligibility(state,request["venue_id"],request["offer_id"])
 if not bool(offer_guard.get("ok",false)):return offer_guard
 for field in ["reputation","fans","morale","tension","readiness","van_health"]:
  if not whole(state.get(field,0)):return _bad("The saved band's preparation or accounts need validation.")
 var today: int=int(state["tour_day"]);var date: int=int(request["day"])
 if today>MAX_DAY-14 or date<today+3 or date>today+14:return _bad("Choose a show day from three days to a fortnight ahead.")
 var venue: Dictionary=Gigs.get_venue(request["venue_id"])
 if not Gigs.available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):return _bad("This promoter has not offered the band a show yet.")
 if today<int(memory(state)["venues"].get(request["venue_id"],{}).get("blocked_until_day",0)):return _bad("This venue needs time before another booking.")
 if memory(state)["seen_slots"].has("%s:%d" % [request["venue_id"],date]):return _bad("That room and day already belong to a recorded commitment. Choose a fresh date.")
 if not _lineup(state,request["session_drummer"]) or (request["session_drummer"] and request["offer_id"]!="standard"):return _bad("Choose a booking supported by the actual active line-up.")
 var trip: Dictionary=Tour.validate(state,request["venue_id"],request["travel_plan"],request["session_drummer"])
 if not bool(trip.get("ok",false)):return trip
 var duration: int=int(venue["days"])
 if date>MAX_DAY-duration:return _bad("That trip would exceed the supported career-day range.")
 return {"ok":true,"request":request.duplicate(true),"quote":{"venue_id":request["venue_id"],"venue":venue["venue"],"city":venue["city"],"day":date,"listed_fee":int(venue["fee"]),"transport":int(trip["plan"]["total_cost"])-int(trip["plan"]["accommodation_cost"]),"accommodation":int(trip["plan"]["accommodation_cost"]),"session":25 if request["session_drummer"] else 0,"total_cost":int(trip["plan"]["total_cost"])+(25 if request["session_drummer"] else 0),"duration":duration,"next_available_day":date+duration,"offer_id":request["offer_id"],"travel_plan":request["travel_plan"]}}

static func book(state: Dictionary, request: Dictionary, token: Dictionary) -> Dictionary:
 var prepared: Dictionary=prepare(state,request,token)
 if not bool(prepared.get("ok",false)):return prepared
 var old: Array=state.get("career_journal",[])
 var result: Dictionary=Promoter.book(state,request["venue_id"],request["offer_id"],request["session_drummer"],request["travel_plan"])
 if not bool(result.get("ok",false)):return result
 var after: Dictionary=result["state"]
 var journal: Array=after.get("career_journal",[])
 if journal.is_empty() or not journal.back() is Dictionary:return _bad("The fresh booking journal could not be identified.")
 var expected_rows: Array=old.duplicate(true)
 expected_rows.append(journal.back().duplicate(true))
 while expected_rows.size()>80:expected_rows.pop_front()
 if expected_rows!=journal:return _bad("The booking changed unrelated saved notes.")
 var data: Dictionary=memory(state)
 if int(data["sequence"])>=MAX_DAY:return _bad("The saved booking sequence is at its supported limit.")
 var sequence: int=int(data["sequence"])+1
 var id: String="gig-commitment:%d:%s:%d" % [sequence,request["venue_id"],int(request["day"])]
 var venue: Dictionary=Gigs.get_venue(request["venue_id"])
 var quote: Dictionary=prepared["quote"]
 var t: Dictionary={"version":1,"commitment_id":id,"policy_version":1,"cancellation_version":1,"venue_snapshot":venue.duplicate(true),"day":int(request["day"]),"offer_id":str(request["offer_id"]),"travel_plan":str(request["travel_plan"]),"session_drummer":bool(request["session_drummer"]),"tariff":{"fee":int(venue["fee"]),"travel":int(venue["travel"]),"accommodation":int(quote["accommodation"]),"duration":int(quote["duration"]),"wear":0 if request["venue_id"]=="local" else int(venue["wear"])},"next_available_day":int(quote["next_available_day"]),"created_day":int(state["tour_day"])}
 after["booked_show"]["day"]=int(request["day"])
 if request.has(Circuit.BILL):t[Circuit.BILL]=request[Circuit.BILL].duplicate(true)
 after["booked_show"][TERMS]=t
 data["sequence"]=sequence
 data["seen_slots"]["%s:%d" % [request["venue_id"],int(request["day"])]]=id
 after[KEY]=data
 var text: String="%s in %s is booked for DAY %d. %d career day(s) reserved; next available DAY %d." % [venue["venue"],venue["city"],int(request["day"]),int(quote["duration"]),int(quote["next_available_day"])]
 var fresh: Dictionary=journal.back().duplicate(true)
 fresh["id"]="booking:%d:%s" % [int(request["day"]),request["venue_id"]]
 fresh["text"]=text
 fresh["commitment_id"]=id
 journal[-1]=fresh
 after["career_journal"]=journal
 var checked: Dictionary=validate(after)
 if not bool(checked["ok"]):return checked
 return {"ok":true,"changed":true,"state":after,"message":text,"quote":quote,"commitment_id":id}

static func trip_closes(before: Dictionary, after: Dictionary) -> Array:
 if not whole(before.get("tour_day"),1) or not whole(after.get("tour_day"),1) or not whole(before.get("cash")) or not whole(after.get("cash")):return []
 var count: int=int(after["tour_day"])-int(before["tour_day"])
 if count<1 or count>3:return []
 var closes: Array=[]
 for index in range(count):closes.append(int(after["cash"]) if index==count-1 else int(before["cash"]))
 return closes

static func departure(state: Dictionary) -> Dictionary:
 var raw: Variant=state.get(JOURNEY,{})
 if not raw is Dictionary or raw.get("version",1) not in [1,2] or (state.has(JOURNEY) and not whole(raw.get("sequence"))) or not raw.get("active",{}) is Dictionary:return _bad("The saved trip needs a compatible version.")
 var visit: Dictionary=raw.get("active",{})
 if visit.is_empty():return {"ok":true,"departed":false,"liability":0}
 if raw["version"]!=2 or visit.get("version")!=2 or not visit.get("departure_committed") is bool or not whole(visit.get("departure_liability")):return _bad("The saved departure cannot be verified.")
 var source: Dictionary=state.duplicate(true);source.erase(JOURNEY)
 if visit.get("source_hash")!=fingerprint(source):return _bad("The saved trip changed. Its departure has been held.")
 return {"ok":true,"departed":visit["departure_committed"],"liability":int(visit["departure_liability"]),"journey_id":str(visit.get("id","")),"revision":int(visit.get("revision",-1))}

static func cancel_quote(state: Dictionary, token: Dictionary, validated_departure: Dictionary = {}) -> Dictionary:
 var context: Dictionary=_context_guard(state)
 if not bool(context.get("ok",false)):return context
 var finance: Dictionary=Finance.guard(state)
 if not bool(finance.get("ok",false)):return finance
 for field in ["reputation","morale"]:
  if not whole(state.get(field,0),0,100):return _bad("The band's current condition cannot be read safely.")
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return valid
 if not modern(state) or not _token(state,token) or not whole(state.get("tour_day"),1) or not whole(state.get("cash")):return _bad("That saved booking changed. Review its current options.")
 var proof: Dictionary=departure(state)
 if not bool(proof.get("ok",false)):return proof
 if validated_departure!=proof:return _bad("The trip's current departure must be validated by its owning controller.")
 var t: Dictionary=terms(state);var today: int=int(state["tour_day"])
 if today>int(t["day"]):return _bad("A missed commitment needs its explicit acknowledgement.")
 var left: int=int(t["day"])-today
 var base: int=3 if proof["departed"] else (0 if left>=3 else (1 if left>=1 else 2))
 var repeat: bool=false
 for row in memory(state)["records"]:
  if row["kind"]=="cancelled" and int(row["day"])>=today-13 and int(row["day"])<=today:repeat=true
 var band: int=mini(3,base+(1 if repeat else 0))
 var fee: int=int(t["tariff"]["fee"])
 var quoted_fee: int=[maxi(15,ceili(float(fee)/4.0)),maxi(20,ceili(float(fee)/2.0)),maxi(25,ceili(3.0*float(fee)/4.0)),maxi(25,fee)][band]
 var liability: int=int(proof["liability"]) if proof["departed"] else 0
 var travel_paid: int=mini(int(state["cash"]),liability)
 var paid: int=mini(int(state["cash"])-travel_paid,quoted_fee)
 var used_days: int=1 if proof["departed"] else 0
 if today>MAX_DAY-used_days or today+used_days>MAX_DAY-[0,3,7,14][band]:return _bad("The cancellation would exceed the supported career-day range.")
 return {"ok":true,"commitment_id":t["commitment_id"],"base_band":base,"effective_band":band,"quoted_fee":quoted_fee,"liability":liability,"travel_paid":travel_paid,"fee_paid":paid,"total_paid":travel_paid+paid,"waived":quoted_fee+liability-travel_paid-paid,"reputation_loss":[3,6,8,10][band],"morale_loss":[0,2,4,6][band],"days":used_days,"blocked_until_day":today+used_days+[0,3,7,14][band],"departure":proof}

static func _terminal(before: Dictionary, raw: Dictionary, quote: Dictionary, kind: String) -> Dictionary:
 var after: Dictionary=raw.duplicate(true);var t: Dictionary=terms(before)
 after["cash"]=int(before["cash"])-int(quote["total_paid"])
 after["tour_day"]=int(before["tour_day"])+int(quote["days"])
 after["reputation"]=maxi(0,int(before.get("reputation",0))-int(quote["reputation_loss"]))
 after["morale"]=maxi(0,int(before.get("morale",0))-int(quote["morale_loss"]))
 var record: Dictionary={"version":1,"kind":kind,"commitment_id":t["commitment_id"],"venue_id":t["venue_snapshot"]["id"],"terms":t.duplicate(true),"day":int(after["tour_day"]),"day_before":int(before["tour_day"]),"day_after":int(after["tour_day"]),"cash_before":int(before["cash"]),"cash_after":int(after["cash"]),"fee_paid":quote["fee_paid"],"travel_paid":quote["travel_paid"],"waived":quote["waived"],"base_band":quote["base_band"],"effective_band":quote["effective_band"],"reputation_before":int(before.get("reputation",0)),"reputation_after":int(after["reputation"]),"morale_before":int(before.get("morale",0)),"morale_after":int(after["morale"]),"blocked_until_day":quote["blocked_until_day"]}
 var data: Dictionary=memory(before)
 data["records"].append(record)
 while data["records"].size()>80:data["records"].pop_front()
 var venue_id: String=str(record["venue_id"])
 var history: Dictionary=data["venues"].get(venue_id,{"version":1,"last_cancellation_day":0,"blocked_until_day":0,"terminal_ids":[]}).duplicate(true)
 history["last_cancellation_day"]=int(after["tour_day"])
 history["blocked_until_day"]=maxi(int(history["blocked_until_day"]),int(quote["blocked_until_day"]))
 history["terminal_ids"].append(t["commitment_id"])
 data["venues"][venue_id]=history
 after[KEY]=data
 var message: String="%s at %s on DAY %d. Paid £%d; %d career day(s) used. The booking is closed." % ["Missed commitment" if kind=="missed" else "Cancelled booking",t["venue_snapshot"]["venue"],int(t["day"]),int(quote["total_paid"]),int(quote["days"])]
 var journal: Array=after.get("career_journal",[]).duplicate(true)
 if journal.is_empty() or not journal.back() is Dictionary:return _bad("The original terminal journal entry is missing.")
 var fresh: Dictionary=journal.back().duplicate(true)
 fresh["id"]="gig-terminal:"+str(t["commitment_id"])
 fresh["text"]=message
 fresh["commitment_id"]=t["commitment_id"]
 journal[-1]=fresh
 after["career_journal"]=journal
 var flows: Array=[]
 if int(quote["travel_paid"])>0:flows.append({"direction":"outgoing","category":"Travel","amount":int(quote["travel_paid"])})
 if int(quote["fee_paid"])>0:flows.append({"direction":"outgoing","category":"Cancellation","amount":int(quote["fee_paid"])})
 return {"ok":true,"changed":true,"state":after,"message":message,"flows":flows,"closing_balances":trip_closes(before,after),"terminal_receipt":record}

static func cancel_original(state: Dictionary, token: Dictionary, validated_departure: Dictionary = {}) -> Dictionary:
 var quote: Dictionary=cancel_quote(state,token,validated_departure)
 if not bool(quote.get("ok",false)):return quote
 var original: Dictionary=Calendar.cancel(state)
 if not bool(original.get("ok",false)):return original
 return _terminal(state,original["state"],quote,"cancelled")

static func expire_quote(state: Dictionary, token: Dictionary) -> Dictionary:
 var context: Dictionary=_context_guard(state)
 if not bool(context.get("ok",false)):return context
 var financial: Dictionary=Finance.guard(state)
 if not bool(financial.get("ok",false)):return financial
 var valid: Dictionary=validate(state)
 if not bool(valid["ok"]):return valid
 if not modern(state) or not _token(state,token) or not whole(state.get("tour_day"),1) or int(state["tour_day"])<=int(terms(state)["day"]):return _bad("There is no current missed agreement to acknowledge.")
 valid=guard_metadata(state)
 if not bool(valid["ok"]):return valid
 # Quote the existing due-day policy without falsifying the authoritative day.
 var t: Dictionary=terms(state);var fee: int=int(t["tariff"]["fee"])
 var band: int=2
 for row in memory(state)["records"]:
  if row["kind"]=="cancelled" and int(row["day"])>=int(state["tour_day"])-13 and int(row["day"])<=int(state["tour_day"]):band=3
 var quoted: int=maxi(25,ceili(3.0*float(fee)/4.0)) if band==2 else maxi(25,fee)
 if int(state["tour_day"])>MAX_DAY-[7,14][band-2]:return _bad("The missed agreement exceeds the supported career-day range.")
 var quote: Dictionary={"base_band":2,"effective_band":band,"fee_paid":mini(int(state.get("cash",0)),quoted),"travel_paid":0,"total_paid":mini(int(state.get("cash",0)),quoted),"waived":maxi(0,quoted-int(state.get("cash",0))),"reputation_loss":8 if band==2 else 10,"morale_loss":6,"days":0,"blocked_until_day":int(state["tour_day"])+[7,14][band-2]}
 quote["ok"]=true
 return quote


static func expire_original(state: Dictionary, token: Dictionary) -> Dictionary:
 var quote: Dictionary=expire_quote(state,token)
 if not bool(quote.get("ok",false)):return quote
 return _terminal(state,Calendar.expire(state),quote,"missed")

static func complete(before: Dictionary, after: Dictionary) -> Dictionary:
 if not modern(before):return {"ok":true,"state":after.duplicate(true)}
 var valid: Dictionary=validate(before)
 if not bool(valid["ok"]):return valid
 var data: Dictionary=memory(after);var t: Dictionary=terms(before)
 for row in data["records"]:
  if row["commitment_id"]==t["commitment_id"]:return _bad("This agreement already has a terminal result.")
 data["records"].append({"version":1,"kind":"completed","commitment_id":t["commitment_id"],"venue_id":t["venue_snapshot"]["id"],"terms":t,"day":int(after["tour_day"])})
 while data["records"].size()>80:data["records"].pop_front()
 var result: Dictionary=after.duplicate(true);result[KEY]=data
 return {"ok":true,"state":result}
