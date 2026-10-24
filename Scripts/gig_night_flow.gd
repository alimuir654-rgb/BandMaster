extends RefCounted
# Pure view-stage rules. Staging a night never consumes a turn or changes game economy.
const PHASES := ["arrival","soundcheck","stage"]
static func stage(state: Dictionary) -> Dictionary:
 var show = state.get("booked_show",{})
 if not show is Dictionary or show.is_empty():
  return {"phase":"none","can_play":false,"title":"NO SHOW BOOKED","detail":"Meet a promoter and book your next performance."}
 var day := int(state.get("tour_day",1))
 var booked_day := int(show.get("day",0))
 if day < booked_day:
  return {"phase":"preparation","can_play":false,"title":"GET READY","detail":"%d day(s) until %s. Rehearse, write or promote before show day." % [booked_day-day,str(show.get("venue","the venue"))]}
 if day > booked_day:
  return {"phase":"overdue","can_play":false,"title":"MISSED DATE","detail":"This gig was due on day %d." % booked_day}
 var phase := str(state.get("gig_night_phase","arrival"))
 if not PHASES.has(phase):
  phase = "arrival"
 var captions := {
  "arrival":{"title":"OUTSIDE THE VENUE","detail":"The van pulls up. You hear the support act through the walls. Take in the room before heading backstage."},
  "soundcheck":{"title":"BACKSTAGE / SOUNDCHECK","detail":"The band checks cables, argues about levels and looks out at the growing crowd. Settle on your approach."},
  "stage":{"title":"LIGHTS UP / SHOW TIME","detail":"The house lights dim. This is the moment the rehearsals were for. Take the stage."}
 }
 return {"phase":phase,"can_play":phase == "stage","title":captions[phase]["title"],"detail":captions[phase]["detail"]}
static func advance(state: Dictionary) -> Dictionary:
 var current := stage(state)
 var phase := str(current.get("phase","none"))
 if phase != "arrival" and phase != "soundcheck":
  return {"ok":false,"message":"There is no further pre-show stage."}
 var next := state.duplicate(true)
 next["gig_night_phase"] = "soundcheck" if phase == "arrival" else "stage"
 return {"ok":true,"state":next}
static func reset_after_show(state: Dictionary) -> Dictionary:
 var next := state.duplicate(true)
 next["gig_night_phase"] = "arrival"
 return next
