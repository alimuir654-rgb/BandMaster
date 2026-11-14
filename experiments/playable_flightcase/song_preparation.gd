extends RefCounted
## Prospective factual rehearsal evidence only. No readiness/transfer score is inferred.
const Workbench=preload("res://experiments/playable_flightcase/song_workbench.gd")
const Intent=preload("res://experiments/playable_flightcase/rehearsal_intent.gd")
const KEY: String="song_preparation_v1"
const POLICY: String="exact_revision_rehearsal_v1"
const MAX_RECEIPTS: int=256
const SOURCE_KEY: String="section_source_v2"
const SOURCE_POLICY: String="rehearsed_section_source_v2"

static func identity_valid(raw: Variant) -> bool:
 if not raw is Dictionary or not Workbench._keys(raw,["song_id","composition_id","revision_id"]):return false
 if not raw.song_id is String or not Workbench._canonical_number_id(raw.song_id,"original:") or not raw.composition_id is String or not Workbench._canonical_number_id(raw.composition_id,"workbench:") or not raw.revision_id is String:return false
 var prefix: String=raw.composition_id+":material:"
 if not raw.revision_id.begins_with(prefix):return false
 var digest: String=raw.revision_id.trim_prefix(prefix)
 if digest.length()!=64:return false
 for character in digest:
  if not "0123456789abcdef".contains(character):return false
 return true

static func candidate_valid(id: Variant) -> bool:
 if not id is String or id.is_empty():return false
 for person in Workbench.Cast.combined_people():
  if person.id==id:return true
 return false

static func valid(raw: Variant) -> bool:
 if not raw is Dictionary or not Workbench._keys(raw,["policy","receipts"]) or raw.policy!=POLICY or not raw.receipts is Array or raw.receipts.size()>MAX_RECEIPTS:return false
 var previous: int=0
 for row in raw.receipts:
  if not row is Dictionary:return false
  var keys: Array=["action_no","action_id","song_id","composition_id","revision_id","participants","direction","day","completed_day","attendance_id"]
  if row.has(SOURCE_KEY):keys.append(SOURCE_KEY)
  if not Workbench._keys(row,keys):return false
  if not Workbench._whole(row.action_no,previous+1) or row.action_id!="practice:tighten:%d" % int(row.action_no):return false
  if not identity_valid({"song_id":row.song_id,"composition_id":row.composition_id,"revision_id":row.revision_id}):return false
  if not row.participants is Array or row.participants.is_empty() or row.participants.size()>6 or not row.direction is Dictionary or not Intent.valid(row.direction) or not Workbench._whole(row.day,1) or not Workbench._whole(row.completed_day,2) or row.completed_day!=row.day+1 or not row.attendance_id is String or row.attendance_id!=row.action_id:return false
  var seen: Array=[]
  for id in row.participants:
   if not candidate_valid(id) or seen.has(id):return false
   seen.append(id)
  if row.has(SOURCE_KEY) and not source_valid(row[SOURCE_KEY],{"song_id":row.song_id,"composition_id":row.composition_id,"revision_id":row.revision_id}):return false
  previous=int(row.action_no)
 return true

static func target(opening: Dictionary,reference: Dictionary) -> Dictionary:
 var read: Dictionary=Workbench.read_finished(opening,reference)
 if not read.ok or not read.fragment.get("composition_identity_v1") is Dictionary:return {"ok":false,"message":"This version has no verified composition identity. Choose a current finished original."}
 var identity: Dictionary=read.fragment.composition_identity_v1
 var count: int=0
 for song in opening.game.career.song_catalogue:
  if song is Dictionary and song.get("id")==identity.song_id:count+=1
 if count!=1:return {"ok":false,"message":"This song identity is ambiguous."}
 return {"ok":true,"identity":{"song_id":identity.song_id,"composition_id":identity.composition_id,"revision_id":identity.revision_id}}

static func record(before: Dictionary,after: Dictionary,identity: Dictionary,direction: Dictionary,result: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"message":"The song rehearsal evidence could not be reconciled."}
 var raw: Variant=before.get(KEY,{"policy":POLICY,"receipts":[]})
 if not identity_valid(identity) or not valid(raw) or raw.receipts.size()>=MAX_RECEIPTS or not Intent.valid(direction):return fail
 if not Workbench._exact(after.get(KEY,{"policy":POLICY,"receipts":[]}),raw):return fail
 if int(after.get("action_count",0))!=int(before.get("action_count",0))+1 or int(after.get("tour_day",0))!=int(before.get("tour_day",0))+1:return fail
 var outcome: Variant=result.get("outcome")
 var attendance: Variant=outcome.get("attendance") if outcome is Dictionary else null
 if not outcome is Dictionary or outcome.get("action_id")!="practice:tighten:%d" % int(after.action_count) or not attendance is Dictionary or attendance.get("id")!=outcome.action_id or attendance.get("day")!=before.tour_day or attendance.get("completed_day")!=after.tour_day or not attendance.get("attendee_ids") is Array:return fail
 var people: Array=[]
 for index in result.get("attendee_indices",[]):
  if not Workbench._whole(index) or int(index)>=before.members.size():return fail
  var id: String=str(before.members[int(index)].get("candidate_id",""))
  if not candidate_valid(id) or people.has(id):return fail
  var count: int=0
  for person in before.members:
   if person is Dictionary and person.get("candidate_id")==id:count+=1
  if count!=1:return fail
  people.append(id)
 # Situation IDs currently equal canonical candidate IDs; require actual returned order.
 if not Workbench._exact(people,attendance.attendee_ids):return fail
 var row: Dictionary={"action_no":after.action_count,"action_id":outcome.action_id,"song_id":identity.song_id,"composition_id":identity.composition_id,"revision_id":identity.revision_id,"participants":people,"direction":direction.duplicate(true),"day":before.tour_day,"completed_day":after.tour_day,"attendance_id":attendance.id}
 var source: Dictionary=_source_for(before,identity)
 if not source.ok:return fail
 row[SOURCE_KEY]=source.value
 var ledger: Dictionary=raw.duplicate(true);ledger.receipts.append(row)
 if not valid(ledger):return fail
 var state: Dictionary=after.duplicate(true);state[KEY]=ledger
 return {"ok":true,"state":state,"receipt":row.duplicate(true)}

static func evidence(career: Dictionary,identity: Dictionary,candidate_id: String) -> Dictionary:
 if not career.has(KEY):return {"ok":true,"known":false,"sessions":[]}
 if not valid(career[KEY]):return {"ok":false,"known":false,"sessions":[]}
 var rows: Array=[]
 for row in career[KEY].receipts:
  if row.song_id==identity.get("song_id") and row.composition_id==identity.get("composition_id") and row.revision_id==identity.get("revision_id") and row.participants.has(candidate_id):rows.append(row.duplicate(true))
 return {"ok":true,"known":not rows.is_empty(),"sessions":rows}

# These are immutable source facts, not preparation scores or an equivalence
# oracle. Older receipts never acquire a synthetic material snapshot.
static func material_valid(value: Variant) -> bool:
 if not value is Dictionary:return false
 var keys: Array=["lines","refrain_line_id","sections"]
 if value.has("producer_recipe"):keys.append("producer_recipe")
 if not Workbench._keys(value,keys) or not Workbench._material_ok(value):return false
 if not Workbench._keys(value.sections,["verse","chorus"]):return false
 for line in value.lines:
  if not line is Dictionary or not Workbench._keys(line,["id","text"]):return false
 return true

static func source_valid(value: Variant,identity: Dictionary) -> bool:
 return identity_valid(identity) and value is Dictionary and Workbench._keys(value,["version","policy","material"]) and Workbench._whole(value.get("version"),2,2) and value.get("policy")==SOURCE_POLICY and material_valid(value.get("material")) and identity.revision_id==identity.composition_id+":material:"+Workbench._hash(value.material)

static func _source_for(career: Dictionary,identity: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false}
 if not identity_valid(identity) or not career.get("song_catalogue") is Array:return fail
 var matches: Array=[]
 for song in career.song_catalogue:
  if song is Dictionary and song.get("id")==identity.song_id:matches.append(song)
 if matches.size()!=1:return fail
 var song: Dictionary=matches[0]
 var extension: Variant=song.get(Workbench.FRAGMENT_KEY)
 if not Workbench._extension_ok(extension) or not Workbench._identity_ok(identity.song_id,extension) or not extension.get("composition_identity_v1") is Dictionary:return fail
 var saved: Dictionary=extension.composition_identity_v1
 if saved.song_id!=identity.song_id or saved.composition_id!=identity.composition_id or saved.revision_id!=identity.revision_id:return fail
 if extension.has("producer_quality_receipt") and (song.get("quality")!=extension.producer_quality_receipt.final_quality or song.get("id")!=extension.producer_quality_receipt.song_id):return fail
 var value: Dictionary={"version":2,"policy":SOURCE_POLICY,"material":Workbench._material(extension.fragment)}
 return {"ok":true,"value":value} if source_valid(value,identity) else fail

static func _section_fingerprints(material: Dictionary) -> Dictionary:
 if not material_valid(material):return {}
 var sections: Dictionary={}
 for section in ["verse","chorus"]:
  var selected: Dictionary={}
  for line in material.lines:
   if line.id==material.sections[section]:selected=line.duplicate(true)
  # Global recipe controls are NOT independently authored stems/sections.
  # Binding the whole recipe prevents a lyric match claiming musical transfer.
  sections[section]=Workbench._hash({"policy":SOURCE_POLICY,"section":section,"line":selected,"refrain":selected.get("id")==material.refrain_line_id,"producer_recipe":material.get("producer_recipe",{"absent":true})})
 return sections

static func section_evidence(opening: Dictionary,reference: Dictionary,candidate_id: String) -> Dictionary:
 var selected: Dictionary=target(opening,reference)
 if not selected.ok:return {"ok":false,"sections":{}}
 var source: Dictionary=_source_for(opening.game.career,selected.identity)
 if not source.ok:return {"ok":false,"sections":{}}
 return _project_sections(opening.game.career,selected.identity,source.value.material,candidate_id)

static func _project_sections(career: Dictionary,identity: Dictionary,material: Dictionary,candidate_id: String) -> Dictionary:
 # Projection is intentionally pure. Controlled future-material tests do not
 # constitute a supported finished-song rewrite or invent saved history.
 var fail: Dictionary={"ok":false,"sections":{}}
 if not candidate_valid(candidate_id) or not source_valid({"version":2,"policy":SOURCE_POLICY,"material":material},identity):return fail
 var raw: Variant=career.get(KEY,{"policy":POLICY,"receipts":[]})
 if not valid(raw):return fail
 var current: Dictionary=_section_fingerprints(material)
 var answer: Dictionary={"ok":true,"policy":SOURCE_POLICY,"scope":"source_material_only","identity":identity.duplicate(true),"candidate_id":candidate_id,"sections":{}}
 for section in ["verse","chorus"]:
  var exact: Array=[];var retained: Array=[]
  for row in raw.receipts:
   if row.song_id!=identity.song_id or row.composition_id!=identity.composition_id or not row.participants.has(candidate_id):continue
   if row.revision_id==identity.revision_id:exact.append(row.action_id)
   elif row.has(SOURCE_KEY) and _section_fingerprints(row[SOURCE_KEY].material).get(section)==current[section]:retained.append(row.action_id)
  answer.sections[section]={"status":"exact" if not exact.is_empty() else ("retained" if not retained.is_empty() else "untracked"),"exact_actions":exact,"retained_actions":retained}
 return answer
