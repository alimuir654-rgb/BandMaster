extends SceneTree
## Independent S53 policy proof aligned to frozen candidate d5bd420d after events318/319.
## Root alone executes after explicit engine grant; no UI/device claims.
## Original Calendar/Promoter chain and explicit numeric expectations are the oracle.
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const SAFE := "/workspace/work/overnight-20261101/s53/"
var output: String=SAFE+"show-policy-proof"
var checks: int=0
var failures: Array[String]=[]
var observations: Array=[]
var model
var base: Dictionary={}
var protected_initial: Dictionary={}
func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 call_deferred("run")
func check(value: bool, message: String) -> bool:
 checks+=1
 if not value:failures.append(message);push_error("S53_POLICY "+message)
 return value
func files(protected_only: bool=false) -> Dictionary:
 var paths: Array=["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if not protected_only:paths.append(Opening.SAVE_PATH)
 var result: Dictionary={}
 for path in paths:result[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result
func fixture_step(value: Variant, tag: String) -> bool:
 return check(bool(value.get("ok",false)) if value is Dictionary else bool(value),"actual C27 fixture "+tag)
func fixture() -> bool:
 model=Opening.new()
 if not fixture_step(model.begin_new(),"begin") or not fixture_step(model.set_genre("Indie rock"),"genre") or not fixture_step(model.to_recruit(),"recruit stage"):return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not fixture_step(model.recruit(id),id):return false
 if not fixture_step(model.choose_vocal("cast_jack"),"lead") or not fixture_step(model.confirm_lineup(),"lineup"):return false
 if not fixture_step(model.start_naming(),"name") or not fixture_step(model.submit_name("QA FIRST SHOW","Raw"),"proposal") or not fixture_step(model.lock_name(),"lock"):return false
 if not fixture_step(model.start_identity(),"identity") or not fixture_step(model.set_identity("Wordmark","Amber / Charcoal","Unpolished"),"design") or not fixture_step(model.finish_identity(),"finish") or not fixture_step(model.start_playing(),"play"):return false
 for number in range(1,4):
  for session in range(3):
   if not fixture_step(model.game.write_session("Riff","Verse / Chorus","QA ORIGINAL %d" % number,0),"original writing session"):return false
 base=model.game.career.duplicate(true)
 if not check(int(base.get("songs",0))==3 and (base.get("song_catalogue",[]) as Array).size()==3,"nine genuine writing sessions create three completed originals"):return false
 for index in range(3):
  if not check(str(base.song_catalogue[index].id)=="original:%d" % (index+1),"actual stable completed-song identity"):return false
 return check(model.save_draft(),"real C27 saved genuine written catalogue")
func plan(ids: Array=[], intensity: int=50, approach: String="tight", shout: String="none") -> Dictionary:
 return {"approach":approach,"intensity":intensity,"song_ids":ids.duplicate(),"shoutout":shout,"shoutout_venue_id":"local" if shout=="thankvenue" else ""}
func strong() -> Dictionary:
 var state: Dictionary=base.duplicate(true)
 state["cash"]=250;state["readiness"]=100;state["morale"]=100;state["tension"]=0;state["fans"]=0;state["reputation"]=0
 state["s53_unknown"]={"nested":[17,{"keep":"career"}]}
 for song in state.song_catalogue:song["quality"]=50
 return state
func post(before: Dictionary, after: Dictionary) -> Dictionary:
 return Life.refresh(Calendar.expire(Story.observe(before,after,"gig:"+str(Calendar.pending(before).get("venue_id","")))))
func book(state: Dictionary, managed: bool=true, offer: String="standard", hire: bool=false) -> Dictionary:
 var prior: Dictionary=state.duplicate(true);var disk: Dictionary=files()
 var result: Dictionary=Live.resolve(state,"book_flow" if managed else "book",offer,hire)
 check(state==prior and files()==disk,"pure booking preserves caller and all files")
 if not check(bool(result.get("ok",false)),"valid real original booking: "+offer):return {}
 return (result["state"] as Dictionary).duplicate(true)
func stage(state: Dictionary, selected: Dictionary) -> Dictionary:
 var current: Dictionary=state.duplicate(true);current["tour_day"]=int(Calendar.pending(current).get("day",0))
 var departed: Dictionary=Flow.depart(current)
 if not check(bool(departed.get("ok",false)),"saved journey acknowledgment succeeds on show day"):return {}
 current=departed["state"]
 var arrived: Dictionary=Live.resolve(current,"advance")
 if not check(bool(arrived.get("ok",false)),"original arrival advance succeeds after journey"):return {}
 var checked: Dictionary=Live.resolve(arrived["state"],"soundcheck",str(selected.get("approach","tight")),false,selected)
 if not check(bool(checked.get("ok",false)),"one managed soundcheck saves validated complete plan"):return {}
 return (checked["state"] as Dictionary).duplicate(true)
func intensity_numbers(value: int) -> Dictionary:
 if value<35:return {"q":4,"fans":-3,"fatigue":0,"tension":0,"band":"CONTROLLED"}
 if value<70:return {"q":0,"fans":0,"fatigue":3,"tension":0,"band":"STEADY"}
 return {"q":-4,"fans":4,"fatigue":8,"tension":3,"band":"ALL_OUT"}
func shape(state: Dictionary, ids: Array) -> int:
 if ids.is_empty():return 0
 var qualities: Dictionary={}
 for song in state.get("song_catalogue",[]):qualities[str(song.get("id",""))]=int(song.get("quality",0))
 var opener: int=int(qualities[str(ids.front())]);var closer: int=int(qualities[str(ids.back())])
 return clampi(floori((float(opener+2*closer)/3.0-50.0)/20.0),-2,2)
func independent_owned(before: Dictionary, selected: Dictionary) -> Dictionary:
 var ids: Array=selected["song_ids"]
 var intensity: Dictionary=intensity_numbers(int(selected["intensity"]))
 var quality: int=int(intensity.q)+shape(before,ids)-(1 if str(selected["shoutout"])=="thankvenue" else 0)
 var temporary: Dictionary=before.duplicate(true)
 temporary["songs"]=ids.size();temporary["readiness"]=int(before.get("readiness",0))+quality
 var raw: Dictionary=Calendar.perform(temporary)
 if not check(bool(raw.get("ok",false)),"independent original Calendar performance succeeds"):return {}
 var after: Dictionary=Promoter.settle(raw["state"],before)
 after["songs"]=before["songs"];after["readiness"]=before["readiness"]
 var latest: Dictionary=after.gig_history.back()
 if ids.is_empty() and int(latest.fee)>5:
  var reduction: int=int(latest.fee)-5;latest["fee"]=5;after["cash"]=maxi(0,int(after.cash)-reduction)
 if bool(latest.success) and not ids.is_empty():
  after["fans"]=maxi(0,int(after.get("fans",0))+int(intensity.fans)+(2 if str(selected["shoutout"])=="thankvenue" else 0))
 after["tension"]=clampi(int(after.get("tension",0))+int(intensity.tension),0,100)
 var before_members: Array=before.get("members",[])
 var after_members: Array=after.get("members",[])
 for index in range(mini(before_members.size(),after_members.size())):
  if str(before_members[index].get("life_status","active"))=="active":after_members[index]["fatigue"]=clampi(int(after_members[index].get("fatigue",0))+int(intensity.fatigue),0,100)
 return Night.reset_after_show(after)
func preview_state(source: Dictionary={}) -> Dictionary:
 var current: Dictionary=book(strong() if source.is_empty() else source,true)
 if current.is_empty():return {}
 current["tour_day"]=int(Calendar.pending(current).day)
 var departed: Dictionary=Flow.depart(current)
 if not check(bool(departed.get("ok",false)),"preview fixture acknowledges local journey"):return {}
 var advanced: Dictionary=Live.resolve(departed["state"],"advance")
 return (advanced.get("state",{}) as Dictionary).duplicate(true) if check(bool(advanced.get("ok",false)),"preview fixture reaches original soundcheck") else {}
func case_queries_and_identity() -> void:
 var source: Dictionary=strong();var disk: Dictionary=files()
 var legacy: Dictionary=book(source,false)
 check(not Flow.managed(legacy) and Flow.phase(legacy)==str(Night.stage(legacy).get("phase","")),"unmarked bookings retain exact original phase")
 for original_phase in ["arrival","soundcheck","stage"]:
  var resumed: Dictionary=legacy.duplicate(true);resumed["tour_day"]=int(Calendar.pending(resumed).day);resumed["gig_night_phase"]=original_phase
  var copy: Dictionary=resumed.duplicate(true)
  check(Flow.phase(resumed)==original_phase and resumed==copy,"legacy saved phase resumes without travel replay or metadata upgrade")
 var current: Dictionary=book(source,true)
 if current.is_empty():return
 var original: Dictionary=current.duplicate(true)
 var booking: Dictionary=Calendar.pending(current)
 check(Flow.managed(current) and Flow.booking_id(booking)=="s53:booking:local:%d" % int(booking.day),"new show identity uses venue and scheduled day")
 check(int(current.cash)==250 and int(current.tour_day)==int(source.tour_day) and int(booking.day)==int(source.tour_day)+3,"managed booking adds no reward/cost/day")
 check(bool(Flow.validate(current).get("ok",false)),"new versioned booking validates")
 var first: Dictionary=Flow.default_plan(current)
 first["song_ids"]=["not-a-real-original"]
 check(current==original,"default-plan query returns no aliases")
 var id_mismatch: Dictionary=current.duplicate(true)
 id_mismatch.booked_show[Flow.FLOW_KEY]["booking_id"]="s53:booking:local:99999"
 check(not bool(Flow.validate(id_mismatch).get("ok",true)),"mismatched scheduled booking identity rejects")
 for raw in ["malformed",{"version":2},{"version":true}]:
  var invalid: Dictionary=current.duplicate(true);invalid.booked_show[Flow.FLOW_KEY]=raw
  var before: Dictionary=invalid.duplicate(true);var rejected: Dictionary=Flow.depart(invalid)
  check(not bool(rejected.get("ok",true)) and invalid==before,"unknown/malformed typed flow metadata rejects without normalization")
 current["tour_day"]=int(booking.day)
 current.booked_show[Flow.FLOW_KEY]["unknown"]={"keep":["flow",4]}
 current.booked_show["unknown_booking"]={"keep":18}
 var before: Dictionary=current.duplicate(true);var departed: Dictionary=Flow.depart(current)
 if not check(bool(departed.get("ok",false)),"first due journey acknowledgment succeeds"):return
 var expected: Dictionary=before.duplicate(true);expected.booked_show[Flow.FLOW_KEY]["travel_acknowledged"]=true
 check(departed.get("state")==expected and current==before,"depart changes ONLY known marker; all original/unknown fields unchanged")
 check(Flow.phase(departed["state"])=="arrival","acknowledged journey resumes original arrival")
 var twice: Dictionary=Flow.depart(departed["state"])
 check(not bool(twice.get("ok",true)),"duplicate journey acknowledgment is rejected")
 check(files()==disk,"all model queries/phase operations have no disk effects")
func case_numeric_and_plan_validation() -> void:
 var current: Dictionary=preview_state()
 if current.is_empty():return
 var before: Dictionary=current.duplicate(true);var disk: Dictionary=files()
 for row in [[0,4,-3,0,0,"CONTROLLED"],[34,4,-3,0,0,"CONTROLLED"],[35,0,0,3,0,"STEADY"],[69,0,0,3,0,"STEADY"],[70,-4,4,8,3,"ALL_OUT"],[100,-4,4,8,3,"ALL_OUT"]]:
  var result: Dictionary=Flow.check_plan(current,plan(["original:1"],int(row[0])))
  if not check(bool(result.get("ok",false)),"valid intensity boundary "+str(row[0])):continue
  var p: Dictionary=result["projection"]
  check(int(p.intensity_quality)==int(row[1]) and int(p.successful_extra_fans)==int(row[2]) and int(p.extra_fatigue)==int(row[3]) and int(p.extra_tension)==int(row[4]) and str(p.intensity_band)==str(row[5]),"independent intensity boundary package "+str(row[0]))
 for row in [[1,-2],[49,-1],[50,0],[69,0],[70,1],[89,1],[90,2],[100,2]]:
  var quality_state: Dictionary=current.duplicate(true);quality_state.song_catalogue[0]["quality"]=int(row[0])
  var result: Dictionary=Flow.check_plan(quality_state,plan(["original:1"]))
  check(bool(result.get("ok",false)) and int(result.get("projection",{}).get("set_shape_quality",99))==int(row[1]),"floor/clipped independent song-shape quality "+str(row[0]))
 var ordered: Dictionary=current.duplicate(true);ordered.song_catalogue[0]["quality"]=40;ordered.song_catalogue[1]["quality"]=1;ordered.song_catalogue[2]["quality"]=100
 var forward: Dictionary=Flow.check_plan(ordered,plan(["original:1","original:2","original:3"]))
 var reverse: Dictionary=Flow.check_plan(ordered,plan(["original:3","original:2","original:1"]))
 check(int(forward.get("projection",{}).get("set_shape_quality",99))==1 and int(reverse.get("projection",{}).get("set_shape_quality",99))==0,"actual selected order changes opener/closer weighting")
 ordered.song_catalogue[1]["quality"]=100
 var middle: Dictionary=Flow.check_plan(ordered,plan(["original:1","original:2","original:3"]))
 check(int(middle.get("projection",{}).get("set_shape_quality",99))==1,"middle song does not replace the specified opener/closer policy")
 for ids in [[],["original:1"],["original:1","original:2"],["original:3","original:2","original:1"]]:
  var result: Dictionary=Flow.check_plan(current,plan(ids))
  var expected_mod: int=[-22,-10,-4,2][ids.size()]
  check(bool(result.get("ok",false)) and int(result.get("projection",{}).get("selected_count",-1))==ids.size() and int(result.get("projection",{}).get("originals_modifier",99))==expected_mod,"selected real IDs drive original material modifier independently of career total")
 var invalid_plans: Array=[]
 for value in [-1,101,34.5,"high",true]:
  var invalid: Dictionary=plan();invalid["intensity"]=value;invalid_plans.append(invalid)
 for ids in [["unknown"],["original:1","original:1"],[1]]:
  invalid_plans.append(plan(ids))
 var wrong_array: Dictionary=plan();wrong_array["song_ids"]="original:1";invalid_plans.append(wrong_array)
 var wrong_approach: Dictionary=plan();wrong_approach["approach"]="random";invalid_plans.append(wrong_approach)
 var wrong_shout: Dictionary=plan(["original:1"],50,"tight","thankvenue");wrong_shout["shoutout_venue_id"]="bristol";invalid_plans.append(wrong_shout)
 for invalid in invalid_plans:
  var untouched: Dictionary=invalid.duplicate(true);var result: Dictionary=Flow.check_plan(current,invalid)
  check(not bool(result.get("ok",true)) and invalid==untouched,"invalid typed draft rejects without mutating caller")
 var checked: Dictionary=Flow.check_plan(current,plan(["original:1"]))
 if bool(checked.get("ok",false)):
  var normalized: Dictionary=checked["plan"];normalized.song_snapshots[0]["title"]="CHANGED QA COPY"
  check(current==before,"normalized actual song snapshots have no alias into catalogue")
 check(current==before and files()==disk,"all preview/validation operations preserve exact input/owner files")
func case_stale_uncommitted_replacement() -> void:
 var current: Dictionary=preview_state()
 if current.is_empty():return
 var source: Dictionary=current.duplicate(true);var disk: Dictionary=files()
 var old_default: Dictionary=current.booked_show[Flow.FLOW_KEY]["plan"].duplicate(true)
 check(not bool(current.booked_show[Flow.FLOW_KEY]["plan_committed"]) and (old_default.get("song_ids",[]) as Array).has("original:1"),"fixture has an uncommitted actual completed-song default")
 # Simulate the original catalogue cap removing its oldest record. The
 # survivors are genuine completed IDs from the nine actual fixture writes.
 var trimmed: Dictionary=current.duplicate(true)
 trimmed.song_catalogue.remove_at(0)
 var trimmed_before: Dictionary=trimmed.duplicate(true)
 check(bool(Flow.validate(trimmed).get("ok",false)) and Flow.phase(trimmed)=="soundcheck" and trimmed==trimmed_before,"stale uncommitted default remains navigable after catalogue trimming; validation never rewrites it")
 var missing: Dictionary=Flow.check_plan(trimmed,old_default)
 check(not bool(missing.get("ok",true)) and trimmed==trimmed_before,"explicitly selecting a removed original still rejects")
 var replacement: Dictionary=plan(["original:3","original:2"],50,"crowd")
 var checked: Dictionary=Flow.check_plan(trimmed,replacement)
 if not check(bool(checked.get("ok",false)),"replacement chooses current genuine completed IDs in player order"):return
 check((checked["plan"] as Dictionary).get("song_ids",[])==["original:3","original:2"] and trimmed==trimmed_before,"free replacement preview does not spend, commit, normalize or mutate saved draft")
 var rejected: Dictionary=Flow.soundcheck(trimmed,old_default)
 check(not bool(rejected.get("ok",true)) and rejected.get("state")==trimmed and trimmed==trimmed_before,"committing the missing old default fails immutably and leaves replacement route available")
 var committed: Dictionary=Flow.soundcheck(trimmed,replacement)
 if not check(bool(committed.get("ok",false)),"valid replacement commits once from the stale-default soundcheck"):return
 var state: Dictionary=committed["state"]
 check(bool(Flow.validate(state).get("ok",false)) and bool(state.booked_show[Flow.FLOW_KEY]["plan_committed"]),"newly committed actual snapshots are valid")
 var missing_committed: Dictionary=state.duplicate(true)
 for index in range((missing_committed.song_catalogue as Array).size()-1,-1,-1):
  if str(missing_committed.song_catalogue[index].get("id",""))=="original:3":missing_committed.song_catalogue.remove_at(index)
 check(not bool(Flow.validate(missing_committed).get("ok",true)) and not bool(Flow.prepare_performance(missing_committed).get("ok",true)),"committed selected IDs cannot silently disappear or be substituted")
 var changed_title: Dictionary=state.duplicate(true);changed_title.song_catalogue[0]["title"]="QA CHANGED AFTER COMMIT"
 check(not bool(Flow.validate(changed_title).get("ok",true)),"committed song title snapshots remain strict")
 var changed_quality: Dictionary=state.duplicate(true);changed_quality.song_catalogue[0]["quality"]=int(changed_quality.song_catalogue[0].get("quality",50))+1
 check(not bool(Flow.validate(changed_quality).get("ok",true)),"committed authored quality cannot drift after confirmation")
 var wrong_type: Dictionary=trimmed.duplicate(true);wrong_type.booked_show[Flow.FLOW_KEY]["plan"]["song_snapshots"]="bad"
 check(not bool(Flow.validate(wrong_type).get("ok",true)),"uncommitted tolerance retains structural/type validation")
 check(current==source and files()==disk,"stale/default/replacement/committed cases preserve original caller and all files")
func case_projection_and_settlement() -> void:
 var source: Dictionary=strong();source["songs"]=7
 var chosen: Dictionary=plan(["original:1"],0)
 var current: Dictionary=stage(book(source,true),chosen)
 if current.is_empty():return
 var prepared: Dictionary=Flow.prepare_performance(current)
 if not check(bool(prepared.get("ok",false)),"managed committed plan can prepare a performance"):return
 check(int(prepared.state.readiness)==104 and int(prepared.state.songs)==1,"temporary selected count and signed quality remain unclamped BEFORE original Calendar")
 var expected: Dictionary=independent_owned(current,chosen)
 var raw: Dictionary=Calendar.perform(prepared["state"])
 if not check(bool(raw.get("ok",false)),"one actual original Calendar settlement"):return
 var promoted: Dictionary=Promoter.settle(raw["state"],current)
 var owned: Dictionary=Flow.after_original_settlement(current,promoted)
 if not check(bool(owned.get("ok",false)),"owned settlement adjustment follows original promoter"):return
 var actual: Dictionary=Night.reset_after_show(owned["state"])
 var normalized: Dictionary=actual.duplicate(true)
 normalized.gig_history.back().erase("show_policy_v1")
 check(normalized==expected,"full independent original state plus explicit owned math matches, only named policy receipt marker excepted")
 check(int(actual.songs)==7 and int(actual.readiness)==100 and int(actual.gig_history.back().originals_played)==1,"canonical totals/readiness restored; played count reflects selected real IDs")
 var again: Dictionary=Flow.after_original_settlement(current,owned["state"])
 check(bool(again.get("ok",false)) and again.get("state")==owned.get("state"),"owned adjustments are idempotent on their durable show-policy marker")
 var post_state: Dictionary=post(current,actual)
 var reviewed: Dictionary=Reviews.apply(current,post_state)
 if not check(bool(reviewed.get("ok",false)),"final factual review records finalized owned fee"):return
 var recorded: Dictionary=Flow.record(current,reviewed["state"],"QA actual original settlement")
 if not check(bool(recorded.get("ok",false)),"durable owned receipt records exactly one show"):return
 var state: Dictionary=recorded["state"]
 var receipt: Dictionary=Flow.last_receipt(state)
 check(str(receipt.get("id",""))==Flow.booking_id(Calendar.pending(current)) and int(receipt.get("scheduled_day",0))==int(Calendar.pending(current).day) and int(receipt.get("completed_day",0))==int(state.tour_day),"durable receipt uses scheduled booking identity and separate completed day")
 check(receipt.get("plan",{}).get("song_ids",[])==["original:1"] and int(receipt.get("originals_played",-1))==1 and int(receipt.get("settled_fee",-1))==int(state.gig_history.back().fee),"receipt retains selected actual IDs/order and final gross fee")
 check((receipt.get("responses",[]) as Array).size()==3,"saved bounded modelled response has three truthful beats")
 for response in receipt.get("responses",[]):
  var mood: String=str(response.get("mood",""));var scores: Dictionary={"strained":3,"steady":6,"positive":9}
  check(scores.has(mood) and int(response.get("meter_score",-1))==int(scores.get(mood,-2)) and response.get("kind")=="modelled_summary" and response.get("meter_label")=="MODELLED SUMMARY (THREE BANDS)","saved response meter is explicit coarse3/6/9 summary, never telemetry")
 var repeated: Dictionary=Flow.record(current,state,"QA actual original settlement")
 check(bool(repeated.get("ok",false)) and repeated.get("state")==state,"replaying receipt record appends no duplicate history or counter")
 receipt["message"]="MUTATED COPY";receipt["plan"]["song_ids"].clear()
 check(Flow.last_receipt(state).get("plan",{}).get("song_ids",[])==["original:1"],"last receipt is deeply copied for read-only presentation")
 observations.append({"case":"independent-settlement","before":current,"after":state})
func settled_owned(source: Dictionary, selected: Dictionary, offer: String="standard", hire: bool=false) -> Dictionary:
 var current: Dictionary=stage(book(source,true,offer,hire),selected)
 if current.is_empty():return {}
 var prepared: Dictionary=Flow.prepare_performance(current)
 if not check(bool(prepared.get("ok",false)),"prepare committed actual plan"):return {}
 var raw: Dictionary=Calendar.perform(prepared["state"])
 if not check(bool(raw.get("ok",false)),"original performance accepts projected set"):return {}
 var promoted: Dictionary=Promoter.settle(raw["state"],current)
 var adjusted: Dictionary=Flow.after_original_settlement(current,promoted)
 if not check(bool(adjusted.get("ok",false)),"owned cap/reach/effort settles once"):return {}
 var expected: Dictionary=independent_owned(current,selected)
 var actual: Dictionary=Night.reset_after_show(adjusted["state"])
 var normalized: Dictionary=actual.duplicate(true);normalized.gig_history.back().erase(Flow.RESULT_KEY)
 check(normalized==expected,"each independent numeric original-chain/owned outcome matches full state")
 return {"before":current,"after":actual,"promoted":promoted}
func case_caps_reach_and_effort() -> void:
 for offer in ["standard","guarantee","guestlist"]:
  var done: Dictionary=settled_owned(strong(),plan([],100,"tight","thankvenue"),offer)
  if done.is_empty():return
  var after: Dictionary=done["after"];var promoted: Dictionary=done["promoted"]
  check(bool(after.gig_history.back().success) and int(after.gig_history.back().fee)==5 and int(after.cash)==250,"marked zero-original successful "+offer+" gross cap5 AFTER promoter; travel5 retained")
  check(int(after.fans)==int(promoted.fans),"no successful owned reach reward without selected originals")
 var poor: Dictionary=strong();poor["readiness"]=0;poor["morale"]=0;poor["tension"]=100
 var weak: Dictionary=settled_owned(poor,plan([],50),"guestlist")
 if not weak.is_empty():check(not bool(weak.after.gig_history.back().success) and int(weak.after.gig_history.back().fee)==1 and int(weak.after.cash)==246,"poor empty guestlist keeps actual gross1; cap never raises fee or refunds travel")
 var legacy: Dictionary=book(strong(),false,"guarantee");legacy["songs"]=0;legacy["tour_day"]=int(Calendar.pending(legacy).day)
 var original: Dictionary=Night.advance(legacy);var chosen: Dictionary=Night.choose_set(original["state"],"tight");var advanced: Dictionary=Night.advance(chosen["state"])
 var raw: Dictionary=Calendar.perform(advanced["state"]);var paid: Dictionary=Promoter.settle(raw["state"],advanced["state"])
 var neutral: Dictionary=Flow.after_original_settlement(advanced["state"],paid)
 check(bool(neutral.get("ok",false)) and neutral.get("state")==paid and int(paid.gig_history.back().fee)==38 and int(paid.cash)==283,"legacy zero-original guarantee stays original gross38; no managed cap applied")
 var legacy_before: Dictionary=advanced["state"]
 var expected_legacy: Dictionary=Reviews.apply(legacy_before,post(legacy_before,Night.reset_after_show(paid)))
 var actual_legacy: Dictionary=Live.resolve(legacy_before,"perform")
 check(bool(actual_legacy.get("ok",false)) and actual_legacy.get("state")==expected_legacy.get("state"),"legacy4-argument managed-bridge entry retains full original settlement+review state")
 for success in [true,false]:
  for effort in [0,50,100]:
   var state: Dictionary=strong()
   if not success:state["readiness"]=0;state["morale"]=0;state["tension"]=80
   state.members[0]["fatigue"]=10;state.members[1]["fatigue"]=99
   state.members[2]["life_status"]="leave";state.members[2]["available_day"]=9999;state.members[2]["fatigue"]=7
   # Two active musicians but one must remain the real drummer.
   state.members[1]["life_status"]="leave";state.members[1]["available_day"]=9999
   state.members[2]["life_status"]="active"
   var selected: Dictionary=plan(["original:1"],effort,"crowd","thankvenue")
   var done: Dictionary=settled_owned(state,selected)
   if done.is_empty():return
   var before: Dictionary=done["before"];var after: Dictionary=done["after"];var promoted: Dictionary=done["promoted"]
   var numbers: Dictionary=intensity_numbers(effort)
   var expected_fans: int=maxi(int(before.get("fans",0)),int(promoted.get("fans",0))+int(numbers.fans)+2) if bool(after.gig_history.back().success) else int(promoted.get("fans",0))
   check(int(after.fans)==expected_fans,"effort/shout reach changes only actual successful selected-original shows")
   check(int(after.members[0].fatigue)==clampi(int(promoted.members[0].get("fatigue",0))+int(numbers.fatigue),0,100) and int(after.members[1].fatigue)==int(promoted.members[1].get("fatigue",0)),"effort fatigue affects actual active performers; away member unchanged")
   check(int(after.tension)==clampi(int(promoted.get("tension",0))+int(numbers.tension),0,100),"extra effort tension is actual bounded settlement data")
func case_call_order_unknown_and_accounting() -> void:
 var current: Dictionary=book(strong(),true)
 if current.is_empty():return
 current["tour_day"]=int(Calendar.pending(current).day)
 var untouched: Dictionary=current.duplicate(true)
 var early: Dictionary=Flow.soundcheck(current,plan(["original:1"]))
 check(not bool(early.get("ok",true)) and current==untouched,"soundcheck cannot skip unacknowledged journey")
 var early_perform: Dictionary=Flow.prepare_performance(current)
 check(not bool(early_perform.get("ok",true)) and current==untouched,"pre-show navigation cannot prepare performance")
 current["cash"]=0
 var account: Dictionary=Finance.view(current);account["broke_days"]=13;current[Finance.KEY]=account
 var departed: Dictionary=Flow.depart(current)
 if not check(bool(departed.get("ok",false)),"zero cash does not invent a journey charge"):return
 var accounted: Dictionary=Finance.apply(current,departed["state"],"live:depart")
 if check(bool(accounted.get("ok",false)),"zero-day owned phase has one valid Finance checkpoint"):
  var data: Dictionary=Finance.view(accounted["state"])
  check(int(data.seq)==int(account.seq)+1 and int(data.broke_days)==13 and not bool(data.game_over),"zero-day phase adds exactly one accounting checkpoint without aging broke streak")
  var last: Dictionary=(data.history as Array).back()
  check(int(last.income)==0 and int(last.outgoing)==0 and (last.closing_balances as Array).is_empty(),"phase accounting has zero flows and no fabricated completed day")
 var terminal: Dictionary=current.duplicate(true);terminal[Finance.KEY]["game_over"]=true;terminal[Finance.KEY]["broke_days"]=14
 var blocked: Dictionary=Finance.apply(terminal,departed["state"],"live:depart")
 check(not bool(Finance.guard(terminal).get("ok",true)) and not bool(blocked.get("ok",true)) and blocked.get("state")==terminal,"authoritative caller Finance guard/rollback preserves sticky terminal career")
 var preview: Dictionary=preview_state()
 if preview.is_empty():return
 var four:=Game.new()
 check(four.restore(model.game.snapshot()),"independent actual fourth-song source clone")
 for session in range(3):fixture_step(four.write_session("Groove","Loose Jam","QA FOURTH ORIGINAL",0),"fourth original session")
 var catalogue: Array=four.career.get("song_catalogue",[])
 var four_preview: Dictionary=preview.duplicate(true);four_preview["song_catalogue"]=catalogue;four_preview["songs"]=4
 var oversized: Dictionary=Flow.check_plan(four_preview,plan(["original:1","original:2","original:3","original:4"]))
 check(not bool(oversized.get("ok",true)),"four unique actual completed originals cannot exceed three selected slots")
 var selected: Dictionary=plan(["original:1"],50,"tight","thankvenue");selected["unknown_plan"]={"keep":[1,2]}
 preview["unknown_career"]={"keep":true};preview.booked_show["unknown_booking"]={"keep":17};preview.booked_show[Flow.FLOW_KEY]["unknown_flow"]={"keep":"yes"}
 var result: Dictionary=Flow.soundcheck(preview,selected)
 if check(bool(result.get("ok",false)),"known plan preserves unrecognized additive fields"):
  var after: Dictionary=result["state"]
  check(after.unknown_career==preview.unknown_career and after.booked_show.unknown_booking==preview.booked_show.unknown_booking and after.booked_show[Flow.FLOW_KEY].unknown_flow==preview.booked_show[Flow.FLOW_KEY].unknown_flow and after.booked_show[Flow.FLOW_KEY].plan.unknown_plan==selected.unknown_plan,"career/booking/flow/plan unknown nested data preserved")
  var stale: Dictionary=after.duplicate(true);stale.song_catalogue.remove_at(0)
  check(not bool(Flow.prepare_performance(stale).get("ok",true)),"stale selected original is rejected before settlement")
func _original_case_integrated_record_and_save() -> void:
 var source: Dictionary=strong()
 var previous: Array=[]
 for index in range(50):previous.append({"venue_id":"other","venue":"Old QA Venue","city":"QA","day":index+1,"fee":0,"success":false})
 source["gig_history"]=previous
 var selected: Dictionary=plan([],0)
 var before: Dictionary=stage(book(source,true,"guarantee"),selected)
 if before.is_empty():return
 var expected: Dictionary=independent_owned(before,selected)
 var reviewed: Dictionary=Reviews.apply(before,post(before,expected))
 if not check(bool(reviewed.get("ok",false)),"independent review handles exact50-row original history trim"):return
 var result: Dictionary=Live.resolve(before,"perform")
 if not check(bool(result.get("ok",false)),"managed bridge orchestrates actual original settlement once"):return
 var state: Dictionary=result["state"]
 var normalized: Dictionary=state.duplicate(true);normalized.erase(Flow.RECORDS_KEY);normalized.gig_history.back().erase(Flow.RESULT_KEY)
 check(normalized==reviewed["state"],"integrated managed bridge matches independent complete original+owned+Review state except explicit owned receipt keys")
 check((state.gig_history as Array).size()==50 and int(Reviews.latest(state).settled_fee)==5 and int(Flow.last_receipt(state).settled_fee)==5,"trimmed original history/review/durable receipt agree on final capped fee")
 var message: String=str(result.get("message",""))
 check(message.contains("Final gross fee £5.") and message.contains("Cash £250 → £250; day %d → %d." % [int(before.tour_day),int(state.tour_day)]) and not message.contains("Fee £23") and not message.contains("fee £38"),"managed visible message reports authoritative final fee/cash/day, never pre-cap gross")
 check(str(Flow.last_receipt(state).get("message",""))==message,"durable receipt preserves the authoritative final settlement message")
 check((state[Flow.RECORDS_KEY].seen_ids as Dictionary).size()==1 and int(state[Flow.RECORDS_KEY].seq)==1,"one stable booking identity creates one durable owned receipt")
 var repeat: Dictionary=Live.resolve(state,"perform")
 check(not bool(repeat.get("ok",true)),"cleared booking prevents repeat performance")
 var corrupt_projections: Array=[{},"bad",{"intensity_band":17}]
 for entry in [["selected_count",4],["intensity_value",101],["intensity_band","UNKNOWN"],["quality_modifier","high"],["threshold",0]]:
  var corrupt: Dictionary=Flow.last_receipt(state)["projection"].duplicate(true);corrupt[str(entry[0])]=entry[1];corrupt_projections.append(corrupt)
 for projection in corrupt_projections:
  var malformed: Dictionary=state.duplicate(true);malformed[Flow.RECORDS_KEY].records[0]["projection"]=projection
  var immutable: Dictionary=malformed.duplicate(true)
  check(not bool(Flow.validate(malformed).get("ok",true)) and Flow.last_receipt(malformed).is_empty() and malformed==immutable,"known saved projection metadata rejects safely before presentation")
  var new_row: Dictionary=state.duplicate(true);new_row.erase(Flow.RECORDS_KEY);new_row.gig_history.back()[Flow.RESULT_KEY]["projection"]=projection
  var row_before: Dictionary=new_row.duplicate(true);var rejected: Dictionary=Flow.record(before,new_row,"malformed metadata QA")
  check(not bool(rejected.get("ok",true)) and rejected.get("state")==before and new_row==row_before,"record rejects invalid typed projection before duplicate/index use without mutating inputs")
 var duplicate: Dictionary=state.duplicate(true);duplicate[Flow.RECORDS_KEY].records.append(duplicate[Flow.RECORDS_KEY].records[0].duplicate(true))
 check(not bool(Flow.validate(duplicate).get("ok",true)),"duplicate persisted receipt IDs/checkpoints are rejected")
 var future: Dictionary=state.duplicate(true);future[Flow.RECORDS_KEY]["version"]=2
 check(not bool(Flow.validate(future).get("ok",true)),"unknown future receipt version is not silently rewritten")
 var accounted: Dictionary=Finance.apply(before,state,"live:perform")
 if not check(bool(accounted.get("ok",false)),"single final managed settlement reconciles original fee/travel"):return
 state=accounted["state"]
 var finance: Dictionary=Finance.view(state);var ledger_row: Dictionary=(finance["history"] as Array).back()
 check(int(ledger_row.get("income",-1))==5 and int(ledger_row.get("outgoing",-1))==5 and int(finance.totals.income.get("Gig fees",-1))==5 and int(finance.totals.outgoing.get("Travel",-1))==5,"single final ledger reconciles actual gross5 and travel5, not net income or uncapped promoter fee")
 state[Flow.RECORDS_KEY]["unknown_records"]={"keep":"ledger"}
 var snapshot_before: Dictionary=model.snapshot().duplicate(true)
 model.game.career=state.duplicate(true)
 if not check(model.save_draft(),"actual schema1 C27 saves additive show receipts"):return
 var bytes: PackedByteArray=FileAccess.get_file_as_bytes(Opening.SAVE_PATH)
 var restored:=Opening.new()
 check(restored.load_draft() and restored.snapshot()==model.snapshot() and FileAccess.get_file_as_bytes(Opening.SAVE_PATH)==bytes,"actual disk restore preserves full nested show state/receipt/unknown fields without rewriting")
 var read_before: Dictionary=restored.snapshot().duplicate(true)
 var receipt: Dictionary=Flow.last_receipt(restored.game.career)
 check(restored.snapshot()==read_before and FileAccess.get_file_as_bytes(Opening.SAVE_PATH)==bytes and str(receipt.get("id",""))==Flow.booking_id(Calendar.pending(before)),"reloaded receipt query never resolves/saves or changes identity")
 model.restore(snapshot_before)
func run() -> void:
 var user_dir: String=ProjectSettings.globalize_path("user://");var target: String=ProjectSettings.globalize_path(output)
 var safe: bool=check(user_dir.begins_with(SAFE) and target.begins_with(SAFE),"fresh isolated S53 model/data guard")
 for path in [Opening.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=check(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh fixture path "+path) and safe
 if not safe:print("S53_POLICY_REFUSED ",JSON.stringify({"errors":failures}));quit(1);return
 output=target
 if not check(DirAccess.make_dir_recursive_absolute(output)==OK,"create isolated policy receipt directory"):quit(1);return
 protected_initial=files(true)
 if fixture():
  for method in ["case_queries_and_identity","case_numeric_and_plan_validation","case_stale_uncommitted_replacement","case_projection_and_settlement","case_caps_reach_and_effort","case_call_order_unknown_and_accounting","case_integrated_record_and_save"]:
   call(method)
   if not failures.is_empty():break
 check(files(true)==protected_initial,"all legacy3/C26 bytes remain unchanged")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info(),"user_data":user_dir,"observations":observations,"method":"Independent original Calendar/Promoter/Night/Story/Life/Review chain plus explicit numeric S53 policy, genuine C27 written IDs and actual schema1 save/load. No UI/GL/device/save-failure-integration claim."}
 var receipt: FileAccess=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:push_error("S53 policy receipt failed");quit(1);return
 receipt.store_string(JSON.stringify(result,"  "));receipt.close();print("S53_POLICY_RESULT ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)

## S53 events341/343 optional factual receipt fields; original328 checks retained.
## Flattened exact original6661 and receipt extensionafc8d9. No scratch dependency/UI/device claim.
var receipt_extension_evidence: Array=[]
func case_integrated_record_and_save() -> void:
 _original_case_integrated_record_and_save()
 if not failures.is_empty():return
 case_receipt_effects_and_expenses()
func extension_case(source: Dictionary, selected: Dictionary, offer: String="standard", hire: bool=false) -> Dictionary:
 var before: Dictionary=stage(book(source,true,offer,hire),selected)
 if before.is_empty():return {}
 var expected: Dictionary=independent_owned(before,selected)
 var review: Dictionary=Reviews.apply(before,post(before,expected))
 if not check(bool(review.get("ok",false)),"independent original/post/Review outcome for factual receipt"):return {}
 var final: Dictionary=review["state"]
 var actual: Dictionary=Live.resolve(before,"perform")
 if not check(bool(actual.get("ok",false)),"original managed show with factual receipt succeeds"):return {}
 var state: Dictionary=actual["state"]
 var normalized: Dictionary=state.duplicate(true);normalized.erase(Flow.RECORDS_KEY);normalized.gig_history.back().erase(Flow.RESULT_KEY)
 if not check(normalized==final,"optional factual fields do not change independently calculated settlement"):return {}
 var receipt: Dictionary=Flow.last_receipt(state)
 if not check(receipt.get("effects") is Dictionary and receipt.get("expenses") is Dictionary,"new durable receipt contains optional factual containers"):return {}
 var effects: Dictionary=receipt["effects"]
 for field in ["readiness","morale","tension","reputation","fans"]:
  var old_value: int=int(before.get(field,0));var new_value: int=int(final.get(field,0))
  var row: Variant=effects.get(field)
  if not check(row is Dictionary,"actual effect row exists: "+field):return {}
  check(int(row.get("before",-1))==old_value and int(row.get("after",-1))==new_value and int(row.get("delta",-99999))==new_value-old_value,"factual receipt effect equals independent actual before/postReview result: "+field)
 var expenses: Dictionary=receipt["expenses"]
 var history: Dictionary=final.gig_history.back()
 check(int(expenses.get("travel_paid",-1))==mini(5,int(before.get("cash",0))),"receipt uses actual local travel paid, including low-cash cap")
 check(int(expenses.get("session_paid",-1))==int(history.get("session_fee",-2)) and int(expenses.get("session_paid",-1))==(25 if hire else 0),"receipt session cost equals actual original newly settled history0/25")
 receipt_extension_evidence.append({"before_reputation_present":before.has("reputation"),"before_cash":before.get("cash"),"effects":effects.duplicate(true),"expenses":expenses.duplicate(true),"fee":receipt.get("settled_fee"),"hire":hire})
 return {"before":before,"state":state,"receipt":receipt,"message":actual.get("message","")}
func assert_invalid_receipt(state: Dictionary, receipt: Dictionary, tag: String) -> void:
 var candidate: Dictionary=state.duplicate(true)
 candidate[Flow.RECORDS_KEY]["records"][-1]=receipt.duplicate(true)
 var untouched: Dictionary=candidate.duplicate(true)
 check(not bool(Flow.validate(candidate).get("ok",true)) and Flow.last_receipt(candidate).is_empty() and candidate==untouched,"malformed optional receipt rejects immutably: "+tag)
func case_receipt_effects_and_expenses() -> void:
 # This is the unseeded genuine C27 path, not strong(): reputation is absent
 # before its first show and original rules use an authoritative zero default.
 check(not base.has("reputation"),"genuine written C27 fixture still has no seeded reputation")
 var genuine: Dictionary=extension_case(base.duplicate(true),plan(["original:1","original:2","original:3"],50))
 if genuine.is_empty():return
 check(not genuine["before"].has("reputation") and int(genuine["receipt"]["effects"]["reputation"]["before"])==0,"first-show receipt honors original absent-counter default without seeding career")
 for ids in [[],["original:1","original:2","original:3"]]:
  if extension_case(strong(),plan(ids,50)).is_empty():return
 var poor: Dictionary=strong();poor["readiness"]=0;poor["morale"]=0;poor["tension"]=100
 if extension_case(poor,plan([],50),"guestlist").is_empty():return
 var low: Dictionary=strong();low["cash"]=2
 var low_case: Dictionary=extension_case(low,plan([],0))
 if low_case.is_empty():return
 check(int(low_case["receipt"]["expenses"]["travel_paid"])==2,"£2 starting cash records£2 actual travel rather than£5 tariff")
 var hired: Dictionary=strong()
 for index in [1,2]:hired["members"][index]["life_status"]="leave";hired["members"][index]["available_day"]=9999
 var hired_case: Dictionary=extension_case(hired,plan([],0),"standard",true)
 if hired_case.is_empty():return
 check(int(hired_case["receipt"]["expenses"]["session_paid"])==25 and int(hired_case["state"]["cash"])==225,"hired actual£25 remains paid even when gross empty-set fee is capped£5")
 var state: Dictionary=genuine["state"]
 var receipt: Dictionary=genuine["receipt"]
 # Present invalid original values must fail; absence is a different contract.
 for bad in ["bad",true,-1,0.5]:
  var before: Dictionary=genuine["before"].duplicate(true);before["reputation"]=bad
  var after: Dictionary=state.duplicate(true);after.erase(Flow.RECORDS_KEY)
  var result: Dictionary=Flow.record(before,after,"malformed original before counter")
  check(not bool(result.get("ok",true)) and result.get("state")==before,"present malformed source counter is rejected instead of coerced/defaulted")
 for key in ["effects","expenses"]:
  var older: Dictionary=state.duplicate(true);older[Flow.RECORDS_KEY]["records"][-1].erase(key)
  check(bool(Flow.validate(older).get("ok",false)),"older receipt independently accepts absent optional "+key)
 var old_both: Dictionary=state.duplicate(true)
 for key in ["effects","expenses"]:old_both[Flow.RECORDS_KEY]["records"][-1].erase(key)
 check(bool(Flow.validate(old_both).get("ok",false)),"older version1 receipt with neither optional container remains valid")
 for bad in ["bad",[],null]:
  var invalid: Dictionary=receipt.duplicate(true);invalid["effects"]=bad;assert_invalid_receipt(state,invalid,"effects container type")
  invalid=receipt.duplicate(true);invalid["expenses"]=bad;assert_invalid_receipt(state,invalid,"expenses container type")
 var missing: Dictionary=receipt.duplicate(true);missing["effects"].erase("fans");assert_invalid_receipt(state,missing,"present effects missing known row")
 for entry in [["before","bad"],["before",true],["before",-1],["before",101],["after",0.5],["after",101],["delta","bad"]]:
  var invalid: Dictionary=receipt.duplicate(true);invalid["effects"]["readiness"][str(entry[0])]=entry[1];assert_invalid_receipt(state,invalid,"effect known value type/bound")
 var delta: Dictionary=receipt.duplicate(true);delta["effects"]["tension"]["delta"]=int(delta["effects"]["tension"]["delta"])+1;assert_invalid_receipt(state,delta,"effect delta must equal after-before")
 for field in ["travel_paid","session_paid"]:
  for bad in ["bad",true,-1,0.5]:
   var invalid: Dictionary=receipt.duplicate(true);invalid["expenses"][field]=bad;assert_invalid_receipt(state,invalid,"expense known value type/bound")
 var tariff: Dictionary=low_case["receipt"].duplicate(true);tariff["expenses"]["travel_paid"]=5;assert_invalid_receipt(low_case["state"],tariff,"nominal travel tariff cannot replace actual low-cash payment")
 var fan_unbounded: Dictionary=state.duplicate(true);fan_unbounded[Flow.RECORDS_KEY]["records"][-1]["effects"]["fans"]={"before":1000,"after":1007,"delta":7}
 check(bool(Flow.validate(fan_unbounded).get("ok",false)),"fans effect is not incorrectly capped to100")
 var unknown: Dictionary=state.duplicate(true);var last: Dictionary=unknown[Flow.RECORDS_KEY]["records"][-1]
 last["effects"]["future_container"]={"keep":[1]};last["effects"]["readiness"]["future_row"]={"keep":[2]};last["expenses"]["future_expense"]={"keep":[3]}
 var unknown_before: Dictionary=unknown.duplicate(true)
 check(bool(Flow.validate(unknown).get("ok",false)) and unknown==unknown_before,"unknown nested factual extensions are preserved without normalization")
 var copy: Dictionary=Flow.last_receipt(unknown);copy["effects"]["future_container"]["keep"].append(9)
 check(unknown==unknown_before,"read-only receipt returns deep copies of nested factual extensions")
 var owner_before: Dictionary=model.snapshot().duplicate(true);model.game.career=old_both.duplicate(true)
 if check(model.save_draft(),"actual schema1 C27 saves older absent-facts receipt"):
  var loaded=Opening.new();check(loaded.load_draft() and loaded.snapshot()==model.snapshot(),"actual C27 reload accepts older receipt without schema migration")
 model.restore(owner_before)
 observations.append({"case":"optional-factual-receipt","proof":receipt_extension_evidence})
