extends RefCounted
## Applies explicit rehearsal intent after the original resolver, before its one save.
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const FOCUSES=["precision","listening"]
const EFFORTS=["steady","push"]
static func valid(plan: Dictionary) -> bool:
 return plan.size()==2 and plan.get("focus") in FOCUSES and plan.get("effort") in EFFORTS
static func apply(before: Dictionary,after: Dictionary,indices: Array,plan: Dictionary,scheduled: bool=false) -> Dictionary:
 if not valid(plan) or not Connections.valid(before):return {"ok":false,"message":"Review the saved rehearsal direction and musician connections."}
 if int(after.get("action_count",0))!=int(before.get("action_count",0))+1:return {"ok":false,"message":"The rehearsal direction must resolve with one original session."}
 var next: Dictionary=after.duplicate(true)
 var report: Dictionary=next.get("last_rehearsal_outcome",{}).duplicate(true)
 if report.is_empty():return {"ok":false,"message":"The original rehearsal report is unavailable."}
 var records: Dictionary=next.get(Connections.KEY,{}).get("records",{}).duplicate(true)
 var notes: Array=[]
 var band_mood: int=0
 var readiness: int=0
 var tension: int=-2 if plan.focus=="listening" else 0
 for index in indices:
  var previous: Dictionary=before.members[index]
  var member: Dictionary=next.members[index]
  var id: String=str(member.get("candidate_id",""))
  var record: Dictionary=records.get(id,{}).duplicate(true)
  var answers: Dictionary=record.get("conversation",{}).get("answers",{})
  var fatigue: int=int(previous.get("fatigue",0))
  var trust: int=int(record.get("rapport",0))
  var worn: bool=fatigue>=55 or int(before.get("tension",0))>=65 or trust<=-5
  var mood: int=0
  var loyalty: int=0
  var rapport: int=0
  var line: String="We kept a steady pace and left something for next time."
  if plan.effort=="push":
   member["fatigue"]=clampi(int(member.get("fatigue",0))+4,0,100)
   readiness+=-2 if worn else 2
   mood+=-2 if worn else 0
   tension+=2 if worn else 0
   line="That hard pass did not settle us. We started losing the details." if worn else "We had enough left for another pass. The parts landed more firmly."
  else:member["fatigue"]=clampi(int(member.get("fatigue",0))-2,0,100)
  if plan.focus=="listening":
   mood+=2;readiness-=1
   line+=" We listened across the room instead of drilling every stop."
  else:
   var performer_trait: String=str(previous.get("trait","")).to_lower()
   if not worn and (performer_trait.contains("reliable") or performer_trait.contains("perfectionist")):readiness+=1
   line+=" We worked on coming in and cutting off together."
  if not record.is_empty():
   if (answers.get("working_style")=="shared" and plan.focus=="listening") or (answers.get("working_style")=="direct" and plan.focus=="precision"):
    rapport+=1;loyalty+=1
    line+=" That followed the way we agreed to work at my audition."
   if answers.get("working_style")=="shared" and plan.effort=="push" and worn:
    rapport-=2;loyalty-=1
    line+=" You said we'd build it together; I needed you to hear that I was struggling."
   if record.request=="own_part" and plan.focus=="listening":mood+=1
   if record.request=="space_for_voice" and plan.focus=="precision" and not worn:readiness+=1
   if answers.get("commitment")=="dates" and scheduled:
    rapport+=1;loyalty+=1;line+=" We agreed this evening and kept it."
   if answers.get("commitment")=="regular" and int(record.practices)>0:
    rapport+=1;loyalty+=1;line+=" We're making the rehearsal habit real."
   record["rapport"]=clampi(trust+rapport,-20,20)
   record["practices"]=mini(1000000000,int(record.practices)+1)
   records[id]=record
  member["morale"]=clampi(int(member.get("morale",55))+mood,0,100)
  member["loyalty"]=clampi(int(member.get("loyalty",60))+loyalty,0,100)
  band_mood+=mood
  var quote: String="The starts are landing together." if plan.focus=="precision" else "I could hear the others across the room."
  if plan.effort=="push" and worn:quote="I needed a breather before another take."
  elif answers.get("working_style")=="shared" and plan.focus=="listening":
   quote={"cast_jack":"That left room for everyone, like we agreed.","cast_zoe":"You left space to listen. That mattered.","cast_marcus":"My idea had room to land. Keep that going.","cast_arjun":"You made room for my part. Let's build on it."}.get(id,"That felt like building it together.")
  elif answers.get("working_style")=="direct" and plan.focus=="precision":quote="Clear direction. We got those starts together."
  notes.append({"candidate_id":id,"name":str(member.get("name","Bandmate")),"text":line,"quote":quote})
 if not records.is_empty():
  var wrapper_copy: Dictionary=next.get(Connections.KEY,{"version":1,"records":{}}).duplicate(true)
  wrapper_copy["records"]=records;next[Connections.KEY]=wrapper_copy
 next["readiness"]=clampi(int(next.get("readiness",0))+roundi(float(readiness)/maxi(1,indices.size())),0,100)
 next["morale"]=clampi(int(next.get("morale",55))+roundi(float(band_mood)/maxi(1,indices.size())),0,100)
 next["tension"]=clampi(int(next.get("tension",0))+tension,0,100)
 var reason: String=("We drilled the starts and stops." if plan.focus=="precision" else "We left space to listen and respond.")+ (" One more hard pass." if plan.effort=="push" else " A steady rehearsal pace.")
 report["direction"]=plan.duplicate(true);report["direction_notes"]=notes
 report["reason"]=str(report.get("reason",""))+" "+reason
 for note in notes:report["reason"]+="\n"+str(note.name)+": "+str(note.text)
 for key in ["readiness","morale","tension","cash","tour_day"]:
  var first: int=int(before.get(key,0));var last: int=int(next.get(key,0))
  report.metrics[key]={"before":first,"after":last,"delta":last-first}
 for row in report.get("member_changes",[]):
  for index in indices:
   if str(row.get("candidate_id",""))==str(next.members[index].get("candidate_id","")) and not str(row.get("candidate_id","")).is_empty():
    for stat in ["morale","fatigue","skill","loyalty"]:
     var first: int=int(before.members[index].get(stat,0));var last: int=int(next.members[index].get(stat,0))
     row.changes[stat]={"before":first,"after":last,"delta":last-first}
 var ready: int=int(report.metrics.readiness.delta);var stress: int=int(report.metrics.tension.delta)
 report["verdict"]="Good progress" if ready>=5 and stress<=3 else ("Tense session" if ready<=0 or stress>=4 else "Mixed session")
 next["last_rehearsal_outcome"]=report
 return {"ok":true,"state":next,"outcome":report,"message":reason}
