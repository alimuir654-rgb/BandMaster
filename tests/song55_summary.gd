extends SceneTree
## Independent saved-fact counterexamples. No file IO or owner transactions.
const Summary = preload("res://experiments/playable_flightcase/song_summary.gd")
const Rules = preload("res://experiments/playable_flightcase/recording_rules.gd")
const ShowFlow = preload("res://experiments/playable_flightcase/show_flow.gd")

const READY := "Preparation not tracked for this version/line-up."
const REACH := "Not tracked."
const RECORDED := "Recorded; execution quality not tracked."
const INCOMPLETE := "Recording history not fully linked."
const NO_TAKE := "No linked take in the saved archive."
const NO_ID := "Song ID missing or ambiguous."
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
 _strength_values()
 _identity_boundaries()
 _recording_absence()
 _captured_identity()
 _malformed_recordings()
 _drafts()
 _ownership_and_saved_context()
 _legacy_song_notes()
 _completed_live_evidence()
 print("SONG55_SUMMARY_RESULT " + JSON.stringify({"ok":failures.is_empty(),"checks":checks,"failures":failures}))
 quit(0 if failures.is_empty() else 1)

func _check(ok: bool, message: String) -> bool:
 checks += 1
 if not ok:
  failures.append(message)
  push_error("SONG55_SUMMARY: " + message)
 return ok

func _song(id: String="original:1", title: String="AFTER THE LAST BUS", quality: Variant=72) -> Dictionary:
 return {"id":id,"title":title,"quality":quality,"lead_writer":"Maya","credited_writers":["Maya","Freya"],"origin":"Lyric","arrangement":"Slow Build","written_day":8,"writing_sessions":[{"day":6,"leader":"Maya","idea":"Lyric","form":"Slow Build"},{"day":7,"leader":"Freya","idea":"Groove","form":"Slow Build"},{"day":8,"leader":"Maya","idea":"Lyric","form":"Slow Build"}],"unknown_extension":{"retain":[1,2.5,{"flag":true}]}}

func _state(song: Dictionary) -> Dictionary:
 return {"song_catalogue":[song.duplicate(true)],"recordings":[],"demos":0,"readiness":99,"fans":480,"buzz":80,"press":70,"cash":250,"tour_day":10,"unknown_state":{"retain":[3.25,{"flag":false}]}}

func _current(state: Dictionary, song: Dictionary, label: String) -> Dictionary:
 var state_before: PackedByteArray = var_to_bytes(state)
 var song_before: PackedByteArray = var_to_bytes(song)
 var result: Dictionary = Summary.current(state,song)
 _check(var_to_bytes(state)==state_before,label+": caller state unchanged byte-for-byte")
 _check(var_to_bytes(song)==song_before,label+": supplied song unchanged byte-for-byte")
 _shape(result,label)
 return result

func _capture(recording: Dictionary, index: int, label: String) -> Dictionary:
 var before: PackedByteArray = var_to_bytes(recording)
 var result: Dictionary = Summary.captured(recording,index)
 _check(var_to_bytes(recording)==before,label+": captured recording unchanged byte-for-byte")
 _shape(result,label)
 return result

func _shape(row: Dictionary, label: String) -> void:
 for field in ["title","strength","credits","origin","arrangement","finish","readiness","recording","reach","evidence","identity"]:
  _check(row.has(field) and row[field] is String,label+": String "+field)
 _check(row.get("known_strength") is bool,label+": boolean known_strength")
 _check(row.has("quality") and (row["quality"]==null or row["quality"] is int),label+": quality is owned integer or null")
 _check(row.get("history") is Array,label+": history array")
 if row.get("history") is Array:
  for line in row["history"]:
   _check(line is String,label+": history contains only strings")
 _check(row.get("readiness")==READY,label+": no global-readiness substitution")
 _check(row.get("reach")==REACH,label+": no fan/buzz/press substitution")

func _strength_values() -> void:
 for pair in [[0,"NEEDS WORK"],[44,"NEEDS WORK"],[45,"PROMISING"],[69,"PROMISING"],[70,"STRONG"],[100,"STRONG"],[72.0,"STRONG"]]:
  var song: Dictionary = _song("original:1","BOUNDARY",pair[0])
  var view: Dictionary = _current(_state(song),song,"quality "+str(pair[0]))
  _check(view.get("known_strength")==true,"supported quality is known: "+str(pair[0]))
  _check(view.get("quality")==int(pair[0]) and typeof(view.get("quality"))==TYPE_INT,"whole float accepted as display integer")
  _check(view.get("strength")=="SONG STRENGTH · %d / 100 · %s" % [int(pair[0]),str(pair[1])],"literal strength bands at "+str(pair[0]))
  _check(not str(view.get("strength","")).contains("SETLIST READY"),"strength never promises preparation")
 var invalid: Array = [null,true,false,"72",72.5,-1,101,NAN,INF,-INF,{},[]]
 for value in invalid:
  var song: Dictionary = _song("original:1","INVALID",value)
  var view: Dictionary = _current(_state(song),song,"invalid quality "+str(value))
  _check(view.get("known_strength")==false and view.get("quality")==null,"invalid quality stays unknown: "+str(value))
  _check(view.get("strength")=="SONG STRENGTH · UNKNOWN","invalid quality not defaulted or clamped")
 var missing: Dictionary = _song()
 missing.erase("quality")
 var absent: Dictionary = _current(_state(missing),missing,"absent quality")
 _check(absent.get("known_strength")==false and absent.get("quality")==null,"absent quality is not a zero score")

func _recording(first: Dictionary, second: Dictionary, id: String="demo:10:2") -> Dictionary:
 # Literal existing RecordingRules contract: no new scoring model or save.
 return {"id":id,"day":12,"source_count":2,"quality":int(round(float(int(first["quality"])+int(second["quality"]))/2.0)),"released":false,"tracks":[{"title":first["title"],"quality":first["quality"]},{"title":second["title"],"quality":second["quality"]}],"song_links_v1":{"version":1,"song_ids":[first["id"],second["id"]],"snapshots":[first.duplicate(true),second.duplicate(true)]},"unknown_recording":{"retain":[8,8.5]}}

func _linked_state(song: Dictionary, recording: Dictionary) -> Dictionary:
 var state: Dictionary = _state(song)
 state["demos"] = 1
 state["recordings"] = [recording.duplicate(true)]
 return state

func _identity_boundaries() -> void:
 var first: Dictionary = _song("original:1","SAME TITLE",72)
 var second: Dictionary = _song("original:2","SAME TITLE",44)
 var third: Dictionary = _song("original:3","OTHER TRACK",64)
 var take: Dictionary = _recording(first,third)
 if not _check(Rules._session_valid(take),"handcrafted linked recording passes original validator"):return
 var state: Dictionary = _linked_state(first,take)
 state["song_catalogue"].append(second.duplicate(true))
 state["song_catalogue"].append(third.duplicate(true))
 _check(_current(state,first,"same title first").get("recording")==RECORDED,"recorded first ID recognised")
 _check(_current(state,second,"same title second").get("recording")==NO_TAKE,"same-title second ID receives no first-song take")
 var renamed: Dictionary = first.duplicate(true)
 renamed["title"] = "RENAMED LATER"
 renamed["quality"] = 99
 state["song_catalogue"][0] = renamed.duplicate(true)
 var after: Dictionary = _current(state,renamed,"renamed current song")
 _check(after.get("recording")==RECORDED and after.get("quality")==99,"rename/upgrade retains identity without replacing current strength")
 var duplicate: Dictionary = state.duplicate(true)
 duplicate["song_catalogue"].append(renamed.duplicate(true))
 var ambiguous: Dictionary = _current(duplicate,renamed,"duplicate current ID")
 _check(ambiguous.get("identity")==NO_ID,"duplicate current IDs explicitly ambiguous")
 _check(ambiguous.get("recording")!=RECORDED,"ambiguous catalogue cannot acquire attributed recording")
 _check(ambiguous.get("quality")==99,"ambiguity does not erase directly supplied saved strength")
 for value in ["",null,1,true]:
  var orphan: Dictionary = first.duplicate(true)
  orphan["id"] = value
  var invalid_state: Dictionary = _linked_state(orphan,take)
  var view: Dictionary = _current(invalid_state,orphan,"invalid ID "+str(value))
  _check(view.get("identity")==NO_ID,"non-string/empty ID remains unknown")
  _check(view.get("recording")!=RECORDED,"invalid ID cannot title-join to a recording")
 var absent_id: Dictionary = first.duplicate(true)
 absent_id.erase("id")
 _check(_current(_state(absent_id),absent_id,"missing ID").get("identity")==NO_ID,"missing ID explicitly identified")

func _recording_absence() -> void:
 var song: Dictionary = _song()
 var state: Dictionary = _state(song)
 _check(_current(state,song,"known zero history").get("recording")=="Not recorded.","only explicit zero/full-empty history proves no recording")
 var scenarios: Array = []
 var legacy_count: Dictionary = state.duplicate(true)
 legacy_count["demos"] = 2
 scenarios.append(legacy_count)
 var absent_archive: Dictionary = legacy_count.duplicate(true)
 absent_archive.erase("recordings")
 scenarios.append(absent_archive)
 var absent_count: Dictionary = state.duplicate(true)
 absent_count.erase("demos")
 scenarios.append(absent_count)
 var missing_empty_archive: Dictionary = state.duplicate(true)
 missing_empty_archive.erase("recordings")
 scenarios.append(missing_empty_archive)
 for value in [true,"0",0.5,-1,NAN]:
  var invalid_count: Dictionary = state.duplicate(true)
  invalid_count["demos"] = value
  scenarios.append(invalid_count)
 for value in [null,{},"legacy"]:
  var invalid_archive: Dictionary = state.duplicate(true)
  invalid_archive["recordings"] = value
  scenarios.append(invalid_archive)
 var unlinked: Dictionary = state.duplicate(true)
 unlinked["demos"] = 1
 unlinked["recordings"] = [{"id":"legacy-demo","tracks":[{"title":song["title"],"quality":72}],"quality":72}]
 scenarios.append(unlinked)
 for index in range(scenarios.size()):
  var view: Dictionary = _current(scenarios[index],song,"incomplete history "+str(index))
  _check(view.get("recording")==INCOMPLETE,"legacy/malformed history cannot prove absence: "+str(index))
  _check(not str(view.get("recording","")).contains("Not recorded"),"incomplete history never says not recorded")

func _captured_identity() -> void:
 var first: Dictionary = _song("original:1","OLD TITLE",72)
 var second: Dictionary = _song("original:2","SECOND",44)
 var take: Dictionary = _recording(first,second)
 if not _check(Rules._session_valid(take),"captured fixture passes existing rule"):return
 var view: Dictionary = _capture(take,0,"valid capture")
 _check(view.get("title")=="OLD TITLE" and view.get("quality")==72,"captured title/quality come from immutable snapshot")
 _check(view.get("strength")=="CAPTURED SONG STRENGTH · 72 / 100 · STRONG","captured composition explicitly distinct from studio execution")
 _check(view.get("recording")==RECORDED,"captured row never calls copied score execution quality")
 var next: Dictionary = _capture(take,1,"second capture")
 _check(next.get("title")=="SECOND" and next.get("quality")==44,"captured order follows exact saved link index")
 first["title"] = "CURRENT TITLE"
 first["quality"] = 99
 _check(_capture(take,0,"capture after external edit").get("quality")==72,"editing current source cannot upgrade captured value")
 for index in [-1,2,20]:
  var invalid: Dictionary = _capture(take,index,"invalid capture index "+str(index))
  _check(invalid.get("known_strength")==false and invalid.get("quality")==null,"out-of-range capture has no fabricated score")
 var legacy: Dictionary = {"tracks":[{"title":"OLD TITLE","quality":72}],"quality":72}
 var unknown: Dictionary = _capture(legacy,0,"unlinked legacy capture")
 _check(unknown.get("known_strength")==false and unknown.get("quality")==null,"legacy raw value is not verified captured composition")
 _check(unknown.get("recording")==RECORDED or unknown.get("recording")==INCOMPLETE,"actual legacy track disclosed without invented execution score")

func _malformed_recordings() -> void:
 var song: Dictionary = _song()
 var other: Dictionary = _song("original:2","SECOND",44)
 var take: Dictionary = _recording(song,other)
 var variants: Array = []
 var mismatch: Dictionary = take.duplicate(true)
 mismatch["song_links_v1"]["snapshots"][0]["quality"] = 99
 variants.append(mismatch)
 var wrong_id: Dictionary = take.duplicate(true)
 wrong_id["song_links_v1"]["snapshots"][0]["id"] = "original:999"
 variants.append(wrong_id)
 var changed_track: Dictionary = take.duplicate(true)
 changed_track["tracks"][0]["title"] = "UNRELATED"
 variants.append(changed_track)
 var wrong_average: Dictionary = take.duplicate(true)
 wrong_average["quality"] = 99
 variants.append(wrong_average)
 var future_version: Dictionary = take.duplicate(true)
 future_version["song_links_v1"]["version"] = 2
 variants.append(future_version)
 var duplicate_id: Dictionary = take.duplicate(true)
 duplicate_id["song_links_v1"]["song_ids"][1] = song["id"]
 variants.append(duplicate_id)
 for index in range(variants.size()):
  var broken: Dictionary = variants[index]
  _check(not Rules._session_valid(broken),"negative fixture rejected by original validator "+str(index))
  var state: Dictionary = _linked_state(song,broken)
  var current: Dictionary = _current(state,song,"corrupt links "+str(index))
  _check(current.get("recording")==INCOMPLETE,"malformed linked row cannot create recording proof")
  var captured: Dictionary = _capture(broken,0,"corrupt capture "+str(index))
  _check(captured.get("known_strength")==false and captured.get("quality")==null,"malformed capture never repairs or falls back to raw track score")
 var duplicate_archive: Dictionary = _linked_state(song,take)
 duplicate_archive["recordings"].append(take.duplicate(true))
 duplicate_archive["demos"] = 2
 _check(_current(duplicate_archive,song,"duplicate demo identity").get("recording")==INCOMPLETE,"duplicate recording IDs cannot masquerade as separate takes")
 var truncated_archive: Dictionary = _linked_state(song,take)
 truncated_archive["demos"] = 2
 var unrecorded: Dictionary = _song("original:3","NEW",65)
 truncated_archive["song_catalogue"].append(unrecorded.duplicate(true))
 _check(_current(truncated_archive,unrecorded,"count exceeds archive").get("recording")==INCOMPLETE,"missing retained demos prevent confident negative attribution")

func _drafts() -> void:
 var state: Dictionary = {"current_song_draft":{"title":"UNFINISHED","leader":"Maya","idea":"Lyric","form":"Slow Build","sessions":[{"day":4},{"day":5}],"quality":99},"song_draft_progress":2,"readiness":100,"fans":999}
 var before: PackedByteArray = var_to_bytes(state)
 var view: Dictionary = Summary.draft(state)
 _shape(view,"two-session draft")
 _check(var_to_bytes(state)==before,"draft read preserves every input byte")
 _check(view.get("title")=="UNFINISHED","draft title is actual saved draft")
 _check(str(view.get("credits","")).contains("Maya"),"actual draft leader is retained")
 _check(view.get("known_strength")==false and view.get("quality")==null,"unfinished draft never has finished score even if stray quality exists")
 var progress: String = str(view.get("strength","")).to_upper()
 _check(progress.contains("DRAFT") and progress.contains("2") and progress.contains("3") and not progress.contains("100"),"draft says saved progress, not a finished percentage")
 var legacy: Dictionary = {"song_draft_progress":1,"current_song_draft":{"title":"LEGACY DRAFT","leader":"Maya"}}
 var legacy_before: PackedByteArray = var_to_bytes(legacy)
 var old: Dictionary = Summary.draft(legacy)
 _check(old.get("known_strength")==false and old.get("quality")==null,"legacy draft never gets composition score")
 _check(var_to_bytes(legacy)==legacy_before,"legacy progress does not migrate draft")
 for raw in [null,[],"bad"]:
  var malformed: Dictionary = {"current_song_draft":raw,"song_draft_progress":2}
  var malformed_before: PackedByteArray = var_to_bytes(malformed)
  var unknown: Dictionary = Summary.draft(malformed)
  _check(not bool(unknown.get("known_strength",false)) and unknown.get("quality")==null,"malformed draft gives no score")
  _check(var_to_bytes(malformed)==malformed_before,"malformed draft retained, never repaired")

func _ownership_and_saved_context() -> void:
 var song: Dictionary = _song("original:1","À TRAVERS LA NUIT — VERY LONG SAVED ORIGINAL TITLE",72)
 var state: Dictionary = _state(song)
 var before: PackedByteArray = var_to_bytes(state)
 var view: Dictionary = _current(state,song,"owned history")
 _check(view.get("title")==song["title"],"full Unicode title retained")
 _check(str(view.get("credits","")).contains("Maya") and str(view.get("credits","")).contains("Freya"),"saved credited writers retained")
 _check(str(view.get("origin","")).contains("Lyric") and str(view.get("arrangement","")).contains("Slow Build"),"saved creative context retained")
 _check(str(view.get("finish","")).contains("8"),"saved finish day retained")
 var second: Dictionary = Summary.current(state,song)
 var second_before: PackedByteArray = var_to_bytes(second)
 if view.get("history") is Array:
  _check(not view["history"].is_empty(),"saved writing history surfaced")
  if not view["history"].is_empty():view["history"][0]="CHANGED RETURN VALUE"
  view["history"].append("ADDED RETURN VALUE")
 _check(var_to_bytes(state)==before,"mutating returned history never aliases caller state")
 _check(var_to_bytes(second)==second_before,"separate descriptors own independent history arrays")
 state["readiness"] = 1
 state["fans"] = 0
 state["buzz"] = 0
 state["press"] = 0
 var low: Dictionary = _current(state,song,"changed current band state")
 _check(low.get("quality")==72 and low.get("readiness")==READY and low.get("reach")==REACH,"today's band stats never rewrite composition/preparation/listens")
 state["cash"] = "unrelated invalid finance"
 var unrelated: Dictionary = _current(state,song,"unrelated bad cash")
 _check(unrelated.get("known_strength")==true and unrelated.get("quality")==72,"display does not run unrelated finance guard")

func _live_state(song: Dictionary) -> Dictionary:
 # Explicit saved receipt, checked with original ShowFlow. No forecast exposed.
 var state: Dictionary = _state(song)
 var plan: Dictionary = {"approach":"tight","intensity":50,"song_ids":[song["id"]],"song_snapshots":[song.duplicate(true)],"shoutout":"none","shoutout_venue_id":""}
 var projection: Dictionary = {"legacy":false,"selected_count":1,"intensity_value":50,"intensity_band":"STEADY","intensity_quality":0,"set_shape_quality":1,"shoutout_quality":0,"quality_modifier":1,"successful_extra_fans":0,"extra_fatigue":3,"extra_tension":0,"originals_modifier":-10,"chemistry_bonus":0,"gear_penalty":0,"journey_bonus":0,"effective_readiness":60,"quality_estimate":60,"threshold":52,"reliability_margin":8}
 var id: String = "s53:booking:local:12"
 var row: Dictionary = {"version":1,"id":id,"booking_id":id,"seq":1,"venue_id":"local","venue":"THE LANTERN","city":"BRISTOL","scheduled_day":12,"completed_day":13,"day_before":12,"day_after":13,"cash_before":100,"cash_after":110,"settled_fee":10,"success":true,"originals_played":1,"plan":plan,"projection":projection,"message":"Saved whole-show result."}
 row["responses"] = ShowFlow._responses(row)
 state["show_receipts_v1"] = {"version":1,"seq":1,"seen_ids":{id:1},"records":[row]}
 return state

func _legacy_song_notes() -> void:
 var song: Dictionary=_song()
 song["live_reception"]="Great crowd response"
 song.erase("id")
 var view: Dictionary=_current(_state(song),song,"legacy song note with no ID")
 _check(view.get("legacy_note")=="Great crowd response","supported legacy song note remains available verbatim")
 _check(not str(view["evidence"]).contains("Great crowd response"),"undated note is separate from identity-linked evidence")
 for value in [null,42,{},[]]:
  song["live_reception"]=value
  _check(Summary.current(_state(song),song).get("legacy_note")=="","malformed note is not invented prose")

func _completed_live_evidence() -> void:
 var song: Dictionary = _song()
 var state: Dictionary = _live_state(song)
 if not _check(bool(ShowFlow._validate_records(state).get("ok",false)),"literal saved show fixture accepted by original validator"):return
 var view: Dictionary = _current(state,song,"completed live receipt")
 var evidence: String = str(view.get("evidence","")).to_upper()
 _check(evidence.contains("THE LANTERN") and evidence.contains("12"),"actual completed receipt venue/scheduled day shown")
 _check(view.get("reach")==REACH,"completed show still cannot invent listening count")
 var journey: Dictionary=state.duplicate(true)
 var receipt: Dictionary=journey["show_receipts_v1"]["records"][0]
 receipt["journey_v1"]={"version":1,"kind":"modelled_live_journey","content_version":1,"policy_version":1,"completed_ids":[song["id"]],"plan":receipt["plan"].duplicate(true)}
 _check(str(_current(journey,song,"completed journey identity")["evidence"]).contains("THE LANTERN"),"supported completed journey retains venue evidence")
 receipt["journey_v1"]["version"]=99
 _check(not str(_current(journey,song,"unknown future journey")["evidence"]).contains("THE LANTERN"),"future journey semantics do not acquire a past performance claim")
 var same_title: Dictionary = _song("original:2",song["title"],72)
 state["song_catalogue"].append(same_title.duplicate(true))
 _check(not str(_current(state,same_title,"live same-title other ID").get("evidence","")).contains("THE LANTERN"),"live evidence never joined by title")
 state["cash"] = "invalid unrelated cash"
 _check(str(_current(state,song,"live invalid finance").get("evidence","")).contains("THE LANTERN"),"valid receipt survives unrelated current-state finance error")
 var duplicate: Dictionary = state.duplicate(true)
 duplicate["song_catalogue"].append(song.duplicate(true))
 _check(not str(_current(duplicate,song,"live duplicate current ID").get("evidence","")).contains("THE LANTERN"),"ambiguous current ID does not claim a live association")
 var malformed: Dictionary = _live_state(song)
 malformed["show_receipts_v1"]["records"][0]["plan"]["song_snapshots"][0]["id"] = "original:99"
 _check(not bool(ShowFlow._validate_records(malformed).get("ok",false)),"mismatched live snapshot rejected by original validator")
 _check(not str(_current(malformed,song,"corrupt pinned live identity").get("evidence","")).contains("THE LANTERN"),"invalid pinned live identity is not exposed as history")
 var unfinished: Dictionary = _state(song)
 unfinished["gig_journey_v1"] = {"version":1,"sequence":1,"active":{"phase":"performing","completed_ids":[song["id"]],"venue":"THE LANTERN","plan":{"song_ids":[song["id"]],"song_snapshots":[song.duplicate(true)]},"feedback":[{"song_id":song["id"],"vibe":90,"kind":"modelled_song_response"}]}}
 _check(not str(_current(unfinished,song,"unsettled gig").get("evidence","")).contains("THE LANTERN"),"in-progress journey is never a completed show receipt")
