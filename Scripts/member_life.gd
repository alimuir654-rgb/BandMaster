extends RefCounted
# Life events are explicit decisions, never random forced departures.
const EVENTS := {
 "career":{"title":"THE DAY JOB","intro":"A musician has been offered a more demanding job. Band commitments are under pressure.","choices":[{"id":"compromise","label":"AGREE A FLEXIBLE SCHEDULE","status":"limited","days":12,"loyalty":5},{"id":"depart","label":"SUPPORT THEIR CAREER MOVE","status":"departed","reason":"left for a full-time career"}]},
 "parenthood":{"title":"A NEW ARRIVAL","intro":"A bandmate is welcoming a child. They need time away from rehearsals and travel.","choices":[{"id":"leave","label":"ARRANGE FAMILY LEAVE","status":"leave","days":18,"loyalty":7},{"id":"depart","label":"PART ON GOOD TERMS","status":"departed","reason":"left to focus on family"}]},
 "relocation":{"title":"MOVING ABROAD","intro":"A musician plans to relocate overseas and cannot maintain the regular gig schedule.","choices":[{"id":"farewell","label":"THROW A FAREWELL SHOW","status":"departed","reason":"moved abroad"},{"id":"remote","label":"KEEP THEM INVOLVED REMOTELY","status":"limited","days":22,"loyalty":3}]},
 "injury":{"title":"INJURED MUSICIAN","intro":"A musician has an injury and needs recovery time before performing.","choices":[{"id":"recover","label":"ALLOW PROPER RECOVERY","status":"leave","days":14,"loyalty":4},{"id":"specialist","label":"PAY FOR SUPPORT (£25)","status":"leave","days":8,"cost":25,"loyalty":5}]}
}
const FIRST_NAMES := ["Ellis","Morgan","Alex","Frankie","Robin","Casey","Taylor","Jules"]
const TRAITS := ["Reliable","Ambitious","Creative","Laid-back","Perfectionist","Restless"]
static func pending(state: Dictionary) -> Array:
 var events: Array = []
 var day := int(state.get("tour_day",1))
 var roster: Array = state.get("members",[])
 var settled: Dictionary = state.get("member_life_resolved",{})
 for i in range(roster.size()):
  if not roster[i] is Dictionary:
   continue
  var person: Dictionary = roster[i]
  if str(person.get("life_status","active")) != "active":
   continue
  var id := ""
  if day >= 20 and int(person.get("loyalty",50)) <= 30:
   id = "career"
  elif day >= 35 and int(person.get("fatigue",0)) >= 80:
   id = "injury"
  elif day >= 50 and int(person.get("morale",50)) <= 25:
   id = "relocation"
  elif day >= 70 and int(person.get("loyalty",50)) >= 60:
   id = "parenthood"
  var key := "%s:%s:%d:%s" % [str(person.get("name","Musician")),str(person.get("role","")),int(person.get("joined_day",1)),id]
  if not id.is_empty() and not settled.has(key):
   events.append({"id":id,"index":i,"key":key,"name":str(person.get("name","Musician"))})
 return events

static func resolve(state: Dictionary, index: int, event_id: String, choice_id: String) -> Dictionary:
 var event_key := ""
 var available := false
 for entry in pending(state):
  if int(entry["index"]) == index and str(entry["id"]) == event_id:
   event_key = str(entry["key"])
   available = true
 if not available:
  return {"ok":false,"message":"Life event is not available."}
 var chosen: Dictionary = {}
 var definition: Dictionary = EVENTS[event_id]
 for option in definition["choices"]:
  if option["id"] == choice_id:
   chosen = option
   break
 if chosen.is_empty():
  return {"ok":false,"message":"Invalid choice."}
 var cost := int(chosen.get("cost",0))
 if int(state.get("cash",0)) < cost:
  return {"ok":false,"message":"Not enough cash for this option."}
 var next := state.duplicate(true)
 var roster: Array = next["members"]
 var person: Dictionary = roster[index]
 var name := str(person.get("name","Musician"))
 next["cash"] = int(next.get("cash",0)) - cost
 next["tour_day"] = int(next.get("tour_day",1)) + 1
 var status := str(chosen["status"])
 if status == "departed":
  var alumni: Array = next.get("former_members",[]).duplicate(true)
  alumni.append({"name":name,"role":person.get("role",""),"trait":person.get("trait",""),"joined_day":int(person.get("joined_day",1)),"left_day":int(next["tour_day"]),"reason":str(chosen.get("reason","left the band")),"loyalty":int(person.get("loyalty",50))})
  next["former_members"] = alumni
  roster.remove_at(index)
 else:
  person["life_status"] = status
  person["available_day"] = int(next["tour_day"]) + int(chosen.get("days",7))
  person["loyalty"] = clampi(int(person.get("loyalty",50))+int(chosen.get("loyalty",0)),0,100)
 var seen: Dictionary = next.get("member_life_resolved",{}).duplicate(true)
 seen[event_key] = choice_id
 next["member_life_resolved"] = seen
 var history: Array = next.get("career_journal",[]).duplicate(true)
 history.append({"id":"life:%s:%d" % [event_id,int(next["tour_day"])],"day":next["tour_day"],"title":definition["title"],"text":"%s — %s" % [name,str(chosen["label"])],"kind":"band"})
 while history.size() > 80:
  history.pop_front()
 next["career_journal"] = history
 return {"ok":true,"state":next,"message":name+": "+str(chosen["label"])}

static func refresh(state: Dictionary) -> Dictionary:
 var next := state.duplicate(true)
 for person in next.get("members",[]):
  if person is Dictionary and str(person.get("life_status","active")) != "active" and int(next.get("tour_day",1)) >= int(person.get("available_day",999999)):
   person["life_status"] = "active"
   person.erase("available_day")
 return next

static func recruit(state: Dictionary) -> Dictionary:
 var next := state.duplicate(true)
 var roster: Array = next.get("members",[])
 if roster.size() >= 6:
  return {"ok":false,"message":"The line-up is already full."}
 var day := int(next.get("tour_day",1))
 var count := int(next.get("recruitment_count",0))
 var role := _missing_role(roster)
 var name := FIRST_NAMES[count % FIRST_NAMES.size()]+" "+str(count+1)
 roster.append({"name":name,"role":role,"trait":TRAITS[count % TRAITS.size()],"skill":35+count%15,"morale":60,"loyalty":55,"fatigue":0,"joined_day":day,"life_status":"active"})
 next["members"] = roster
 next["recruitment_count"] = count+1
 next["tour_day"] = day+1
 return {"ok":true,"state":next,"message":name+" joins the band as "+role+"."}

static func _missing_role(roster: Array) -> String:
 for role in ["Drummer","Bassist","Guitarist","Vocalist"]:
  var found := false
  for person in roster:
   if person is Dictionary and str(person.get("role","")).to_lower() == role.to_lower():
    found = true
  if not found:
   return role
 return "Multi-instrumentalist"
