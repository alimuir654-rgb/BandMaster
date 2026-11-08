extends RefCounted
## Private recorded phrases. No audition state, paid resolver or filesystem writes.
const HOOKS := ["steady_early_v1","steady_later_v1"]
const LABELS := ["STEADY EARLY","STEADY LATER"]
const MANIFEST := "res://experiments/playable_flightcase/audio/recorded_steady_v2/manifest.json"
const PREFIX := "res://experiments/playable_flightcase/audio/recorded_steady_v2/"
const USES := "recorded_phrase_uses_v1"

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
 if not has_hook(value) or not FileAccess.file_exists(MANIFEST):return {}
 var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if not data is Dictionary or data.get("schema_version")!=1 or data.get("content_version")!="recorded_steady_v2" or data.get("review_only")!=true or not data.get("entries") is Dictionary:return {}
 var item: Variant=data.entries.get(value.hook)
 if not item is Dictionary or item.get("tempo")!=100 or item.get("frames")!=460800 or item.get("sample_rate")!=48000 or item.get("channels")!=2 or not item.get("parts") is Dictionary or item.parts.size()!=5:return {}
 for part in ["guitar_warm","guitar_gritty","guitar_biting","bass","kit"]:
  var asset: Variant=item.parts.get(part)
  if not asset is Dictionary or not asset.get("path") is String or not asset.path.begins_with(PREFIX) or not ResourceLoader.exists(asset.path) or not asset.get("pcm_sha256") is String or asset.pcm_sha256.length()!=64:return {}
 return item

static func stream(asset: Dictionary) -> AudioStreamWAV:
 var wav: AudioStreamWAV=load(str(asset.path)) as AudioStreamWAV
 if wav==null or wav.format!=AudioStreamWAV.FORMAT_16_BITS or wav.mix_rate!=48000 or not wav.stereo or wav.loop_mode!=AudioStreamWAV.LOOP_DISABLED or wav.data.size()!=460800*4:return null
 var hash:=HashingContext.new()
 hash.start(HashingContext.HASH_SHA256);hash.update(wav.data)
 return wav if hash.finish().hex_encode()==asset.pcm_sha256 else null
