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
  "first_line":"I bring ideas, but they never make it into the set.",
  "second_line":"I am trying to keep us ready. We cannot rewrite every song.",
  "choices":[
   {"id":"listen","label":"LET BOTH BE HEARD","text":"You make room for both voices and agree how the next rehearsal will work.","trust":12,"tension":-7,"morale":4,"readiness":-2,"first_loyalty":4,"second_loyalty":3},
   {"id":"keep","label":"KEEP THE CURRENT ARRANGEMENT","text":"The set stays on schedule, but the disagreement is unresolved.","trust":-9,"tension":9,"morale":-3,"readiness":4,"first_loyalty":-5,"second_loyalty":2}
  ]
 },
 "song_credit":{
  "title":"WHO GETS THE WRITING CREDIT?",
  "intro":"%s led the finished song \"%s\", but %s also led a writing session. The sleeve currently credits only one writer.",
  "first_line":"I brought the final version together. I thought that made me the lead writer.",
  "second_line":"I shaped this song in the writing room too. I want that work acknowledged.",
  "choices":[
   {"id":"share","label":"CREDIT BOTH CONTRIBUTORS","text":"You recognise both musicians on the song sleeve without erasing the original session lead.","credit_label":"BOTH WRITERS","trust":12,"tension":-8,"morale":4,"readiness":-2,"first_loyalty":3,"second_loyalty":5},
   {"id":"lead","label":"KEEP THE LEAD CREDIT","text":"The lead writer keeps sole credit. The other contributor feels their session was overlooked.","credit_label":"LEAD ONLY","trust":-10,"tension":9,"morale":-3,"readiness":3,"first_loyalty":3,"second_loyalty":-6}
  ]
 },
 "road_pressure":{
  "title":"A LONG DRIVE HOME",
  "intro":"%s and %s are arguing about loading the van. Everyone is tired, and the next show is looming.",
  "first_line":"I am always the one left loading the van.",
  "second_line":"We are all tired. I thought we agreed to share the work.",
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

# A credit dispute is earned by actual completed-song writing sessions.
# Do not invent a collaborator when old saves have no session provenance.
static func _credit_song_for_pair(state: Dictionary, first: Dictionary, second: Dictionary) -> Dictionary:
 var songs: Array = state.get("song_catalogue",[])
 var first_name := str(first.get("name","")).strip_edges()
 var second_name := str(second.get("name","")).strip_edges()
 if first_name.is_empty() or second_name.is_empty() or first_name.to_lower() == second_name.to_lower():
  return {}
 for index in range(songs.size()-1,-1,-1):
  if not songs[index] is Dictionary:
   continue
  var song: Dictionary = songs[index]
  if song.has("credit_resolution"):
   continue
  var lead := str(song.get("lead_writer","")).strip_edges()
  var title := str(song.get("title","")).strip_edges()
  if lead.is_empty() or title.is_empty():
   continue
  var lead_position := -1
  if lead.to_lower() == first_name.to_lower():
   lead_position = 0
  elif lead.to_lower() == second_name.to_lower():
   lead_position = 1
  if lead_position < 0:
   continue
  var other_name := second_name if lead_position == 0 else first_name
  var sessions = song.get("writing_sessions",[])
  if not sessions is Array:
   continue
  var lead_contributed := false
  var other_contributed := false
  for session in sessions:
   if not session is Dictionary:
    continue
   var writer := str(session.get("leader","")).strip_edges().to_lower()
   if writer == lead.to_lower():
    lead_contributed = true
   if writer == other_name.to_lower():
    other_contributed = true
  if lead_contributed and other_contributed:
   return {"index":index,"title":title,"lead_position":lead_position}
 return {}

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
   for kind in ["rehearsal_resentment","road_pressure","song_credit"]:
    if kind == "rehearsal_resentment" and (day < 6 or songs < 2 or trust > 58):
     continue
    if kind == "road_pressure" and (day < 10 or fatigue < 55 or trust > 68):
     continue
    var credit: Dictionary = {}
    var case_first: Dictionary = first
    var case_second: Dictionary = second
    var case_first_index := i
    var case_second_index := j
    if kind == "song_credit":
     if day < 7 or trust > 75:
      continue
     credit = _credit_song_for_pair(state,first,second)
     if credit.is_empty():
      continue
     if int(credit["lead_position"]) == 1:
      case_first = second
      case_second = first
      case_first_index = j
      case_second_index = i
    var case_id := _pair_incident_key(kind,case_first,case_second,case_first_index,case_second_index)
    if kind == "song_credit":
     case_id += ":song:%d" % int(credit["index"])
    if seen.has(case_id):
     continue
    var rule: Dictionary = PAIR_EVENTS[kind]
    var priority := (100-trust)+(30 if kind == "road_pressure" else (45 if kind == "song_credit" else 0))+fatigue/10
    var case := {
     "id":case_id,"kind":kind,"title":str(rule["title"]),
     "intro":(str(rule["intro"]) % [str(case_first.get("name","Musician")),str(credit.get("title","")),str(case_second.get("name","Musician"))]) if kind == "song_credit" else (str(rule["intro"]) % [str(case_first.get("name","Musician")),str(case_second.get("name","Musician"))]),
     "first":str(case_first.get("name","Musician")),"second":str(case_second.get("name","Musician")),
     "first_index":case_first_index,"second_index":case_second_index,"trust":trust,
     "song_index":int(credit.get("index",-1)),"song_title":str(credit.get("title","")),
     "first_line":str(rule.get("first_line","")),"second_line":str(rule.get("second_line","")),
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
 var credited: Array = []
 if str(incident.get("kind","")) == "song_credit":
  var catalogue: Array = next.get("song_catalogue",[])
  var song_index := int(incident.get("song_index",-1))
  if song_index >= 0 and song_index < catalogue.size() and catalogue[song_index] is Dictionary:
   var song: Dictionary = catalogue[song_index]
   credited = [str(incident["first"]),str(incident["second"])] if choice_id == "share" else [str(incident["first"])]
   song["credited_writers"] = credited.duplicate()
   song["credit_resolution"] = {"day":int(next["tour_day"]),"choice":choice_id,"case_id":case_id}
   catalogue[song_index] = song
   next["song_catalogue"] = catalogue
 var journal: Array = next.get("career_journal",[]).duplicate(true)
 var moment := {"id":case_id,"day":int(next["tour_day"]),"title":incident["title"],"text":"%s & %s — %s" % [incident["first"],incident["second"],selected["text"]],"kind":"band","pair":pair_key,"trust_change":int(selected["trust"]),
  "pair_names":[incident["first"],incident["second"]],"trust_before":int(incident["trust"]),"trust_after":int(relationships[pair_key]),
  "choice_id":choice_id,"decision_label":str(selected["label"]),"first_line":str(incident.get("first_line","")),"second_line":str(incident.get("second_line",""))}
 if str(incident.get("kind","")) == "song_credit":
  moment["song_title"] = str(incident.get("song_title",""))
  moment["credited_writers"] = credited.duplicate()
 journal.append(moment)
 while journal.size() > 80:
  journal.pop_front()
 next["career_journal"] = journal
 return {"ok":true,"state":next,"message":str(selected["text"])+" One day passes."}
