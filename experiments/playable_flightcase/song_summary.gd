extends RefCounted
## Saved facts only. Reading never resolves gameplay, normalises a save or writes.
const Recording = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Shows = preload("res://experiments/playable_flightcase/show_flow.gd")

static func _number(value: Variant, low: int=0, high: int=2147483647) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=low and float(value)<=high

static func _text(value: Variant, fallback: String="") -> String:
 return value.strip_edges() if value is String and not value.strip_edges().is_empty() else fallback

static func _names(value: Variant) -> String:
 if not value is Array:return ""
 var names: PackedStringArray=[]
 for item in value:
  if not _text(item).is_empty():names.append(_text(item))
 return ", ".join(names)

static func _description(song: Dictionary, captured_song: bool=false) -> Dictionary:
 var quality: Variant=song.get("quality")
 var known: bool=_number(quality,0,100)
 var prefix: String="CAPTURED SONG STRENGTH" if captured_song else "SONG STRENGTH"
 var strength: String=prefix+" · UNKNOWN"
 if known:
  var band: String="NEEDS WORK" if int(quality)<45 else ("PROMISING" if int(quality)<70 else "STRONG")
  strength=prefix+" · %d / 100 · %s" % [int(quality),band]
 var credits: String=_names(song.get("credited_writers"))
 if not credits.is_empty():credits="CREDIT: "+credits
 elif not _text(song.get("lead_writer")).is_empty():credits="LEAD WRITER: "+_text(song["lead_writer"])
 else:
  credits=_names(song.get("writers"))
  credits="WRITERS: "+credits if not credits.is_empty() else "WRITING CREDITS NOT RECORDED"
 var history: Array[String]=[]
 var sessions: Variant=song.get("writing_sessions")
 if sessions is Array:
  for session in sessions:
   if not session is Dictionary:continue
   var parts: PackedStringArray=[]
   if _number(session.get("day"),1):parts.append("DAY %d" % int(session["day"]))
   for field in ["leader","idea","form"]:
    if not _text(session.get(field)).is_empty():parts.append(_text(session[field]))
   if not parts.is_empty():history.append(" / ".join(parts))
 return {"title":_text(song.get("title"),"UNTITLED"),"strength":strength,
  "quality":int(quality) if known else null,"known_strength":known,"credits":credits,
  "origin":_text(song.get("origin"),"ORIGIN NOT RECORDED"),
  "arrangement":_text(song.get("arrangement"),"ARRANGEMENT NOT RECORDED"),
  "finish":"FINISHED DAY %d" % int(song["written_day"]) if _number(song.get("written_day"),1) else "FINISH DATE NOT RECORDED",
  "history":history,"legacy_note":_text(song.get("live_reception")),"readiness":"Preparation not tracked for this version/line-up.",
  "recording":"Recording history not fully linked.","reach":"Not tracked.",
  "evidence":"No identity-linked live evidence in the saved archive.","identity":"Song version not tracked."}

static func _unique_id(state: Dictionary, song: Dictionary) -> bool:
 var id: Variant=song.get("id")
 var catalogue: Variant=state.get("song_catalogue")
 if not id is String or id.strip_edges().is_empty() or not catalogue is Array:return false
 var count: int=0
 for row in catalogue:
  if row is Dictionary and row.get("id") is String and row["id"]==id:count+=1
 return count==1

static func _recording_history(state: Dictionary, id: String) -> String:
 var raw: Variant=state.get("recordings",[])
 if not raw is Array:return "Recording history not fully linked."
 var seen: Dictionary={}
 var linked: bool=false
 var complete: bool=state.has("recordings") and _number(state.get("demos")) and int(state["demos"])==raw.size()
 for row in raw:
  if not row is Dictionary or not Recording._session_valid(row):return "Recording history not fully linked."
  var recording_id: String=_text(row.get("id"))
  if recording_id.is_empty():complete=false
  elif seen.has(recording_id):return "Recording history not fully linked."
  else:seen[recording_id]=true
  if not row.has(Recording.LINK_KEY):complete=false
  elif row[Recording.LINK_KEY]["song_ids"].has(id):linked=true
 if linked:return "Recorded; execution quality not tracked."
 if not complete:return "Recording history not fully linked."
 return "Not recorded." if raw.is_empty() else "No linked take in the saved archive."

static func _live_evidence(state: Dictionary, id: String) -> String:
 if not state.has(Shows.RECORDS_KEY):return "No identity-linked live evidence in the saved archive."
 if not Shows._validate_records(state).get("ok",false):return "Saved live evidence needs review."
 var rows: Array=state[Shows.RECORDS_KEY]["records"]
 for index in range(rows.size()-1,-1,-1):
  var row: Dictionary=rows[index]
  var plan: Dictionary=row["plan"]
  if not plan["song_ids"].has(id):continue
  # A completed set can carry a more specific journey archive. Do not infer
  # that a selected song was played from an unvalidated/partial extension.
  if row.has("journey_v1"):
   var visit: Variant=row["journey_v1"]
   if not visit is Dictionary or not visit.get("completed_ids") is Array or not visit.get("plan") is Dictionary:continue
   if not _number(visit.get("version"),1,2) or visit.get("kind")!="modelled_live_journey" or visit.get("content_version")!=1 or visit.get("policy_version")!=1:continue
   if visit["plan"]!=plan or not visit["completed_ids"].has(id):continue
   var done: Dictionary={}
   var valid: bool=true
   for completed in visit["completed_ids"]:
    if not completed is String or done.has(completed) or not plan["song_ids"].has(completed):valid=false;break
    done[completed]=true
   if not valid:continue
  return "SAVED SET · %s · DAY %d\nSong version and individual song scores are not tracked." % [row["venue"],int(row["scheduled_day"])]
 return "No identity-linked live evidence in the saved archive."

static func current(state: Dictionary, song: Dictionary) -> Dictionary:
 var result: Dictionary=_description(song)
 if not _unique_id(state,song):
  result["identity"]="Song ID missing or ambiguous."
  result["evidence"]="Live evidence not linked to a unique song."
  return result
 var id: String=song["id"]
 result["recording"]=_recording_history(state,id)
 result["evidence"]=_live_evidence(state,id)
 return result

static func draft(state: Dictionary) -> Dictionary:
 var raw: Variant=state.get("current_song_draft")
 var song: Dictionary=raw if raw is Dictionary else {}
 var result: Dictionary=_description(song)
 result["quality"]=null;result["known_strength"]=false
 result["credits"]="LEAD WRITER: "+_text(song["leader"]) if not _text(song.get("leader")).is_empty() else "WRITING CREDITS NOT RECORDED"
 result["strength"]="WRITING DRAFT · PROGRESS UNKNOWN"
 var sessions: Variant=song.get("sessions")
 var progress: Variant=state.get("song_draft_progress")
 if sessions is Array:
  var valid: bool=sessions.size()<=3
  for session in sessions:
   if not session is Dictionary:valid=false
  if state.has("song_draft_progress") and (not _number(progress,0,3) or int(progress)!=sessions.size()):valid=false
  if valid:result["strength"]="WRITING DRAFT · SESSION %d / 3" % sessions.size()
 elif _number(progress,0,3):result["strength"]="WRITING DRAFT · SESSION %d / 3" % int(progress)
 result["recording"]="Finish this draft before recording."
 result["identity"]="Unfinished draft; no finished song strength."
 return result

static func captured(recording: Dictionary, index: int) -> Dictionary:
 var tracks: Variant=recording.get("tracks")
 var valid_track: bool=tracks is Array and index>=0 and index<tracks.size() and tracks[index] is Dictionary
 var title: String=_text(tracks[index].get("title"),"UNTITLED") if valid_track else "UNTITLED"
 var valid: bool=valid_track and Recording._session_valid(recording)
 var linked: bool=valid and recording.has(Recording.LINK_KEY)
 # Never substitute today's catalogue, or call an unlinked legacy value an
 # identified composition snapshot. The old stored data remains unchanged.
 var song: Dictionary=recording[Recording.LINK_KEY]["snapshots"][index] if linked else {"title":title}
 var result: Dictionary=_description(song,true)
 result["recording"]="Recorded; execution quality not tracked." if valid else "Recording metadata needs review."
 result["identity"]="Captured song snapshot; composition revision not tracked." if linked else "Saved song link and writing history not recorded."
 result["evidence"]="Audience evidence is not attributed to this recording."
 return result
