extends RefCounted
# Deterministic, no-turn-cost replies to a musician's conversation.
# Limit a given musician to one relationship-affecting reply per in-game day.
const RESPONSES := [
 {"id":"support","label":"I'M LISTENING","line":"Thanks for hearing me out.","loyalty":2,"morale":1},
 {"id":"plan","label":"LET'S MAKE A PLAN","line":"Good. Let's put that into practice.","loyalty":1,"morale":2},
 {"id":"space","label":"GIVE THEM SPACE","line":"I appreciate you respecting that.","loyalty":1,"morale":0}
]

static func options(state: Dictionary, index: int) -> Array:
 var members: Array = state.get("members",[])
 if index < 0 or index >= members.size() or not members[index] is Dictionary:
  return []
 var person: Dictionary = members[index]
 var identifier := str(person.get("candidate_id",person.get("id",index)))
 var used: Dictionary = state.get("conversation_reply_days",{})
 if int(used.get(identifier,-1)) == int(state.get("tour_day",1)):
  return []
 return RESPONSES.duplicate(true)

static func respond(state: Dictionary, index: int, reply_id: String) -> Dictionary:
 var available := options(state,index)
 var selected: Dictionary = {}
 for response in available:
  if str(response.get("id","")) == reply_id:
   selected = response
   break
 if selected.is_empty():
  return {"ok":false,"message":"This conversation has already been answered today or the reply is unavailable."}
 var next := state.duplicate(true)
 var members: Array = next.get("members",[]).duplicate(true)
 var person: Dictionary = members[index].duplicate(true)
 person["loyalty"] = clampi(int(person.get("loyalty",50))+int(selected["loyalty"]),0,100)
 person["morale"] = clampi(int(person.get("morale",50))+int(selected["morale"]),0,100)
 members[index] = person
 next["members"] = members
 var used: Dictionary = next.get("conversation_reply_days",{}).duplicate(true)
 used[str(person.get("candidate_id",person.get("id",index)))] = int(next.get("tour_day",1))
 next["conversation_reply_days"] = used
 var conversation: Dictionary = next.get("last_band_conversation",{}).duplicate(true)
 conversation["player_reply"] = str(selected["label"])
 conversation["response_text"] = str(selected["line"])
 conversation["answered"] = true
 next["last_band_conversation"] = conversation
 return {"ok":true,"state":next,"message":str(person.get("name","Musician"))+": "+str(selected["line"])}
