extends RefCounted
## Read-only presentation of existing attendance and informal-practice routes.
## Entering this preview never advances time; Session owns the real day action.
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")

static func preview_label(count: int) -> String:
 return ("QUIET EVENING" if count==0 else ("SOLO PRACTICE" if count==1 else "FREE JAM"))+" ›"

static func inspect(state: Dictionary) -> Dictionary:
 var attendance: Dictionary=Situation.inspect_rehearsal(state)
 if not attendance.get("ok",false):return attendance
 var names: PackedStringArray=[]
 for index in attendance.attendee_indices:names.append(str(state.members[index].get("name","Bandmate")))
 var count: int=names.size()
 var summary: String="Nobody is free tonight. You can take a quiet evening and check tomorrow." if count==0 else (names[0]+" is free tonight. You can practise solo." if count==1 else ", ".join(names)+" are free for an informal jam.")
 var reason: String=""
 if attendance.plan_status=="future":reason="Rehearsal is agreed for DAY %d. " % int(attendance.plan.day)
 elif count<2:reason="A rehearsal needs two available musicians. "
 return {"ok":true,"count":count,"names":names,"preview_label":preview_label(count),"commit_label":preview_label(count).trim_suffix(" ›")+" · £0","summary":summary,"rehearsal_reason":reason+summary,"rehearsal_available":count>=2 and attendance.plan_status!="future","attendance":attendance}
