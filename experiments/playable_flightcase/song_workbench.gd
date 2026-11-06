extends RefCounted
## Optional lyric metadata. Original Workshop/Practice remain the sole musical model.
const Social = preload("res://experiments/playable_flightcase/producer_social.gd")
const Sound = preload("res://experiments/playable_flightcase/band_sound.gd")
const Producer = preload("res://experiments/playable_flightcase/producer_recipe.gd")
const Content = preload("res://experiments/playable_flightcase/song_fragment_content.gd")
const Canon = preload("res://experiments/playable_flightcase/audition_encounter.gd")
const Workshop = preload("res://Scripts/song_workshop.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Radio = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Situation = preload("res://experiments/playable_flightcase/situation_core.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const KEY := "song_workbench_v1"
const FRAGMENT_KEY := "creative_fragment_v1"
const POLICY := "s84_literal_workbench_v1"
const LIMIT := 1000000000

static func _whole(value: Variant, minimum: int=0, maximum: int=LIMIT) -> bool:
 return Canon._whole(value,minimum,maximum)

static func _hash(value: Variant) -> String:
 var canonical: Variant=Canon._canon(value)
 return "" if canonical==null else JSON.stringify(canonical).sha256_text()

static func _same(first: Variant,second: Variant) -> bool:
 return Canon._same(first,second)

static func _typed(value: Variant) -> Variant:
 if value is Dictionary:
  var keys: Array=value.keys();keys.sort()
  var rows: Array=[]
  for key in keys:rows.append([key,_typed(value[key])])
  return [TYPE_DICTIONARY,rows]
 if value is Array:
  var rows: Array=[]
  for item in value:rows.append(_typed(item))
  return [TYPE_ARRAY,rows]
 return [typeof(value),var_to_bytes(value).hex_encode()]

static func _exact(first: Variant,second: Variant) -> bool:
 return _typed(first)==_typed(second)

static func _keys(value: Dictionary,keys: Array) -> bool:
 if value.size()!=keys.size():return false
 for key in keys:
  if not value.has(key):return false
 return true

static func _career(opening: Dictionary) -> Dictionary:
 if not opening.get("game") is Dictionary or not opening.game.get("career") is Dictionary:return {}
 return opening.game.career

static func preplay_held(opening: Dictionary) -> bool:
 return _career(opening).has(KEY) and opening.get("screen")!="play"

static func _source_hash(opening: Dictionary) -> String:
 var source:=opening.duplicate(true)
 if source.get("game") is Dictionary and source.game.get("career") is Dictionary:source.game.career.erase(KEY)
 return _hash(source)

static func _game_hash(game: Dictionary) -> String:
 var source: Dictionary={}
 for field in ["schema_version","genre","roster","phase","career"]:
  if not game.has(field):return ""
  source[field]=game[field].duplicate(true) if game[field] is Dictionary or game[field] is Array else game[field]
 if not source.career is Dictionary:return ""
 source.career.erase(KEY)
 return _hash(source)

static func _source_ok(opening: Dictionary) -> bool:
 if opening.get("screen")!="play" or not opening.get("game") is Dictionary or opening.game.get("phase")!="play":return false
 var state:=_career(opening)
 if _source_hash(opening).is_empty() or not state.get("members") is Array or not state.get("song_catalogue") is Array or not state.get("current_song_draft") is Dictionary:return false
 if not _whole(state.get("tour_day"),1) or not _whole(state.get("cash")) or not _whole(state.get("songs")) or not _whole(state.get("song_draft_progress"),0,2):return false
 if state.members.size()>6:return false
 # Only known fields consumed by the original writing pipeline are checked;
 # unrelated/unknown career extensions are not parsed or replaced.
 for field in ["readiness","morale","tension","buzz","press"]:
  if state.has(field) and not _whole(state[field],0,100):return false
 for field in ["gear","fans"]:
  if state.has(field) and not _whole(state[field],0,100000):return false
 if state.has("action_count") and not _whole(state.action_count,0,LIMIT-1):return false
 for field in ["action_counters","band_work_counters","relationships","opportunities_seen"]:
  if state.has(field) and not state[field] is Dictionary:return false
 for field in ["rest","song_draft","songwrite"]:
  if state.get("action_counters",{}).has(field) and not _whole(state.action_counters[field],0,LIMIT-1):return false
 if state.get("band_work_counters",{}).has("songwrite") and not _whole(state.band_work_counters.songwrite,0,LIMIT-1):return false
 if state.has("career_journal") and not state.career_journal is Array:return false
 for a in range(state.members.size()):
  for b in range(a+1,state.members.size()):
   var key: String="%d_%d" % [a,b]
   if state.get("relationships",{}).has(key) and not _whole(state.relationships[key],0,100):return false
 for person in state.members:
  if not person is Dictionary:return false
  for field in ["skill","loyalty","morale","fatigue"]:
   if person.has(field) and not _whole(person[field],0,100):return false
  if person.has("rehearsal_risk"):
   if not person.rehearsal_risk is Dictionary:return false
   if person.rehearsal_risk.has("creative_friction") and not _whole(person.rehearsal_risk.creative_friction,0,LIMIT-1):return false
 for row in state.song_catalogue:
  if not row is Dictionary:return false
 if not state.current_song_draft.get("sessions",[]) is Array:return false
 return true

static func _empty() -> Dictionary:
 return {"version":1,"sequence":0,"revision":0,"project":{},"last_result":{}}

static func _wrapper(opening: Dictionary) -> Dictionary:
 var raw: Variant=_career(opening).get(KEY)
 return raw.duplicate(true) if raw is Dictionary else _empty()

static func _material(fragment: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for field in ["lines","refrain_line_id","sections","producer_recipe"]:
  if fragment.has(field):result[field]=fragment[field].duplicate(true) if fragment[field] is Array or fragment[field] is Dictionary else fragment[field]
 return result

static func _material_ok(value: Variant) -> bool:
 if value is Dictionary and value.has("producer_recipe") and not Producer.material_matches(value):return false
 if not value is Dictionary or not value.get("lines") is Array or value.lines.size()!=2 or value.get("refrain_line_id") not in ["hook:1","hook:2"] or not value.get("sections") is Dictionary:return false
 for index in range(2):
  var row: Variant=value.lines[index]
  if not row is Dictionary or row.get("id")!="hook:%d" % (index+1) or not row.get("text") is String:return false
  var text: String=row.text
  if text.strip_edges().is_empty() or text.length()>96:return false
  for number in range(text.length()):
   if text.unicode_at(number)<32 or text.unicode_at(number)==127:return false
 return value.sections.get("chorus")==value.refrain_line_id and value.sections.get("verse")==("hook:2" if value.refrain_line_id=="hook:1" else "hook:1") and not _hash(value).is_empty()

static func _fragment_ok(value: Variant,project_id: String) -> bool:
 return value is Dictionary and _material_ok(value) and _whole(value.get("revision"),1) and value.get("fragment_id")=="%s:f:%d" % [project_id,int(value.revision)] and value.get("source_kind") in ["seed","alternate","player","producer"] and (value.get("source_kind")=="producer")==value.has("producer_recipe")

static func _merge_material(old: Dictionary,current: Dictionary) -> Dictionary:
 var merged:=old.duplicate(true)
 merged.merge(current,true)
 var lines: Array=[]
 for index in range(2):
  var row: Dictionary=old.lines[index].duplicate(true)
  row.merge(current.lines[index],true)
  lines.append(row)
 merged.lines=lines
 var sections: Dictionary=old.sections.duplicate(true)
 sections.merge(current.sections,true)
 merged.sections=sections
 return merged

static func _merge_target(old: Dictionary,current: Dictionary) -> Dictionary:
 var merged:=old.duplicate(true)
 merged.merge(current,true)
 for field in ["leader_ref","respondent_ref"]:
  var ref: Dictionary=old.get(field,{}).duplicate(true)
  ref.merge(current.get(field,{}),true)
  merged[field]=ref if not current.get(field,{}).is_empty() else {}
 return merged

static func _target_same(first: Dictionary,second: Dictionary) -> bool:
 if first.get("title")!=second.get("title"):return false
 for field in ["leader_ref","respondent_ref"]:
  var a: Dictionary=first.get(field,{})
  var b: Dictionary=second.get(field,{})
  if a.is_empty()!=b.is_empty():return false
  for key in ["slot","member_id","candidate_id","name","role","bio_sha256"]:
   if not _same(a.get(key),b.get(key)):return false
 return true

static func _ref_ok(value: Variant,allow_empty: bool=false) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return allow_empty
 if not _whole(value.get("slot"),0,5):return false
 for field in ["candidate_id","name","role","bio_sha256"]:
  if not value.get(field) is String:return false
 return value.has("member_id") and not _hash(value).is_empty()

static func _trial_number(id: Variant,project_id: String) -> int:
 if not id is String or not str(id).begins_with(project_id+":trial:"):return -1
 var suffix: String=str(id).trim_prefix(project_id+":trial:")
 if not suffix.is_valid_int():return -1
 var number: int=int(suffix)
 return number if number>=1 and number<LIMIT and id=="%s:trial:%d" % [project_id,number] else -1

static func _request_ok(request: Dictionary) -> bool:
 if request.is_empty():return true
 if not request.get("kind") is String:return false
 if request.get("kind")=="raw_change":return Producer.request_ok(request)
 if request.get("kind")=="refrain":return _keys(request,["kind","line_id"]) and request.line_id in ["hook:1","hook:2"]
 if request.get("kind")!="keep_line" or not _keys(request,["kind","line_id","text"]) or request.line_id not in ["hook:1","hook:2"] or not request.text is String:return false
 var text: String=request.text
 if text.strip_edges().is_empty() or text.length()>96:return false
 for index in range(text.length()):
  if text.unicode_at(index)<32 or text.unicode_at(index)==127:return false
 return true

static func _trial_ok(value: Variant,project_id: String) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return true
 if _trial_number(value.get("id"),project_id)<1 or not _whole(value.get("stage"),0,2) or not _material_ok(value.get("fragment_snapshot")):return false
 if not value.get("target") is Dictionary or not value.target.get("title") is String or not _ref_ok(value.target.get("leader_ref")) or not _ref_ok(value.target.get("respondent_ref"),true):return false
 if not value.get("immutable_context") is Dictionary or not _whole(value.immutable_context.get("day"),1) or not value.get("note") is Dictionary:return false
 if value.fragment_snapshot.has("producer_recipe"):
  if not _whole(value.get("producer_fragment_revision"),1) or value.get("producer_fragment_id")!="%s:f:%d" % [project_id,int(value.producer_fragment_revision)]:return false
 var note: Dictionary=value.note
 if value.fragment_snapshot.has("producer_recipe") and not value.target.respondent_ref.is_empty():
  if not note.get("request") is Dictionary or not Producer.request_ok(note.request) or not _same(note.request,Producer.offer(note.request.recipe,value.target.respondent_ref)):return false
 if value.fragment_snapshot.has("producer_recipe") and not note.get("request") is Dictionary:return false
 return note.get("text") is String and str(note.text).length()<=1024 and note.get("delivery")=="written_note" and note.get("source_kind") in ["literal","authored"] and note.get("content_version") is String and not str(note.content_version).is_empty() and note.get("request") is Dictionary and _request_ok(note.request) and _ref_ok(note.get("respondent_ref"),true) and _same(note.respondent_ref,value.target.respondent_ref) and _whole(note.get("day"),1) and int(note.day)==int(value.immutable_context.day) and not _hash(value).is_empty()

static func _paid_ok(value: Variant) -> bool:
 if not value is Array or value.size()>3:return false
 for index in range(value.size()):
  var row: Variant=value[index]
  if not row is Dictionary or row.get("stage")!=index or not _whole(row.get("day_before"),1) or not _whole(row.get("day_after"),2) or int(row.day_after)!=int(row.day_before)+1:return false
  if not _whole(row.get("cash_before")) or not _whole(row.get("cash_after")) or not _material_ok(row.get("fragment_snapshot")) or not row.get("trial_id") is String:return false
 return not _hash(value).is_empty()

static func _closed_project_ok(value: Variant,id: String,paid_count: int) -> bool:
 if not value is Dictionary or value.get("id")!=id or not value.get("binding") is Dictionary or not value.get("target") is Dictionary:return false
 if not _whole(value.binding.get("progress"),0,2) or not _whole(value.binding.get("original_song_sequence")) or not value.binding.get("canonical_draft") is Dictionary or value.binding.get("canonical_draft_fingerprint")!=_hash(value.binding.canonical_draft):return false
 if not _decision_ok(value):return false
 if not _fragment_ok(value.get("fragment"),id) or not value.get("prior_fragment") is Dictionary or not _material_ok(value.get("authored_alternate")) or not _trial_ok(value.get("last_trial"),id):return false
 if not value.prior_fragment.is_empty() and not _fragment_ok(value.prior_fragment,id):return false
 if not _paid_ok(value.get("paid_receipts")) or value.paid_receipts.size()!=paid_count or not value.get("feedback_history") is Array or value.feedback_history.size()>3:return false
 for trial in value.feedback_history:
  if not _trial_ok(trial,id) or trial.is_empty():return false
 return value.target.get("title") is String and _ref_ok(value.target.get("leader_ref")) and _ref_ok(value.target.get("respondent_ref"),true) and not _hash(value).is_empty()

static func _producer_final_trial_ok(project: Dictionary,fragment: Dictionary,paid: Array) -> bool:
 if paid.size()!=3 or not project.get("last_trial") is Dictionary:return false
 var trial: Dictionary=project.last_trial
 return _same(trial.get("fragment_snapshot"),_material(fragment)) and trial.get("producer_fragment_id")==fragment.fragment_id and trial.get("producer_fragment_revision")==fragment.revision and paid.back().get("trial_id")==trial.get("id") and _same(trial.get("target"),project.get("target")) and _same(paid.back().get("target"),project.get("target"))

static func _closed_ok(value: Variant,sequence: int) -> bool:
 if not value is Dictionary:return false
 if value.is_empty():return true
 if not value.get("id") is String or not str(value.id).begins_with("workbench:") or value.get("result") not in ["archived","finished"] or not _whole(value.get("sequence"),1,sequence):return false
 if value.id!="workbench:%d" % int(value.sequence) or not _fragment_ok(value.get("fragment"),value.id) or not _paid_ok(value.get("paid_receipts")):return false
 if value.result=="archived" and value.get("reason") not in ["user_archive","switch_route","source_review"]:return false
 if value.result=="finished" and value.paid_receipts.size()!=3:return false
 if value.fragment.has("producer_recipe") and not value.get("project_snapshot") is Dictionary:return false
 if value.fragment.has("producer_recipe") and (not _same(value.fragment,value.get("project_snapshot",{}).get("fragment")) or not _same(value.paid_receipts,value.get("project_snapshot",{}).get("paid_receipts"))):return false
 if not _closed_project_ok(value.get("project_snapshot"),value.id,value.paid_receipts.size()):return false
 if value.result=="finished" and value.fragment.has("producer_recipe") and (not _same(_material(value.fragment),value.paid_receipts.back().fragment_snapshot) or not _producer_final_trial_ok(value.project_snapshot,value.fragment,value.paid_receipts)):return false
 return not _hash(value).is_empty()

static func validate(opening: Dictionary) -> Dictionary:
 var state:=_career(opening)
 var exists: bool=state.has(KEY)
 var fail: Dictionary={"ok":false,"exists":exists,"active":false,"held":true,"message":"This saved lyric sketch needs compatible review. Its words and source are retained."}
 if preplay_held(opening):return fail
 if not _source_ok(opening):return fail
 if not exists:return {"ok":true,"exists":false,"active":false,"held":false,"message":""}
 var raw: Variant=state[KEY]
 if not raw is Dictionary or not _whole(raw.get("version"),1,1) or not _whole(raw.get("sequence")) or not _whole(raw.get("revision")) or not raw.get("project") is Dictionary or not _closed_ok(raw.get("last_result"),int(raw.sequence)):return fail
 if raw.project.is_empty():return {"ok":true,"exists":true,"active":false,"held":false,"message":""}
 var project: Dictionary=raw.project
 if project.get("fragment") is Dictionary and project.fragment.has("producer_recipe") and not Producer.skills_ok(state):return fail
 if not _whole(project.get("sequence"),1,int(raw.sequence)) or project.get("id")!="workbench:%d" % int(project.sequence) or project.get("content_version")!=Content.VERSION or project.get("policy_version")!=POLICY:return fail
 if project.get("phase") not in ["seed","trial","revision","between_sessions"] or not project.get("binding") is Dictionary or not project.get("target") is Dictionary:return fail
 if not _decision_ok(project):return fail
 var binding: Dictionary=project.binding
 if not _whole(binding.get("progress"),0,2) or not _whole(binding.get("original_song_sequence")) or not binding.get("canonical_draft") is Dictionary or binding.get("canonical_draft_fingerprint")!=_hash(binding.canonical_draft):return fail
 if not project.target.get("title") is String or not _ref_ok(project.target.get("leader_ref")) or not _ref_ok(project.target.get("respondent_ref"),true):return fail
 if not _fragment_ok(project.get("fragment"),project.id) or not project.get("prior_fragment") is Dictionary or not _material_ok(project.get("authored_alternate")) or not _trial_ok(project.get("last_trial"),project.id) or not _paid_ok(project.get("paid_receipts")):return fail
 if not project.prior_fragment.is_empty() and not _fragment_ok(project.prior_fragment,project.id):return fail
 if not project.get("feedback_history") is Array or project.feedback_history.size()>3:return fail
 for trial in project.feedback_history:
  if not _trial_ok(trial,project.id) or trial.is_empty() or _trial_number(trial.id,project.id)>int(raw.revision):return fail
 if not project.last_trial.is_empty() and _trial_number(project.last_trial.id,project.id)>int(raw.revision):return fail
 if project.paid_receipts.size()!=int(binding.progress):return fail
 return {"ok":true,"exists":true,"active":true,"held":false,"message":""}

static func expected(opening: Dictionary) -> Dictionary:
 var source_hash:=_source_hash(opening)
 if source_hash.is_empty():return {}
 var raw:=_wrapper(opening)
 var project: Dictionary=raw.get("project",{}) if raw.get("project") is Dictionary else {}
 var fragment: Dictionary=project.get("fragment",{}) if project.get("fragment") is Dictionary else {}
 return {"source_hash":source_hash,"wrapper_hash":_hash(_career(opening).get(KEY,{"absent":true})),"project_id":str(project.get("id","")),"wrapper_revision":int(raw.get("revision",0)) if _whole(raw.get("revision")) else -1,"fragment_revision":int(fragment.get("revision",0)) if _whole(fragment.get("revision",0)) else -1,"stage":int(_career(opening).get("song_draft_progress",0)) if _whole(_career(opening).get("song_draft_progress",0),0,2) else -1}

static func _token(opening: Dictionary,token: Dictionary) -> bool:
 return _keys(token,["source_hash","wrapper_hash","project_id","wrapper_revision","fragment_revision","stage"]) and not expected(opening).is_empty() and _same(token,expected(opening))

static func _ref(state: Dictionary,index: int) -> Dictionary:
 var person: Dictionary=state.members[index]
 var candidate: String=str(person.get("candidate_id","")) if person.get("candidate_id","") is String else ""
 var source: Dictionary={}
 if not candidate.is_empty():
  for row in Cast.combined_people():
   if str(row.get("id",""))==candidate:source=row;break
 return {"slot":index,"member_id":person.get("id",null),"candidate_id":candidate,"name":str(person.get("name","Musician")),"role":str(person.get("role","")),"bio_sha256":_hash(source) if not source.is_empty() else ""}

static func _target(state: Dictionary,title: String,index: int) -> Dictionary:
 var preview: Dictionary=Workshop.develop(state,"Lyric","Verse / Chorus",title,index)
 if not preview.get("ok",false):return {"ok":false,"message":str(preview.get("message","Choose the current title and leader."))}
 var respondent: Dictionary={}
 for slot in range(state.members.size()):
  if slot!=index and state.members[slot].get("life_status","active")=="active":respondent=_ref(state,slot);break
 return {"ok":true,"target":{"title":title.strip_edges().to_upper(),"leader_ref":_ref(state,index),"respondent_ref":respondent}}

static func _binding(state: Dictionary) -> Dictionary:
 return {"progress":int(state.song_draft_progress),"canonical_draft":state.current_song_draft.duplicate(true),"canonical_draft_fingerprint":_hash(state.current_song_draft),"original_song_sequence":int(state.songs)}

static func _binding_ok(state: Dictionary,project: Dictionary) -> bool:
 var actual:=_binding(state)
 for field in actual:
  if not _same(project.binding.get(field),actual[field]):return false
 return true

static func _participants_ok(state: Dictionary,target: Dictionary) -> bool:
 var leader: Dictionary=target.leader_ref
 var index: int=int(leader.slot)
 if index>=state.members.size() or state.members[index].get("life_status","active")!="active":return false
 var current: Dictionary=_ref(state,index)
 for field in ["slot","member_id","candidate_id","name","role","bio_sha256"]:
  if not _same(current.get(field),leader.get(field)):return false
 var live:=_target(state,str(target.title),index)
 return live.get("ok",false) and _target_same(live.target,target)

static func _priority(opening: Dictionary) -> String:
 var state:=_career(opening)
 if not _source_ok(opening) or preplay_held(opening) or Canon.locked(opening):return "review"
 if state.has(Finance.KEY) and not Finance._valid(state[Finance.KEY]):return "review"
 if Finance.is_over(state):return "terminal"
 if Radio.locked(state):return "radio"
 var guard: Dictionary=Booking.guard_commitment(state,"song_workbench",0)
 if not guard.get("ok",false):return "show"
 if state.has("booked_show") and not state.booked_show is Dictionary:return "review"
 var show:=Calendar.pending(state)
 if not show.is_empty():
  if not _whole(show.get("day"),1):return "review"
  if int(show.day)<=int(state.tour_day):return "show"
 var core: Dictionary=Situation.validate(state)
 if not core.get("ok",false):return "review"
 return "workbench"

static func _decision_ok(project: Dictionary) -> bool:
 if not project.has("producer_decision"):return true
 var d: Variant=project.producer_decision
 if not d is Dictionary:return false
 if d.is_empty():return true
 if not d.get("choice") is String or not d.get("offer_id") is String or not (d.get("stage") is int or d.get("stage") is float):return false
 if not _keys(d,["offer_id","stage","member","base_recipe","chosen_recipe","choice"]) or d.choice not in ["keep","try","dismiss"] or not _ref_ok(d.get("member")) or not Producer.valid(d.get("base_recipe")) or not Producer.valid(d.get("chosen_recipe")):return false
 var offer: Dictionary=Producer.offer(d.base_recipe,d.member)
 if offer.is_empty() or d.offer_id!=offer.offer_id or d.stage!=offer.stage:return false
 var chosen: Dictionary=d.base_recipe.duplicate(true)
 if d.choice=="try":chosen[offer.field]=offer.value
 return _same(chosen,d.chosen_recipe)

static func producer_reply_ok(project: Dictionary,stage: int) -> bool:
 if not _decision_ok(project):return false
 var d: Dictionary=project.get("producer_decision",{})
 return not d.is_empty() and int(d.stage)==stage and _same(d.member,project.get("target",{}).get("respondent_ref",{})) and _same(d.chosen_recipe,project.get("fragment",{}).get("producer_recipe",{}))

static func _ready(opening: Dictionary,project: Dictionary,require_reply: bool=true) -> bool:
 var state:=_career(opening)
 var trial: Dictionary=project.last_trial
 if require_reply and project.fragment.has("producer_recipe") and not project.target.respondent_ref.is_empty():
  if not producer_reply_ok(project,int(state.song_draft_progress)):return false
 if project.fragment.has("producer_recipe") and (int(project.fragment.producer_recipe.stage)!=int(state.song_draft_progress) or not _same(project.fragment.producer_recipe.brief,Sound.read(state)) or not Social.valid(state.get(Social.KEY,{"version":1,"members":{}}))):return false
 if project.fragment.has("producer_recipe") and (trial.get("producer_fragment_id")!=project.fragment.fragment_id or trial.get("producer_fragment_revision")!=project.fragment.revision):return false
 return _binding_ok(state,project) and _participants_ok(state,project.target) and not trial.is_empty() and int(trial.stage)==int(state.song_draft_progress) and _same(trial.fragment_snapshot,_material(project.fragment)) and _same(trial.target,project.target)

static func view(opening: Dictionary) -> Dictionary:
 var checked:=validate(opening)
 var project: Dictionary=_wrapper(opening).get("project",{}) if checked.ok else {}
 var priority: String=_priority(opening)
 if checked.ok and checked.active and (not _binding_ok(_career(opening),project) or not _participants_ok(_career(opening),project.target)):checked.held=true;checked.message="The saved draft or people changed. Review the current source or archive the sketch; its words are retained."
 if not checked.ok or checked.held:priority="review" if priority=="workbench" else priority
 return {"ok":checked.ok,"exists":checked.exists,"active":checked.active,"held":checked.held,"message":checked.message,"phase":str(project.get("phase","legacy")),"project":project.duplicate(true),"priority":priority if checked.exists else (priority if priority!="workbench" else "legacy"),"expected":expected(opening),"can_write":checked.ok and checked.active and not checked.held and priority=="workbench" and _ready(opening,project)}

static func _mutation(opening: Dictionary,ok: bool,message: String="",changed: bool=false) -> Dictionary:
 return {"ok":ok,"changed":changed,"state":opening.duplicate(true),"message":message}

static func _put(opening: Dictionary,wrapper: Dictionary,message: String="") -> Dictionary:
 var next:=opening.duplicate(true)
 next.game.career[KEY]=Canon._freeze_candidate(wrapper)
 return _mutation(next,true,message,true)

static func begin(opening: Dictionary,title: String,leader_index: int,token: Dictionary,recipe: Dictionary={}) -> Dictionary:
 var checked:=validate(opening)
 if not checked.ok or checked.active or not _token(opening,token) or _priority(opening)!="workbench":return _mutation(opening,false,"Review the saved career and its current commitments before starting a lyric sketch.")
 var state:=_career(opening)
 if int(state.song_draft_progress)!=0 or not state.current_song_draft.is_empty():return _mutation(opening,false,"This earlier song has no lyric fragment recorded. Finish it through its original session route.")
 if not recipe.is_empty() and (not Producer.valid(recipe) or recipe.get("stage")!=0 or not _same(recipe.get("brief"),Sound.read(state)) or recipe.get("brief",{}).get("genre")!=opening.game.get("genre") or not Social.valid(state.get(Social.KEY,{"version":1,"members":{}})) or (opening.game.get("genre")!="Indie rock" and recipe.get("version") not in [3,4]) or not Producer.skills_ok(state)):return _mutation(opening,false,"This arrangement needs a compatible band and recorded participants.")
 var chosen:=_target(state,title,leader_index)
 if not chosen.ok:return _mutation(opening,false,chosen.message)
 var wrapper:=_wrapper(opening)
 if int(wrapper.sequence)>=LIMIT-1 or int(wrapper.revision)>=LIMIT-1:return _mutation(opening,false,"The sketch history is full; it has been retained.")
 wrapper.sequence=int(wrapper.sequence)+1;wrapper.revision=int(wrapper.revision)+1
 var id: String="workbench:%d" % int(wrapper.sequence)
 var fragment: Dictionary=Content.material().material if recipe.is_empty() else Producer.material(recipe)
 fragment.merge({"revision":1,"fragment_id":id+":f:1","source_kind":"seed" if recipe.is_empty() else "producer"})
 wrapper.project={"id":id,"sequence":int(wrapper.sequence),"content_version":Content.VERSION,"policy_version":POLICY,"binding":_binding(state),"target":chosen.target,"phase":"seed","fragment":fragment,"prior_fragment":{},"authored_alternate":Content.material("alternate").material if recipe.is_empty() else Producer.material(recipe),"last_trial":{},"feedback_history":[],"paid_receipts":[]}
 if not recipe.is_empty():return _put(opening,wrapper,"Your arrangement is saved. Listen and try a direction free; only WRITE uses a day.")
 return _put(opening,wrapper,"The leader's new two-line idea is saved. Try or rewrite the actual words; no day has been used.")

static func _payload_material(payload: Dictionary) -> Dictionary:
 if not _keys(payload,["text","refrain_line_id","title","leader_index"]) or not payload.get("text") is String or not payload.get("title") is String or not _whole(payload.get("leader_index"),0,5):return {}
 var lines: PackedStringArray=str(payload.text).replace("\r\n","\n").split("\n",true)
 if lines.size()!=2:return {}
 var refrain: String=str(payload.get("refrain_line_id",""))
 var result: Dictionary={"lines":[{"id":"hook:1","text":lines[0]},{"id":"hook:2","text":lines[1]}],"refrain_line_id":refrain,"sections":{"verse":"hook:2" if refrain=="hook:1" else "hook:1","chorus":refrain}}
 return result if _material_ok(result) else {}

static func _context(state: Dictionary,target: Dictionary) -> Dictionary:
 var contexts: Dictionary={}
 var core: Dictionary=Situation.validate(state)
 if core.ok:
  for ref in [target.leader_ref,target.respondent_ref]:
   if not ref.is_empty() and not str(ref.candidate_id).is_empty():contexts[ref.candidate_id]=core.core.member_contexts.get(ref.candidate_id,{"kind":"unknown"}).duplicate(true)
 return {"day":int(state.tour_day),"recorded_contexts":contexts,"delivery":"written_note","attendance":"not_recorded"}

static func checkpoint(opening: Dictionary,action: String,token: Dictionary,payload: Dictionary={}) -> Dictionary:
 var checked:=validate(opening)
 if not checked.ok or not checked.active or not _token(opening,token):return _mutation(opening,false,"The saved sketch changed or needs compatible review. Nothing was written.")
 var wrapper:=_wrapper(opening);var project: Dictionary=wrapper.project
 if _priority(opening)!="workbench":return _mutation(opening,false,"The current show, radio or final accounts comes first. The sketch is retained.")
 if int(wrapper.revision)>=LIMIT-1:return _mutation(opening,false,"The bounded sketch history is full.")
 if action=="archive":
  if not _keys(payload,["reason"]) or payload.reason not in ["user_archive","switch_route","source_review"]:return _mutation(opening,false,"Choose why to close this saved sketch.")
  wrapper.last_result={"id":project.id,"sequence":project.sequence,"result":"archived","reason":payload.reason,"fragment":project.fragment.duplicate(true),"paid_receipts":project.paid_receipts.duplicate(true),"project_snapshot":project.duplicate(true)}
  wrapper.project={};wrapper.revision=int(wrapper.revision)+1
  return _put(opening,wrapper,"Sketch archived. The original song and completed days are unchanged.")
 if _priority(opening)!="workbench" or not _binding_ok(_career(opening),project):return _mutation(opening,false,"The current show, radio, final accounts or changed draft needs attention first. The words are retained.")
 var state:=_career(opening)
 var material: Dictionary=_material(project.fragment)
 var target: Dictionary=project.target.duplicate(true)
 var producer: bool=material.has("producer_recipe")
 if producer and action in ["save_sketch","try","use_alternate"]:return _mutation(opening,false,"Use the producer controls for this arrangement; the saved recipe is retained.")
 if action in ["producer_save","producer_try"]:
  if not producer or not _keys(payload,["recipe","title","leader_index"]) or not Producer.valid(payload.get("recipe")) or not payload.get("title") is String or not _whole(payload.get("leader_index"),0,5):return _mutation(opening,false,"Choose a compatible arrangement, title and leader.")
  if int(payload.recipe.stage)!=int(state.song_draft_progress) or not _same(payload.recipe.brief,Sound.read(state)):return _mutation(opening,false,"Develop the current writing stage with the confirmed band sound.")
  if int(state.song_draft_progress)>0:
   var recorded: Dictionary=project.fragment.producer_recipe
   if recorded.version!=payload.recipe.version or recorded.hook!=payload.recipe.hook or recorded.get("voice","off")!=payload.recipe.get("voice","off"):return _mutation(opening,false,"This song's foundation is already recorded. Shape its arrangement, or finish it before starting another original.")
  if not _same(payload.recipe,project.fragment.producer_recipe):project.producer_decision={}
  material=_merge_material(material,Producer.material(payload.recipe))
  var chosen:=_target(state,payload.title,int(payload.leader_index))
  if not chosen.ok:return _mutation(opening,false,chosen.message)
  target=_merge_target(target,chosen.target)
 elif action=="producer_offer":
  if not producer or not _keys(payload,["choice","offer_id"]) or payload.get("choice") not in ["keep","try","dismiss"] or not _ready(opening,project,false):return _mutation(opening,false,"Try the current saved take before considering this idea.")
  var base: Dictionary=project.fragment.producer_recipe.duplicate(true)
  var offer: Dictionary=Producer.offer(base,target.respondent_ref)
  if offer.is_empty() or payload.get("offer_id")!=offer.offer_id:return _mutation(opening,false,"This bandmate idea changed. Review the current note.")
  var chosen: Dictionary=base.duplicate(true)
  if payload.choice=="try":chosen[offer.field]=offer.value
  project.producer_decision={"offer_id":offer.offer_id,"stage":int(base.stage),"member":target.respondent_ref.duplicate(true),"base_recipe":base,"chosen_recipe":chosen.duplicate(true),"choice":payload.choice}
  material=_merge_material(material,Producer.material(chosen))
 elif action in ["save_sketch","try"]:
  var parsed:=_payload_material(payload)
  if parsed.is_empty():return _mutation(opening,false,"Use two nonblank lines, up to 96 characters each, and choose the refrain, title and leader.")
  material=_merge_material(material,parsed)
  var chosen:=_target(state,payload.title,int(payload.leader_index))
  if not chosen.ok:return _mutation(opening,false,chosen.message)
  target=_merge_target(target,chosen.target)
 elif action=="review_participants":
  if not _keys(payload,["title","leader_index"]) or not payload.get("title") is String or not _whole(payload.get("leader_index"),0,5):return _mutation(opening,false,"Review the actual title and leader.")
  var chosen:=_target(state,payload.title,int(payload.leader_index))
  if not chosen.ok:return _mutation(opening,false,chosen.message)
  target=_merge_target(target,chosen.target)
 elif action=="use_alternate":
  if not _keys(payload,["kind"]) or payload.kind not in ["seed","alternate"]:return _mutation(opening,false,"Choose one recorded take.")
  if not _participants_ok(state,target):return _mutation(opening,false,"Review the actual people before changing this sketch.")
  material=_merge_material(material,Content.material(payload.kind).material)
 else:return _mutation(opening,false,"That lyric action is unavailable.")
 var material_changed: bool=not _same(material,_material(project.fragment))
 var target_changed: bool=not _same(target,project.target)
 if producer and target_changed and not _same(project.get("producer_decision",{}).get("member",{}),target.respondent_ref):project.producer_decision={}
 var identical_trial: bool=not project.last_trial.is_empty() and project.last_trial.stage==state.song_draft_progress and _same(project.last_trial.fragment_snapshot,material) and _same(project.last_trial.target,target)
 if producer and project.last_trial.get("producer_fragment_id")!=project.fragment.fragment_id:identical_trial=false
 if not material_changed and not target_changed and (action not in ["try","producer_try","producer_offer"] or (identical_trial and action!="producer_offer")):return _mutation(opening,true,"The same saved take and note are retained.")
 if int(wrapper.revision)>=LIMIT-1 or int(project.fragment.revision)>=LIMIT-1:return _mutation(opening,false,"The bounded sketch history is full.")
 if material_changed:
  project.prior_fragment=project.fragment.duplicate(true)
  project.fragment.merge(material,true)
  project.fragment.revision=int(project.fragment.revision)+1
  project.fragment.fragment_id="%s:f:%d" % [project.id,int(project.fragment.revision)]
  project.fragment.source_kind="producer" if producer else ("seed" if material==Content.material().material else ("alternate" if material==Content.material("alternate").material else "player"))
 project.target=target
 project.phase="revision" if material_changed or target_changed else project.phase
 wrapper.revision=int(wrapper.revision)+1
 if action in ["try","producer_try","producer_offer"]:
  var context:=_context(state,target)
  var response: Dictionary=Producer.note(target.respondent_ref,material.producer_recipe,context) if producer else Content.note(target.respondent_ref,material,project.last_trial,context)
  if not response.ok:return _mutation(opening,false,response.message)
  if producer and action=="producer_offer":
   response.note.request=Producer.offer(project.producer_decision.base_recipe,target.respondent_ref)
   response.note.text="You tried their proposed change; the original take is retained for comparison." if payload.choice=="try" else ("You considered the written change and kept your direction." if payload.choice=="keep" else "You chose to leave this idea unanswered for this writing session.")

  var trial: Dictionary={"id":"%s:trial:%d" % [project.id,int(wrapper.revision)],"stage":int(state.song_draft_progress),"fragment_snapshot":material.duplicate(true),"target":target.duplicate(true),"immutable_context":context,"note":response.note}
  if producer:
   trial.producer_fragment_id=project.fragment.fragment_id
   trial.producer_fragment_revision=project.fragment.revision
  project.last_trial=trial
  project.feedback_history.append(trial.duplicate(true))
  while project.feedback_history.size()>3:project.feedback_history.pop_front()
  project.phase="trial"
 wrapper.project=project
 return _put(opening,wrapper,"The written take and note are saved; no day or room fee was used." if action in ["try","producer_try"] else "Sketch saved. Try this exact take before using the next session day.")

static func prepare_mixing_local(opening: Dictionary,token: Dictionary,payload: Dictionary) -> Dictionary:
 # Pure in-memory preparation. The original owner keeps its PRE-click rollback
 # snapshot and makes only its existing final paid save. HEAR never calls this.
 var fail: Dictionary={"ok":false,"message":"Review this exact direction and bandmate response before committing.","state":opening,"prepared":{}}
 var Mixing=preload("res://experiments/playable_flightcase/mixing_recipe.gd")
 if not _token(opening,token) or not _keys(payload,["recipe","title","leader_index","decision"]) or not Mixing.valid(payload.get("recipe")) or not payload.get("title") is String or not _whole(payload.get("leader_index"),0,5) or not payload.get("decision") is Dictionary:return fail
 var project: Dictionary=_wrapper(opening).get("project",{})
 if not Mixing.valid(project.get("fragment",{}).get("producer_recipe")):return fail
 var decision: Dictionary=payload.decision
 if not _keys(decision,["choice","base_recipe","offer_id"]) or not decision.get("choice") is String or decision.choice not in ["try","keep","dismiss","none"] or not Mixing.valid(decision.get("base_recipe")) or not decision.get("offer_id") is String:return fail
 var staged: Dictionary=checkpoint(opening,"producer_try",token,{"recipe":decision.base_recipe,"title":payload.title,"leader_index":payload.leader_index})
 if not staged.get("ok",false):fail.message=staged.get("message",fail.message);return fail
 var next: Dictionary=staged.state
 var trial: Dictionary=_wrapper(next).project.last_trial
 if trial.target.respondent_ref.is_empty():
  if decision.choice!="none" or not decision.offer_id.is_empty():return fail
 else:
  if decision.choice=="none":return fail
  var request: Dictionary=trial.note.request
  if not Mixing.request_ok(request) or decision.offer_id!=request.offer_id:return fail
  var response: Dictionary=checkpoint(next,"producer_offer",expected(next),{"choice":decision.choice,"offer_id":decision.offer_id})
  if not response.get("ok",false):fail.message=response.get("message",fail.message);return fail
  next=response.state
 if not _same(_wrapper(next).project.fragment.producer_recipe,payload.recipe):return fail
 var before_outer: Dictionary=opening.duplicate(true)
 var next_outer: Dictionary=next.duplicate(true)
 before_outer.game.career.erase(KEY);next_outer.game.career.erase(KEY)
 if not _exact(before_outer,next_outer):return fail
 var prepared: Dictionary=prepare_paid(next,expected(next))
 if not prepared.get("ok",false):fail.message=prepared.get("message",fail.message);return fail
 return {"ok":true,"message":"","state":next,"prepared":prepared.prepared}

static func prepare_paid(opening: Dictionary,token: Dictionary) -> Dictionary:
 var failure: Dictionary={"ok":false,"message":"Try the exact current saved words, title and leader before writing this session.","prepared":{}}
 var checked:=validate(opening)
 if not checked.ok or not checked.active or not _token(opening,token) or _priority(opening)!="workbench":return failure
 var project: Dictionary=_wrapper(opening).project
 if not _ready(opening,project):return failure
 var prepared: Dictionary={"version":1,"project_id":project.id,"wrapper_revision":int(_wrapper(opening).revision),"fragment_id":project.fragment.fragment_id,"fragment_revision":int(project.fragment.revision),"stage":int(_career(opening).song_draft_progress),"source_hash":_source_hash(opening),"wrapper_hash":_hash(_career(opening)[KEY]),"game_hash":_game_hash(opening.game),"trial_hash":_hash(project.last_trial),"args":{"idea":"Lyric","form":"Verse / Chorus","title":project.target.title,"leader_index":int(project.target.leader_ref.slot)},"material":_material(project.fragment)}
 return {"ok":true,"message":"","prepared":prepared}

static func guard_write(game_snapshot: Dictionary,idea: String,form: String,title: String,leader_index: int,prepared: Dictionary={}) -> Dictionary:
 var state: Dictionary=game_snapshot.get("career",{}) if game_snapshot.get("career") is Dictionary else {}
 if not state.has(KEY):return {"ok":prepared.is_empty(),"message":"No saved sketch authorises this prepared session." if not prepared.is_empty() else ""}
 var opening: Dictionary={"screen":"play","game":game_snapshot}
 var checked:=validate(opening)
 if not checked.ok:return {"ok":false,"message":"This saved lyric sketch is held for review."}
 if not checked.active:return {"ok":prepared.is_empty(),"message":"No active sketch authorises a prepared session." if not prepared.is_empty() else ""}
 var project: Dictionary=state[KEY].project
 if not _keys(prepared,["version","project_id","wrapper_revision","fragment_id","fragment_revision","stage","source_hash","wrapper_hash","game_hash","trial_hash","args","material"]):return {"ok":false,"message":"Use the saved lyric workbench to write this session."}
 if not prepared.get("source_hash") is String or str(prepared.source_hash).length()!=64 or not str(prepared.source_hash).is_valid_hex_number(false):return {"ok":false,"message":"The saved owner pin is not readable."}
 var exact: Dictionary=prepare_paid(opening,expected(opening)).prepared
 if exact.is_empty():return {"ok":false,"message":"Try the current saved take before writing."}
 exact.source_hash=prepared.source_hash
 var ok: bool=not exact.is_empty() and _same(prepared,exact) and not str(prepared.source_hash).is_empty() and prepared.args=={"idea":idea,"form":form,"title":title,"leader_index":leader_index}
 return {"ok":ok,"message":"" if ok else "The saved lyric take or session setup changed. Review it before writing."}

static func complete_original(before: Dictionary,after_original: Dictionary,prepared: Dictionary,original_result: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"message":"The original writing result did not match this saved take. Nothing was saved.","completion":{}}
 var planned:=prepare_paid(before,expected(before))
 if not planned.ok or not _same(planned.prepared,prepared) or not original_result.get("ok",false):return fail
 if not after_original.get("game") is Dictionary or not after_original.game.get("career") is Dictionary or not _exact(original_result.get("state"),after_original.game.career):return fail
 var old:=_career(before);var next:=_career(after_original)
 var outer_before:=before.duplicate(true);outer_before.game.erase("career")
 var outer_after:=after_original.duplicate(true);outer_after.game.erase("career")
 if not _exact(outer_before,outer_after) or not _whole(next.get("tour_day"),1) or int(next.tour_day)!=int(old.tour_day)+1 or not _whole(next.get("song_draft_progress"),0,2):return fail
 var stage: int=int(old.song_draft_progress)
 if int(next.song_draft_progress)!=(stage+1)%3 or next.get(KEY)!=old.get(KEY) or not next.get("song_catalogue") is Array:return fail
 var index: int=-1
 if stage<2:
  if not _exact(next.song_catalogue,old.song_catalogue) or not _exact(next.get("songs"),old.get("songs")):return fail
 else:
  if not _whole(next.get("songs"),1) or int(next.songs)!=int(old.songs)+1:return fail
  var trim: int=maxi(0,old.song_catalogue.size()+1-60)
  var retained: Array=old.song_catalogue.slice(trim)
  index=retained.size()
  if next.song_catalogue.size()!=index+1 or next.song_catalogue.size()>60 or not _exact(next.song_catalogue.slice(0,index),retained):return fail
  if not next.song_catalogue[index] is Dictionary or next.song_catalogue[index].get("id")!="original:%d" % maxi(1,int(next.songs)):return fail
  if next.song_catalogue[index].has(FRAGMENT_KEY):return fail
 var rebound: Dictionary=_wrapper(before).project.binding.duplicate(true)
 rebound.merge(_binding(next),true)
 return {"ok":true,"message":"","completion":{"project_id":prepared.project_id,"stage":stage,"prepared_hash":_hash(prepared),"catalogue":next.song_catalogue.duplicate(true),"catalogue_hash":_hash(next.song_catalogue),"appended_index":index,"new_id":str(next.song_catalogue[index].get("id","")) if index>=0 else "","songs":int(next.songs),"binding":rebound,"original_result_hash":_hash(original_result)}}

static func _producer_receipt_ok(extension: Dictionary) -> bool:
 if not extension.fragment.has("producer_recipe"):return not extension.has("producer_quality_receipt")
 var r=extension.get("producer_quality_receipt")
 if not r is Dictionary or not _keys(r,["model","recipe_sha256","song_id","base_quality","delta","final_quality","context","reason"]):return false
 if not r.get("model") is String or not r.get("recipe_sha256") is String:return false
 if r.recipe_sha256!=_hash(extension.fragment.producer_recipe) or not r.song_id is String or not r.reason is String:return false
 if extension.fragment.producer_recipe.get("version") in [3,4]:return preload("res://experiments/playable_flightcase/mixing_recipe.gd").receipt_ok(r,extension.fragment.producer_recipe)
 if r.model!="producer_raw_craft_v2":return false
 if not _whole(r.base_quality,0,100) or not _whole(r.final_quality,1,100) or not (r.delta is int or r.delta is float) or not is_finite(float(r.delta)) or float(r.delta)!=floor(float(r.delta)) or int(r.delta)<-3 or int(r.delta)>3:return false
 var c=r.context
 if not c is Dictionary or not _keys(c,["active_skill_sum","active_count","capacity","demand"]) or not _whole(c.active_count,1,6) or not _whole(c.active_skill_sum,0,int(c.active_count)*100) or not _whole(c.capacity,1,4) or not _whole(c.demand,1,4):return false
 var mean: float=float(c.active_skill_sum)/int(c.active_count)
 var capacity: int=1+int(mean>=35)+int(mean>=55)+int(mean>=75)
 var recipe: Dictionary=extension.fragment.producer_recipe
 var id:=Producer.index(recipe)
 var demand: int=1+Producer.VALUES[0].find(recipe.pace)+Producer.VALUES[1].find(recipe.energy)+Producer.VALUES[2].find(recipe.originality)
 return int(c.capacity)==capacity and int(c.demand)==demand and int(r.delta)==clampi(int(Producer.CRAFT[id])-absi(capacity-demand),-3,3) and int(r.final_quality)==clampi(int(r.base_quality)+int(r.delta),1,100) and r.reason==Producer.REASONS[id]

static func _extension_ok(value: Variant) -> bool:
 if not value is Dictionary or value.get("version")!=1 or not value.get("project_id") is String or not _fragment_ok(value.get("fragment"),str(value.project_id)) or not _paid_ok(value.get("paid_receipts")):return false
 if value.fragment.has("producer_recipe") and not value.get("project_snapshot") is Dictionary:return false
 if value.fragment.has("producer_recipe") and (not _same(value.fragment,value.get("project_snapshot",{}).get("fragment")) or not _same(value.paid_receipts,value.get("project_snapshot",{}).get("paid_receipts"))):return false
 if value.fragment.has("producer_recipe") and (value.paid_receipts.size()!=3 or not _same(_material(value.fragment),value.paid_receipts.back().fragment_snapshot)):return false
 if value.fragment.has("producer_recipe") and not _producer_final_trial_ok(value.project_snapshot,value.fragment,value.paid_receipts):return false
 if value.fragment.has("producer_recipe"):
  var project: Dictionary=value.project_snapshot
  var trial: Dictionary=project.get("last_trial",{}) if project.get("last_trial") is Dictionary else {}
  if not _same(trial.get("fragment_snapshot"),_material(value.fragment)) or trial.get("producer_fragment_id")!=value.fragment.fragment_id or value.paid_receipts.back().get("trial_id")!=trial.get("id"):return false
 return _producer_receipt_ok(value) and value.paid_receipts.size()==3 and _closed_project_ok(value.get("project_snapshot"),str(value.project_id),3) and value.get("content_version") is String and value.get("policy_version") is String and not _hash(value).is_empty()

static func _finished_ref(index: int,song: Dictionary) -> Dictionary:
 var extension: Dictionary=song[FRAGMENT_KEY]
 return {"catalogue_index":index,"song_id":str(song.get("id","")),"project_id":str(extension.project_id),"fragment_id":str(extension.fragment.fragment_id),"fragment_sha256":_hash(extension)}

static func _finance_closed_once(before: Dictionary,after: Dictionary) -> bool:
 if before.has(Finance.KEY) and not Finance._valid(before[Finance.KEY]):return false
 var old: Dictionary=Finance.view(before)
 var current: Variant=after.get(Finance.KEY)
 if not Finance._valid(current):return false
 if int(current.seq)!=int(old.seq)+1 or int(current.accounted_day)!=int(after.tour_day) or int(current.closing_balance)!=int(after.cash):return false
 if not _exact(current.get("opening_balance"),old.get("opening_balance")) or not _exact(current.get("opening_day"),old.get("opening_day")):return false
 var previous: Array=old.history
 var trim: int=maxi(0,previous.size()+1-Finance.HISTORY_LIMIT)
 var retained: Array=previous.slice(trim)
 if current.history.size()!=retained.size()+1 or not _exact(current.history.slice(0,retained.size()),retained):return false
 var row: Variant=current.history.back()
 if not row is Dictionary or not _keys(row,["seq","action","day_before","day_after","cash_before","cash_after","income","outgoing","flows","closing_balances"]):return false
 if row.get("action")!="practice:create" or row.get("seq")!=current.seq:return false
 for pair in [["day_before",before.tour_day],["day_after",after.tour_day],["cash_before",before.cash],["cash_after",after.cash]]:
  if not _whole(row.get(pair[0])) or int(row[pair[0]])!=int(pair[1]):return false
 if not _whole(row.get("income")) or not _whole(row.get("outgoing")) or not row.get("flows") is Array:return false
 if int(before.cash)+int(row.income)-int(row.outgoing)!=int(after.cash):return false
 return row.get("closing_balances") is Array and _exact(row.closing_balances,[int(after.cash)])

static func seal_paid(before: Dictionary,after_accounting: Dictionary,prepared: Dictionary,completion: Dictionary,original_result: Dictionary) -> Dictionary:
 var fail:=_mutation(before,false,"The saved writing receipt could not be reconciled. Nothing changed.")
 if completion.get("prepared_hash")!=_hash(prepared) or completion.get("original_result_hash")!=_hash(original_result) or not _source_ok(after_accounting):return fail
 var outside_before:=before.duplicate(true);outside_before.game.erase("career")
 var outside_after:=after_accounting.duplicate(true);outside_after.game.erase("career")
 if not _exact(outside_before,outside_after):return fail
 var state:=_career(after_accounting)
 if not _finance_closed_once(_career(before),state):return fail
 if not _exact(state.song_catalogue,completion.get("catalogue")) or not _binding_ok(state,{"binding":completion.get("binding",{})}) or not _exact(state.get(KEY),_career(before).get(KEY)):return fail
 var wrapper:=_wrapper(before);var project: Dictionary=wrapper.project
 var row: Dictionary={"stage":int(completion.stage),"day_before":int(_career(before).tour_day),"day_after":int(state.tour_day),"cash_before":int(_career(before).cash),"cash_after":int(state.cash),"fragment_snapshot":_material(project.fragment),"trial_id":str(project.last_trial.id),"target":project.target.duplicate(true),"original_outcome":state.get("last_rehearsal_outcome",{}).duplicate(true)}
 project.paid_receipts.append(row)
 project.binding=completion.binding.duplicate(true)
 project.phase="between_sessions"
 wrapper.revision=int(wrapper.revision)+1
 var next:=after_accounting.duplicate(true)
 var social_message: String=""
 if project.fragment.has("producer_recipe"):
  var social: Dictionary=Social.apply(next.game.career,project,int(completion.stage))
  if not social.ok:return fail
  next.game.career=social.state
  social_message=social.message
 if int(completion.stage)==2:
  var index: int=int(completion.appended_index)
  var extension: Dictionary={"version":1,"project_id":project.id,"content_version":project.content_version,"policy_version":POLICY,"fragment":project.fragment.duplicate(true),"paid_receipts":project.paid_receipts.duplicate(true),"contributions":project.feedback_history.duplicate(true),"project_snapshot":project.duplicate(true)}
  if project.fragment.has("producer_recipe"):
   var craft: Dictionary=Producer.craft(_career(before),project.fragment.producer_recipe)
   var song: Dictionary=next.game.career.song_catalogue[index]
   if not craft.get("ok",false) or not _whole(song.get("quality"),0,100) or song.get("id")!=completion.new_id:return fail
   var base_quality: int=int(song.quality)
   var final_quality: int=clampi(base_quality+int(craft.delta),1,100)
   extension.producer_quality_receipt={"model":craft.model,"recipe_sha256":_hash(project.fragment.producer_recipe),"song_id":song.id,"base_quality":base_quality,"delta":int(craft.delta),"final_quality":final_quality,"context":{"active_skill_sum":craft.active_skill_sum,"active_count":craft.active_count,"capacity":craft.capacity,"demand":craft.demand},"reason":craft.reason}
   next.game.career.song_catalogue[index].quality=final_quality
  next.game.career.song_catalogue[index][FRAGMENT_KEY]=Canon._freeze_candidate(extension)
  var reference:=_finished_ref(index,next.game.career.song_catalogue[index])
  wrapper.last_result={"id":project.id,"sequence":project.sequence,"result":"finished","fragment":project.fragment.duplicate(true),"paid_receipts":project.paid_receipts.duplicate(true),"finished_ref":reference,"project_snapshot":project.duplicate(true)}
  wrapper.project={}
 else:wrapper.project=project
 next.game.career[KEY]=Canon._freeze_candidate(wrapper)
 return _mutation(next,true,"The original session and this exact take are saved. "+social_message,true)

static func finished(opening: Dictionary) -> Dictionary:
 var items: Array=[]
 var state:=_career(opening)
 if not state.get("song_catalogue") is Array:return {"ok":false,"message":"The song catalogue needs review.","items":[]}
 for index in range(state.song_catalogue.size()):
  var song: Variant=state.song_catalogue[index]
  if song is Dictionary and _extension_ok(song.get(FRAGMENT_KEY)) and (not song[FRAGMENT_KEY].has("producer_quality_receipt") or (song.get("quality")==song[FRAGMENT_KEY].producer_quality_receipt.final_quality and song.get("id")==song[FRAGMENT_KEY].producer_quality_receipt.song_id)):items.append({"title":str(song.get("title","UNTITLED")),"reference":_finished_ref(index,song)})
 return {"ok":true,"message":"","items":items}

static func read_finished(opening: Dictionary,reference: Dictionary) -> Dictionary:
 var fail: Dictionary={"ok":false,"found":false,"message":"This catalogue reference changed. Open the current finished-sketch list.","reference":reference.duplicate(true),"fragment":{}}
 if not _keys(reference,["catalogue_index","song_id","project_id","fragment_id","fragment_sha256"]) or not _whole(reference.get("catalogue_index")):return fail
 var state:=_career(opening)
 if not state.get("song_catalogue") is Array or int(reference.catalogue_index)>=state.song_catalogue.size():return fail
 var song: Variant=state.song_catalogue[int(reference.catalogue_index)]
 if not song is Dictionary or not _extension_ok(song.get(FRAGMENT_KEY)) or (song[FRAGMENT_KEY].has("producer_quality_receipt") and (song.get("quality")!=song[FRAGMENT_KEY].producer_quality_receipt.final_quality or song.get("id")!=song[FRAGMENT_KEY].producer_quality_receipt.song_id)) or not _same(reference,_finished_ref(int(reference.catalogue_index),song)):return fail
 return {"ok":true,"found":true,"message":"","reference":reference.duplicate(true),"fragment":song[FRAGMENT_KEY].duplicate(true)}
