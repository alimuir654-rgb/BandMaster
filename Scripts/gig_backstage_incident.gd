extends RefCounted
# A contextual soundcheck incident that gives the player an actual choice.
# Pure state transitions, no day cost, and one resolution per booked show.
const OPTIONS := [
 {"id":"rest","label":"GIVE THEM A BREATHER","fatigue":-12,"morale":4,"readiness":-3,"text":"The bassist gets water and a quiet moment. The set may be less polished, but the band looks after its own."},
 {"id":"simplify","label":"SIMPLIFY THE BASS PARTS","fatigue":-6,"morale":2,"readiness":-5,"text":"You strip the difficult passages out of the set. The bassist can get through the night."},
 {"id":"push","label":"PUSH THROUGH THE SET","fatigue":8,"morale":-7,"readiness":2,"text":"They agree to play, but the pressure damages the mood backstage."}
]

static func incident(state: Dictionary) -> Dictionary:
 var booking: Dictionary = state.get("booked_show",{})
 if booking.is_empty() or str(state.get("gig_night_phase","arrival")) != "soundcheck":
  return {}
 if int(booking.get("day",-1)) != int(state.get("tour_day",0)):
  return {}
 # JSON numbers may reload as 7.0; use a canonical integer booking day so
 # the same incident cannot reappear after save/reload or type normalization.
 var prefix := str(booking.get("venue_id",booking.get("venue","gig")))+":"
 var identifier := prefix+str(int(booking.get("day",0)))
 var legacy_identifier := prefix+str(booking.get("day",0))
 if str(state.get("illness_resolved_booking","")) in [identifier,legacy_identifier]:
  return {}
 var roster: Array = state.get("members",[])
 for index in range(roster.size()):
  if roster[index] is Dictionary:
   var member: Dictionary = roster[index]
   if str(member.get("role","")).to_lower().contains("bass") and str(member.get("life_status","active")) == "active" and int(member.get("fatigue",0)) >= 60:
    return {"index":index,"name":str(member.get("name","Bassist")),"identifier":identifier,"options":OPTIONS}
 return {}

static func resolve(state: Dictionary, choice_id: String) -> Dictionary:
 var context := incident(state)
 if context.is_empty():
  return {"ok":false,"message":"There is no active backstage illness to resolve."}
 for item in OPTIONS:
  if str(item["id"]) == choice_id:
   var next := state.duplicate(true)
   var members: Array = next.get("members",[]).duplicate(true)
   var index := int(context["index"])
   var member: Dictionary = members[index].duplicate(true)
   member["fatigue"] = clampi(int(member.get("fatigue",0))+int(item["fatigue"]),0,100)
   member["morale"] = clampi(int(member.get("morale",50))+int(item["morale"]),0,100)
   members[index] = member
   next["members"] = members
   next["morale"] = clampi(int(next.get("morale",50))+int(item["morale"]),0,100)
   next["readiness"] = clampi(int(next.get("readiness",50))+int(item["readiness"]),0,100)
   next["illness_resolved_booking"] = str(context["identifier"])
   return {"ok":true,"state":next,"message":str(item["text"])}
 return {"ok":false,"message":"Unknown backstage decision."}
