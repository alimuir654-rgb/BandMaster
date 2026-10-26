extends RefCounted
# Deterministic, save-compatible band situations and meaningful choices.
const EVENTS := {
 "creative_clash":{"title":"WHO WROTE THE CHORUS?","intro":"Two bandmates disagree over who deserves credit for the new song.","choices":[
  {"id":"share","label":"SHARE THE CREDIT","morale":5,"tension":-8,"loyalty":4},
  {"id":"pick","label":"BACK THE LEAD WRITER","readiness":4,"tension":10,"loyalty":-7}]},
 "exhausted":{"title":"RUNNING ON EMPTY","intro":"Someone is visibly exhausted and the band wants a decision.","choices":[
  {"id":"rest","label":"TAKE A DAY OFF","morale":9,"fatigue":-18,"readiness":-3},
  {"id":"push","label":"PUSH THROUGH","readiness":6,"morale":-8,"fatigue":12}]},
 "money_argument":{"title":"WHO PAYS FOR THIS?","intro":"A bandmate questions another expense from the shared cash box.","choices":[
  {"id":"budget","label":"AGREE A BUDGET","tension":-9,"loyalty":4},
  {"id":"spend","label":"TRUST THE PLAN","tension":8,"readiness":3,"loyalty":-4}]}
}
static func pending(state: Dictionary) -> Array:
 var result: Array = []
 var seen: Dictionary = state.get("band_drama_resolved",{})
 var day := int(state.get("tour_day",1))
 var members: Array = state.get("members",[])
 if members.size() < 2:
  return result
 if day >= 6 and int(state.get("songs",0)) >= 2 and not seen.has("creative_clash"):
  result.append("creative_clash")
 if day >= 10 and _maximum_fatigue(members) >= 60 and not seen.has("exhausted"):
  result.append("exhausted")
 if day >= 14 and int(state.get("cash",0)) <= 40 and not seen.has("money_argument"):
  result.append("money_argument")
 return result

static func resolve(state: Dictionary, event_id: String, choice_id: String) -> Dictionary:
 if not pending(state).has(event_id):
  return {"ok":false,"message":"This band situation is not available."}
 var definition: Dictionary = EVENTS[event_id]
 var selected: Dictionary = {}
 for option in definition["choices"]:
  if option["id"] == choice_id:
   selected = option
   break
 if selected.is_empty():
  return {"ok":false,"message":"Invalid decision."}
 var next := state.duplicate(true)
 var roster: Array = next.get("members",[])
 for member in roster:
  if not member is Dictionary:
   continue
  for key in ["loyalty","morale","fatigue"]:
   if selected.has(key):
    member[key] = clampi(int(member.get(key,50))+int(selected[key]),0,100)
 for key in ["tension","morale","readiness"]:
  if selected.has(key):
   next[key] = clampi(int(next.get(key,50))+int(selected[key]),0,100)
 next["tour_day"] = int(next.get("tour_day",1))+1
 var seen: Dictionary = next.get("band_drama_resolved",{}).duplicate(true)
 seen[event_id] = choice_id
 next["band_drama_resolved"] = seen
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":"drama:"+event_id,"day":next["tour_day"],"title":definition["title"],"text":selected["label"],"kind":"band"})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":definition["title"]+" — "+selected["label"]+"."}

static func _maximum_fatigue(members: Array) -> int:
 var maximum := 0
 for member in members:
  if member is Dictionary:
   maximum = maxi(maximum,int(member.get("fatigue",0)))
 return maximum

# Pair-specific cases share the established band_drama_resolved and index-pair
# relationship schema. Existing generic event IDs and saves remain untouched.
const PAIR_EVENTS := {
 "rehearsal_resentment":{
  "title":"TWO VOICES, ONE REHEARSAL",
  "intro":"%s feels %s keeps dismissing their ideas in rehearsal. The others have noticed.",
  "choices":[
   {"id":"listen","label":"LET BOTH BE HEARD","text":"You make room for both voices and agree how the next rehearsal will work.","trust":12,"tension":-7,"morale":4,"readiness":-2,"first_loyalty":4,"second_loyalty":3},
   {"id":"keep","label":"KEEP THE CURRENT ARRANGEMENT","text":"The set stays on schedule, but the disagreement is unresolved.","trust":-9,"tension":9,"morale":-3,"readiness":4,"first_loyalty":-5,"second_loyalty":2}
  ]
 },
 "road_pressure":{
  "title":"A LONG DRIVE HOME",
  "intro":"%s and %s are arguing about loading the van. Everyone is tired, and the next show is looming.",
  "choices":[
   {"id":"mediate","label":"STOP AND SORT IT OUT","text":"You give the band a day to recover and divide the work fairly.","trust":10,"tension":-6,"morale":3,"readiness":-2,"fatigue":-10,"first_loyalty":3,"second_loyalty":3},
   {"id":"push","label":"STICK TO THE SCHEDULE","text":"You keep momentum, but both musicians feel unheard.","trust":-8,"tension":8,"morale":-4,"readiness":4,"fatigue":8,"first_loyalty":-3,"second_loyalty":-3}
  ]
 }
}

static func _identity(person: Dictionary, index: int) -> String:
 var identifier := str(person.get("candidate_id",person.get("id","")))
 if not identifier.is_empty():
  return "id:"+identifier
 # Legacy saves may lack IDs; name+role+index prevents silently attributing
 # an old pair case to a newly recruited musician at the same roster position.
 return "legacy:%d:%s:%s" % [index,str(person.get("name","")),str(person.get("role",""))]

static func _pair_incident_key(kind: String, first: Dictionary, second: Dictionary, a: int, b: int) -> String:
 var identities := [_identity(first,a),_identity(second,b)]
 identities.sort()
 return "pair:%s:%s|%s" % [kind,identities[0],identities[1]]

static func pair_pending(state: Dictionary) -> Array:
 var roster: Array = state.get("members",[])
 var relationships: Dictionary = state.get("relationships",{})
 var seen: Dictionary = state.get("band_drama_resolved",{})
 var day := int(state.get("tour_day",1))
 var songs := int(state.get("songs",0))
 var best: Dictionary = {}
 for i in range(roster.size()):
  if not roster[i] is Dictionary or str(roster[i].get("life_status","active")) != "active":
   continue
  for j in range(i+1,roster.size()):
   if not roster[j] is Dictionary or str(roster[j].get("life_status","active")) != "active":
    continue
   var first: Dictionary = roster[i]
   var second: Dictionary = roster[j]
   var relationship_key := "%d_%d" % [i,j]
   var reverse_key := "%d_%d" % [j,i]
   var trust := clampi(int(relationships.get(relationship_key,relationships.get(reverse_key,50))),0,100)
   var fatigue := maxi(int(first.get("fatigue",0)),int(second.get("fatigue",0)))
   for kind in ["rehearsal_resentment","road_pressure"]:
    if kind == "rehearsal_resentment" and (day < 6 or songs < 2 or trust > 58):
     continue
    if kind == "road_pressure" and (day < 10 or fatigue < 55 or trust > 68):
     continue
    var case_id := _pair_incident_key(kind,first,second,i,j)
    if seen.has(case_id):
     continue
    var rule: Dictionary = PAIR_EVENTS[kind]
    var priority := (100-trust)+(30 if kind == "road_pressure" else 0)+fatigue/10
    var case := {
     "id":case_id,"kind":kind,"title":str(rule["title"]),
     "intro":str(rule["intro"]) % [str(first.get("name","Musician")),str(second.get("name","Musician"))],
     "first":str(first.get("name","Musician")),"second":str(second.get("name","Musician")),
     "first_index":i,"second_index":j,"trust":trust,
     "choices":rule["choices"].duplicate(true),"priority":priority
    }
    if best.is_empty() or priority > int(best.get("priority",-1)) or (priority == int(best.get("priority",-1)) and case_id < str(best.get("id",""))):
     best = case
 return [] if best.is_empty() else [best]

static func resolve_pair(state: Dictionary, case_id: String, choice_id: String) -> Dictionary:
 var cases := pair_pending(state)
 if cases.is_empty() or str(cases[0].get("id","")) != case_id:
  return {"ok":false,"message":"This disagreement has already been handled or is no longer available."}
 var incident: Dictionary = cases[0]
 var selected: Dictionary = {}
 for option in incident["choices"]:
  if str(option.get("id","")) == choice_id:
   selected = option
   break
 if selected.is_empty():
  return {"ok":false,"message":"That intervention is unavailable."}
 var next: Dictionary = state.duplicate(true)
 var roster: Array = next.get("members",[])
 var first_index := int(incident["first_index"])
 var second_index := int(incident["second_index"])
 var first: Dictionary = roster[first_index]
 var second: Dictionary = roster[second_index]
 first["loyalty"] = clampi(int(first.get("loyalty",50))+int(selected.get("first_loyalty",0)),0,100)
 second["loyalty"] = clampi(int(second.get("loyalty",50))+int(selected.get("second_loyalty",0)),0,100)
 for index in [first_index,second_index]:
  var member: Dictionary = roster[index]
  member["morale"] = clampi(int(member.get("morale",50))+int(selected.get("morale",0)),0,100)
  member["fatigue"] = clampi(int(member.get("fatigue",0))+int(selected.get("fatigue",0)),0,100)
 next["members"] = roster
 var relationships: Dictionary = next.get("relationships",{}).duplicate(true)
 var pair_key := "%d_%d" % [mini(first_index,second_index),maxi(first_index,second_index)]
 relationships[pair_key] = clampi(int(incident["trust"])+int(selected.get("trust",0)),0,100)
 next["relationships"] = relationships
 for key in ["morale","tension","readiness"]:
  next[key] = clampi(int(next.get(key,50))+int(selected.get(key,0)),0,100)
 next["tour_day"] = int(next.get("tour_day",1))+1
 var seen: Dictionary = next.get("band_drama_resolved",{}).duplicate(true)
 seen[case_id] = choice_id
 next["band_drama_resolved"] = seen
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 journal.append({"id":case_id,"day":int(next["tour_day"]),"title":incident["title"],"text":"%s & %s — %s" % [incident["first"],incident["second"],selected["text"]],"kind":"band","pair":pair_key,"trust_change":int(selected["trust"])})
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":str(selected["text"])+" One day passes."}
