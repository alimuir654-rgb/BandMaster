extends RefCounted
## Reviewed authored writing, and literal observations. No lyric analysis or rewards.
const VERSION := "s84_two_line_hook_v1"
const FIRST := "We keep a light above the door"
const SECOND := "For everyone still coming home"
const ALTERNATE := "Till the last bus brings us home"

static func material(kind: String = "seed") -> Dictionary:
 if kind not in ["seed","alternate"]:return {"ok":false,"content_version":VERSION,"material":{},"message":"Choose a recorded take."}
 return {"ok":true,"content_version":VERSION,"message":"","material":{"lines":[{"id":"hook:1","text":FIRST},{"id":"hook:2","text":SECOND if kind=="seed" else ALTERNATE}],"refrain_line_id":"hook:2","sections":{"verse":"hook:1","chorus":"hook:2"}}}

static func _input_material(value: Variant) -> bool:
 if not value is Dictionary or not value.get("lines") is Array or value.lines.size()!=2 or value.get("refrain_line_id") not in ["hook:1","hook:2"] or not value.get("sections") is Dictionary:return false
 for row in value.lines:
  if not row is Dictionary or not row.get("text") is String:return false
 return value.sections.get("verse") in ["hook:1","hook:2"] and value.sections.get("chorus")==value.refrain_line_id

static func _owned_material(value: Dictionary) -> Dictionary:
 return {"lines":[{"id":"hook:1","text":value.lines[0].text},{"id":"hook:2","text":value.lines[1].text}],"refrain_line_id":value.refrain_line_id,"sections":{"verse":value.sections.verse,"chorus":value.sections.chorus}}

static func note(respondent: Dictionary,current: Dictionary,previous: Dictionary,context: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"note":{},"message":"The literal writing material or saved note needs review."}
 if not _input_material(current):return fail
 var day: Variant=context.get("day")
 if not (day is int or day is float) or not is_finite(float(day)) or float(day)!=floor(float(day)) or float(day)<1 or float(day)>1000000000:return fail
 if not previous.is_empty():
  if not _input_material(previous.get("fragment_snapshot")) or not previous.get("note") is Dictionary or not previous.note.get("request") is Dictionary:return fail
  var old: Dictionary=previous.note.request
  if old.get("kind")=="keep_line" and (old.get("line_id") not in ["hook:1","hook:2"] or not old.get("text") is String):return fail
 var text := ""
 var request: Dictionary={}
 var kind := "literal"
 var candidate: String=str(respondent.get("candidate_id","")) if not str(respondent.get("bio_sha256","")).is_empty() else ""
 var seed: Dictionary=material().material
 var alternate: Dictionary=material("alternate").material
 if _owned_material(current)==seed and candidate in ["cast_zoe","cast_jack","cast_casey"]:
  kind="authored"
  match candidate:
   "cast_zoe":
    text="I’d keep ‘We keep a light above the door’. Could we try a more particular second line?"
    request={"kind":"keep_line","line_id":"hook:1","text":FIRST}
   "cast_jack":
    text="Could we try the other line as the refrain and leave the rest underneath it?"
    request={"kind":"refrain","line_id":"hook:1"}
   "cast_casey":
    text="Let’s put the first line in the chorus for a take, then look at both versions."
    request={"kind":"refrain","line_id":"hook:1"}
 elif _owned_material(current)==alternate:
  text="That second line is now ‘Till the last bus brings us home’. Shall we keep that take beside the first?"
 elif not previous.is_empty() and previous.get("fragment_snapshot") is Dictionary:
  var prior: Dictionary=previous.fragment_snapshot
  var changes: Array[String]=[]
  for index in range(2):
   if current.lines[index].text!=prior.lines[index].text:
    changes.append("Line %d changed from ‘%s’ to ‘%s’." % [index+1,prior.lines[index].text,current.lines[index].text])
  if current.refrain_line_id!=prior.refrain_line_id:
   changes.append("The refrain moved from line %s to line %s." % [str(prior.refrain_line_id).trim_prefix("hook:"),str(current.refrain_line_id).trim_prefix("hook:")])
  var old_request: Dictionary=previous.get("note",{}).get("request",{})
  if old_request.get("kind")=="keep_line":
   var request_index: int=0 if old_request.line_id=="hook:1" else 1
   if current.lines[request_index].text!=old_request.text:
    changes.append("The saved note asked to keep ‘%s’; this take has ‘%s’." % [old_request.text,current.lines[request_index].text])
  text=" ".join(changes) if not changes.is_empty() else "The words and refrain are unchanged from the recorded take. Keep it beside the earlier note."
 else:
  text="The saved refrain is ‘%s’. Keep this take to compare with your next revision." % current.lines[0 if current.refrain_line_id=="hook:1" else 1].text
 if respondent.is_empty():text="No other active bandmate has a written response recorded. "+text
 return {"ok":true,"message":"","note":{"text":text,"request":request,"source_kind":kind,"content_version":VERSION,"respondent_ref":respondent.duplicate(true),"day":int(context.get("day",1)),"delivery":"written_note"}}
