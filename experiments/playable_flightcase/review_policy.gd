extends RefCounted
## Factual settled-show records and one explicit recoverable offer restriction.
## No resolver, scoring, journal, cash/day changes, finance application or IO.
const KEY := "live_reviews_v1"
const VERSION := 1
const HISTORY_LIMIT := 80

static func _whole(value: Variant) -> bool:
 return (value is int or value is float) and float(value)==floor(float(value))

static func _valid_count(value: Variant, minimum: int = 0) -> bool:
 return _whole(value) and int(value)>=minimum

static func view(state: Dictionary) -> Dictionary:
 var raw: Variant = state.get(KEY,{})
 var data: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
 var defaults := {"version":VERSION,"seq":0,"seen_ids":{},"records":[],"last_poor_seq":0,"last_success_seq":0}
 for field in defaults:
  if not data.has(field):data[field]=defaults[field]
 return data

static func _invalid(message: String) -> Dictionary:
 return {"ok":false,"message":message}

static func validate(state: Dictionary) -> Dictionary:
 if not state.has(KEY):return {"ok":true,"message":""}
 var raw: Variant = state[KEY]
 if not raw is Dictionary or not _whole(raw.get("version",0)) or int(raw.get("version",0))!=VERSION:
  return _invalid("The saved show-review version needs validation before another booking or performance.")
 for field in ["seq","last_poor_seq","last_success_seq"]:
  if not raw.has(field) or not _valid_count(raw[field]):
   return _invalid("The saved show-review counters need validation.")
 var seq: int = int(raw["seq"])
 if int(raw["last_poor_seq"])>seq or int(raw["last_success_seq"])>seq:
  return _invalid("A saved show-review confidence counter is ahead of its sequence.")
 if not raw.get("seen_ids") is Dictionary or not raw.get("records") is Array or raw["records"].size()>HISTORY_LIMIT:
  return _invalid("The saved show-review history needs validation.")
 var seen: Dictionary = raw["seen_ids"]
 for id in seen:
  if not id is String or str(id).is_empty() or not _valid_count(seen[id],1) or int(seen[id])>seq:
   return _invalid("A saved settled-show identifier is malformed.")
 var retained: Dictionary = {}
 var prior_sequence := 0
 for record in raw["records"]:
  if not record is Dictionary:
   return _invalid("A saved show report is malformed.")
  for field in ["id","venue_id","venue","city","headline","body"]:
   if not record.get(field) is String:
    return _invalid("A saved show report has an invalid text field.")
  var id: String = str(record["id"])
  if id.is_empty() or retained.has(id) or not seen.has(id) or not _valid_count(record.get("seq",0),1) or int(record["seq"])!=int(seen[id]) or int(record["seq"])<=prior_sequence:
   return _invalid("A saved show report does not match its settled-show checkpoint.")
  for field in ["scheduled_day","completed_day"]:
   if not _valid_count(record.get(field,0),1):return _invalid("A saved show report has an invalid day.")
  if int(record["completed_day"])<int(record["scheduled_day"]) or not record.get("success") is bool or not _valid_count(record.get("settled_fee",-1)):
   return _invalid("A saved show report has invalid result facts.")
  if record.has("originals_played") and not _valid_count(record["originals_played"]):
   return _invalid("A saved original-song count is invalid.")
  for field in ["approach","promoter_terms"]:
   if record.has(field) and not record[field] is String:return _invalid("A saved show report has invalid original terms.")
  retained[id]=true
  prior_sequence=int(record["seq"])
 if seq==0 and (not seen.is_empty() or not raw["records"].is_empty()):
  return _invalid("An unstarted show-review checkpoint contains recorded shows.")
 if seq>0 and (raw["records"].is_empty() or prior_sequence!=seq):
  return _invalid("The latest saved show-review checkpoint is missing.")
 return {"ok":true,"message":""}

static func latest(state: Dictionary) -> Dictionary:
 if not bool(validate(state).get("ok",false)):return {}
 var data: Dictionary = view(state)
 var records: Array = data["records"]
 return {} if records.is_empty() else records.back().duplicate(true)

static func eligibility(state: Dictionary, venue_id: String = "local", offer_id: String = "standard") -> Dictionary:
 var valid: Dictionary = validate(state)
 if not bool(valid.get("ok",false)):
  return {"ok":false,"message":str(valid.get("message","Invalid show-review metadata.")),"restricted":false,"recovery":"Validate the saved show-review metadata before booking."}
 var data: Dictionary = view(state)
 var poor: bool = int(data["last_poor_seq"])>int(data["last_success_seq"])
 var restricted: bool = poor and offer_id=="guarantee"
 var recovery: String = "Play a successful hometown show to restore promoter confidence. STANDARD and GUESTLIST retain their normal requirements." if poor else ""
 # venue_id is deliberately not a gate. No regional policy is introduced.
 return {"ok":not restricted,"message":"The GUARANTEE offer is paused after the latest poor show. "+recovery if restricted else "","restricted":restricted,"recovery":recovery,"venue_id":venue_id}

static func _failure(before: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":before.duplicate(true),"message":message}

static func apply(before: Dictionary, settled: Dictionary) -> Dictionary:
 var valid: Dictionary = validate(before)
 if not bool(valid.get("ok",false)):return _failure(before,str(valid["message"]))
 valid=validate(settled)
 if not bool(valid.get("ok",false)):return _failure(before,str(valid["message"]))
 if before==settled:return {"ok":true,"state":settled.duplicate(true),"message":""}
 var booking_raw: Variant = before.get("booked_show",{})
 if not booking_raw is Dictionary or booking_raw.is_empty():
  return _failure(before,"A show report needs the original pending booking.")
 var booking: Dictionary = booking_raw
 if not booking.get("venue_id") is String or str(booking["venue_id"]).is_empty() or not _valid_count(booking.get("day",0),1):
  return _failure(before,"The original booking cannot identify a settled show.")
 var venue_id: String = str(booking["venue_id"])
 var scheduled: int = int(booking["day"])
 var id: String = "s49:show:%s:%d" % [venue_id,scheduled]
 var old: Dictionary = view(before)
 var data: Dictionary = view(settled)
 if data["seen_ids"].has(id):
  return {"ok":true,"state":settled.duplicate(true),"message":""}
 if old["seen_ids"].has(id):
  return _failure(before,"The settlement discarded an existing show-review checkpoint.")
 if before.has(KEY) and not settled.has(KEY):
  return _failure(before,"The settlement discarded the saved show-review metadata.")
 for field in ["seq","seen_ids","records","last_poor_seq","last_success_seq"]:
  if old[field]!=data[field]:return _failure(before,"The show-review checkpoint changed before this settlement was recorded.")
 if not _valid_count(before.get("tour_day",0),1) or int(before["tour_day"])!=scheduled:
  return _failure(before,"The original booking was not due on the performance day.")
 var remaining: Variant = settled.get("booked_show",null)
 if not remaining is Dictionary or not remaining.is_empty():
  return _failure(before,"The original show has not been settled and cleared.")
 var history_raw: Variant = settled.get("gig_history",[])
 var previous_raw: Variant = before.get("gig_history",[])
 if not history_raw is Array or history_raw.is_empty() or not previous_raw is Array or not history_raw.back() is Dictionary:
  return _failure(before,"No newly settled original show is available to review.")
 var history: Array = history_raw
 var previous: Array = previous_raw
 var show: Dictionary = history.back()
 if not show.get("venue_id") is String or str(show["venue_id"])!=venue_id:
  return _failure(before,"The settled show does not match the original venue.")
 for field in ["venue","city"]:
  if not show.get(field) is String or (booking.has(field) and str(show[field])!=str(booking[field])):
   return _failure(before,"The settled venue facts do not match the original booking.")
 if not _valid_count(show.get("day",0),1) or not _valid_count(settled.get("tour_day",0),1) or int(show["day"])!=int(settled["tour_day"]) or int(show["day"])<=scheduled:
  return _failure(before,"The actual completed show day is invalid.")
 if not show.get("success") is bool or not _valid_count(show.get("fee",-1)):
  return _failure(before,"The original settled success or fee is missing.")
 var expected: Array = previous.duplicate(true)
 expected.append(show.duplicate(true))
 if expected.size()>50:expected.pop_front()
 if expected!=history:
  return _failure(before,"The show history is not one newly settled original performance.")
 var seq: int = int(data["seq"])+1
 var success: bool = bool(show["success"])
 var headline: String = "A GOOD NIGHT" if success else "A TOUGH NIGHT"
 var body: String = ("A successful show" if success else "A difficult reception")+" at %s. Settled fee £%d. Scheduled day %d; completed day %d." % [str(show["venue"]),int(show["fee"]),scheduled,int(show["day"])]
 var report: Dictionary = {"id":id,"seq":seq,"venue_id":venue_id,"venue":str(show["venue"]),"city":str(show["city"]),"scheduled_day":scheduled,"completed_day":int(show["day"]),"success":success,"settled_fee":int(show["fee"]),"headline":headline,"body":body}
 for field in ["approach","originals_played","promoter_terms"]:
  if show.has(field):report[field]=show[field]
 if report.has("originals_played"):
  body+=" %d original song(s) were played." % int(report["originals_played"])
 if report.has("promoter_terms"):
  body+=" Promoter terms: "+str(report["promoter_terms"])+"."
 if success:
  body+=(" Promoter confidence has recovered; all existing booking requirements still apply." if int(old["last_poor_seq"])>int(old["last_success_seq"]) else " The good reception keeps GUARANTEE offers available under their normal booking requirements.")
 else:
  body+=" GUARANTEE offers are paused until a later successful show. STANDARD and GUESTLIST retain their normal requirements."
 report["body"]=body
 data["seq"]=seq
 data["seen_ids"][id]=seq
 data["records"].append(report)
 while data["records"].size()>HISTORY_LIMIT:data["records"].pop_front()
 data["last_success_seq" if success else "last_poor_seq"]=seq
 var after: Dictionary = settled.duplicate(true)
 after[KEY]=data
 valid=validate(after)
 if not bool(valid.get("ok",false)):return _failure(before,str(valid["message"]))
 return {"ok":true,"state":after,"message":body}
