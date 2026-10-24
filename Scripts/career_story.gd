extends RefCounted
# Deterministic narrative history. Events are data, never authoritative game logic.
const MAX_HISTORY := 80
const MILESTONES := {
 "first_song":{"title":"The first original","text":"The band finished its first proper song.","kind":"song"},
 "first_show":{"title":"A night to remember","text":"The first show became part of the band's history.","kind":"gig"},
 "first_press":{"title":"In print","text":"The local music press started paying attention.","kind":"press"},
 "first_following":{"title":"A crowd of your own","text":"The band reached its first fifty fans.","kind":"fans"},
 "demo_ready":{"title":"Demo material","text":"Three songs are ready for a rough demo.","kind":"recording"},
 "van_crisis":{"title":"Breakdown territory","text":"The van reached a dangerously unreliable condition.","kind":"van"},
 "band_fracture":{"title":"Tensions rise","text":"The band needs to talk before things fall apart.","kind":"band"}
}
static func record(state: Dictionary, event_id: String, detail: String = "") -> Dictionary:
 var next := state.duplicate(true)
 if not MILESTONES.has(event_id):
  return next
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 for entry in journal:
  if entry is Dictionary and str(entry.get("id","")) == event_id:
   return next
 var definition: Dictionary = MILESTONES[event_id]
 journal.append({"id":event_id,"day":maxi(1,int(next.get("tour_day",1))),"title":definition["title"],"text":detail if not detail.is_empty() else definition["text"],"kind":definition["kind"]})
 while journal.size() > MAX_HISTORY:
  journal.pop_front()
 next["career_journal"] = journal
 return next

static func observe(previous: Dictionary, current: Dictionary, action_id: String = "") -> Dictionary:
 var next := current.duplicate(true)
 if int(previous.get("songs",0)) < 1 and int(next.get("songs",0)) >= 1:
  next = record(next,"first_song")
 if int(previous.get("songs",0)) < 3 and int(next.get("songs",0)) >= 3:
  next = record(next,"demo_ready")
 if int(previous.get("press",0)) < 1 and int(next.get("press",0)) >= 1:
  next = record(next,"first_press")
 if int(previous.get("fans",0)) < 50 and int(next.get("fans",0)) >= 50:
  next = record(next,"first_following")
 if int(next.get("van_health",100)) <= 15:
  next = record(next,"van_crisis")
 if int(next.get("tension",0)) >= 65:
  next = record(next,"band_fracture")
 if action_id.begins_with("gig:"):
  next = record(next,"first_show")
 return next

static func latest(state: Dictionary, count: int = 5) -> Array:
 var journal: Array = state.get("career_journal",[])
 var result: Array = []
 for i in range(journal.size()-1,maxi(-1,journal.size()-count-1),-1):
  result.append(journal[i])
 return result
