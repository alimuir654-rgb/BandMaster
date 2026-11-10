extends RefCounted
## Read-only presentation of saved room feedback. Never predicts show settlement.
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Song=preload("res://experiments/playable_flightcase/song_audio.gd")
const REGISTRY="res://experiments/playable_flightcase/art/crowd34.json"
const CAPTIONS={"watching":"THE ROOM IS WATCHING","enjoying":"THE ROOM IS WITH YOU","restless":"ATTENTION IS DRIFTING","displeased":"AN UNHAPPY RECEPTION"}
static var _textures: Dictionary={}
static func live(visit: Dictionary) -> String:
 var rows: Array=visit.get("feedback",[])
 if rows.is_empty():return "watching"
 var previous: int=40 if rows.size()<2 else int(rows[-2].get("vibe",40))
 var change: int=int(visit.get("vibe",rows[-1].get("vibe",40)))-previous
 return "enjoying" if change>=2 else ("restless" if change<=-3 else "watching")
static func finale(receipt: Dictionary) -> String:
 if typeof(receipt.get("success"))!=TYPE_BOOL:return "watching"
 return "enjoying" if receipt.success else "displeased"
static func identity(visit: Dictionary) -> String:
 var phase: String=str(visit.get("phase",""))
 if phase=="performing":
  if not visit.get("plan") is Dictionary or not visit.plan.get("song_snapshots") is Array:return ""
  var cursor: int=int(visit.get("cursor",0));var songs: Array=visit.plan.song_snapshots
  if cursor<0:return ""
  if cursor<songs.size():return "song:%s:%d:%s" % [str(visit.get("id","")),cursor,str(songs[cursor].get("id",""))]
  return "short:"+str(visit.get("id",""))
 if phase=="after_set":return "tail:"+str(visit.get("id",""))
 return ""
static func saved_event(before: Dictionary,after: Dictionary,action: String) -> Dictionary:
 var visit: Dictionary=Journey.active(after)
 var key: String=identity(visit)
 if not key.is_empty() and key!=identity(Journey.active(before)):
  if visit.get("phase")=="after_set":return {"id":key,"kind":"courtesy","recipe":{}}
  var cursor: int=int(visit.get("cursor",0));var songs: Array=visit.get("plan",{}).get("song_snapshots",[])
  var recipe: Dictionary=Song.recipe(songs[cursor]) if cursor<songs.size() else {}
  if recipe.get("version") not in [3,4]:recipe={}
  return {"id":key,"kind":"entrance" if cursor==0 else "song","recipe":recipe}
 if action=="wrap":
  var receipt: Dictionary=Flow.last_receipt(after)
  if not receipt.is_empty() and typeof(receipt.get("success"))==TYPE_BOOL and receipt.get("id")!=Flow.last_receipt(before).get("id"):
   return {"id":"result:"+str(receipt.id),"kind":"cheer" if receipt.success else "boo","recipe":{}}
 return {}
static func source_token(value: Dictionary) -> String:
 return Journey.Policy.fingerprint(value)
static func texture(variant: String) -> Texture2D:
 if _textures.has(variant):return _textures[variant]
 if variant not in CAPTIONS or not FileAccess.file_exists(REGISTRY):return null
 var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
 if not raw is Dictionary or raw.get("content_version")!="crowd34" or raw.get("integration_review_accepted")!=true or raw.get("authority")!="owner_crowd_request_20261110":return null
 var path: String=str(raw.get("texture",""))
 if path!="res://experiments/playable_flightcase/art/crowd34.png" or not ResourceLoader.exists(path):return null
 if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=raw.get("sha256"):return null
 var source: Texture2D=load(path) as Texture2D
 if source==null or source.get_size()!=Vector2(1536,1024):return null
 var rects: Dictionary={"watching":Rect2(0,0,768,512),"enjoying":Rect2(768,0,768,512),"restless":Rect2(0,512,768,512),"displeased":Rect2(768,512,768,512)}
 var atlas:=AtlasTexture.new();atlas.atlas=source;atlas.region=rects[variant];atlas.filter_clip=true
 _textures[variant]=atlas
 return atlas
static func apply(photo: TextureRect,variant: String) -> void:
 var image: Texture2D=texture(variant)
 if image==null:return
 photo.texture=image;photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 photo.set_meta("source",REGISTRY);photo.set_meta("crowd_variant",variant);photo.set_meta("kind","illustrative_saved_room_response");photo.set_meta("full_source_contained",true)
