extends RefCounted
# Calendar decisions are pure, deterministic, and additive to existing saves.
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Chemistry = preload("res://Scripts/song_chemistry.gd")
const LEAD_DAYS := 3
const CANCELLATION_FEE := 15
const MISSED_REPUTATION := 8

static func pending(state: Dictionary) -> Dictionary:
 var item = state.get("booked_show",{})
 return item.duplicate(true) if item is Dictionary else {}

static func book(state: Dictionary, venue_id: String, approach: String = "tight", hire_session: bool = false) -> Dictionary:
 if not pending(state).is_empty():
  return {"ok":false,"message":"One gig is already booked. Play or cancel it first."}
 if not Gigs.APPROACHES.has(approach):
  return {"ok":false,"message":"Unknown set approach."}
 var venue: Dictionary = Gigs.get_venue(venue_id)
 if venue.is_empty():
  return {"ok":false,"message":"Unknown venue."}
 if not Gigs.available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):
  return {"ok":false,"message":"The venue has not offered your band a show yet."}
 var stage_day := maxi(1,int(state.get("tour_day",1))) + LEAD_DAYS
 var next := state.duplicate(true)
 next["gig_night_phase"] = "arrival"
 next["booked_show"] = {"venue_id":venue_id,"venue":str(venue["venue"]),"city":str(venue["city"]),"day":stage_day,"approach":approach,"session_drummer":hire_session}
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"booking:%d:%s" % [stage_day,venue_id],"day":int(state.get("tour_day",1)),"title":"A SHOW ON THE CALENDAR","text":"%s in %s is booked for day %d. Prepare your set." % [str(venue["venue"]),str(venue["city"]),stage_day],"kind":"gig"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":"Booked %s for day %d. You have %d days to prepare." % [str(venue["venue"]),stage_day,LEAD_DAYS]}

static func perform(state: Dictionary) -> Dictionary:
 var show := pending(state)
 if show.is_empty():
  return {"ok":false,"message":"No show is booked."}
 var day := int(state.get("tour_day",1))
 if day < int(show.get("day",0)):
  return {"ok":false,"message":"The gig is on day %d. Use the time to practise or promote." % int(show["day"])}
 if day > int(show.get("day",0)):
  return {"ok":false,"message":"The show date has passed."}
 # Live quality depends on a rehearsed set, not preparation statistics alone.
 var originals := maxi(0,int(state.get("songs",0)))
 var setlist_modifier := -22 if originals == 0 else (-10 if originals == 1 else (-4 if originals == 2 else 2))
 var performance_state := state.duplicate(true)
 var chemistry: Dictionary = Chemistry.calculate(state)
 var live_bonus: int = int(chemistry.get("bonus",0))
 performance_state["readiness"] = clampi(int(state.get("readiness",0)) + setlist_modifier + live_bonus,0,100)
 var result: Dictionary = Gigs.play(performance_state,str(show.get("venue_id","")),str(show.get("approach","tight")),bool(show.get("session_drummer",false)))
 if not bool(result.get("ok",false)):
  return result
 var updated: Dictionary = result["state"]
 updated["readiness"] = int(state.get("readiness",0))
 var recent_repeat := false
 var old_gigs: Array = state.get("gig_history",[])
 for previous in old_gigs:
  if previous is Dictionary and (str(previous.get("venue_id","")) == str(show.get("venue_id","")) or str(previous.get("venue","")) == str(show.get("venue",""))):
   if int(state.get("tour_day",1)) - int(previous.get("day",0)) <= 14:
    recent_repeat = true
 var gigs: Array = updated.get("gig_history",[])
 if not gigs.is_empty():
  var latest: Dictionary = gigs[gigs.size()-1]
  var gross_fee := int(latest.get("fee",0))
  var setlist_factor := 0.65 if originals == 0 else (0.85 if originals == 1 else (0.95 if originals == 2 else 1.0))
  var repeat_factor := 0.8 if recent_repeat else 1.0
  var actual_fee := maxi(0,int(round(float(gross_fee)*setlist_factor*repeat_factor)))
  var shortfall := maxi(0,gross_fee-actual_fee)
  updated["cash"] = maxi(0,int(updated.get("cash",0))-shortfall)
  latest["fee"] = actual_fee
  latest["venue_id"] = str(show.get("venue_id",""))
  latest["originals_played"] = originals
  latest["return_visit"] = recent_repeat
  latest["setlist_modifier"] = setlist_modifier
  latest["live_chemistry_bonus"] = live_bonus
  var baseline_fans := int(state.get("fans",0))
  var new_fans := int(updated.get("fans",0))
  var gain := maxi(0,new_fans-baseline_fans)
  if originals == 0:
   updated["fans"] = baseline_fans + int(round(float(gain)*0.5))
  elif recent_repeat:
   updated["fans"] = baseline_fans + int(round(float(gain)*0.75))
  var settlement: String = str(result.get("message","Show completed.")).replace("Fee £%d" % gross_fee,"Fee £%d" % actual_fee)
  result["message"] = settlement+" %s" % ("The crowd wants more original material." if originals < 2 else ("Another night here draws fewer new faces." if recent_repeat else "The new songs are paying off."))
 updated["booked_show"] = {}
 result["state"] = updated
 return result

static func cancel(state: Dictionary) -> Dictionary:
 var show := pending(state)
 if show.is_empty():
  return {"ok":false,"message":"There is no booking to cancel."}
 var next := state.duplicate(true)
 next["booked_show"] = {}
 next["gig_night_phase"] = "arrival"
 next["promoter_offer"] = {}
 var charge := mini(CANCELLATION_FEE,int(next.get("cash",0)))
 next["cash"] = maxi(0,int(next.get("cash",0))-charge)
 next["reputation"] = maxi(0,int(next.get("reputation",0))-3)
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"cancel:%d" % int(next.get("tour_day",1)),"day":int(next.get("tour_day",1)),"title":"GIG CANCELLED","text":"The band cancelled %s. The promoter was not pleased." % str(show.get("venue","the show")),"kind":"gig"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":"Cancelled %s. £%d fee and -3 reputation." % [str(show.get("venue","the show")),charge]}

static func expire(state: Dictionary) -> Dictionary:
 var show := pending(state)
 if show.is_empty() or int(state.get("tour_day",1)) <= int(show.get("day",0)):
  return state.duplicate(true)
 var next := state.duplicate(true)
 next["booked_show"] = {}
 next["gig_night_phase"] = "arrival"
 next["promoter_offer"] = {}
 next["reputation"] = maxi(0,int(next.get("reputation",0))-MISSED_REPUTATION)
 next["morale"] = maxi(0,int(next.get("morale",0))-6)
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"missed:%d:%s" % [int(show.get("day",0)),str(show.get("venue_id",""))],"day":int(next.get("tour_day",1)),"title":"MISSED SHOW","text":"%s went ahead without the band. Promoters remember." % str(show.get("venue","The gig")),"kind":"gig"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return next
