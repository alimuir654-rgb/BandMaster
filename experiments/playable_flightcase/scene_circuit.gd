extends RefCounted
## Optional shared-bill policy. Existing fee/travel/booking economics stay authoritative.
const Facts=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Gigs=preload("res://Scripts/uk_gig_circuit.gd")
const Reviews=preload("res://experiments/playable_flightcase/review_policy.gd")
const KEY := "scene_contacts_v1"
const BILL := "scene_bill_v1"
const ENCOUNTER := "scene_encounter_v1"
const BANDS := {
 "northbound_static":{"name":"NORTHBOUND STATIC","advice":"Give the first chorus room. Look at your drummer before the count-in. The room can wait for you.","style":"count_in"},
 "glass_arcade":{"name":"GLASS ARCADE","advice":"Keep them chasing you. Fill every gap and run straight into the next one. Never let the room breathe.","style":"no_gaps"}
}
const PITCHES := {"fit":"WE CAN PLAY A SHORT OPENING SET","crowd":"WE WANT TO BRING OUR OWN CROWD","scene":"WE'RE GETTING TO KNOW THE LOCAL BANDS"}

static func empty() -> Dictionary:
 return {"version":1,"venues":{},"bands":{},"processed":{},"receipts":[]}

static func commitment(id: Variant) -> Dictionary:
 if not id is String:return {}
 var parts: PackedStringArray=id.split(":")
 if parts.size()!=4 or parts[0]!="gig-commitment" or not parts[1].is_valid_int() or not parts[3].is_valid_int() or Gigs.get_venue(parts[2]).is_empty():return {}
 var seq: int=int(parts[1]);var day: int=int(parts[3])
 if not Facts.whole(seq,1) or not Facts.whole(day,1) or id!="gig-commitment:%d:%s:%d" % [seq,parts[2],day]:return {}
 return {"sequence":seq,"venue_id":str(parts[2]),"day":day}

static func validate(state: Dictionary) -> Dictionary:
 if not state.has(KEY):return {"ok":true}
 var d: Variant=state[KEY]
 if not d is Dictionary or not Facts.whole(d.get("version"),1,1) or not d.get("venues") is Dictionary or not d.get("bands") is Dictionary or not d.get("processed") is Dictionary or not d.get("receipts") is Array or d.receipts.size()>80:return Facts.bad("The saved local music scene needs a compatible version. Its records are retained.")
 for id in d.venues:
  if Gigs.get_venue(str(id)).is_empty() or not d.venues[id] is Dictionary:return Facts.bad("A saved venue contact is invalid.")
  for k in ["played","supported"]:
   if not Facts.whole(d.venues[id].get(k)):return Facts.bad("A venue's saved scene history needs validation.")
 for id in d.bands:
  if id not in BANDS or not d.bands[id] is Dictionary or not Facts.whole(d.bands[id].get("supported")):return Facts.bad("A saved band contact needs validation.")
 for id in d.processed:
  if commitment(id).is_empty() or typeof(d.processed[id])!=TYPE_BOOL or d.processed[id]!=true:return Facts.bad("A scene result has no durable booking identity.")
  if not state.get("gig_commitments_v1",{}) is Dictionary or not state.get("gig_commitments_v1",{}).get("seen_slots",{}) is Dictionary:return Facts.bad("The scene's saved booking history needs validation.")
  if not state.get("gig_commitments_v1",{}).get("seen_slots",{}).values().has(id):return Facts.bad("A scene result is not bound to a recorded booking.")
 var seen: Dictionary={}
 for receipt in d.receipts:
  if not receipt is Dictionary or not receipt.get("commitment_id") is String or not d.processed.has(receipt.commitment_id) or not bill_valid(receipt.get("bill")) or not encounter_valid(receipt.get("encounter"),receipt.bill) or not receipt.get("facts") is Dictionary:return Facts.bad("A saved shared-bill receipt needs validation.")
  var identity: Dictionary=commitment(receipt.commitment_id)
  if identity.is_empty() or seen.has(receipt.commitment_id) or identity.venue_id!=receipt.bill.venue_id:return Facts.bad("The saved bill and booking identity disagree.")
  seen[receipt.commitment_id]=true
  if not Facts.whole(receipt.facts.get("fans_delta"),-2,3) or not Facts.whole(receipt.facts.get("fatigue_per_active_member"),0,2) or not receipt.facts.get("note") is String:return Facts.bad("The saved scene consequences cannot be read safely.")
 return {"ok":true}

static func context(state: Dictionary,venue_id: String) -> Dictionary:
 var venue: Dictionary=state.get(KEY,{}).get("venues",{}).get(venue_id,{})
 return {"venue_id":venue_id,"reputation":int(state.get("reputation",0)),"fans":int(state.get("fans",0)),"shows":state.get("gig_history",[]).size(),"supported":int(venue.get("supported",0)),"guarantee_restricted":not Reviews.eligibility(state,venue_id,"guarantee").get("ok",false),"last_success":bool(state.get("gig_history",[]).back().get("success",false)) if not state.get("gig_history",[]).is_empty() else false}

static func _offer(c: Dictionary,pitch: String,ask: String) -> Dictionary:
 var credible: bool=(int(c.fans)>=20 and int(c.reputation)>=14 and bool(c.last_success)) or (int(c.supported)>=2 and int(c.reputation)>=10)
 credible=credible and not bool(c.guarantee_restricted)
 var offer: String="standard" if ask=="guarantee" and not credible else ask
 var slot: String="opening"
 if int(c.shows)>=3 and int(c.reputation)>=18 and int(c.fans)>=18:slot="main_support"
 if int(c.shows)>=5 and int(c.reputation)>=40 and int(c.fans)>=65:slot="headline"
 var lineup: Array=["player","northbound_static","glass_arcade"] if slot=="opening" else (["northbound_static","player","glass_arcade"] if slot=="main_support" else ["northbound_static","glass_arcade","player"])
 return {"version":1,"venue_id":c.venue_id,"pitch":pitch,"asked":ask,"offer_id":offer,"slot":slot,"lineup":lineup,"context":c.duplicate(true)}

static func bill_valid(raw: Variant) -> bool:
 if not raw is Dictionary or not Facts.whole(raw.get("version"),1,1) or raw.get("pitch") not in PITCHES or raw.get("asked") not in ["standard","guarantee","guestlist"] or not raw.get("context") is Dictionary:return false
 var c: Dictionary=raw.context
 if Gigs.get_venue(str(c.get("venue_id",""))).is_empty() or typeof(c.get("last_success"))!=TYPE_BOOL or typeof(c.get("guarantee_restricted"))!=TYPE_BOOL:return false
 for key in ["reputation","fans","shows","supported"]:
  if not Facts.whole(c.get(key),0,100 if key=="reputation" else 2147483647):return false
 var wanted: Dictionary=_offer(c,raw.pitch,raw.asked)
 for key in wanted:
  if Facts.fingerprint(raw.get(key))!=Facts.fingerprint(wanted[key]):return false
 return true

static func proposal(state: Dictionary,venue_id: String,pitch: String,ask: String) -> Dictionary:
 var valid: Dictionary=validate(state)
 if not valid.ok:return valid
 valid=Reviews.validate(state)
 if not valid.get("ok",false):return valid
 if not Facts.whole(state.get("reputation",0),0,100) or not Facts.whole(state.get("fans",0)) or not state.get("gig_history",[]) is Array:return Facts.bad("The band's current standing cannot be read safely.")
 if not state.get("gig_history",[]).is_empty() and not state.gig_history.back() is Dictionary:return Facts.bad("The last show record needs validation before this offer.")
 if pitch not in PITCHES or ask not in ["standard","guarantee","guestlist"] or Gigs.get_venue(venue_id).is_empty():return Facts.bad("Tell the promoter what you're asking for.")
 var c: Dictionary=context(state,venue_id)
 var bill: Dictionary=_offer(c,pitch,ask)
 var line: String="Let's start with you opening. A short set, get in on time, and give the next band room to change over."
 if bill.slot=="main_support":line="You've earned a main support spot. There will be another band before you; help make it a good night for all three acts."
 elif bill.slot=="headline":line="You can close this one. We'll put two bands on before you. I expect you to help carry the night."
 if pitch=="crowd" and int(c.fans)<20:line+=" I haven't seen that following in this room yet. Show me what you can bring."
 elif pitch=="scene" and int(c.supported)>0:line+=" The other bands have mentioned you staying around. That matters here."
 if ask!=bill.offer_id:
  line+=" I can't add a guarantee on that record. Standard terms are my counteroffer; you're free to leave it."
  if bool(c.guarantee_restricted):line+=" We need to see a successful hometown show before we revisit that."
 elif ask=="guarantee":line+=" You've got enough behind you to ask. I'll add the usual £15 to the final fee."
 elif ask=="guestlist":line+=" We can make room for that guest list, for £10 less on the final fee."
 return {"ok":true,"bill":bill,"reply":line,"counteroffer":ask!=bill.offer_id}

static func above(bill: Dictionary) -> Array:
 var index: int=bill.lineup.find("player")
 return bill.lineup.slice(index+1)

static func encounter_valid(raw: Variant,bill: Dictionary) -> bool:
 if not raw is Dictionary or not Facts.whole(raw.get("version"),1,1) or not raw.get("advice") is Dictionary or not raw.get("support") is Dictionary:return false
 var a: Dictionary=raw.advice;var s: Dictionary=raw.support
 if not a.is_empty() and (a.get("choice") not in ["try","own_set"] or (a.get("choice")=="try" and a.get("band_id") not in above(bill)) or (a.get("choice")=="own_set" and a.get("band_id")!="")):return false
 if not s.is_empty() and (s.get("choice") not in ["watch","help","own_gear"] or (s.get("choice")!="own_gear" and (s.get("band_id") not in bill.lineup or s.get("band_id") not in BANDS)) or (s.get("choice")=="own_gear" and s.get("band_id")!="")):return false
 if s.get("choice")=="watch" and s.get("band_id") not in above(bill):return false
 return true

static func encounter_empty() -> Dictionary:
 return {"version":1,"advice":{},"support":{}}

static func choose(visit: Dictionary,bill: Dictionary,kind: String,payload: Dictionary) -> Dictionary:
 if not bill_valid(bill):return Facts.bad("This shared bill needs its original agreement.")
 var d: Dictionary=visit.get(ENCOUNTER,encounter_empty()).duplicate(true)
 if not encounter_valid(d,bill):return Facts.bad("The saved bill encounter needs validation.")
 var phase: String=str(visit.get("phase",""))
 if kind not in ["advice","support"] or not d[kind].is_empty() or phase!=("backstage" if kind=="advice" else "after_set"):return Facts.bad("That moment on the bill is already answered or has passed.")
 d[kind]=payload.duplicate(true)
 if not encounter_valid(d,bill):return Facts.bad("Choose an actual band and reply from tonight's bill.")
 var next: Dictionary=visit.duplicate(true);next[ENCOUNTER]=d
 return {"ok":true,"visit":next}

static func settle(before: Dictionary,after: Dictionary,visit: Dictionary) -> Dictionary:
 var t: Dictionary=before.get("booked_show",{}).get("booking_terms_v1",{})
 if not t.has(BILL):return {"ok":true,"state":after.duplicate(true),"message":""}
 var valid: Dictionary=validate(before)
 if not valid.ok:return valid
 valid=validate(after)
 if not valid.ok:return valid
 var bill: Dictionary=t[BILL];var encounter: Dictionary=visit.get(ENCOUNTER,encounter_empty())
 if not bill_valid(bill) or not encounter_valid(encounter,bill):return Facts.bad("The original shared bill or encounter cannot be verified.")
 var id: String=str(t.get("commitment_id",""));var result: Dictionary=after.duplicate(true)
 var d: Dictionary=result.get(KEY,empty()).duplicate(true)
 if id.is_empty() or d.processed.has(id):return Facts.bad("That shared bill has already settled.")
 var fan_delta: int=0;var fatigue_delta: int=0;var lines: PackedStringArray=[]
 var v: Dictionary=d.venues.get(bill.venue_id,{"played":0,"supported":0}).duplicate(true);v.played=int(v.played)+1
 var a: Dictionary=encounter.advice;var s: Dictionary=encounter.support
 if a.get("choice")=="try":
  var readiness: int=int(visit.get("context",{}).get("readiness",before.get("readiness",0)))
  var tired: int=int(visit.get("context",{}).get("actor",{}).get("fatigue",0))
  var style: String=str(BANDS[a.band_id].style)
  var change: int=(2 if readiness<65 else 0) if style=="count_in" else (2 if readiness>=60 and tired<40 else -2)
  fan_delta+=change
  lines.append(str(BANDS[a.band_id].name)+(": the suggestion helped you find a connection." if change>0 else (": chasing their suggestion made it harder to hold the room." if change<0 else ": the suggestion made little difference to this set.")))
 if s.get("choice") in ["watch","help"]:
  var band: String=s.band_id;var contact: Dictionary=d.bands.get(band,{"supported":0}).duplicate(true);contact.supported=int(contact.supported)+1;d.bands[band]=contact;v.supported=int(v.supported)+1
  fatigue_delta=2 if s.choice=="help" else 0;fan_delta+=1
  lines.append(str(BANDS[band].name)+(" remember you helping with their gear." if s.choice=="help" else " noticed you staying for their set."))
 var previous_fans: int=int(result.get("fans",0))
 result["fans"]=clampi(previous_fans+fan_delta,0,2147483647)
 fan_delta=int(result.fans)-previous_fans
 if fatigue_delta:
  for p in result.get("members",[]):
   if p is Dictionary and p.get("life_status","active")=="active":p.fatigue=mini(100,int(p.get("fatigue",0))+fatigue_delta)
 d.venues[bill.venue_id]=v;d.processed[id]=true
 var facts: Dictionary={"fans_delta":fan_delta,"fatigue_per_active_member":fatigue_delta,"note":" ".join(lines)}
 d.receipts.append({"commitment_id":id,"bill":bill.duplicate(true),"encounter":encounter.duplicate(true),"facts":facts})
 while d.receipts.size()>80:d.receipts.pop_front()
 result[KEY]=d
 var checked: Dictionary=validate(result)
 if not checked.ok:return checked
 return {"ok":true,"state":result,"message":facts.note,"facts":facts}
