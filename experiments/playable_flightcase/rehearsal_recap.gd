extends RefCounted
## S39: purely present the S38 saved resolver result. This file NEVER changes career.
const FOCUS_LABELS = {"tighten":"LIVE REHEARSAL","connect":"BAND MEETING","create":"WRITING SESSION","jam":"INFORMAL PRACTICE"}

static func signed_change(value: int, unit: String = "") -> String:
 if value > 0:
  return "+" + unit + str(value)
 if value < 0:
  return "−" + unit + str(absi(value))
 return "0"

static func _metric_row(key: String, label: String, metrics: Dictionary) -> Dictionary:
 var item: Dictionary = metrics.get(key,{})
 var before: int = int(item.get("before",0))
 var after: int = int(item.get("after",0))
 var delta: int = int(item.get("delta",after-before))
 var money := key == "cash"
 var left := ("£" if money else "") + str(before)
 var right := ("£" if money else "") + str(after)
 return {"key":key,"label":label,"before":before,"after":after,"delta":delta,
  "text":"%s  %s → %s   %s" % [label,left,right,signed_change(delta,"£" if money else "")]}

static func _reaction(report: Dictionary, change: Dictionary, _members: Array, used_quotes: Dictionary) -> Dictionary:
 var id: String = str(change.get("candidate_id",""))
 var name: String = str(change.get("name","Musician"))
 var stats: Dictionary = change.get("changes",{})
 var mood: int = int(stats.get("morale",{}).get("delta",0))
 var tired: int = int(stats.get("fatigue",{}).get("delta",0))
 var loyalty: int = int(stats.get("loyalty",{}).get("delta",0))
 var focus: String = str(report.get("focus",""))
 var strained: bool = int(report.get("metrics",{}).get("tension",{}).get("delta",0))>0
 # These are short authored readings of recorded personal and band outcomes.
 # A current trait/risk is not evidence that this musician caused a saved
 # disagreement. In particular, feeling better and a tense room can coexist.
 var lines: Array[String] = ["Let's see what comes next.","I'll see how the next session goes.","I'm taking stock of that one.","We'll have to build from here.","I need to sit with that session.","Let's come back to it."]
 if focus=="jam":
  lines = ["Good to spend time with the music.","Something to bring back to the others.","A few patterns to keep working on.","Worth finding a little space to practise.","We can pick this up together next time.","A little more time getting comfortable with the parts."]
 elif mood>0 and strained:
  lines = ["Glad we got through it. Tense room, though.","Something to keep. Still a tense session.","I'm feeling better; the room was tense.","I took something from it, despite the strain.","A lift for me, even with the tension.","That helped me. It wasn't an easy session."]
 elif mood>0 and focus=="create":
  lines = ["There's something worth building on.","I'm glad we put time into this song.","That gives us something to work with.","I feel better about where this is going.","Something to bring to the next session.","I'm taking something good from that."]
 elif mood>0 and focus=="connect":
  lines = ["I'm glad we talked.","It helped to hear everyone out.","I feel better for that conversation.","We needed time to talk.","That was worth making space for.","I'm leaving that in a better mood."]
 elif mood>0:
  lines = ["That felt a bit more locked in.","I'm feeling better after that.","That was time well spent.","I'm glad we got the session in.","Something to take into the next rehearsal.","I got something out of that."]
 elif mood<0:
  lines = ["I wasn't feeling that one.","I'm coming away frustrated.","That didn't feel good to me.","I'm not leaving that in a good mood.","I found that session difficult.","That wasn't an easy session for me."]
 elif loyalty>0:
  lines = ["It helped to hear everyone out.","I'm glad we made time for each other.","That conversation mattered to me.","I feel more part of this.","Worth showing up for each other.","I'm glad we stayed with it."]
 elif tired>0:
  lines = ["Hard work, but we did the session.","I'm worn out after that.","I could do with a rest.","That took some energy.","Time to catch my breath.","I'm feeling that session now."]
 var start: int = posmod(id.hash(),lines.size())
 var quote: String = lines[start]
 for offset in range(lines.size()):
  var candidate: String = lines[(start+offset)%lines.size()]
  if not used_quotes.has(candidate):
   quote=candidate
   break
 used_quotes[quote]=true
 var changes := PackedStringArray()
 if focus=="jam":
  var skill: int=int(stats.get("skill",{}).get("delta",0))
  if skill!=0:changes.append("skill " + signed_change(skill))
 if mood != 0:
  changes.append("morale " + signed_change(mood))
 if tired != 0:
  changes.append("fatigue " + signed_change(tired))
 if loyalty != 0:
  changes.append("loyalty " + signed_change(loyalty))
 var change_text: String = "no personal stat change" if changes.is_empty() else ", ".join(changes)
 return {"candidate_id":id,"name":name,"quote":quote,"effects":change_text}

static func present(report: Dictionary, career_members: Array) -> Dictionary:
 if int(report.get("version",0)) != 1 or not report.get("metrics",{}) is Dictionary:
  return {}
 var metrics: Dictionary = report.get("metrics",{})
 var rows: Array = []
 for pair in [["readiness","READINESS"],["cohesion","COHESION*"],["morale","BAND MORALE"],
  ["tension","TENSION"],["cash","CASH"],["tour_day","DAY"]]:
  if metrics.has(pair[0]) and metrics[pair[0]] is Dictionary:
   rows.append(_metric_row(str(pair[0]),str(pair[1]),metrics))
 var voices: Array = []
 var used_quotes: Dictionary = {}
 for member in report.get("member_changes",[]):
  if member is Dictionary:
   voices.append(_reaction(report,member,career_members,used_quotes))
 var focus: String = str(report.get("focus","tighten"))
 var title: String = str(FOCUS_LABELS.get(focus,"SESSION"))
 var tensions: int = int(metrics.get("tension",{}).get("delta",0))
 var ready: int = int(metrics.get("readiness",{}).get("delta",0))
 var next_step := "Keep shaping an original and rehearse before your first show."
 if focus=="jam":
  next_step="Keep a full rehearsal for the live set. Check the calendar for an evening together."
 elif tensions > 0:
  next_step = "Tension rose. CLEAR THE AIR can help before the next push."
 elif focus == "connect":
  next_step = "You have talked things through. Try a focused rehearsal."
 elif ready <= 0:
  next_step = "The set did not improve. Consider the band's preparation before drilling again."
 var day_change: Dictionary = metrics.get("tour_day",{})
 var cash_change: Dictionary = metrics.get("cash",{})
 var has_receipt: bool = day_change.has("before") and day_change.has("after") and cash_change.has("before") and cash_change.has("after")
 var completed_day: int = int(day_change.get("before",maxi(1,int(report.get("day",1))-1)))
 var after_day: int = int(day_change.get("after",report.get("day",1)))
 var receipt := "SAVED SESSION NOTES"
 if has_receipt:
  receipt = "SESSION CASH  £%d → £%d  •  %d DAY%s" % [int(cash_change["before"]),int(cash_change["after"]),after_day-completed_day,"" if after_day-completed_day==1 else "S"]
 var personal_lift: bool = false
 for saved_member in report.get("member_changes",[]):
  if saved_member is Dictionary and int(saved_member.get("changes",{}).get("morale",{}).get("delta",0))>0:
   personal_lift=true
 var room_context: String = "Personal morale improved; band tension also rose." if tensions>0 and personal_lift else ""
 var saved_reason: String = str(report.get("reason",""))
 var first_sentence: String = saved_reason.split(" — ",false,1)[0] if saved_reason.contains(" — ") else saved_reason
 for suffix in [" Creative disagreements add "," Missed preparation costs "]:
  var cut: int = first_sentence.find(suffix)
  if cut>=0:
   first_sentence=first_sentence.substr(0,cut).strip_edges()
 return {"action_id":str(report.get("action_id","")),"focus":focus,
  "heading":title + "  /  DAY " + str(completed_day if has_receipt else int(report.get("day",0))),
  "verdict":str(report.get("verdict","Session completed")),
  "reason":saved_reason,"summary":first_sentence,"room_context":room_context,
  "completed_day":completed_day,"after_day":after_day,"has_receipt":has_receipt,
  "receipt":receipt,"completed_heading":"SAVED DAY %d  •  %s" % [completed_day,str({"tighten":"REHEARSAL","create":"WRITING","connect":"BAND MEETING","jam":"INFORMAL PRACTICE"}.get(focus,"SESSION"))] if has_receipt else "SESSION COMPLETE",
  "metric_rows":rows,"reactions":voices,
  "footnote":"* Cohesion is the mean of existing pair relationships, not a separate bonus.",
  "next_step":next_step}
