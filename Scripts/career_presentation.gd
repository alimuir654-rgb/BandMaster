extends RefCounted
# Offline, deterministic character dialogue. A local LLM can later replace only the prose.
const LINES := {
 "Reliable":["I can make rehearsal. Just give me enough notice.","We play better when we show up for each other."],
 "Ambitious":["I want to play somewhere bigger than the same old room.","If we mean this, we need a plan."],
 "Creative":["I've got an idea for the next song. Hear me out.","The best bits happen when we stop forcing it."],
 "Laid-back":["I'm happy to be here. Let's not make everything a drama.","A good gig beats another argument."],
 "Perfectionist":["That middle eight still needs work.","We could be brilliant, but we need to practise properly."],
 "Restless":["Can we do something different next time?","I don't want to play the same set forever."]
}
static func dialogue_for(state: Dictionary, member_index: int) -> Dictionary:
 var members: Array = state.get("members",[])
 if member_index < 0 or member_index >= members.size() or not members[member_index] is Dictionary:
  return {"ok":false,"message":"Musician not available."}
 var member: Dictionary = members[member_index]
 var name := str(member.get("name","Musician"))
 var trait := str(member.get("trait",""))
 var options: Array = LINES.get(trait,["I just want this band to work.","We'll see where the next gig takes us."])
 var day := int(state.get("tour_day",1))
 var statement := str(options[(day + member_index) % options.size()])
 if str(member.get("life_status","active")) != "active":
  statement = "I still care about the band, but I need this time away."
 elif int(member.get("fatigue",0)) >= 70:
  statement = "I'm running on empty. Can we slow down for a bit?"
 elif int(member.get("loyalty",50)) <= 25:
  statement = "I'm not sure I can keep putting the band first."
 return {"ok":true,"speaker":name,"text":statement,"day":day,"kind":"conversation"}

static func clipping(entry: Dictionary) -> Dictionary:
 var kind := str(entry.get("kind","career"))
 var labels := {"gig":"LIVE REVIEW","band":"BACKSTAGE NOTES","song":"SONGBOOK","press":"PRESS CUTTING","fans":"LOCAL BUZZ","milestone":"CAREER MILESTONE","career":"FROM THE ARCHIVE"}
 return {"day":int(entry.get("day",1)),"title":str(entry.get("title","A MOMENT IN THE STORY")),"text":str(entry.get("text","")),"rubric":str(labels.get(kind,"THE ARCHIVE")),"kind":kind}
