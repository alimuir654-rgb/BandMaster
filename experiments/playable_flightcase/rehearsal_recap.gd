extends RefCounted
## S39: purely present the S38 saved resolver result. This file NEVER changes career.
const FOCUS_LABELS = {"tighten":"LIVE REHEARSAL","connect":"BAND MEETING","create":"WRITING SESSION"}

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

static func _reaction(report: Dictionary, change: Dictionary, members: Array) -> Dictionary:
 var id: String = str(change.get("candidate_id",""))
 var name: String = str(change.get("name","Musician"))
 var person: Dictionary = {}
 for candidate in members:
  if candidate is Dictionary and str(candidate.get("candidate_id","")) == id:
   person = candidate
   break
 var trait: String = str(person.get("trait","Musician")).to_lower()
 var risk: Dictionary = person.get("rehearsal_risk",{})
 var stats: Dictionary = change.get("changes",{})
 var mood: int = int(stats.get("morale",{}).get("delta",0))
 var tired: int = int(stats.get("fatigue",{}).get("delta",0))
 var loyalty: int = int(stats.get("loyalty",{}).get("delta",0))
 var focus: String = str(report.get("focus",""))
 var quote := "Same mood as before. Let's see what comes next."
 if focus == "tighten" and int(risk.get("missed_preparation",0))>0 and str(report.get("reason","")).contains("Missed preparation"):
  quote = "I could've done more preparation before today."
 elif focus == "create" and int(risk.get("creative_friction",0))>0 and str(report.get("reason","")).contains("Creative disagreements"):
  quote = "I didn't agree with all the decisions."
 elif mood > 0:
  if trait.contains("perfectionist") or trait.contains("reliable"):
   quote = "That felt a bit more locked in."
  elif focus == "create" and (trait.contains("creative") or trait.contains("chaos")):
   quote = "There's something worth building on."
  elif focus == "connect":
   quote = "We needed to have that conversation."
  else:
   quote = "That was a useful session."
 elif mood < 0:
  if trait.contains("restless") or trait.contains("chaos"):
   quote = "Too much repetition for my liking."
  elif trait.contains("perfectionist") and focus == "create":
   quote = "I wanted more time on the details."
  else:
   quote = "I wasn't feeling that one."
 elif loyalty > 0:
  quote = "It helped to hear everyone out."
 elif tired > 0:
  quote = "Hard work, but we did the session."
 var changes: Array[String] = []
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
 for member in report.get("member_changes",[]):
  if member is Dictionary:
   voices.append(_reaction(report,member,career_members))
 var focus: String = str(report.get("focus","tighten"))
 var title: String = str(FOCUS_LABELS.get(focus,"SESSION"))
 var tensions: int = int(metrics.get("tension",{}).get("delta",0))
 var ready: int = int(metrics.get("readiness",{}).get("delta",0))
 var next_step := "Keep shaping an original and rehearse before your first show."
 if tensions > 0:
  next_step = "Tension rose. CLEAR THE AIR can help before the next push."
 elif focus == "connect":
  next_step = "You have talked things through. Try a focused rehearsal."
 elif ready <= 0:
  next_step = "The set did not improve. Consider the band's preparation before drilling again."
 return {"action_id":str(report.get("action_id","")),"focus":focus,
  "heading":title + "  /  DAY " + str(int(report.get("day",0))),
  "verdict":str(report.get("verdict","Session completed")),
  "reason":str(report.get("reason","")),
  "metric_rows":rows,"reactions":voices,
  "footnote":"* Cohesion is the mean of existing pair relationships, not a separate bonus.",
  "next_step":next_step}
