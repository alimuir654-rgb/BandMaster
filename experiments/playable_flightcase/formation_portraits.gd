extends RefCounted
## Presentation-only registry. Canonical audition data and old sources stay intact.
const PATH="res://experiments/playable_flightcase/art/identity/next32_portraits.json"
# Authored presentation proportions, not measured real-world heights or stats.
# Shared atlas framing must not make every selected musician the same stature.
const LINEUP_SCALE={
 "cast_jack":1.00,"cast_maya":0.91,"cast_ellis":0.96,"cast_zoe":0.94,
 "cast_dan":1.05,"cast_ryan":1.02,"cast_lily":0.98,"cast_marcus":1.08,
 "cast_ben":1.03,"cast_freya":0.96,"cast_arjun":1.04,"cast_nina":0.91,
 "cast_tom":0.98,"cast_casey":0.90,"cast_hannah":0.97,"cast_oscar":1.01,
 "cast_bex":0.95,"cast_sam":1.06
}
static var _cached: Dictionary={}
static func entries() -> Dictionary:
 if not _cached.is_empty():return _cached.duplicate(true)
 if not FileAccess.file_exists(PATH):return {}
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 if not raw is Dictionary or raw.get("schema_version")!=1 or raw.get("content_version")!="next32_camera_poses" or raw.get("integration_review_accepted")!=true or not raw.get("people") is Dictionary:return {}
 var result: Dictionary={}
 for id in raw.people:
  var e: Variant=raw.people[id]
  if not e is Dictionary or not e.get("texture") is String or not str(e.texture).begins_with("res://experiments/playable_flightcase/art/identity/next32_cast_") or not ResourceLoader.exists(e.texture):return {}
  if FileAccess.file_exists(e.texture) and FileAccess.get_sha256(e.texture)!=e.get("sha256"):return {}
  var t: Texture2D=load(e.texture) as Texture2D
  var r: Variant=e.get("region")
  if t==null or t.get_size()!=Vector2(1536,1024) or not r is Array or r.size()!=4:return {}
  for n in r:
   if not n is float and not n is int:return {}
   if float(n)!=floorf(float(n)):return {}
  if r[0]<0 or r[1]<0 or r[2]<=8 or r[3]<=8 or r[0]+r[2]>1536 or r[1]+r[3]>1024:return {}
  result[id]=e.duplicate(true)
  result[id]["pose_height_ratio"]=float(LINEUP_SCALE.get(id,1.0))
 if result.size()!=18:return {}
 _cached=result
 return _cached.duplicate(true)
