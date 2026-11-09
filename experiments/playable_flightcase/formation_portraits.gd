extends RefCounted
## Presentation-only registry. Canonical audition data and old sources stay intact.
const PATH="res://experiments/playable_flightcase/art/identity/next32_portraits.json"
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
 if result.size()!=18:return {}
 _cached=result
 return _cached.duplicate(true)
