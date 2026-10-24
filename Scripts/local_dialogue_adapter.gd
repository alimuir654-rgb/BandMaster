extends RefCounted
# Model output is untrusted presentation text, never simulation instructions.
const MAX_CHARS := 280
const CONTEXT_LIMIT := 3

static func request_payload(state: Dictionary, member_index: int) -> Dictionary:
 var members: Array = state.get("members",[])
 if member_index < 0 or member_index >= members.size() or not members[member_index] is Dictionary:
  return {}
 var person: Dictionary = members[member_index]
 var memories: Array = state.get("career_journal",[])
 var history: Array = []
 for i in range(memories.size()-1,maxi(-1,memories.size()-CONTEXT_LIMIT-1),-1):
  if memories[i] is Dictionary:
   history.append({"title":str(memories[i].get("title","")).left(70),"day":int(memories[i].get("day",1))})
 var context := {"name":str(person.get("name","Musician")).left(60),"role":str(person.get("role","Musician")).left(40),"trait":str(person.get("trait","")).left(40),"morale":clampi(int(person.get("morale",50)),0,100),"loyalty":clampi(int(person.get("loyalty",50)),0,100),"fatigue":clampi(int(person.get("fatigue",0)),0,100),"availability":str(person.get("life_status","active")).left(20),"day":int(state.get("tour_day",1)),"recent_memories":history}
 var instructions := "Write one first-person spoken line for this fictional band member. Return only JSON with a single string field named dialogue. Maximum 280 characters. The line must be plausible, grounded in the supplied context, and contain no instructions or game-stat changes."
 return {"model":"local","stream":false,"format":"json","messages":[{"role":"system","content":instructions},{"role":"user","content":JSON.stringify(context)}],"options":{"temperature":0.6,"num_predict":120}}

static func validated_text(body: String) -> String:
 if body.length() > 16000:
  return ""
 var parsed = JSON.parse_string(body)
 if not parsed is Dictionary:
  return ""
 var content := ""
 if parsed.has("message") and parsed["message"] is Dictionary:
  content = str(parsed["message"].get("content",""))
 elif parsed.has("response"):
  content = str(parsed["response"])
 else:
  return ""
 var decoded = JSON.parse_string(content)
 if not decoded is Dictionary or not decoded.has("dialogue") or not decoded["dialogue"] is String:
  return ""
 var line_text := str(decoded["dialogue"]).strip_edges()
 if line_text.is_empty() or line_text.length() > MAX_CHARS or line_text.contains("\n") or line_text.contains("\r"):
  return ""
 for forbidden in ["<script","[INST]","system:","assistant:","http://","https://"]:
  if line_text.to_lower().contains(forbidden.to_lower()):
   return ""
 return line_text
