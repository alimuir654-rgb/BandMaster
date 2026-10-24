extends RefCounted
# One-time career objectives reward distinct stages of the first month.
# Additive save keys; old careers can pick up completed chapters safely.
const CHAPTERS := [
 {"id":"find_sound","title":"FIND YOUR SOUND","description":"Write your first original song and hold two rehearsals.","requirements":{"songs":1,"rehearse":2},"reward_cash":20,"reward_rep":2,"story":"The band has a song, a sound, and something worth practising."},
 {"id":"first_crowd","title":"PLAY TO STRANGERS","description":"Play your first gig and start building a following.","requirements":{"gigs":1,"fans":12},"reward_cash":30,"reward_rep":3,"story":"People outside the rehearsal room have finally heard your music."},
 {"id":"local_noise","title":"WORD GETS AROUND","description":"Write three originals and reach twenty-five fans.","requirements":{"songs":3,"fans":25},"reward_cash":40,"reward_rep":4,"story":"A recognisable setlist and a handful of regular faces. Something is happening."},
 {"id":"earn_stripes","title":"EARN YOUR STRIPES","description":"Play three shows and build readiness to seventy.","requirements":{"gigs":3,"readiness":70},"reward_cash":50,"reward_rep":5,"story":"The band is starting to look like it belongs on a proper stage."},
 {"id":"first_month","title":"THE FIRST CHAPTER","description":"Survive thirty days, play five shows and earn forty fans.","requirements":{"day":30,"gigs":5,"fans":40},"reward_cash":75,"reward_rep":7,"story":"Thirty days in, the dream is no longer entirely hypothetical."}
]
static func progress(state: Dictionary) -> Dictionary:
 var earned: Dictionary = state.get("career_chapters_claimed",{})
 for chapter in CHAPTERS:
  if not earned.has(chapter["id"]):
   var completed := true
   var details: Array = []
   var required: Dictionary = chapter["requirements"]
   for key in required:
    var target := int(required[key])
    var current := _metric(state,str(key))
    details.append({"label":str(key),"current":mini(current,target),"target":target})
    if current < target:
     completed = false
   return {"done":false,"id":chapter["id"],"title":chapter["title"],"description":chapter["description"],"requirements":details,"ready":completed,"reward_cash":chapter["reward_cash"],"reward_rep":chapter["reward_rep"]}
 return {"done":true,"title":"A CAREER IN THE MAKING","description":"The opening chapters are complete. The rest is yours to write."}

static func claim(state: Dictionary, chapter_id: String) -> Dictionary:
 var status := progress(state)
 if bool(status.get("done",false)) or str(status.get("id","")) != chapter_id or not bool(status.get("ready",false)):
  return {"ok":false,"message":"That chapter cannot be completed yet."}
 var next := state.duplicate(true)
 var seen: Dictionary = next.get("career_chapters_claimed",{}).duplicate(true)
 seen[chapter_id] = int(next.get("tour_day",1))
 next["career_chapters_claimed"] = seen
 next["cash"] = int(next.get("cash",0)) + int(status["reward_cash"])
 next["reputation"] = clampi(int(next.get("reputation",0)) + int(status["reward_rep"]),0,100)
 var story := ""
 for chapter in CHAPTERS:
  if str(chapter["id"]) == chapter_id:
   story = str(chapter["story"])
   break
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"chapter:"+chapter_id,"day":int(next.get("tour_day",1)),"title":status["title"],"text":story,"kind":"milestone"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":story+"  Reward: £%d, +%d reputation." % [int(status["reward_cash"]),int(status["reward_rep"])]}

static func _metric(state: Dictionary, key: String) -> int:
 match key:
  "day":
   return int(state.get("tour_day",1))
  "gigs":
   return state.get("gig_history",[]).size()
  "rehearse":
   return int(state.get("action_counters",{}).get("rehearse",0))
  _:
   return int(state.get(key,0))
