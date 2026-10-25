extends RefCounted
# The songbook is a read-only view over actual finished compositions.
# Per-song live reception is only shown when gameplay has recorded it.
static func entries(state: Dictionary) -> Array:
 var result: Array = []
 var songs: Array = state.get("song_catalogue",[])
 for i in range(songs.size()):
  if not songs[i] is Dictionary:
   continue
  var song: Dictionary = songs[i]
  var quality := clampi(int(song.get("quality",0)),0,100)
  var verdict := "NEEDS WORK" if quality < 45 else ("PROMISING" if quality < 70 else "SETLIST READY")
  var reception := "NOT RECORDED"
  if song.has("live_reception") and not str(song["live_reception"]).strip_edges().is_empty():
   reception = str(song["live_reception"]).left(80)
  result.append({
   "number":i+1,
   "title":str(song.get("title","UNTITLED")),
   "quality":quality,
   "verdict":verdict,
   "writer":str(song.get("lead_writer","BAND COLLABORATION")),
   "arrangement":str(song.get("arrangement","IN DEVELOPMENT")),
   "reception":reception
  })
 return result
