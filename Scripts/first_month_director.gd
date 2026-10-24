extends RefCounted
# Deterministic guidance, based on career state. Never changes rewards or outcomes.
const Chapters = preload("res://Scripts/career_chapters.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")

static func next_move(state: Dictionary) -> Dictionary:
 var show: Dictionary = Calendar.pending(state)
 var day := int(state.get("tour_day",1))
 if not show.is_empty():
  var due := int(show.get("day",day)) - day
  if due <= 0:
   return {"title":"SHOW NIGHT","detail":"Your band is expected on stage today. Resolve this booking before the day ends.","tab":"GIGS","action":"PLAY THE GIG"}
  if int(state.get("readiness",0)) < 65:
   return {"title":"PREPARE FOR THE SHOW","detail":"%d day(s) until %s. Drill the set to improve readiness." % [due,str(show.get("venue","the show"))],"tab":"ACTIONS","action":"REHEARSE"}
  if int(state.get("songs",0)) < 2:
   return {"title":"WRITE BEFORE THE SHOW","detail":"You have %d day(s) before the gig. Original songs help the audience remember you." % due,"tab":"ACTIONS","action":"WRITE TOGETHER"}
  return {"title":"KEEP THE BAND TOGETHER","detail":"The set is taking shape. Use the time before show day to build trust or promote.","tab":"ACTIONS","action":"PREPARE"}
 var chapter: Dictionary = Chapters.progress(state)
 if bool(chapter.get("done",false)):
  return {"title":"BUILD YOUR CAREER","detail":"Your opening chapters are complete. Develop your songs and expand the live circuit.","tab":"GIGS","action":"FIND A SHOW"}
 if bool(chapter.get("ready",false)):
  return {"title":"CHAPTER COMPLETE","detail":"Claim your milestone reward before progressing to the next chapter.","tab":"HOME","action":"CLAIM REWARD"}
 var id := str(chapter.get("id",""))
 var songs := int(state.get("songs",0))
 var gigs := state.get("gig_history",[]).size()
 var rehearsal_count := int(state.get("action_counters",{}).get("rehearse",0))
 match id:
  "find_sound":
   if songs < 1:
    return {"title":"FIND YOUR SOUND","detail":"Write your first original. A finished song takes three writing sessions; progress is saved.","tab":"ACTIONS","action":"WRITE TOGETHER"}
   if rehearsal_count < 2:
    return {"title":"TIGHTEN THE SET","detail":"Rehearse together to prepare for the live circuit.","tab":"ACTIONS","action":"REHEARSE"}
  "first_crowd":
   if gigs < 1:
    return {"title":"PLAY TO STRANGERS","detail":"Book a local gig, prepare, then play on the scheduled day.","tab":"GIGS","action":"BOOK A GIG"}
   if int(state.get("fans",0)) < 12:
    return {"title":"BUILD A FOLLOWING","detail":"Promotion or another show can bring your first regulars.","tab":"SCENE","action":"PROMOTE"}
  "local_noise":
   if songs < 3:
    return {"title":"BUILD YOUR SETLIST","detail":"Keep writing originals. Three songs give the band a distinct live identity.","tab":"ACTIONS","action":"WRITE TOGETHER"}
   return {"title":"REACH THE LOCAL SCENE","detail":"Promote the band and play gigs to reach 25 fans.","tab":"SCENE","action":"PROMOTE"}
  "earn_stripes":
   if int(state.get("readiness",0)) < 70:
    return {"title":"PUT IN THE HOURS","detail":"A well-rehearsed band gives promoters a reason to book again.","tab":"ACTIONS","action":"REHEARSE"}
   return {"title":"BUILD YOUR LIVE CV","detail":"Play more shows to earn your stripes.","tab":"GIGS","action":"BOOK A GIG"}
  "first_month":
   if gigs < 5:
    return {"title":"FINISH THE FIRST MONTH","detail":"Keep playing shows, preparing and growing the band's following.","tab":"GIGS","action":"BOOK A GIG"}
   if int(state.get("fans",0)) < 40:
    return {"title":"FIND MORE FANS","detail":"Promote and perform to build a lasting crowd.","tab":"SCENE","action":"PROMOTE"}
   return {"title":"KEEP THE BAND MOVING","detail":"Reach day 30 while managing relationships and money.","tab":"ACTIONS","action":"MAKE TODAY COUNT"}
 return {"title":"YOUR NEXT MOVE","detail":"Balance rehearsals, songs and promotion to advance the career.","tab":"ACTIONS","action":"PREPARE"}
