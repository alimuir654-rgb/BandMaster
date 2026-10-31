extends RefCounted
## Original hometown live-career rules over the existing C27 career dictionary.
## Pure adapter: no file IO, scene changes, callbacks, saving or new scoring.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const PracticeSession = preload("res://experiments/playable_flightcase/session.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const LOCAL_VENUE := "local"

static func show_day(state: Dictionary) -> bool:
 var booking: Dictionary = Calendar.pending(state)
 return not booking.is_empty() and int(booking.get("day",-1))==int(state.get("tour_day",0))

static func booking_eligibility(state: Dictionary, hire: bool = false, offer_id: String = "standard") -> Dictionary:
 var active := 0
 var drummer := false
 var roster: Variant = state.get("members",[])
 if roster is Array:
  for raw in roster:
   if raw is Dictionary and str(raw.get("life_status","active"))=="active":
    active += 1
    if str(raw.get("role","")).to_lower().contains("drum"):
     drummer = true
 var normal_ready: bool = active>=2 and drummer
 # Original promoter UI only offers session fallback to an inadequate normal
 # lineup. Existing Tour validation includes travel plus the existing £25 fee.
 var offer: Dictionary = Promoter.negotiate(state,LOCAL_VENUE,offer_id)
 var normal_plan: Dictionary = Tour.validate(state,LOCAL_VENUE,Tour.DRIVE,false)
 var session_plan: Dictionary = Tour.validate(state,LOCAL_VENUE,Tour.DRIVE,true)
 var session_available: bool = not normal_ready and active>=1 and bool(offer.get("ok",false)) and bool(session_plan.get("ok",false))
 var view := {"ok":false,"message":"","active":active,"drummer":drummer,"normal_ready":normal_ready,"session_available":session_available}
 if not bool(offer.get("ok",false)):
  view["message"] = str(offer.get("message","Booking unavailable."))
 elif hire:
  if normal_ready:
   view["message"] = "Your active lineup already covers a normal booking. Choose a promoter offer without a session drummer."
  elif active<1:
   view["message"] = "At least one active band member is needed with a session drummer."
  elif not bool(session_plan.get("ok",false)):
   view["message"] = str(session_plan.get("message","The session journey is unavailable."))
  else:
   view["ok"] = true
 elif not normal_ready:
  view["message"] = "A normal booking needs two active musicians including a drummer."
 elif not bool(normal_plan.get("ok",false)):
  view["message"] = str(normal_plan.get("message","The journey is unavailable."))
 else:
  view["ok"] = true
 if bool(view["ok"]):
  var confidence: Dictionary = Reviews.eligibility(state,LOCAL_VENUE,offer_id)
  if not bool(confidence.get("ok",false)):
   view["ok"] = false
   view["message"] = str(confidence.get("message","This promoter offer is unavailable."))
 return view

static func _post(before: Dictionary, result: Dictionary, source: String = "") -> Dictionary:
 if bool(result.get("ok",false)):
  result["state"] = Life.refresh(Calendar.expire(Story.observe(before,result["state"],source)))
 return result

static func _new_journal_text(previous: Dictionary, current: Dictionary) -> Array[String]:
 var old_rows: Variant = previous.get("career_journal",[])
 var new_rows: Variant = current.get("career_journal",[])
 var texts: Array[String] = []
 if not new_rows is Array:
  return texts
 for raw in new_rows:
  if not raw is Dictionary or (old_rows is Array and old_rows.has(raw)):
   continue
  var text: String = str(raw.get("text",""))
  if not text.strip_edges().is_empty() and not texts.has(text):
   texts.append(text)
 return texts

static func resolve(state: Dictionary, verb: String, choice: String = "", hire: bool = false) -> Dictionary:
 if verb in ["advance","perform","cancel","expire"] and not choice.is_empty():
  return {"ok":false,"message":"This live-career action does not accept a choice."}
 var before: Dictionary = state.duplicate(true)
 if verb in ["book","perform"]:
  var tracking: Dictionary = Reviews.validate(before)
  if not bool(tracking.get("ok",false)):
   return {"ok":false,"message":str(tracking.get("message","The show record cannot be read safely."))}
 match verb:
  "book":
   var eligible: Dictionary = booking_eligibility(before,hire,choice)
   if not bool(eligible.get("ok",false)):
    return {"ok":false,"message":str(eligible.get("message","Booking unavailable."))}
   if hire and choice!="standard":
    return {"ok":false,"message":"The session-drummer fallback uses the standard promoter offer."}
   return _post(before,Promoter.book(before,LOCAL_VENUE,choice,hire,Tour.DRIVE))
  "advance":
   if str(Night.stage(before).get("phase","none"))!="arrival":
    return {"ok":false,"message":"Arrival is not the current stage of this booking."}
   # Original arrival navigation does not run the successful-action post-chain.
   return Night.advance(before)
  "soundcheck":
   var chosen: Dictionary = Night.choose_set(before,choice)
   if not bool(chosen.get("ok",false)):
    return chosen
   var advanced: Dictionary = Night.advance(chosen["state"])
   if not bool(advanced.get("ok",false)):
    return advanced
   # One UI commitment combines the existing choice and advancement. Keep the
   # original authored approach message; neither step spends a day or money.
   chosen["state"] = advanced["state"]
   return chosen
  "incident":
   # The original UI permits continuing without resolving an optional incident.
   return _post(before,Backstage.resolve(before,choice),"backstage")
  "perform":
   if not bool(Night.stage(before).get("can_play",false)):
    return {"ok":false,"message":"Complete the arrival and soundcheck before going onstage."}
   var result: Dictionary = Calendar.perform(before)
   if not bool(result.get("ok",false)):
    return result
   result["state"] = Night.reset_after_show(Promoter.settle(result["state"],before))
   var terms: Dictionary = before.get("promoter_offer",{})
   var history: Array = result["state"].get("gig_history",[])
   if not terms.is_empty() and not history.is_empty():
    var latest: Dictionary = history.back()
    result["message"] = str(result.get("message","Show finished."))+" Promoter settlement: £%d after the %s agreement." % [int(latest.get("fee",0)),str(terms.get("offer_id","standard"))]
   var booking: Dictionary = Calendar.pending(before)
   var finished: Dictionary = _post(before,result,"gig:"+str(booking.get("venue_id","")))
   var reviewed: Dictionary = Reviews.apply(before,finished["state"])
   if not bool(reviewed.get("ok",false)):
    return {"ok":false,"message":str(reviewed.get("message","The show record could not be completed."))}
   finished["state"] = reviewed["state"]
   if not str(reviewed.get("message","")).is_empty():
    finished["message"] = str(finished.get("message",""))+"\n\n"+str(reviewed["message"])
   return finished
  "cancel":
   return _post(before,Calendar.cancel(before),"booking_cancel")
  "expire":
   var booking: Dictionary = Calendar.pending(before)
   if booking.is_empty() or int(before.get("tour_day",1))<=int(booking.get("day",0)):
    return {"ok":false,"message":"There is no overdue booking to close."}
   var expired: Dictionary = Calendar.expire(before)
   var texts: Array[String] = _new_journal_text(before,expired)
   var message: String = " ".join(texts)
   return _post(before,{"ok":true,"state":expired,"message":message})
  _:
   return {"ok":false,"message":"Unknown live-career action."}

static func after_practice(before: Dictionary, after: Dictionary) -> Dictionary:
 # Preserve the entire verified non-live practice contract byte-for-byte in
 # value. Merely opening live screens must not activate unrelated post-rules.
 if Calendar.pending(before).is_empty():
  return after.duplicate(true)
 var current: Dictionary = Life.refresh(Calendar.expire(Story.observe(before,after)))
 var raw_report: Variant = current.get("last_rehearsal_outcome",null)
 if not raw_report is Dictionary or raw_report.is_empty() or int(raw_report.get("version",0))!=1:
  return current
 var report: Dictionary = raw_report.duplicate(true)
 var raw_metrics: Variant = report.get("metrics",null)
 if raw_metrics is Dictionary:
  var metrics: Dictionary = raw_metrics.duplicate(true)
  for key in ["readiness","morale","tension","cash","tour_day"]:
   if metrics.has(key) and metrics[key] is Dictionary:
    var row: Dictionary = metrics[key].duplicate(true)
    var start: int = int(before.get(key,0))
    var finish: int = int(current.get(key,0))
    row["before"] = start
    row["after"] = finish
    row["delta"] = finish-start
    metrics[key] = row
  if metrics.has("cohesion") and metrics["cohesion"] is Dictionary:
   # Reuse the exact existing C27 active-pair mean; SongChemistry is a
   # different measure and must not substitute for the report's cohesion.
   var practice = PracticeSession.new()
   var start: int = int(practice._cohesion(before))
   var finish: int = int(practice._cohesion(current))
   var row: Dictionary = metrics["cohesion"].duplicate(true)
   row["before"] = start
   row["after"] = finish
   row["delta"] = finish-start
   metrics["cohesion"] = row
  report["metrics"] = metrics
 if report.has("reason"):
  var reason: String = str(report["reason"])
  for text in _new_journal_text(after,current):
   if not reason.contains(text):
    reason += (" " if not reason.is_empty() else "")+text
  report["reason"] = reason
 current["last_rehearsal_outcome"] = report
 return current
