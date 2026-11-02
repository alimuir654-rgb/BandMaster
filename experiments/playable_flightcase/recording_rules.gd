extends RefCounted
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
## Owned selected-song recording adapter. Pure: no IO, UI, callbacks or saving.
## Original recording/release, story, expiry, life and Finance own consequences.
const Original = preload("res://Scripts/recording_career.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const LINK_KEY := "song_links_v1"
const VERSION := 1

static func _whole(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func _number(value: Variant, minimum: int=0, maximum: int=2147483647) -> bool:
 return _whole(value) and float(value)>=float(minimum) and float(value)<=float(maximum)
static func _bad(message: String) -> Dictionary:
 return {"ok":false,"message":message}
static func _fail(state: Dictionary, message: String) -> Dictionary:
 return {"ok":false,"state":state.duplicate(true),"message":message,"session":{},"demo_id":"","closing_balances":[],"finance_action":""}
static func _consumed_dates_valid(song: Dictionary) -> bool:
 # Protected SongSleeve.describe converts these fields to int. Missing dates
 # retain its original zero default; unknown non-date fields are untouched.
 if song.has("written_day") and not _number(song["written_day"]):return false
 if song.has("writing_sessions"):
  if not song["writing_sessions"] is Array:return false
  for session in song["writing_sessions"]:
   # The original sleeve ignores unstructured legacy history entries.
   if session is Dictionary and session.has("day") and not _number(session["day"]):return false
 return true
static func _snapshot_valid(raw: Variant) -> bool:
 return raw is Dictionary and raw.get("id") is String and not str(raw["id"]).is_empty() and raw.get("title") is String and _number(raw.get("quality",-1),0,100) and _consumed_dates_valid(raw)
static func _links_valid(row: Dictionary) -> bool:
 var raw: Variant=row[LINK_KEY]
 if not raw is Dictionary or not _number(raw.get("version",0),1,1) or not raw.get("song_ids") is Array or not raw.get("snapshots") is Array:return false
 var ids: Array=raw["song_ids"];var snapshots: Array=raw["snapshots"]
 if ids.size()<2 or ids.size()>3 or snapshots.size()!=ids.size() or not row.get("tracks") is Array or row["tracks"].size()!=ids.size():return false
 var seen: Dictionary={};var total: int=0
 for index in range(ids.size()):
  var id: Variant=ids[index];var snapshot: Variant=snapshots[index];var track: Variant=row["tracks"][index]
  if not id is String or str(id).is_empty() or seen.has(id) or not _snapshot_valid(snapshot) or snapshot["id"]!=id or not track is Dictionary:return false
  if track.get("title")!=snapshot["title"] or not _number(track.get("quality",-1),0,100) or int(track["quality"])!=int(snapshot["quality"]):return false
  seen[id]=true;total+=int(snapshot["quality"])
 if not row.get("id") is String or str(row["id"]).is_empty() or not _number(row.get("day",0),1) or not _number(row.get("source_count",0),ids.size()) or not _number(row.get("quality",-1),0,100):return false
 return int(row["quality"])==int(round(float(total)/float(ids.size())))
static func _session_valid(row: Dictionary) -> bool:
 # Old sessions/tracks may lack IDs, titles, quality or released flags. Leave
 # them unchanged; the protected original release uses its existing defaults.
 if row.has("id") and not row["id"] is String:return false
 if row.has("day") and not _number(row["day"],1):return false
 if row.has("source_count") and not _number(row["source_count"]):return false
 if row.has("quality") and not _number(row["quality"],0,100):return false
 if row.has("released") and not row["released"] is bool:return false
 for field in ["release_day","fans_gained"]:
  if row.has(field) and not _number(row[field],1 if field=="release_day" else 0):return false
 if row.has("tracks"):
  if not row["tracks"] is Array:return false
  for track in row["tracks"]:
   if not track is Dictionary:return false
   if track.has("title") and not track["title"] is String:return false
   if track.has("quality") and not _number(track["quality"],0,100):return false
 return not row.has(LINK_KEY) or _links_valid(row)
static func validate(state: Dictionary) -> Dictionary:
 for field in ["cash","tour_day","readiness","fans","press","buzz","demos"]:
  if not state.has(field):continue
  var minimum: int=1 if field=="tour_day" else 0
  var maximum: int=100 if field in ["readiness","press","buzz"] else 2147483647
  if not _number(state[field],minimum,maximum):return _bad("The saved "+field+" value needs validation before recording or release.")
 if state.has("career_journal") and not state["career_journal"] is Array:return _bad("The saved career notes cannot be read safely.")
 if state.has("song_catalogue"):
  if not state["song_catalogue"] is Array:return _bad("The completed-song catalogue cannot be read safely.")
  for song in state["song_catalogue"]:
   if not song is Dictionary:return _bad("A completed-song record is malformed.")
   if song.has("id") and not song["id"] is String:return _bad("A completed-song identifier is malformed.")
   if song.has("title") and not song["title"] is String:return _bad("A completed-song title is malformed.")
   if song.has("quality") and not _number(song["quality"],0,100):return _bad("A completed-song quality is malformed.")
   if not _consumed_dates_valid(song):return _bad("A completed song has invalid finish/session dates; review its saved notes before recording or release.")
 if not state.has("recordings"):return {"ok":true,"message":""}
 if not state["recordings"] is Array:return _bad("The saved recording archive cannot be read safely.")
 var seen: Dictionary={}
 for row in state["recordings"]:
  if not row is Dictionary or not _session_valid(row):return _bad("A saved recording or its song links needs validation before a studio commitment.")
  var id: String=str(row.get("id",""))
  if not id.is_empty():
   if seen.has(id):return _bad("Two saved recordings have the same identifier; release selection is ambiguous.")
   seen[id]=true
 return {"ok":true,"message":""}
static func songs(state: Dictionary) -> Array:
 var raw: Variant=state.get("song_catalogue",[])
 if not raw is Array:return []
 var counts: Dictionary={}
 for song in raw:
  if song is Dictionary and song.get("id") is String and not str(song["id"]).is_empty():counts[song["id"]]=int(counts.get(song["id"],0))+1
 var result: Array=[]
 for song in raw:
  if _snapshot_valid(song) and int(counts.get(song["id"],0))==1:result.append(song.duplicate(true))
 return result
static func describe_song(song: Dictionary) -> Dictionary:
 # Saved-data descriptor only. This deliberately avoids the protected sleeve's
 # file-level production UI dependency while retaining its authored defaults.
 var credits: String="WRITING CREDITS NOT RECORDED"
 var credited: Variant=song.get("credited_writers",[])
 var legacy_writers: Variant=song.get("writers",[])
 if credited is Array and not credited.is_empty():
  var names: PackedStringArray=[]
  for value in credited:
   if not str(value).strip_edges().is_empty():names.append(str(value))
  if not names.is_empty():credits="CREDIT: "+", ".join(names)
 elif not str(song.get("lead_writer","")).strip_edges().is_empty():
  credits="LEAD WRITER: "+str(song["lead_writer"])
 elif legacy_writers is Array and not legacy_writers.is_empty():
  var names: PackedStringArray=[]
  for value in legacy_writers:
   if not str(value).strip_edges().is_empty():names.append(str(value))
  if not names.is_empty():credits="WRITERS: "+", ".join(names)
 var notes: Array[String]=[]
 var sessions: Variant=song.get("writing_sessions",[])
 if sessions is Array:
  for session in sessions:
   if not session is Dictionary:continue
   var parts: PackedStringArray=[]
   var saved_day: Variant=session.get("day",0)
   if _number(saved_day,1):parts.append("DAY %d" % int(saved_day))
   for key in ["leader","idea","form"]:
    var value: String=str(session.get(key,"")).strip_edges()
    if not value.is_empty():parts.append(value)
   if not parts.is_empty():notes.append("  /  ".join(parts))
 var day: String="FINISH DATE NOT RECORDED"
 var saved_day: Variant=song.get("written_day",0)
 if _number(saved_day,1):day="FINISHED DAY %d" % int(saved_day)
 var quality: String="QUALITY NOT RECORDED"
 if song.has("quality") and _number(song["quality"],0,100):quality="QUALITY %d / 100" % int(song["quality"])
 var origin: String=str(song.get("origin","")).strip_edges()
 var arrangement: String=str(song.get("arrangement","")).strip_edges()
 return {"credits":credits,"origin":origin if not origin.is_empty() else "ORIGIN NOT RECORDED","arrangement":arrangement if not arrangement.is_empty() else "ARRANGEMENT NOT RECORDED","quality":quality,"day":day,"notes":notes}
static func sessions(state: Dictionary) -> Array:
 var raw: Variant=state.get("recordings",[])
 if not raw is Array:return []
 var result: Array=[]
 for row in raw:
  # Do not filter/reindex a partially malformed archive: actual legacy indices
  # identify the original row only when the entire row sequence is safe.
  if not row is Dictionary or not _session_valid(row):return []
  result.append(row.duplicate(true))
 return result
static func fingerprint(session: Dictionary) -> String:
 return JSON.stringify(session).sha256_text()
static func _selection(state: Dictionary, ids: Array) -> Dictionary:
 if ids.size()<2 or ids.size()>3:return _bad("Select two or three completed originals for this demo.")
 var eligible: Array=songs(state);var selected: Array=[];var seen: Dictionary={}
 for id in ids:
  if not id is String or str(id).is_empty() or seen.has(id):return _bad("Each selected original needs a unique completed-song ID.")
  var matches: Array=[]
  for song in eligible:
   if song["id"]==id:matches.append(song)
  if matches.size()!=1:return _bad("A selected original is missing, ambiguous or has no complete source identity. Choose current finished songs.")
  selected.append(matches[0].duplicate(true));seen[id]=true
 return {"ok":true,"songs":selected,"message":""}
static func _guard(state: Dictionary, recording: bool) -> Dictionary:
 var commitment: Dictionary=Booking.guard_commitment(state,"recording",2 if recording else 1)
 if not bool(commitment.get("ok",false)):return commitment
 var valid: Dictionary=validate(state)
 if not bool(valid.get("ok",false)):return valid
 valid=Finance.guard(state)
 if not bool(valid.get("ok",false)):return valid
 var booking: Dictionary=Calendar.pending(state)
 if not booking.is_empty():
  if not _number(booking.get("day",0),1):return _bad("The pending show date needs validation before studio time.")
  var today: int=int(state.get("tour_day",1));var date: int=int(booking["day"])
  if date==today:return _bad("Tonight's show comes first. Finish or cancel it before studio work.")
  if recording and date>today and date<=today+Original.RECORD_DAYS:return _bad("These two studio days overlap your booked show. Finish or cancel that booking first.")
 return {"ok":true,"message":""}
static func _account(before: Dictionary, raw: Dictionary, action: String, cost: int, closes: Array, index: int) -> Dictionary:
 var after: Dictionary=Life.refresh(Calendar.expire(Story.observe(before,raw,"recording" if action=="recording:record" else "release")))
 var rows: Array=[{"direction":"outgoing","category":"Other","amount":cost}]
 var accounted: Dictionary=Finance.apply(before,after,action,rows,closes)
 if not bool(accounted.get("ok",false)):return _fail(before,str(accounted.get("message","The studio accounts could not be reconciled.")))
 after=accounted["state"]
 var session: Dictionary=after["recordings"][index].duplicate(true)
 return {"ok":true,"state":after,"message":str(raw.get("_recording_result_message","")),"session":session,"demo_id":str(session.get("id","")),"session_index":index,"closing_balances":closes.duplicate(true),"finance_action":action}
static func preview(state: Dictionary, ids: Array) -> Dictionary:
 # Simulation only: all original adapters/Finance are pure and the returned
 # candidate is never applied or saved by this method.
 return record(state,ids)
static func record(state: Dictionary, ids: Array) -> Dictionary:
 var guard: Dictionary=_guard(state,true)
 if not bool(guard.get("ok",false)):return _fail(state,str(guard["message"]))
 var eligible: Dictionary=Original.can_record(state)
 if not bool(eligible.get("ok",false)):return _fail(state,str(eligible.get("message","The studio is not available.")))
 var chosen: Dictionary=_selection(state,ids)
 if not bool(chosen.get("ok",false)):return _fail(state,str(chosen["message"]))
 var selected: Array=chosen["songs"]
 var original_recordings: Array=state.get("recordings",[])
 var full_catalogue: Array=state.get("song_catalogue",[])
 var demo_id: String="demo:%d:%d" % [int(state.get("tour_day",1)),full_catalogue.size()]
 for old in original_recordings:
  if str(old.get("id",""))==demo_id:return _fail(state,"This studio session identifier is already recorded.")
 var projection: Dictionary=state.duplicate(true);projection["song_catalogue"]=selected.duplicate(true);projection["recordings"]=[]
 var result: Dictionary=Original.record(projection)
 if not bool(result.get("ok",false)):return _fail(state,str(result.get("message","The original studio session was rejected.")))
 var after: Dictionary=result["state"]
 var session: Dictionary=after["recordings"][0].duplicate(true)
 session["id"]=demo_id;session["source_count"]=full_catalogue.size()
 session[LINK_KEY]={"version":VERSION,"song_ids":ids.duplicate(true),"snapshots":selected.duplicate(true)}
 var archive: Array=original_recordings.duplicate(true);archive.append(session)
 after["recordings"]=archive;after["song_catalogue"]=full_catalogue.duplicate(true)
 after["demos"]=maxi(int(state.get("demos",0)),archive.size())
 var closes: Array=[int(after["cash"]),int(after["cash"])]
 # Carry authored text separately, never add a transient field to career state.
 var accounted: Dictionary=_account(state,after,"recording:record",Original.DEMO_COST,closes,archive.size()-1)
 if bool(accounted.get("ok",false)):accounted["message"]=str(result.get("message","Recorded."))
 return accounted
static func preview_release(state: Dictionary, id: String, expected_fingerprint: String="", expected_index: int=-1) -> Dictionary:
 return release(state,id,expected_fingerprint,expected_index)
static func release(state: Dictionary, id: String, expected_fingerprint: String="", expected_index: int=-1) -> Dictionary:
 var guard: Dictionary=_guard(state,false)
 if not bool(guard.get("ok",false)):return _fail(state,str(guard["message"]))
 var archive: Array=state.get("recordings",[]);var index: int=-1
 if id.is_empty():
  if expected_index<0 or expected_index>=archive.size() or not str(archive[expected_index].get("id","")).is_empty() or expected_fingerprint.is_empty():return _fail(state,"Choose the exact unlinked legacy recording again before releasing it.")
  index=expected_index
 else:
  for candidate in range(archive.size()):
   if str(archive[candidate].get("id",""))==id:
    if index>=0:return _fail(state,"The selected recording identifier is ambiguous.")
    index=candidate
 if index<0:return _fail(state,"Choose a recorded demo to release.")
 if not expected_fingerprint.is_empty() and fingerprint(archive[index])!=expected_fingerprint:return _fail(state,"This recording changed after it was selected. Review the saved demo again.")
 var result: Dictionary=Original.release(state,index)
 if not bool(result.get("ok",false)):return _fail(state,str(result.get("message","The original release was rejected.")))
 var after: Dictionary=result["state"];var closes: Array=[int(after["cash"])]
 var accounted: Dictionary=_account(state,after,"recording:release",Original.RELEASE_COST,closes,index)
 if bool(accounted.get("ok",false)):accounted["message"]=str(result.get("message","Released."))
 return accounted
