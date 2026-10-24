extends RefCounted
# Deterministic UK grassroots booking catalogue. No external services.
const VENUES := [
 {"id":"local","city":"HOMETOWN","venue":"The Lantern Room","tier":0,"fee":35,"travel":5,"min_rep":0,"min_fans":0,"days":1,"wear":2},
 {"id":"bristol","city":"BRISTOL","venue":"The Copper Fox","tier":1,"fee":75,"travel":28,"min_rep":14,"min_fans":10,"days":2,"wear":6},
 {"id":"cardiff","city":"CARDIFF","venue":"The Cellar Stage","tier":1,"fee":90,"travel":35,"min_rep":18,"min_fans":18,"days":2,"wear":8},
 {"id":"birmingham","city":"BIRMINGHAM","venue":"The Foundry","tier":2,"fee":150,"travel":52,"min_rep":30,"min_fans":40,"days":3,"wear":12},
 {"id":"manchester","city":"MANCHESTER","venue":"The North Room","tier":2,"fee":190,"travel":72,"min_rep":40,"min_fans":65,"days":3,"wear":15},
 {"id":"london","city":"LONDON","venue":"The Archway","tier":3,"fee":270,"travel":95,"min_rep":55,"min_fans":110,"days":3,"wear":17}
]

static func available(rep: int, fans: int) -> Array:
 var result: Array = []
 for venue in VENUES:
  if rep >= int(venue["min_rep"]) and fans >= int(venue["min_fans"]):
   result.append(venue)
 return result

static func get_venue(venue_id: String) -> Dictionary:
 for venue in VENUES:
  if venue["id"] == venue_id:
   return venue
 return {}

const APPROACHES := {
 "tight": {"label":"PLAY THE TIGHT SET","quality":8,"fan_bonus":0,"tension":1},
 "wild": {"label":"MAKE IT A BIG NIGHT","quality":-8,"fan_bonus":12,"tension":7},
 "crowd": {"label":"WIN OVER THE ROOM","quality":0,"fan_bonus":7,"tension":-2}
}

static func play(state: Dictionary, venue_id: String, approach: String = "tight") -> Dictionary:
 if state.has("members"):
  var roster: Array = state.get("members",[])
  var active := 0
  var drummer := false
  for person in roster:
   if person is Dictionary and str(person.get("life_status","active")) == "active":
    active += 1
    if str(person.get("role","")).to_lower().contains("drum"):
     drummer = true
  if active < 2:
   return {"ok":false,"message":"You need at least two available musicians before playing a show."}
  if not drummer:
   return {"ok":false,"message":"No drummer is available. Recruit a replacement or wait for their return."}
 if not APPROACHES.has(approach):
  return {"ok":false,"message":"Invalid performance approach."}
 var option: Dictionary = APPROACHES[approach]
 var venue := get_venue(venue_id)
 if venue.is_empty():
  return {"ok":false,"message":"Unknown venue."}
 if not available(int(state.get("reputation",0)),int(state.get("fans",0))).has(venue):
  return {"ok":false,"message":"The promoter wants a bigger local following first."}
 if int(state.get("cash",0)) < int(venue["travel"]) and venue_id != "local":
  return {"ok":false,"message":"Not enough money for travel. Promote locally or play a hometown gig."}
 if int(state.get("van_health",0)) < int(venue["wear"]) and venue_id != "local":
  return {"ok":false,"message":"Your van needs attention before this journey."}
 var next := state.duplicate(true)
 var quality := int(state.get("readiness",0)) + int(state.get("morale",0)) / 4 - int(state.get("tension",0)) / 4
 var success := quality + int(option["quality"]) >= 52
 var earned := int(venue["fee"]) if success else int(venue["fee"]) / 2
 var actual_travel := mini(int(venue["travel"]),int(state.get("cash",0))) if venue_id == "local" else int(venue["travel"])
 next["cash"] = maxi(0,int(state.get("cash",0)) - actual_travel + earned)
 next["tour_day"] = int(state.get("tour_day",1)) + int(venue["days"])
 next["van_health"] = clampi(int(state.get("van_health",0)) - (0 if venue_id == "local" else int(venue["wear"])),0,100)
 next["fans"] = maxi(0,int(state.get("fans",0)) + (12 + 9 * int(venue["tier"]) + int(option["fan_bonus"]) if success else 3))
 next["reputation"] = clampi(int(state.get("reputation",0)) + (4 + 3 * int(venue["tier"]) if success else 1),0,100)
 next["morale"] = clampi(int(state.get("morale",0)) + (4 if success else -5),0,100)
 next["tension"] = clampi(int(state.get("tension",0)) + (1 if success else 4) + int(option["tension"]),0,100)
 var gigs: Array = next.get("gig_history",[]).duplicate(true)
 gigs.append({"city":venue["city"],"venue":venue["venue"],"day":next["tour_day"],"fee":earned,"success":success,"approach":approach})
 if gigs.size() > 50:
  gigs.pop_front()
 next["gig_history"] = gigs
 var result_text := "A packed little room and a surprisingly good reception." if success else "A difficult soundcheck and a thin crowd, but you finish the set."
 return {"ok":true,"state":next,"message":"%s, %s. %s Fee £%d, travel £%d." % [venue["venue"],venue["city"],result_text,earned,actual_travel]}
