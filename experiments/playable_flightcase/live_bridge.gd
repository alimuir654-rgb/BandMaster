extends RefCounted
## Original hometown live-career rules over the existing C27 career dictionary.
## Pure adapter: original legacy rules plus explicitly versioned S53 show policy.
## No file IO, scene changes, callbacks or saving.
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const PracticeSession = preload("res://experiments/playable_flightcase/session.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const LivePolicy = preload("res://experiments/playable_flightcase/gig_performance_policy.gd")
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const LOCAL_VENUE := "local"

static func show_day(state: Dictionary) -> bool:
 var booking: Dictionary = Calendar.pending(state)
 if Booking.modern(state):return not bool(Booking.validate(state).get("ok",false)) or int(booking.get("day",-1))<=int(state.get("tour_day",0))
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

static func resolve(state: Dictionary, verb: String, choice: String = "", hire: bool = false, plan: Dictionary = {}) -> Dictionary:
 if verb in ["advance","perform","cancel","expire"] and not choice.is_empty():
  return {"ok":false,"message":"This live-career action does not accept a choice."}
 var before: Dictionary = state.duplicate(true)
 if state.has(Booking.KEY) or Booking.modern(state):return {"ok":false,"message":"Use this saved agreement's current booking and show controls."}
 if state.has(Journey.KEY):
  var journey_checked: Dictionary=Journey.validate(state)
  if not bool(journey_checked.get("ok",false)) or Journey.locked(state):
   return {"ok":false,"message":"Resume the saved gig journey before another live commitment."}
 if verb=="book_flow":
  var checked: Dictionary = Flow.validate(before)
  if not bool(checked.get("ok",false)):
   return {"ok":false,"message":str(checked.get("message","The show journal cannot be read."))}
  var booked: Dictionary = resolve(before,"book",choice,hire)
  if bool(booked.get("ok",false)):
   booked["state"] = Flow.new_booking(booked["state"])
   if not Flow.managed(booked["state"]):
    return {"ok":false,"message":"The new local-show journey could not be prepared. No booking was committed."}
  return booked
 if Flow.managed(before) and verb in ["depart","advance","soundcheck","perform"]:
  var checked: Dictionary = Flow.validate(before)
  if not bool(checked.get("ok",false)):
   return {"ok":false,"message":str(checked.get("message","The saved show plan needs attention."))}
 if verb in ["book","perform"]:
  var tracking: Dictionary = Reviews.validate(before)
  if not bool(tracking.get("ok",false)):
   return {"ok":false,"message":str(tracking.get("message","The show record cannot be read safely."))}
 match verb:
  "depart":
   return Flow.depart(before)
  "book":
   var eligible: Dictionary = booking_eligibility(before,hire,choice)
   if not bool(eligible.get("ok",false)):
    return {"ok":false,"message":str(eligible.get("message","Booking unavailable."))}
   if hire and choice!="standard":
    return {"ok":false,"message":"The session-drummer fallback uses the standard promoter offer."}
   return _post(before,Promoter.book(before,LOCAL_VENUE,choice,hire,Tour.DRIVE))
  "advance":
   if Flow.managed(before) and Flow.phase(before)!="arrival":
    return {"ok":false,"message":"Acknowledge the local journey before arriving."}
   if str(Night.stage(before).get("phase","none"))!="arrival":
    return {"ok":false,"message":"Arrival is not the current stage of this booking."}
   # Original arrival navigation does not run the successful-action post-chain.
   return Night.advance(before)
  "soundcheck":
   if Flow.managed(before):
    return Flow.soundcheck(before,plan)
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
   return _perform(before)
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
 var commitment: Dictionary=Booking.guard_commitment(before,"practice",maxi(0,int(after.get("tour_day",1))-int(before.get("tour_day",1))))
 if not bool(commitment.get("ok",false)):return before.duplicate(true)
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


static func _perform(before: Dictionary, journey: Dictionary = {}) -> Dictionary:
 if not bool(Night.stage(before).get("can_play",false)):
  return {"ok":false,"message":"Complete the arrival and soundcheck before going onstage."}
 var performance: Dictionary = before
 var owned: bool = Flow.managed(before)
 if owned:
  var prepared: Dictionary = Flow.prepare_performance(before)
  if not bool(prepared.get("ok",false)):
   return prepared
  performance = prepared["state"]
 var result: Dictionary = Calendar.perform(performance)
 if not bool(result.get("ok",false)):
  return result
 var settled: Dictionary = Promoter.settle(result["state"],before)
 if owned:
  var adjusted: Dictionary = Flow.after_original_settlement(before,settled)
  if not bool(adjusted.get("ok",false)):
   return adjusted
  settled = adjusted["state"]
 var policy_facts: Dictionary={}
 if not journey.is_empty():
  var applied: Dictionary=LivePolicy.apply(before,settled,journey)
  if not bool(applied.get("ok",false)):return applied
  settled=applied["state"]
  policy_facts=applied["actual_effects"]
 result["state"] = Night.reset_after_show(settled)
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
 if owned:
  var final: Dictionary = finished["state"]
  var row: Dictionary = final["gig_history"].back()
  finished["message"] = "%s — %s. %d originals. Final gross fee £%d. Cash £%d → £%d; day %d → %d." % [str(booking.get("venue","The show")),"GOOD RECEPTION" if bool(row.get("success",false)) else "A TOUGH NIGHT",int(row.get("originals_played",0)),int(row.get("fee",0)),int(before.get("cash",0)),int(final.get("cash",0)),int(before.get("tour_day",1)),int(final.get("tour_day",1))]
  if int(row.get("originals_played",0))==0:
   finished["message"] += " No originals were selected: the final gross fee was limited to £5."
  if not str(reviewed.get("message","")).is_empty():
   finished["message"] += "\n\n"+str(reviewed["message"])
  var recorded: Dictionary = Flow.record(before,finished["state"],str(finished.get("message","")))
  if not bool(recorded.get("ok",false)):
   return recorded
  finished["state"] = recorded["state"]
 if not journey.is_empty():
  var completed: Dictionary=Journey.complete(finished["state"],journey,policy_facts)
  if not bool(completed.get("ok",false)):return completed
  finished["state"]=completed["state"]
  var contextual: Dictionary=Core.after_action(before,finished["state"])
  if not bool(contextual.get("ok",false)):return contextual
  finished["state"]=contextual["state"]
  finished["journey_receipt"]=completed["receipt"]
  finished["finance_action"]="live:perform"
 if Booking.modern(before):
  var commitment: Dictionary=Booking.complete(before,finished["state"])
  if not bool(commitment.get("ok",false)):return commitment
  finished["state"]=commitment["state"]
  finished["closing_balances"]=Booking.trip_closes(before,finished["state"])
  if finished["closing_balances"].size()!=int(Booking.terms(before)["tariff"]["duration"]):return {"ok":false,"message":"The trip's closing accounts do not match its agreed duration."}
 return finished

static func wrap_journey(state: Dictionary, expected: Dictionary) -> Dictionary:
 var checked: Dictionary=Journey.prepare_wrap(state,expected)
 if not bool(checked.get("ok",false)):return checked
 return _perform(state.duplicate(true),checked["active"])

static func cancel_journey(state: Dictionary, expected: Dictionary) -> Dictionary:
 if Booking.modern(state):return cancel_selected(state,Booking.expected(state),expected)
 var checked: Dictionary=Journey._owned(state,expected)
 if not bool(checked.get("ok",false)):return checked
 var result: Dictionary=_post(state,Calendar.cancel(state.duplicate(true)),"booking_cancel")
 if bool(result.get("ok",false)):
  result["state"]=Journey.clear_cancelled(result["state"])
  result["finance_action"]="live:cancel"
 return result

static func journey_incident(state: Dictionary, expected: Dictionary, choice: String) -> Dictionary:
 var checked: Dictionary=Journey._owned(state,expected)
 if not bool(checked.get("ok",false)):return checked
 if checked["active"]["phase"]!="soundcheck":return {"ok":false,"message":"That soundcheck moment has passed."}
 var result: Dictionary=_post(state,Backstage.resolve(state.duplicate(true),choice),"backstage")
 if not bool(result.get("ok",false)):return result
 var rebased: Dictionary=Journey.rebase_owned_action(state,result["state"],expected)
 if not bool(rebased.get("ok",false)):return rebased
 rebased["message"]=str(result.get("message","The band responded."))
 rebased["finance_action"]="live:incident"
 return rebased


static func prepare_booking(state: Dictionary, request: Dictionary, expected: Dictionary) -> Dictionary:
 return Booking.prepare(state,request,expected)

static func book_selected(state: Dictionary, request: Dictionary, expected: Dictionary) -> Dictionary:
 var valid: Dictionary=Flow.validate(state)
 if not bool(valid.get("ok",false)):return valid
 var result: Dictionary=Booking.book(state,request,expected)
 if not bool(result.get("ok",false)):return result
 result["state"]=Flow.new_booking(result["state"])
 valid=Flow.validate(result["state"])
 if not bool(valid.get("ok",false)) or Flow.version_of(result["state"])!=2:return {"ok":false,"message":"The new show journey could not be prepared."}
 return _post(state,result)

static func cancellation_quote(state: Dictionary, expected: Dictionary, journey_expected: Dictionary = {}) -> Dictionary:
 var valid: Dictionary=Flow.validate(state)
 if not bool(valid.get("ok",false)):return valid
 if Journey.locked(state):
  valid=Journey._owned(state,journey_expected)
  if not bool(valid.get("ok",false)):return valid
 else:
  valid=Booking.guard_metadata(state)
  if not bool(valid.get("ok",false)):return valid
 var proof: Dictionary=Booking.departure(state)
 if not bool(proof.get("ok",false)):return proof
 return Booking.cancel_quote(state,expected,proof)

static func cancel_selected(state: Dictionary, expected: Dictionary, journey_expected: Dictionary = {}) -> Dictionary:
 var quote: Dictionary=cancellation_quote(state,expected,journey_expected)
 if not bool(quote.get("ok",false)):return quote
 var result: Dictionary=Booking.cancel_original(state,expected,quote["departure"])
 if not bool(result.get("ok",false)):return result
 if state.has(Journey.KEY):result["state"]=Journey.clear_cancelled(result["state"])
 result=_post(state,result,"booking_cancel")
 if int(result["state"].get("tour_day",1))>int(state.get("tour_day",1)):
  var context: Dictionary=Core.after_action(state,result["state"])
  if not bool(context.get("ok",false)):return context
  result["state"]=context["state"]
 result["finance_action"]="live:cancel"
 return result

static func expire_selected(state: Dictionary, expected: Dictionary) -> Dictionary:
 var valid: Dictionary=Flow.validate(state)
 if not bool(valid.get("ok",false)):return valid
 var result: Dictionary=Booking.expire_original(state,expected)
 if not bool(result.get("ok",false)):return result
 result=_post(state,result,"booking_missed")
 result["finance_action"]="live:expire"
 return result
