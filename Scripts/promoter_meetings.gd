extends RefCounted
# Promoter terms are deterministic, visible, and optional.
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const OFFERS := {
 "standard":{"label":"STANDARD OFFER","description":"Accept the normal arrangement. No added risk.","fee_bonus":0,"rep_risk":0,"fan_bonus":0},
 "guarantee":{"label":"ASK FOR A GUARANTEE","description":"Negotiate £15 extra, but spend reputation if the room is empty.","fee_bonus":15,"rep_risk":2,"fan_bonus":0},
 "guestlist":{"label":"BRING YOUR CROWD","description":"Offer a smaller fee in exchange for extra guest-list exposure.","fee_bonus":-10,"rep_risk":0,"fan_bonus":3}
}
static func negotiate(state: Dictionary, venue_id: String, offer_id: String) -> Dictionary:
 if not OFFERS.has(offer_id):
  return {"ok":false,"message":"Unknown promoter offer."}
 var booked = state.get("booked_show",{})
 if booked is Dictionary and not booked.is_empty():
  return {"ok":false,"message":"Finish the existing booking before negotiating another."}
 var venue: Dictionary = Gigs.get_venue(venue_id)
 if venue.is_empty():
  return {"ok":false,"message":"The promoter cannot offer that venue."}
 if not Gigs.available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):
  return {"ok":false,"message":"The promoter doesn't know the band well enough yet."}
 var result := state.duplicate(true)
 result["promoter_offer"] = {"venue_id":venue_id,"offer_id":offer_id}
 return {"ok":true,"state":result}
static func book(state: Dictionary, venue_id: String, offer_id: String, hire_session: bool = false, travel_plan: String = "drive_home") -> Dictionary:
 var proposal: Dictionary = negotiate(state,venue_id,offer_id)
 if not bool(proposal.get("ok",false)):
  return proposal
 var booked: Dictionary = Calendar.book(proposal["state"],venue_id,"tight",hire_session,travel_plan)
 if not bool(booked.get("ok",false)):
  return booked
 booked["message"] = str(booked.get("message",""))+" Promoter deal: "+str(OFFERS[offer_id]["label"])+"."
 return booked

static func settle(state: Dictionary, before: Dictionary) -> Dictionary:
 var after := state.duplicate(true)
 var terms: Dictionary = before.get("promoter_offer",{})
 var gigs: Array = after.get("gig_history",[])
 if gigs.is_empty() or terms.is_empty():
  after["promoter_offer"] = {}
  return after
 var booking: Dictionary = before.get("booked_show",{})
 if str(terms.get("venue_id","")) != str(booking.get("venue_id","")):
  after["promoter_offer"] = {}
  return after
 var choice: Dictionary = OFFERS.get(str(terms.get("offer_id","standard")),OFFERS["standard"])
 var latest: Dictionary = gigs[gigs.size()-1]
 var bonus := int(choice["fee_bonus"])
 if bonus < 0:
  bonus = maxi(bonus,-int(latest.get("fee",0)))
 after["cash"] = maxi(0,int(after.get("cash",0))+bonus)
 latest["fee"] = maxi(0,int(latest.get("fee",0))+bonus)
 latest["promoter_terms"] = str(terms.get("offer_id","standard"))
 if str(terms.get("offer_id","")) == "guarantee" and not bool(latest.get("success",false)):
  after["reputation"] = maxi(0,int(after.get("reputation",0))-int(choice["rep_risk"]))
 if bool(latest.get("success",false)):
  after["fans"] = int(after.get("fans",0))+int(choice["fan_bonus"])
 after["promoter_offer"] = {}
 return after
