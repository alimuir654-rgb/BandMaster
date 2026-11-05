extends RefCounted
## Newly authored work-evening proposals. They take effect only after agreement.
const Core = preload("res://experiments/playable_flightcase/situation_core.gd")
const Dates = preload("res://experiments/playable_flightcase/career_dates.gd")
const Personal = preload("res://experiments/playable_flightcase/personal_context.gd")
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Radio = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Audition = preload("res://experiments/playable_flightcase/audition_encounter.gd")
const Workbench = preload("res://experiments/playable_flightcase/song_workbench.gd")
const PATTERNS := {
 "cast_jack":[0,2],"cast_arjun":[1,3],"cast_zoe":[1,5],"cast_marcus":[0,2],"cast_ellis":[4,5],
 "cast_maya":[1,5],"cast_dan":[0,2],"cast_ryan":[1,3],"cast_lily":[3,5],"cast_ben":[1,4],
 "cast_freya":[2,5],"cast_nina":[0,3],"cast_tom":[1,3],"cast_casey":[0,4],"cast_hannah":[0,2],
 "cast_oscar":[2,4],"cast_bex":[4,5],"cast_sam":[3,5]
}

static func exact(first: Variant, second: Variant) -> bool:
 # Iterative typed equality: Dictionary order is immaterial, key/scalar types
 # and exact binary float values are not. No recursive Array equality.
 var pending: Array=[[first,second]]
 var visited: int=0
 while not pending.is_empty():
  visited+=1
  if visited>2000000:return false
  var pair: Array=pending.pop_back()
  var a: Variant=pair[0];var b: Variant=pair[1]
  if typeof(a)!=typeof(b):return false
  if a is Dictionary:
   if a.size()!=b.size():return false
   var keys: Dictionary={}
   for key in b:keys[var_to_bytes(key).hex_encode()]=key
   for key in a:
    var code: String=var_to_bytes(key).hex_encode()
    if not keys.has(code):return false
    pending.append([a[key],b[keys[code]]])
  elif a is Array:
   if a.size()!=b.size():return false
   for index in range(a.size()):pending.append([a[index],b[index]])
  elif typeof(a) not in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING,TYPE_STRING_NAME] or var_to_bytes(a)!=var_to_bytes(b):return false
 return true

static func schema_ok(value: Variant) -> bool:
 var pending: Array=[value]
 var count: int=0
 while not pending.is_empty():
  count+=1
  if count>2000000:return false
  var item: Variant=pending.pop_back()
  if item is Dictionary:
   for key in item:
    if typeof(key)!=TYPE_STRING:return false
    pending.append(item[key])
  elif item is Array:
   for child in item:pending.append(child)
  elif typeof(item)==TYPE_FLOAT:
   if not is_finite(item):return false
  elif typeof(item) not in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_STRING]:return false
 return true

static func offer(career: Dictionary) -> Dictionary:
 var core: Dictionary=Core.validate(career)
 var clock: Dictionary=Dates.inspect(career)
 if not core.ok:return {"ok":false,"message":str(core.message),"rows":[],"proposals":{},"changed":false}
 if not clock.ok:return {"ok":false,"message":str(clock.message),"rows":[],"proposals":{},"changed":false}
 var rows: Array=[];var proposals: Dictionary={}
 for person in Core.members(career):
  if not person.active:continue
  var propose: bool=person.kind=="unknown" and PATTERNS.has(person.id)
  var entry: Dictionary={"id":person.id,"name":person.name,"proposed":propose,"work":Personal.for_candidate(str(person.id)).work,"text":Core.context_text(person,int(career.tour_day))}
  if propose:
   entry["days"]=PATTERNS[person.id].duplicate()
   entry["text"]="WORK EVENINGS: "+Core.weekday_words(entry.days)
   proposals[person.id]=entry.days.duplicate()
  rows.append(entry)
 return {"ok":true,"message":"","rows":rows,"proposals":proposals,"changed":not clock.exists or not proposals.is_empty(),"date_proposal":Dates.DAY_ONE if not clock.exists else str(clock.day_one)}

static func apply(opening: Dictionary, expected: Dictionary) -> Dictionary:
 var failure: Dictionary={"ok":false,"changed":false,"message":"The band changed. Reopen the proposed week before agreeing.","state":opening.duplicate(true)}
 if not schema_ok(opening) or not exact(opening,expected):return failure
 if opening.get("screen")!="play" or not opening.get("game") is Dictionary or opening.game.get("phase")!="play" or not opening.game.get("career") is Dictionary:return failure
 var career: Dictionary=opening.game.career
 if Finance.is_over(career) or Radio.locked(career) or Audition.locked(opening):failure.message="Finish the current visit or held activity before agreeing the week.";return failure
 if career.has(Workbench.KEY) and not Workbench.validate(opening).get("ok",false):failure.message="Review the saved writing activity before agreeing the week.";return failure
 var commitment: Dictionary=Booking.guard_commitment(career,"recorded_context",0)
 if not commitment.get("ok",false):failure.message=str(commitment.get("message","Finish the current commitment first."));return failure
 var proposal: Dictionary=offer(career)
 if not proposal.ok:failure.message=proposal.message;return failure
 if not proposal.changed:return {"ok":true,"changed":false,"message":"This week is already agreed. No day, fee or save has been used.","state":opening.duplicate(true)}
 var result: Dictionary=Core.agree_weekly(career,proposal.proposals)
 if not result.ok:failure.message=result.message;return failure
 var next: Dictionary=opening.duplicate(true)
 next.game.career=result.state.duplicate(true)
 if not next.game.career.has(Dates.KEY):next.game.career[Dates.KEY]=Dates.initial()
 return {"ok":true,"changed":true,"message":"The recorded patterns and career dates are saved. Unrecorded availability stays unknown. No day or room fee was used.","state":next}

static func outside_equal(first: Dictionary, second: Dictionary) -> bool:
 var a: Dictionary=first.duplicate(true);var b: Dictionary=second.duplicate(true)
 for value in [a,b]:
  if not value.get("game") is Dictionary or not value.game.get("career") is Dictionary:return false
  value.game.career.erase(Core.KEY);value.game.career.erase(Dates.KEY)
 return exact(a,b)
