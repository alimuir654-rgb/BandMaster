extends RefCounted
## Private recorded phrases. No audition state, paid resolver or filesystem writes.
const STEADY_HOOKS := ["steady_early_v1","steady_later_v1"]
const REHEARSAL_HOOKS := ["rehearsal_01_v1","rehearsal_02_v1","rehearsal_03_v1","rehearsal_04_v1","rehearsal_05_v1","rehearsal_06_v1"]
const DGAD_HOOKS := ["dgad_01_v1","dgad_02_v1","dgad_03_v1","dgad_04_v1","dgad_05_v1","dgad_06_v1"]
const HOOKS := STEADY_HOOKS+REHEARSAL_HOOKS+DGAD_HOOKS
const LABELS := ["STEADY EARLY","STEADY LATER","REHEARSAL 01","REHEARSAL 02","REHEARSAL 03","REHEARSAL 04","REHEARSAL 05","REHEARSAL 06","D–G–A–D 01","D–G–A–D 02","D–G–A–D 03","D–G–A–D 04","D–G–A–D 05","D–G–A–D 06"]
const MANIFEST := "res://experiments/playable_flightcase/audio/recorded_steady_v2/manifest.json"
const PREFIX := "res://experiments/playable_flightcase/audio/recorded_steady_v2/"
const USES := "recorded_phrase_uses_v1"
const REHEARSAL_MANIFEST := "res://experiments/playable_flightcase/audio/recorded_rehearsal_v1/manifest.json"
const REHEARSAL_PREFIX := "res://experiments/playable_flightcase/audio/recorded_rehearsal_v1/"
const DGAD_MANIFEST := "res://experiments/playable_flightcase/audio/recorded_dgad_v1/manifest.json"
const DGAD_PREFIX := "res://experiments/playable_flightcase/audio/recorded_dgad_v1/"
const BANKS := [
 {"hooks":STEADY_HOOKS,"manifest":MANIFEST,"prefix":PREFIX,"version":"recorded_steady_v2","tempo":100,"frames":460800,"tempo_caption":"100 BPM"},
 {"hooks":REHEARSAL_HOOKS,"manifest":REHEARSAL_MANIFEST,"prefix":REHEARSAL_PREFIX,"version":"recorded_rehearsal_v1","tempo":102,"frames":451765,"tempo_caption":"~102 BPM"},
 {"hooks":DGAD_HOOKS,"manifest":DGAD_MANIFEST,"prefix":DGAD_PREFIX,"version":"recorded_dgad_v1","tempo":100,"frames":460800,"tempo_caption":"~100 BPM"}
]

static func bank_for(value: Dictionary) -> Dictionary:
 for bank in BANKS:
  if value.get("hook") in bank.hooks:return bank
 return {}

static func expanded(value: Dictionary) -> bool:
 return has_hook(value) and value.hook not in STEADY_HOOKS

static func rehearsal(value: Dictionary) -> bool:
 return value.get("hook") in REHEARSAL_HOOKS

static func tempo(value: Dictionary) -> int:
 return int(bank_for(value).get("tempo",0))

static func frames(value: Dictionary) -> int:
 return int(bank_for(value).get("frames",0))

static func tempo_caption(value: Dictionary) -> String:
 return str(bank_for(value).get("tempo_caption","REVIEW"))

static func has_hook(value: Variant) -> bool:
 return value is Dictionary and value.get("hook") in HOOKS

static func participants(career: Dictionary) -> Array:
 var result: Array=[]
 if not career.get("members") is Array:return []
 for member in career.members:
  if not member is Dictionary:return []
  if member.get("life_status","active")!="active" or member.get("role") not in ["Guitarist","Bassist","Drummer"]:continue
  var id: Variant=member.get("candidate_id")
  if not id is String or id.is_empty() or id in result:return []
  result.append(id)
 return result

static func uses_valid(career: Dictionary) -> bool:
 if not career.has(USES):return true
 var data: Variant=career[USES]
 if not data is Dictionary or data.size()!=2 or data.get("version")!=1 or not data.get("records") is Array:return false
 var seen: Dictionary={}
 for row in data.records:
  if not row is Dictionary or row.size()!=3 or not row.get("candidate_id") is String or row.candidate_id.is_empty() or row.get("hook") not in HOOKS or not row.get("project_id") is String or row.project_id.is_empty():return false
  var key: String=row.candidate_id+":"+row.hook
  if seen.has(key):return false
  seen[key]=true
 return true

static func available(career: Dictionary,value: Dictionary,project_id: String) -> bool:
 if not has_hook(value):return true
 if project_id.is_empty() or not uses_valid(career):return false
 if int(value.get("stage",0))>0:
  # The first paid cohort owns this song's source even if the live lineup changes.
  for row in career.get(USES,{"records":[]}).records:
   if row.project_id==project_id and row.hook==value.hook:return true
  return false
 var people: Array=participants(career)
 if people.is_empty():return false
 for row in career.get(USES,{"records":[]}).records:
  if row.hook==value.hook and row.candidate_id in people and row.project_id!=project_id:return false
 return true

static func consume(career: Dictionary,value: Dictionary,project_id: String) -> Dictionary:
 if not has_hook(value):return {"ok":true,"state":career.duplicate(true)}
 if not available(career,value,project_id):return {"ok":false,"state":career}
 if int(value.get("stage",0))>0:return {"ok":true,"state":career.duplicate(true)}
 var next: Dictionary=career.duplicate(true)
 var data: Dictionary=next.get(USES,{"version":1,"records":[]}).duplicate(true)
 for id in participants(career):
  var exists: bool=false
  for row in data.records:
   if row.candidate_id==id and row.hook==value.hook:exists=true
  if not exists:data.records.append({"candidate_id":id,"hook":value.hook,"project_id":project_id})
 next[USES]=data
 return {"ok":true,"state":next}

static func entry(value: Dictionary) -> Dictionary:
 var bank: Dictionary=bank_for(value)
 if bank.is_empty() or not FileAccess.file_exists(bank.manifest):return {}
 var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(bank.manifest))
 if not data is Dictionary or data.get("schema_version")!=1 or data.get("content_version")!=bank.version or data.get("review_only")!=true or not data.get("entries") is Dictionary:return {}
 var item: Variant=data.entries.get(value.hook)
 if not item is Dictionary or item.get("tempo")!=tempo(value) or item.get("frames")!=frames(value) or item.get("sample_rate")!=48000 or item.get("channels")!=2 or not item.get("parts") is Dictionary or item.parts.size()!=5:return {}
 for part in ["guitar_warm","guitar_gritty","guitar_biting","bass","kit"]:
  var asset: Variant=item.parts.get(part)
  if not asset is Dictionary or not asset.get("path") is String or not asset.path.begins_with(bank.prefix) or not ResourceLoader.exists(asset.path) or not asset.get("pcm_sha256") is String or asset.pcm_sha256.length()!=64:return {}
 return item

static func stream(asset: Dictionary,expected_frames: int=460800) -> AudioStreamWAV:
 if expected_frames not in [460800,451765]:return null
 var wav: AudioStreamWAV=load(str(asset.path)) as AudioStreamWAV
 if wav==null or wav.format!=AudioStreamWAV.FORMAT_16_BITS or wav.mix_rate!=48000 or not wav.stereo or wav.loop_mode!=AudioStreamWAV.LOOP_DISABLED or wav.data.size()!=expected_frames*4:return null
 var hash:=HashingContext.new()
 hash.start(HashingContext.HASH_SHA256);hash.update(wav.data)
 return wav if hash.finish().hex_encode()==asset.pcm_sha256 else null
