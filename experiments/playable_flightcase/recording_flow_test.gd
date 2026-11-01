extends SceneTree
## SCRATCH independent S54 proof. Root alone copies/runs an isolated runtime.
## Protected original Recording/Story/Calendar/Life/Finance are the oracle.
const Rules = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Original = preload("res://Scripts/recording_career.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Model = preload("res://experiments/playable_flightcase/opening_state.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const SAFE := "/workspace/work/overnight-20261101/s54/"
const LINKS := "song_links_v1"
const RECORD_ACTION := "recording:record"
const RELEASE_ACTION := "recording:release"
var output: String=SAFE+"independent-model-proof"
var checks: int=0
var failures: Array[String]=[]
var evidence: Array=[]
var base: Dictionary={}
var protected_initial: Dictionary={}
var model

func _init() -> void:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--out="):output=argument.trim_prefix("--out=")
 call_deferred("run")

func check(ok: bool, message: String) -> bool:
 checks+=1
 if not ok:
  failures.append(message)
  push_error("S54_RECORDING_TEST "+message)
 return ok

func files(protected_only: bool=false) -> Dictionary:
 var result: Dictionary={}
 var paths: Array=["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if not protected_only:paths.append(Model.SAVE_PATH)
 for path in paths:result[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result

func step(result: Variant, label: String) -> bool:
 return check(bool(result.get("ok",false)) if result is Dictionary else bool(result),"actual C27 fixture: "+label)

func fixture() -> bool:
 model=Model.new()
 if not step(model.begin_new(),"begin") or not step(model.set_genre("Indie rock"),"genre") or not step(model.to_recruit(),"recruit"):return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not step(model.recruit(id),str(id)):return false
 if not step(model.choose_vocal("cast_jack"),"lead") or not step(model.confirm_lineup(),"lineup"):return false
 if not step(model.start_naming(),"name phase") or not step(model.submit_name("QA RECORDED ORIGINALS","Raw"),"name") or not step(model.lock_name(),"name lock"):return false
 if not step(model.start_identity(),"identity") or not step(model.set_identity("Wordmark","Amber / Charcoal","Unpolished"),"identity choice") or not step(model.finish_identity(),"identity done") or not step(model.start_playing(),"play"):return false
 for song_number in range(1,4):
  for session in range(3):
   if not step(model.game.write_session("Riff","Verse / Chorus","QA RECORDING SONG %d" % song_number,0),"genuine completed original"):return false
 base=model.game.career.duplicate(true)
 if not check(int(base.get("songs",0))==3 and (base.get("song_catalogue",[]) as Array).size()==3,"nine original model sessions produce three actual stable IDs"):return false
 for index in range(3):
  if not check(str(base["song_catalogue"][index].get("id",""))=="original:%d" % (index+1),"source completed ID is authored by original model"):return false
 return check(model.save_draft(),"save initial genuine C27 catalogue")

func state_fixture() -> Dictionary:
 # Numeric QA clone: source IDs/credits/history are genuine, qualities explicit.
 var state: Dictionary=base.duplicate(true)
 for index in range(3):
  state["song_catalogue"][index]["quality"]=[55,70,85][index]
  state["song_catalogue"][index]["qa_unknown_song"]={"preserve":[index,{"credit":"original"}]}
 state["qa_unknown_career"]={"preserve":[11,{"nested":true}]}
 return state

func selected_snapshots(state: Dictionary, ids: Array) -> Array:
 var result: Array=[]
 for id in ids:
  for song in state.get("song_catalogue",[]):
   if song is Dictionary and song.get("id")==id:
    result.append(song.duplicate(true))
    break
 return result

func post(before: Dictionary, after: Dictionary) -> Dictionary:
 return Life.refresh(Calendar.expire(Story.observe(before,after)))

func record_oracle(before: Dictionary, ids: Array) -> Dictionary:
 # Selection changes only the declared original-recording projection.
 var eligible: Dictionary=Original.can_record(before)
 if not bool(eligible.get("ok",false)):return eligible
 var selected: Array=selected_snapshots(before,ids)
 var temporary: Dictionary=before.duplicate(true)
 temporary["song_catalogue"]=selected.duplicate(true)
 temporary["recordings"]=[]
 var raw: Dictionary=Original.record(temporary)
 if not bool(raw.get("ok",false)):return raw
 var after: Dictionary=raw["state"].duplicate(true)
 var session: Dictionary=after["recordings"].back().duplicate(true)
 var total: int=(before.get("song_catalogue",[]) as Array).size()
 session["id"]="demo:%d:%d" % [int(before.get("tour_day",1)),total]
 session["source_count"]=total
 session[LINKS]={"version":1,"song_ids":ids.duplicate(true),"snapshots":selected.duplicate(true)}
 var history: Array=before.get("recordings",[]).duplicate(true)
 history.append(session.duplicate(true))
 after["recordings"]=history
 after["song_catalogue"]=before["song_catalogue"].duplicate(true)
 after["demos"]=maxi(int(before.get("demos",0)),history.size())
 after=post(before,after)
 var closes: Array=[int(after["cash"]),int(after["cash"])]
 var rows: Array=[{"direction":"outgoing","category":"Other","amount":60}]
 var accounted: Dictionary=Finance.apply(before,after,RECORD_ACTION,rows,closes)
 if not bool(accounted.get("ok",false)):return accounted
 return {"ok":true,"state":accounted["state"],"session":session,"message":str(raw.get("message","")),"closing_balances":closes}

func release_oracle(before: Dictionary, id: String, expected_index: int=-1) -> Dictionary:
 var history: Array=before.get("recordings",[])
 var index: int=expected_index if id.is_empty() else -1
 if not id.is_empty():
  for i in range(history.size()):
   if history[i] is Dictionary and history[i].get("id")==id:index=i
 var raw: Dictionary=Original.release(before,index)
 if not bool(raw.get("ok",false)):return raw
 var after: Dictionary=post(before,raw["state"])
 var closes: Array=[int(after["cash"])]
 var rows: Array=[{"direction":"outgoing","category":"Other","amount":25}]
 var accounted: Dictionary=Finance.apply(before,after,RELEASE_ACTION,rows,closes)
 if not bool(accounted.get("ok",false)):return accounted
 return {"ok":true,"state":accounted["state"],"message":str(raw.get("message","")),"closing_balances":closes}

func rejected(result: Dictionary, before: Dictionary, label: String) -> void:
 check(not bool(result.get("ok",true)) and not str(result.get("message","")).is_empty(),label+": explicit rejection")
 if result.has("state"):check(result["state"]==before,label+": full failure state remains unchanged")

func case_queries_and_order() -> void:
 var state: Dictionary=state_fixture()
 var before: Dictionary=state.duplicate(true)
 var disk: Dictionary=files()
 check(bool(Rules.validate(state).get("ok",false)),"fresh canonical state validates without recording metadata")
 var songs: Array=Rules.songs(state)
 check(songs.size()==3 and songs[0].get("id")=="original:1","songs query exposes actual completed IDs")
 if not songs.is_empty():songs[0]["title"]="MUTATED QUERY COPY"
 var ids: Array=["original:2","original:1"]
 var preview: Dictionary=Rules.preview(state,ids)
 var expected: Dictionary=record_oracle(state,ids)
 if not check(bool(preview.get("ok",false)) and bool(expected.get("ok",false)),"free ordered preview is available"):return
 check(preview.get("state")==expected.get("state"),"preview exact state uses original rules and one declared Finance checkpoint")
 check(state==before and files()==disk,"query/preview leaves actual caller and every save byte unchanged")
 var recorded: Dictionary=Rules.record(state,ids)
 if not check(bool(recorded.get("ok",false)),"record two selected real originals"):return
 var after: Dictionary=recorded["state"]
 var session: Dictionary=recorded.get("session",{})
 check(after==expected["state"],"full independent original projection/post-chain/accounting equals owned result")
 check(recorded.get("finance_action")==RECORD_ACTION and recorded.get("closing_balances")==[190,190],"record declares upfront60 and two explicit daily closing balances")
 check(int(after["cash"])==190 and int(after["tour_day"])==int(state["tour_day"])+2,"original recording cash/day economy is unchanged")
 check(int(session.get("quality",-1))==63 and session.get("tracks",[])[0].get("title")==state["song_catalogue"][1]["title"] and session.get("tracks",[])[1].get("title")==state["song_catalogue"][0]["title"],"55/70 half-up mean63 and chosen order are independent numeric facts")
 check(session.get("id")=="demo:%d:3" % int(state["tour_day"]) and int(session.get("source_count",0))==3,"record identity and new-material gate use FULL canonical source count")
 check(session.get(LINKS,{})=={"version":1,"song_ids":ids,"snapshots":selected_snapshots(state,ids)},"additive links pin full creative snapshots in selected order")
 check(after["song_catalogue"]==before["song_catalogue"] and after["qa_unknown_career"]==before["qa_unknown_career"],"original catalogue/credits/unknown nested career data are restored exactly")
 var triple_ids: Array=["original:3","original:1","original:2"]
 var triple: Dictionary=Rules.record(state,triple_ids)
 var triple_expected: Dictionary=record_oracle(state,triple_ids)
 check(bool(triple.get("ok",false)) and triple.get("state")==triple_expected.get("state") and int(triple.get("session",{}).get("quality",-1))==70,"three ordered real originals preserve independent mean70 and whole original state")
 var account: Dictionary=Finance.view(after)
 check(int(account["seq"])==int(Finance.view(state)["seq"])+1 and int(account["totals"]["outgoing"]["Other"])==60,"one recording appends one Finance checkpoint and only original60 outgoing")
 var latest: Dictionary=(account["history"] as Array).back()
 check(latest.get("closing_balances")==[190,190] and int(latest.get("income",-1))==0 and int(latest.get("outgoing",-1))==60,"ledger stores each completed day and no invented income")
 var fingerprint: String=Rules.fingerprint(session)
 check(fingerprint==JSON.stringify(session).sha256_text(),"fingerprint is stable whole-session JSON SHA256")
 var changed: Dictionary=session.duplicate(true)
 changed["qa_unknown_session"]={"nested":[1,2]}
 check(Rules.fingerprint(changed)!=fingerprint,"fingerprint includes optional unknown nested content")
 var queried: Array=Rules.sessions(after)
 queried[0]["tracks"][0]["title"]="MUTATED ARCHIVE COPY"
 check(after==expected["state"] and Rules.fingerprint(session)==fingerprint,"archive and fingerprint queries expose no aliases or mutations")
 var edited: Dictionary=after.duplicate(true)
 edited["song_catalogue"][1]["title"]="LATER CREATIVE EDIT"
 edited["song_catalogue"][1]["quality"]=1
 check(edited["recordings"][0][LINKS]["snapshots"][0]==before["song_catalogue"][1] and edited["recordings"][0]["tracks"]==session["tracks"],"recorded snapshots remain immutable after later catalogue edits")
 check(bool(Rules.validate(edited).get("ok",false)) and Rules.sessions(edited)[0][LINKS]==session[LINKS],"historical snapshots validate independently of later current catalogue changes")
 evidence.append({"case":"independent ordered recording","before":state,"after":after})

func case_selection_and_malformed() -> void:
 var state: Dictionary=state_fixture()
 var disk: Dictionary=files()
 for ids in [[],["original:1"],["original:1","original:1"],["original:1","missing"],[1,"original:2"],["original:1","original:2","original:3","missing"]]:
  var before: Dictionary=state.duplicate(true)
  rejected(Rules.record(state,ids),before,"invalid selected IDs "+str(ids))
  check(state==before,"invalid selection never mutates actual input")
 var insufficient: Dictionary=state.duplicate(true)
 insufficient["cash"]=59
 rejected(Rules.record(insufficient,["original:1","original:2"]),insufficient,"cash59 cannot pay original60")
 var bad_states: Array=[]
 for raw in ["bad",[17]]:
  var malformed: Dictionary=state.duplicate(true)
  malformed["recordings"]=raw
  bad_states.append(malformed)
 for malformed in bad_states:
  var immutable: Dictionary=malformed.duplicate(true)
  check(not bool(Rules.validate(malformed).get("ok",true)),"malformed known catalogue/session fields reject safely")
  rejected(Rules.record(malformed,["original:1","original:2"]),immutable,"malformed state commit")
  check(malformed==immutable,"validation never repairs or discards malformed user fields")
 # Global legacy validation need not invent IDs or rewrite old catalogue rows.
 # New selection itself must reject missing/ambiguous/malformed actual sources.
 for field in ["id","title","quality"]:
  var malformed: Dictionary=state.duplicate(true)
  malformed["song_catalogue"][0][field]=false
  var immutable: Dictionary=malformed.duplicate(true)
  rejected(Rules.record(malformed,["original:1","original:2"]),immutable,"malformed new selected source "+field)
  check(malformed==immutable,"selected-source rejection leaves full raw catalogue unchanged")
 var duplicate: Dictionary=state.duplicate(true)
 duplicate["song_catalogue"].append(duplicate["song_catalogue"][0].duplicate(true))
 rejected(Rules.record(duplicate,["original:1","original:2"]),duplicate,"ambiguous canonical song identity")
 var linked: Dictionary=Rules.record(state,["original:1","original:2"])
 if check(bool(linked.get("ok",false)),"valid linked session for known-metadata rejection fixtures"):
  for field in ["version","song_ids","snapshots"]:
   var malformed: Dictionary=linked["state"].duplicate(true)
   malformed["recordings"][0][LINKS][field]=false
   var immutable: Dictionary=malformed.duplicate(true)
   check(not bool(Rules.validate(malformed).get("ok",true)) and Rules.sessions(malformed).is_empty() and malformed==immutable,"known linked metadata types reject before archive use: "+field)
 check(files()==disk,"all failed pure selections/validation leave actual files unchanged")

func read_eligible_descriptors(state: Dictionary, label: String) -> void:
 var immutable: Dictionary=state.duplicate(true)
 var eligible: Array=Rules.songs(state)
 for index in range(eligible.size()):
  var described: Dictionary=Rules.describe_song(eligible[index])
  check(described.get("credits") is String and described.get("origin") is String and described.get("arrangement") is String and described.get("quality") is String and described.get("day") is String and described.get("notes") is Array,"owned data-only descriptor returns native facts safely: "+label)
 check(state==immutable,"data-only descriptor preserves raw source/unknown fields: "+label)

func case_literal_descriptor360() -> void:
 var defaults: Dictionary={}
 var absent: Dictionary=Rules.describe_song(defaults)
 check(absent=={"credits":"WRITING CREDITS NOT RECORDED","origin":"ORIGIN NOT RECORDED","arrangement":"ARRANGEMENT NOT RECORDED","quality":"QUALITY NOT RECORDED","day":"FINISH DATE NOT RECORDED","notes":[]},"literal descriptor defaults remain honest without fabricated credits or dates")
 var song: Dictionary={"credited_writers":["Ellis","Morgan"],"lead_writer":"Unused fallback","origin":"Riff","arrangement":"Slow Build","quality":70,"written_day":12,"writing_sessions":["ignored",{"day":3,"leader":"Ellis","idea":"Riff","form":"Loose Jam"},{"leader":"Morgan"}],"qa_unknown":{"keep":[1,{"nested":true}]}}
 var before: Dictionary=song.duplicate(true)
 var expected: Dictionary={"credits":"CREDIT: Ellis, Morgan","origin":"Riff","arrangement":"Slow Build","quality":"QUALITY 70 / 100","day":"FINISHED DAY 12","notes":["DAY 3  /  Ellis  /  Riff  /  Loose Jam","Morgan"]}
 var facts: Dictionary=Rules.describe_song(song)
 check(facts==expected and song==before,"independent literal saved facts/notes formatting preserves source unknowns")
 facts["notes"].append("MUTATED QUERY COPY")
 check(song==before and Rules.describe_song(song)==expected,"descriptor returns no aliases into source or future queries")
 var lead: Dictionary={"lead_writer":"Casey","quality":0,"written_day":0}
 var lead_facts: Dictionary=Rules.describe_song(lead)
 check(lead_facts.get("credits")=="LEAD WRITER: Casey" and lead_facts.get("quality")=="QUALITY 0 / 100" and lead_facts.get("day")=="FINISH DATE NOT RECORDED","zero-quality/date and saved lead-writer literal fallback remain distinct")
 check(Rules.describe_song({"writers":["Jack","Zoe"]}).get("credits")=="WRITERS: Jack, Zoe","legacy writer list literal fallback remains available")
 var malformed: Dictionary={"written_day":{},"quality":70,"writing_sessions":[17,{"day":{},"leader":"Ellis","idea":"Riff","form":"Slow Build"}],"qa_unknown":{"preserve":true}}
 var immutable: Dictionary=malformed.duplicate(true)
 var safe: Dictionary=Rules.describe_song(malformed)
 check(safe.get("day")=="FINISH DATE NOT RECORDED" and safe.get("quality")=="QUALITY 70 / 100" and safe.get("notes")==["Ellis  /  Riff  /  Slow Build"] and malformed==immutable,"direct malformed date descriptor safely omits invalid dates without int casts or source mutation")

func case_consumed_dates359() -> void:
 var state: Dictionary=state_fixture()
 var missing: Dictionary=state.duplicate(true)
 missing["song_catalogue"][0].erase("written_day")
 missing["song_catalogue"][0]["writing_sessions"]=["ignored legacy note",17,{"leader":"QA LEADER","qa_unknown":{"keep":[1,2]}}]
 var before: Dictionary=missing.duplicate(true)
 check(bool(Rules.validate(missing).get("ok",false)) and Rules.songs(missing).size()==3,"missing dates keep original zero defaults; non-Dictionary session entries stay ignored")
 var eligible: Array=Rules.songs(missing)
 var info: Dictionary=Rules.describe_song(eligible[0])
 check(info.get("day")=="FINISH DATE NOT RECORDED" and info.get("notes")==["QA LEADER"],"data-only positive control uses missing-date copy and ignores raw legacy entries")
 read_eligible_descriptors(missing,"missing consumed dates")
 var recorded: Dictionary=Rules.record(missing,["original:1","original:2"])
 if check(bool(recorded.get("ok",false)),"missing consumed dates remain eligible for explicit recording"):
  check(recorded["session"][LINKS]["snapshots"][0]==before["song_catalogue"][0] and missing==before,"full snapshots preserve missing-date defaults and unknown/unstructured history verbatim")
 for value in [0,0.0,2147483647]:
  var boundary: Dictionary=state.duplicate(true)
  boundary["song_catalogue"][0]["written_day"]=value
  boundary["song_catalogue"][0]["writing_sessions"]=[{"day":value,"leader":"BOUNDARY"}]
  check(bool(Rules.validate(boundary).get("ok",false)) and Rules.songs(boundary).size()==3,"finite whole consumed dates include zero and2147483647")
  read_eligible_descriptors(boundary,"bounded consumed dates")
 for value in [{},-1,0.5,"5",true,2147483648]:
  for field in ["written_day","writing_sessions"]:
   var malformed: Dictionary=state.duplicate(true)
   if field=="written_day":malformed["song_catalogue"][0][field]=value
   else:malformed["song_catalogue"][0][field]=[{"day":value,"qa_unknown":{"keep":true}}]
   var immutable: Dictionary=malformed.duplicate(true)
   check(not bool(Rules.validate(malformed).get("ok",true)) and Rules.songs(malformed).size()==2,"malformed consumed date rejected before original Sleeve conversion: "+field)
   rejected(Rules.record(malformed,["original:1","original:2"]),immutable,"malformed consumed date cannot commit")
   check(malformed==immutable,"date validation preserves malformed raw value/unknown extensions")
   read_eligible_descriptors(malformed,"filtered malformed "+field)
 for value in [INF,NAN]:
  var nonfinite: Dictionary=state.duplicate(true)
  nonfinite["song_catalogue"][0]["written_day"]=value
  # NaN is unequal to itself; avoid confusing Dictionary equality with mutation.
  check(not bool(Rules.validate(nonfinite).get("ok",true)) and Rules.songs(nonfinite).size()==2,"nonfinite consumed date cannot reach protected presentation")
 for raw in ["bad",{},17]:
  var malformed: Dictionary=state.duplicate(true)
  malformed["song_catalogue"][0]["writing_sessions"]=raw
  var immutable: Dictionary=malformed.duplicate(true)
  check(not bool(Rules.validate(malformed).get("ok",true)) and Rules.songs(malformed).size()==2,"present non-Array writing history rejects before Sleeve")
  rejected(Rules.record(malformed,["original:1","original:2"]),immutable,"malformed writing history cannot commit")
  read_eligible_descriptors(malformed,"filtered non-Array history")
 var linked: Dictionary=Rules.record(state,["original:1","original:2"])
 if check(bool(linked.get("ok",false)),"valid linked archive for historical date counterexample"):
  for field in ["written_day","writing_sessions"]:
   var malformed: Dictionary=linked["state"].duplicate(true)
   if field=="written_day":malformed["recordings"][0][LINKS]["snapshots"][0][field]={}
   else:malformed["recordings"][0][LINKS]["snapshots"][0][field]=[{"day":{}}]
   var immutable: Dictionary=malformed.duplicate(true)
   check(not bool(Rules.validate(malformed).get("ok",true)) and Rules.sessions(malformed).is_empty() and malformed==immutable,"malformed historical snapshot date blocks archive before original Sleeve use")
   rejected(Rules.preview_release(malformed,str(linked["session"]["id"])),immutable,"unsafe historical date cannot reach release preview")

func case_legacy_gate_and_release() -> void:
 var state: Dictionary=state_fixture()
 var original: Dictionary=Original.record(state)
 if not check(bool(original.get("ok",false)),"protected original records legacy automatic last-three session"):return
 var legacy: Dictionary=original["state"]
 var id: String=str(legacy["recordings"][0]["id"])
 legacy["recordings"][0]["qa_unknown_legacy"]={"keep":["credit",9]}
 var immutable: Dictionary=legacy.duplicate(true)
 check(bool(Rules.validate(legacy).get("ok",false)) and not Rules.sessions(legacy)[0].has(LINKS),"title/quality-only legacy session stays valid without fabricated song IDs")
 rejected(Rules.record(legacy,["original:1","original:2"]),legacy,"full original source-count gate prevents selection farming")
 var expected: Dictionary=release_oracle(legacy,id)
 var disk: Dictionary=files()
 var preview: Dictionary=Rules.preview_release(legacy,id,Rules.fingerprint(legacy["recordings"][0]))
 var released: Dictionary=Rules.release(legacy,id,Rules.fingerprint(legacy["recordings"][0]))
 check(preview==released and legacy==immutable and files()==disk,"release preview deep-equals real pure result without applying career or writing files")
 if not check(bool(released.get("ok",false)) and bool(expected.get("ok",false)),"existing title-only demo can use original local release"):return
 var after: Dictionary=released["state"]
 check(after==expected["state"] and released.get("finance_action")==RELEASE_ACTION and released.get("closing_balances")==[165],"release equals independent original/post-chain/one-Finance state with25/day1")
 check(legacy==immutable and not after["recordings"][0].has(LINKS) and after["recordings"][0]["qa_unknown_legacy"]==legacy["recordings"][0]["qa_unknown_legacy"],"legacy release preserves caller, original tracks and unknown fields without upgrade")
 check(int(after["cash"])==165 and int(after["tour_day"])==int(legacy["tour_day"])+1,"original release cash/day remain unchanged")
 check(int(after.get("fans",0))==9 and int(after.get("press",0))==2 and int(after.get("buzz",0))==4,"quality70 original release independently yields9fans/2press/4buzz")
 rejected(Rules.release(after,id),after,"same demo cannot release twice")
 rejected(Rules.release(legacy,"missing"),legacy,"release identifies actual saved session, not array position")
 rejected(Rules.release(legacy,id,"stale fingerprint"),legacy,"stale whole-session confirmation is rejected")
 var two: Dictionary=state.duplicate(true)
 two["song_catalogue"]=[state["song_catalogue"][0].duplicate(true),state["song_catalogue"][1].duplicate(true)]
 two["tour_day"]=int(state["tour_day"])-2
 var old: Dictionary=Original.record(two)
 if not check(bool(old.get("ok",false)),"independent two-source legacy recording fixture"):return
 var expanded: Dictionary=old["state"]
 expanded["song_catalogue"]=state["song_catalogue"].duplicate(true)
 expanded["songs"]=3
 expanded["recordings"][0]["qa_unknown_legacy"]={"retain":true}
 var prior: Dictionary=expanded["recordings"][0].duplicate(true)
 var next: Dictionary=Rules.record(expanded,["original:2","original:1"])
 var next_expected: Dictionary=record_oracle(expanded,["original:2","original:1"])
 if check(bool(next.get("ok",false)) and bool(next_expected.get("ok",false)),"new full catalogue material unlocks recording even when selected projection stays two songs"):
  check(next["state"]==next_expected["state"] and next["state"]["recordings"][0]==prior and int(next["state"]["demos"])==2,"full history/demos/source gate survive selected projection")
 var malformed: Dictionary=legacy.duplicate(true)
 malformed["recordings"][0][LINKS]={"version":2,"song_ids":[],"snapshots":[]}
 check(not bool(Rules.validate(malformed).get("ok",true)),"future link version is blocked without legacy rewrite")
 var ambiguous: Dictionary=legacy.duplicate(true)
 ambiguous["recordings"].append(ambiguous["recordings"][0].duplicate(true))
 rejected(Rules.release(ambiguous,id),ambiguous,"duplicate session identity cannot release arbitrary array row")
 var idless: Dictionary=state_fixture()
 idless["recordings"]=[{"tracks":[{}]},{"tracks":[{}]}]
 var raw_legacy: Array=idless["recordings"].duplicate(true)
 check(bool(Rules.validate(idless).get("ok",false)) and Rules.sessions(idless)==raw_legacy,"IDless legacy rows/defaulted track title and quality remain valid in original order")
 var raw_fingerprint: String=Rules.fingerprint(raw_legacy[1])
 rejected(Rules.release(idless,"",raw_fingerprint),idless,"IDless release requires explicit original raw index")
 rejected(Rules.release(idless,"","stale",1),idless,"IDless raw index also requires exact whole-session fingerprint")
 rejected(Rules.release(idless,"",raw_fingerprint,2),idless,"IDless release cannot address outside raw history")
 var legacy_expected: Dictionary=release_oracle(idless,"",1)
 var idless_before: Dictionary=idless.duplicate(true)
 var idless_preview: Dictionary=Rules.preview_release(idless,"",raw_fingerprint,1)
 var legacy_released: Dictionary=Rules.release(idless,"",raw_fingerprint,1)
 check(idless_preview==legacy_released and idless==idless_before and files()==disk,"IDless raw-index release preview preserves caller/files and matches actual release")
 if check(bool(legacy_released.get("ok",false)) and bool(legacy_expected.get("ok",false)),"explicit index/fingerprint releases the second identical IDless row"):
  check(legacy_released.get("state")==legacy_expected.get("state") and legacy_released["state"]["recordings"][0]==raw_legacy[0] and bool(legacy_released["state"]["recordings"][1].get("released",false)),"IDless defaults use exact original release on requested row, without filtered reindexing")
  check(not legacy_released["state"]["recordings"][0].has("id") and not legacy_released["state"]["recordings"][1].has("id") and idless["recordings"]==raw_legacy,"legacy release never fabricates IDs or mutates caller rows")
 for raw_tracks in ["bad",[17]]:
  var bad_tracks: Dictionary=legacy.duplicate(true)
  bad_tracks["recordings"][0]["tracks"]=raw_tracks
  check(not bool(Rules.validate(bad_tracks).get("ok",true)),"present malformed legacy track container is rejected; absence/defaults remain distinct")

func case_booking_and_closing_days() -> void:
 var state: Dictionary=state_fixture()
 var original: Dictionary=Original.record(state)
 if not check(bool(original.get("ok",false)),"legacy release fixture for booked-day matrix"):return
 var legacy: Dictionary=original["state"]
 var id: String=str(legacy["recordings"][0]["id"])
 for offset in [-1,0,1,2,3]:
  var recording: Dictionary=state.duplicate(true)
  var booking: Dictionary=Calendar.book(recording,"local")
  if not check(bool(booking.get("ok",false)),"actual original pending booking fixture"):return
  recording=booking["state"]
  recording["booked_show"]["day"]=int(recording["tour_day"])+offset
  var result: Dictionary=Rules.record(recording,["original:1","original:2"])
  if offset in [0,1,2]:rejected(result,recording,"record blocks inclusive two-day booking overlap "+str(offset))
  else:
   var expected: Dictionary=record_oracle(recording,["original:1","original:2"])
   check(bool(result.get("ok",false)) and result.get("state")==expected.get("state"),"non-overlap/overdue record uses exact original expiry chain "+str(offset))
  var release_state: Dictionary=legacy.duplicate(true)
  var release_booking: Dictionary=Calendar.book(release_state,"local")
  if not check(bool(release_booking.get("ok",false)),"actual release booking fixture"):return
  release_state=release_booking["state"]
  release_state["booked_show"]["day"]=int(release_state["tour_day"])+offset
  var release_before: Dictionary=release_state.duplicate(true)
  var disk: Dictionary=files()
  var preview: Dictionary=Rules.preview_release(release_state,id)
  var released: Dictionary=Rules.release(release_state,id)
  check(preview==released and release_state==release_before and files()==disk,"release preview preserves full state/files and exact success or booking reason "+str(offset))
  if offset==0:rejected(released,release_state,"release blocks actual show day")
  else:
   var expected: Dictionary=release_oracle(release_state,id)
   check(bool(released.get("ok",false)) and released.get("state")==expected.get("state"),"release before/after due day preserves original post chain "+str(offset))
 for streak in [0,12,13]:
  # Deliberate Finance boundary fixture, not a claim of natural cash history.
  var poor: Dictionary=state_fixture()
  poor["cash"]=60
  var account: Dictionary=Finance.view(poor)
  account["broke_days"]=streak
  poor[Finance.KEY]=account
  var result: Dictionary=Rules.record(poor,["original:1","original:2"])
  if streak==13:
   rejected(result,poor,"two-day action cannot continue past first closing day")
  elif check(bool(result.get("ok",false)),"cash60 funds two upfront zero-cash completed days"):
   var after: Dictionary=result["state"]
   var data: Dictionary=Finance.view(after)
   check(result.get("closing_balances")==[0,0] and int(data["broke_days"])==streak+2,"both zero balances count as separate completed broke days")
   check(bool(data["game_over"])==(streak==12) and int(data["ended_day"])==(int(poor["tour_day"])+2 if streak==12 else 0),"terminal can begin only on exact final completed day")
 var terminal: Dictionary=state_fixture()
 var account: Dictionary=Finance.view(terminal)
 account["game_over"]=true
 account["broke_days"]=14
 account["ended_day"]=int(terminal["tour_day"])
 terminal[Finance.KEY]=account
 rejected(Rules.record(terminal,["original:1","original:2"]),terminal,"sticky terminal blocks recording before spending")

func case_actual_save_and_snapshots() -> void:
 var state: Dictionary=state_fixture()
 var recorded: Dictionary=Rules.record(state,["original:3","original:1"])
 if not check(bool(recorded.get("ok",false)),"owned saved-snapshot fixture records real completed IDs"):return
 var after: Dictionary=recorded["state"]
 var session: Dictionary=recorded["session"]
 var id: String=str(session["id"])
 var original_fingerprint: String=Rules.fingerprint(session)
 var before_disk: Dictionary=files()
 var preview: Dictionary=Rules.preview(after,["original:1","original:2"])
 check(not bool(preview.get("ok",true)) and files()==before_disk,"new-material gate preview is pure and cannot write career")
 after["recordings"][0]["qa_saved_unknown"]={"nested":[3,{"keep":"session"}]}
 after["recordings"][0][LINKS]["qa_saved_unknown"]={"keep":"links"}
 model.game.career=after.duplicate(true)
 if not check(model.save_draft(),"actual schema1 C27 saves linked ordered recording"):return
 var bytes: PackedByteArray=FileAccess.get_file_as_bytes(Model.SAVE_PATH)
 var loaded=Model.new()
 if not check(loaded.load_draft() and loaded.snapshot()==model.snapshot() and FileAccess.get_file_as_bytes(Model.SAVE_PATH)==bytes,"actual disk reload preserves whole career/ordered full snapshots/unknowns without rewrite"):return
 var saved: Dictionary=Rules.sessions(loaded.game.career)[0]
 check(saved[LINKS]["song_ids"]==["original:3","original:1"] and saved[LINKS]["snapshots"][0]==state["song_catalogue"][2],"reloaded archive has original creative credits/history, not current draft labels")
 var fingerprint: String=Rules.fingerprint(saved)
 check(fingerprint!=original_fingerprint,"saved optional fields participate in current whole-session confirmation")
 var before: Dictionary=loaded.game.career.duplicate(true)
 var expected: Dictionary=release_oracle(before,id)
 var released: Dictionary=Rules.release(before,id,fingerprint)
 if not check(bool(released.get("ok",false)) and released.get("state")==expected.get("state"),"linked session release follows exact original and one Finance application after real reload"):return
 var released_session: Dictionary=released["state"]["recordings"][0]
 check(released_session[LINKS]==saved[LINKS] and released_session["tracks"]==saved["tracks"],"release preserves recorded identity/snapshot bytes while adding original release facts")
 model.game.career=released["state"].duplicate(true)
 if not check(model.save_draft(),"actual schema1 saves original local release"):return
 var final_bytes: PackedByteArray=FileAccess.get_file_as_bytes(Model.SAVE_PATH)
 var final=Model.new()
 check(final.load_draft() and final.snapshot()==model.snapshot() and FileAccess.get_file_as_bytes(Model.SAVE_PATH)==final_bytes,"released recording survives actual C27 save/load exactly")
 var untouched: Dictionary=final.snapshot().duplicate(true)
 Rules.sessions(final.game.career)
 Rules.fingerprint(final.game.career["recordings"][0])
 check(final.snapshot()==untouched and FileAccess.get_file_as_bytes(Model.SAVE_PATH)==final_bytes,"archive/fingerprint queries after reload never settle, save or alter recorded facts")

func run() -> void:
 var user_dir: String=ProjectSettings.globalize_path("user://")
 var target: String=ProjectSettings.globalize_path(output)
 var allowed: bool=check(user_dir.begins_with(SAFE) and target.begins_with(SAFE),"strict fresh S54 XDG/output guard")
 for path in [Model.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  allowed=check(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated fixture path "+path) and allowed
 if not allowed:
  print("S54_RECORDING_REFUSED ",JSON.stringify({"errors":failures}))
  quit(1)
  return
 output=target
 if not check(DirAccess.make_dir_recursive_absolute(output)==OK,"create isolated result directory"):
  quit(1)
  return
 protected_initial=files(true)
 if fixture():
  for method in ["case_queries_and_order","case_selection_and_malformed","case_literal_descriptor360","case_consumed_dates359","case_legacy_gate_and_release","case_booking_and_closing_days","case_actual_save_and_snapshots"]:
   call(method)
   if not failures.is_empty():break
 check(files(true)==protected_initial,"all original legacy/C26 save bytes remain untouched")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info(),"evidence":evidence,"method":"Independent protected original Recording.record/release projection plus Story/Calendar.expire/Life/Finance once; explicit ID/order/numeric/snapshot/legacy/malformed/booking/two-day terminal boundaries; actual isolated schema1 C27 save/load. No UI/GL/device/save-failure integration claim."}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:
  push_error("S54 result receipt could not be written")
  quit(1)
  return
 receipt.store_string(JSON.stringify(result,"  "))
 receipt.close()
 print("S54_RECORDING_RESULT ",JSON.stringify(result))
 quit(0 if failures.is_empty() else 1)
