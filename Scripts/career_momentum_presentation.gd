extends RefCounted
# Deterministic read-only status summaries for the home screen.
static func signals(state: Dictionary) -> Array:
 var result: Array = []
 var draft = state.get("current_song_draft",{})
 var progress := clampi(int(state.get("song_draft_progress",0)),0,2)
 if draft is Dictionary and not draft.is_empty() and progress > 0:
  result.append({"label":"SONG IN PROGRESS","detail":"%s - %d OF 3 SESSIONS" % [str(draft.get("title","UNTITLED")),progress],"tab":"ACTIONS"})
 var booked = state.get("booked_show",{})
 if booked is Dictionary and not booked.is_empty():
  var due := int(booked.get("day",0))-int(state.get("tour_day",1))
  result.append({"label":"UPCOMING SHOW" if due >= 0 else "OVERDUE SHOW","detail":"%d DAYS TO GIG" % due if due >= 0 else "CHECK YOUR GIG CALENDAR","tab":"GIGS"})
 var members = state.get("members",[])
 if members is Array:
  var absent := 0
  for member in members:
   if member is Dictionary and str(member.get("life_status","active")) != "active":
    absent += 1
  if absent > 0:
   result.append({"label":"LINE-UP ALERT","detail":"%d MUSICIAN(S) UNAVAILABLE" % absent,"tab":"BAND"})
 if int(state.get("cash",0)) < 25:
  result.append({"label":"LOW FUNDS","detail":"CASH LEFT: GBP %d" % int(state.get("cash",0)),"tab":"SCENE"})
 if result.is_empty():
  result.append({"label":"KEEP BUILDING","detail":"WRITE, REHEARSE AND PLAY LOCAL SHOWS","tab":"ACTIONS"})
 return result
