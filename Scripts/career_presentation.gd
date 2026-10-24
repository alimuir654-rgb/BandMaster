extends RefCounted
# Narrative-only presentation. This never changes the simulation.
static func dialogue_for(state: Dictionary, member_index: int) -> Dictionary:
 var roster: Array = state.get("members", [])
 if member_index < 0 or member_index >= roster.size():
  return {"ok":false,"message":"Musician not available."}
 if not roster[member_index] is Dictionary:
  return {"ok":false,"message":"Musician data unavailable."}
 var person: Dictionary = roster[member_index]
 var text_line: String = "I just want this band to work."
 var trait_name: String = str(person.get("trait","")).to_lower()
 match trait_name:
  "reliable":
   text_line = "We play better when we show up for each other."
  "ambitious":
   text_line = "I want to play somewhere bigger than the same old room."
  "creative":
   text_line = "I've got an idea for the next song. Hear me out."
  "laid-back":
   text_line = "A good gig beats another argument."
  "perfectionist":
   text_line = "That middle eight still needs work."
  "restless":
   text_line = "I don't want to play the same set forever."
 if str(person.get("life_status","active")) != "active":
  text_line = "I still care about the band, but I need this time away."
 elif int(person.get("fatigue",0)) >= 70:
  text_line = "I'm running on empty. Can we slow down for a bit?"
 elif int(person.get("loyalty",50)) <= 25:
  text_line = "I'm not sure I can keep putting the band first."
 return {"ok":true,"speaker":str(person.get("name","Musician")),"text":text_line,"day":int(state.get("tour_day",1)),"kind":"conversation"}

static func clipping(entry: Dictionary) -> Dictionary:
 var kind_name: String = str(entry.get("kind","career"))
 var rubric: String = "THE ARCHIVE"
 match kind_name:
  "gig":
   rubric = "LIVE REVIEW"
  "band":
   rubric = "BACKSTAGE NOTES"
  "song":
   rubric = "SONGBOOK"
  "press":
   rubric = "PRESS CUTTING"
  "fans":
   rubric = "LOCAL BUZZ"
  "milestone":
   rubric = "CAREER MILESTONE"
 return {"day":int(entry.get("day",1)),"title":str(entry.get("title","A MOMENT IN THE STORY")),"text":str(entry.get("text","")),"rubric":rubric,"kind":kind_name}
