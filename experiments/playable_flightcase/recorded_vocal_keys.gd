extends RefCounted
## Approved first passages only. A new source/performer binding, no legacy migration.
const HOOKS=["indie39_plates_01","indie39_wear_01","indie39_stairs_01"]
const LABELS=["MAYA / FREYA","LILY / DAN","SAM / OSCAR"]
const TITLES=["GET THE GOOD PLATES DOWN","WEAR AND TEAR","UNDERNEATH THE KITCHEN STAIRS"]
const SINGERS=["cast_maya","cast_lily","cast_sam"]
const KEYS=["cast_freya","cast_dan","cast_oscar"]
const FINGERPRINTS=["bf70d59ad3ac29e764f11786126a3166ba83ecbcabbf34e360c8fee57f1486e8", "23041a2f67795226f277cf6c2509a53bd79242e56c1e12cab0539e009e683ff2", "47deb8577c4949b7d409a5bc33f233e25b63ec0c73107b20d0ead03b0f96091f"]
const FRAMES=[453120,403199,403199]
const TEMPOS=[101.695,114.286,114.286]
const PREFIX="res://experiments/playable_flightcase/audio/recorded_indie39/"
const MANIFEST=PREFIX+"manifest.json"
const PARTS=["vocals","keys","guitar","bass","kit"]
static func has_hook(value: Variant) -> bool:return value is Dictionary and value.get("hook") in HOOKS
static func index(value: Dictionary) -> int:return HOOKS.find(value.get("hook"))
static func bound(value: Dictionary) -> bool:
 var i: int=index(value)
 return i>=0 and value.get("version")==5 and value.get("voice")==SINGERS[i] and value.get("keys")==KEYS[i] and value.get("tone")=="warm"
static func active_pair(career: Dictionary,value: Dictionary) -> bool:
 if not bound(value):return false
 var singer:=false;var keys:=false
 for member in career.get("members",[]):
  if not member is Dictionary or member.get("life_status","active")!="active":continue
  if member.get("candidate_id")==value.voice and member.get("role")=="Singer":singer=true
  if member.get("candidate_id")==value.keys and member.get("role")=="Keyboardist":keys=true
 return singer and keys
static func select(base: Dictionary,hook: String) -> Dictionary:
 var value: Dictionary=base.duplicate(true);var i: int=HOOKS.find(hook)
 value["hook"]=hook;value["version"]=5 if i>=0 else 4;value["voice"]=SINGERS[i] if i>=0 else "off"
 value.erase("keys")
 if i>=0:value["keys"]=KEYS[i];value["tone"]="warm"
 return value
static func entry(value: Dictionary) -> Dictionary:
 if not bound(value) or not FileAccess.file_exists(MANIFEST):return {}
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if not raw is Dictionary or raw.get("content_version")!="recorded_indie39" or raw.get("owner_listening_accepted")!=true:return {}
 var row: Variant=raw.get("entries",{}).get(value.hook)
 var i: int=index(value)
 if not row is Dictionary or row.get("frames")!=FRAMES[i] or row.get("tempo")!=TEMPOS[i] or row.get("sample_rate")!=48000 or row.get("singer")!=value.voice or row.get("keyboardist")!=value.keys:return {}
 if row.get("fingerprint")!=FINGERPRINTS[i]:return {}
 if not row.get("parts") is Dictionary or row.parts.size()!=5:return {}
 var hashes: Array[String]=[]
 for part in PARTS:
  var asset: Variant=row.parts.get(part)
  if not asset is Dictionary or asset.get("path")!=PREFIX+value.hook+"_"+part+".wav" or not asset.get("pcm_sha256") is String or asset.pcm_sha256.length()!=64 or not ResourceLoader.exists(asset.path):return {}
  hashes.append(asset.pcm_sha256)
  if FileAccess.file_exists(asset.path) and FileAccess.get_sha256(asset.path)!=asset.get("sha256"):return {}
 if "|".join(hashes).sha256_text()!=FINGERPRINTS[i]:return {}
 return row.duplicate(true)
static func stream(asset: Dictionary,frames: int) -> AudioStreamWAV:
 if frames not in FRAMES:return null
 var wav: AudioStreamWAV=load(str(asset.get("path",""))) as AudioStreamWAV
 if wav==null or wav.format!=AudioStreamWAV.FORMAT_16_BITS or wav.mix_rate!=48000 or not wav.stereo or wav.loop_mode!=AudioStreamWAV.LOOP_DISABLED or wav.data.size()!=frames*4:return null
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(wav.data)
 return wav if hash.finish().hex_encode()==asset.get("pcm_sha256") else null
