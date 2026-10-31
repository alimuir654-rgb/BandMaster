extends RefCounted
## Pure adapter for existing career rules over the current C27 flat career.
## No files, scene changes, signals, animations, saves or new gameplay rules.
const Gear = preload("res://Scripts/gear_shop.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")

static func show_day(state: Dictionary) -> bool:
 var booking: Dictionary = Calendar.pending(state)
 # Exact original CareerHub predicate, including its default numeric value.
 return not booking.is_empty() and int(booking.get("day",-1))==int(state.get("tour_day",0))

static func _member(state: Dictionary, index: int) -> Dictionary:
 var members: Variant = state.get("members",[])
 if not members is Array or index<0 or index>=members.size() or not members[index] is Dictionary:
  return {}
 return members[index]

static func _selected_voice(state: Dictionary, person: Dictionary) -> bool:
 var selected: String = str(state.get("lead_vocal_candidate_id",""))
 return not selected.is_empty() and str(person.get("candidate_id",""))==selected

static func _needs_voice_projection(state: Dictionary, item: String, person: Dictionary) -> bool:
 if person.is_empty() or Gear.compatible(item,person) or not _selected_voice(state,person):
  return false
 var projected: Dictionary = person.duplicate(true)
 projected["role"] = "Singer"
 return Gear.compatible(item,projected)

static func compatible(state: Dictionary, item: String, member: int) -> bool:
 # Role compatibility only, matching Gear.compatible. Ownership, life status,
 # show-day and repeated-assignment checks remain authoritative at dispatch.
 var person: Dictionary = _member(state,member)
 return not person.is_empty() and (Gear.compatible(item,person) or _needs_voice_projection(state,item,person))

static func _assignment_state(state: Dictionary, item: String, member: int) -> Dictionary:
 var projected: Dictionary = state.duplicate(true)
 var person: Dictionary = _member(state,member)
 if not _needs_voice_projection(state,item,person):
  return projected
 var members: Array = projected["members"]
 members[member]["role"] = "Singer"
 projected["members"] = members
 var entry: Dictionary = Gear.record(state,item)
 var holder: int = Gear.holder_index(state,entry)
 if holder==member:
  # Preserve a VALID same-person assignment through the temporary role change,
  # so original Gear.assign still rejects the same assignment as a no-op.
  entry["holder_role"] = "Singer"
 elif holder<0 and Gear.holder_index(projected,entry)==member:
  # An originally stale record must not become valid solely due to projection.
  # Mark it unassigned only in this resolver copy. Explicit Gear.assign creates
  # fresh holder metadata; no read or failed action repairs the original state.
  entry["holder_index"] = -1
 else:
  return projected
 var records: Dictionary = projected.get("gear_records",{}).duplicate(true)
 records[item] = entry
 projected["gear_records"] = records
 return projected

static func gear_action(state: Dictionary, verb: String, item: String, member: int = -1) -> Dictionary:
 if show_day(state):
  return {"ok":false,"message":"Tonight's gig comes first. Finish the show before another activity."}
 var before: Dictionary = state.duplicate(true)
 var result: Dictionary
 var source := ""
 match verb:
  "buy":
   # Original CareerHub._buy supplies the default empty source string.
   result = Gear.buy(before,item)
  "assign":
   source = "gear:assign"
   result = Gear.assign(_assignment_state(before,item,member),item,member)
   if bool(result.get("ok",false)):
    var updated: Dictionary = result["state"]
    var original_members: Array = before["members"]
    updated["members"] = original_members.duplicate(true)
    var records: Dictionary = updated["gear_records"]
    var entry: Dictionary = records[item]
    entry["holder_role"] = str(original_members[member].get("role",""))
    records[item] = entry
    updated["gear_records"] = records
    result["state"] = updated
  "service":
   source = "gear:service"
   result = Gear.service(before,item)
  _:
   return {"ok":false,"message":"Unknown equipment action."}
 if not bool(result.get("ok",false)):
  return result
 # Exact original CareerHub successful-result order. Refresh only returns
 # existing away members; this adapter never calls Life.candidates/recruit or
 # resolves departures. Canonical member roles were restored before this chain.
 result["state"] = Life.refresh(Calendar.expire(Story.observe(before,result["state"],source)))
 return result
