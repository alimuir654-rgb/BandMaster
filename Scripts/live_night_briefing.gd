extends RefCounted
# Pure live-night view model. The booking/performance engines own every outcome.
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")

static func briefing(state: Dictionary) -> Dictionary:
 var booking: Dictionary = Calendar.pending(state)
 if booking.is_empty():
  return {"active":false,"headline":"THE NEXT STAGE IS WAITING","detail":"Find a venue and agree terms with its promoter.","steps":[]}
 var days := int(booking.get("day",1))-int(state.get("tour_day",1))
 var phase := str(state.get("gig_night_phase","arrival")) if days == 0 else ("preparation" if days > 0 else "overdue")
 var readiness := clampi(int(state.get("readiness",0)),0,100)
 var originals := maxi(0,int(state.get("songs",0)))
 var tension := clampi(int(state.get("tension",0)),0,100)
 var morale := clampi(int(state.get("morale",50)),0,100)
 var detail := "Rehearse and write before travelling to the show."
 if days == 0:
  detail = "The venue is expecting you tonight. Follow the arrival, soundcheck and stage sequence."
 elif days < 0:
  detail = "This date has passed. Resolve the missed booking."
 var deal: Dictionary = state.get("promoter_offer",{})
 var terms: Dictionary = Promoter.OFFERS.get(str(deal.get("offer_id","standard")),Promoter.OFFERS["standard"])
 var tips: Array = []
 if originals < 2:
  tips.append("WRITE ORIGINALS  /  Too few songs can weaken ticket income and fan growth.")
 if readiness < 60:
  tips.append("REHEARSE  /  The live set needs work.")
 if morale < 45:
  tips.append("BAND MORALE  /  Check in with the musicians.")
 if tension > 65:
  tips.append("TENSION  /  Clear the air before the performance.")
 if tips.is_empty():
  tips.append("READY TO PLAY  /  Focus on the set and live approach.")
 return {"active":true,"headline":str(booking.get("venue","THE NEXT SHOW")).to_upper(),"city":str(booking.get("city","")),"day":int(booking.get("day",1)),"days_left":days,"phase":phase,"detail":detail,"deal":str(terms["label"]),"approach":str(booking.get("approach","tight")),"originals":originals,"readiness":readiness,"tips":tips,"steps":["ARRIVAL","SOUNDCHECK","STAGE"]}

static func stage_index(phase: String) -> int:
 match phase:
  "arrival": return 0
  "soundcheck": return 1
  "stage": return 2
 return -1

static func last_show(state: Dictionary) -> Dictionary:
 var history: Array = state.get("gig_history",[])
 if history.is_empty() or not history.back() is Dictionary:
  return {}
 var show: Dictionary = history.back()
 return {"venue":str(show.get("venue","LAST SHOW")),"fee":maxi(0,int(show.get("fee",0))),"success":bool(show.get("success",false)),"originals":maxi(0,int(show.get("originals_played",0))),"terms":str(show.get("promoter_terms","standard"))}
