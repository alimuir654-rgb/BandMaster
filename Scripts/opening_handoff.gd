extends RefCounted
# Idempotent bridge from scripted introduction into the persistent Career Hub.
# Leaves incomplete tutorials untouched and preserves pre-existing career data.
static func migrate(save: Dictionary) -> Dictionary:
 var next := save.duplicate(true)
 if str(next.get("current_event","")) != "aftershow" or not str(next.get("pending_next","")).is_empty():
  return next
 var extra: Dictionary = next.get("career_extra",{}).duplicate(true)
 if bool(extra.get("intro_handoff_complete",false)):
  return next
 var decisions: Dictionary = next.get("decisions",{})
 if not decisions.has("first_gig"):
  return next
 var day := maxi(1,int(next.get("tour_day",1)))
 var rehearsal_count := maxi(0,int(next.get("rehearsal_number",0)))
 var counters: Dictionary = extra.get("action_counters",{}).duplicate(true)
 counters["rehearse"] = maxi(rehearsal_count,int(counters.get("rehearse",0)))
 extra["action_counters"] = counters
 var journal: Array = extra.get("career_journal",[]).duplicate(true)
 var has_opening := false
 for entry in journal:
  if entry is Dictionary and str(entry.get("id","")) == "intro:first_show":
   has_opening = true
 if not has_opening:
  journal.append({"id":"intro:first_show","day":day,"title":"THE FIRST NIGHT: THE TOADSTOOL","text":"The band completed its debut show. The choices made in the practice room, on the road and onstage shaped what happened.","kind":"gig"})
 while journal.size() > 80:
  journal.pop_front()
 extra["career_journal"] = journal
 var gigs: Array = extra.get("gig_history",[]).duplicate(true)
 var found := false
 for item in gigs:
  if item is Dictionary and str(item.get("id","")) == "intro:first_gig":
   found = true
 if not found:
  gigs.append({"id":"intro:first_gig","venue":"The Toadstool","city":"HOMETOWN","day":day,"fee":0,"success":true,"approach":str(decisions.get("first_gig","safe")),"intro":true})
 extra["gig_history"] = gigs
 # An introductory songwriting choice contributes to a real work-in-progress.
 var writing_sessions := 0
 for session in range(1,4):
  if str(decisions.get("rehearsal_%d" % session,"")) == "write":
   writing_sessions += 1
 if writing_sessions > 0:
  extra["song_draft_progress"] = maxi(int(extra.get("song_draft_progress",0)),mini(2,writing_sessions))
 extra["intro_handoff_complete"] = true
 extra["intro_completion_day"] = day
 next["career_extra"] = extra
 return next
