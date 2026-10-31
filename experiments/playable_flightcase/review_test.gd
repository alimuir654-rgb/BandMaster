extends SceneTree
## Independent original-model/numeric review proof. Root alone executes.
const Review = preload("res://experiments/playable_flightcase/review_policy.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const Practice = preload("res://Scripts/practice_room.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const SAFE := "/workspace/work/business/s49/"
var checks: int=0
var failures: Array[String]=[]
var model: RefCounted
var base: Dictionary={}
var protected_initial: Dictionary={}

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> bool:
 checks+=1
 if not ok: failures.append(message);push_error("S49_REVIEW_TEST "+message)
 return ok
func files(include_c27: bool=true) -> Dictionary:
 var paths: Array=["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if include_c27: paths.append(Opening.SAVE_PATH)
 var result: Dictionary={}
 for path in paths: result[path]=FileAccess.get_file_as_bytes(str(path)) if FileAccess.file_exists(str(path)) else null
 return result
func step(value: Variant) -> bool:
 return check(bool(value.get("ok",false)) if value is Dictionary else bool(value),"real C27 fixture API succeeds")
func fixture() -> bool:
 model=Opening.new()
 if not step(model.begin_new()) or not step(model.set_genre("Indie rock")) or not step(model.to_recruit()): return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not step(model.recruit(id)): return false
 if not step(model.choose_vocal("cast_jack")) or not step(model.confirm_lineup()) or not step(model.start_naming()) or not step(model.submit_name("QA REVIEW BAND","Raw")) or not step(model.lock_name()) or not step(model.start_identity()) or not step(model.set_identity("Wordmark","Amber / Charcoal","Unpolished")) or not step(model.finish_identity()) or not step(model.start_playing()): return false
 base=model.game.career.duplicate(true)
 base["unknown_review_sentinel"]={"keep":[2,7]}
 return check(int(base.cash)==250 and int(base.tour_day)==1 and base.members.size()==3,"genuine original250/day1 canonical band")
func stage(songs: int=0, offer: String="standard", seed: Dictionary={}, scheduled: int=4, readiness: int=40) -> Dictionary:
 # Explicit pure numeric boundary fixture; no claim that these were native sessions.
 var state: Dictionary=(base if seed.is_empty() else seed).duplicate(true)
 state.erase(Finance.KEY)
 state.cash=100;state.tour_day=scheduled;state.readiness=readiness;state.morale=40;state.tension=0;state.songs=songs;state.fans=0;state.reputation=10
 state["relationships"]={};state["owned_equipment"]=[];state["gear_records"]={}
 state["booked_show"]={"venue_id":"local","venue":"The Lantern Room","city":"HOMETOWN","day":scheduled,"approach":"tight","session_drummer":false,"travel_plan":"drive_home"}
 state["promoter_offer"]={"venue_id":"local","offer_id":offer};state["gig_night_phase"]="stage"
 return state
func original_perform(before: Dictionary) -> Dictionary:
 var original: Dictionary=Calendar.perform(before)
 if not bool(original.get("ok",false)): return original
 var state: Dictionary=Night.reset_after_show(Promoter.settle(original.state,before))
 var terms: Dictionary=before.get("promoter_offer",{})
 var history: Array=state.get("gig_history",[])
 if not terms.is_empty() and not history.is_empty():
  original.message=str(original.message)+" Promoter settlement: £%d after the %s agreement." % [int((history.back() as Dictionary).get("fee",0)),str(terms.get("offer_id","standard"))]
 state=Life.refresh(Calendar.expire(Story.observe(before,state,"gig:"+str((before.get("booked_show",{}) as Dictionary).get("venue_id","")))))
 original["state"]=state
 return original
func apply_review(before: Dictionary, settled: Dictionary) -> Dictionary:
 var input: Dictionary=before.duplicate(true)
 var outcome: Dictionary=settled.duplicate(true)
 var disk: Dictionary=files()
 var result: Dictionary=Review.apply(before,settled)
 check(before==input and settled==outcome and files()==disk,"review application has no caller/disk mutation")
 return result
func strip_review(state: Dictionary) -> Dictionary:
 var result: Dictionary=state.duplicate(true);result.erase(Review.KEY);return result
func reviewed(songs: int=0, seed: Dictionary={}, scheduled: int=4, readiness: int=40) -> Dictionary:
 var before: Dictionary=stage(songs,"standard",seed,scheduled,readiness)
 var original: Dictionary=original_perform(before)
 if not check(bool(original.get("ok",false)),"protected original show resolves"): return {}
 var result: Dictionary=apply_review(before,original.state)
 if not check(bool(result.get("ok",false)),"new review records actual original settlement"): return {}
 return result.state
func rejected(before: Dictionary, settled: Dictionary) -> void:
 var result: Dictionary=apply_review(before,settled)
 check(not bool(result.get("ok",false)) and result.get("state",{})==before,"invalid recording rejects with exact previous state")

func numeric_and_live_parity() -> void:
 var fees: Array[int]=[11,14,33,35]
 var cashes: Array[int]=[106,109,128,130]
 for songs in range(4):
  for offer in ["standard","guarantee","guestlist"]:
   var before: Dictionary=stage(songs,offer)
   var original: Dictionary=original_perform(before)
   if not check(bool(original.get("ok",false)),"original numeric performance valid"): return
   var result: Dictionary=apply_review(before,original.state)
   if not check(bool(result.get("ok",false)),"numeric performance records once"): return
   var record: Dictionary=Review.latest(result.state)
   var bonus: int=15 if offer=="guarantee" else (-10 if offer=="guestlist" else 0)
   check(int(record.settled_fee)==fees[songs]+bonus and int(result.state.cash)==cashes[songs]+bonus,"independent settled fee11/14/33/35 plus actual original promoter terms")
   check(bool(record.success)==(songs>=2) and int(record.scheduled_day)==4 and int(record.completed_day)==5,"factual actual success and distinct scheduled/completed days")
   check(int(result.state.readiness)==40 and strip_review(result.state)==strip_review(original.state),"recording changes ONLY new metadata; exact original readiness/economy/stats/history retained")
   check(str(record.id)=="s49:show:local:4" and str(result.message)==str(record.body) and str(record.body).contains("£%d" % int(record.settled_fee)),"durable bookingID and authored body retain exact original settledfee")
   var actual: Dictionary=Live.resolve(before,"perform")
   check(bool(actual.get("ok",false)) and strip_review(actual.state)==strip_review(original.state),"integrated live bridge preserves FULL original composition apart from named review metadata")
   check(Review.latest(actual.state)==record,"integrated bridge records the same actual show facts")
   check(str(actual.message)==str(original.message)+"\n\n"+str(record.body),"integrated authored text retains exact original prefix, separator AND explicit full review body")
 var good_zero: Dictionary=reviewed(0,{},4,80)
 var poor_three: Dictionary=reviewed(3,{},4,0)
 check(bool(Review.latest(good_zero).success) and int(Review.latest(good_zero).settled_fee)==23,"zero originals can produce GOOD actual result; do not infer poor from song count")
 check(not str(Review.latest(good_zero).body).contains("recovered"),"first-ever tracked good show cannot claim a previous poor show was recovered")
 check(not bool(Review.latest(poor_three).success) and int(Review.latest(poor_three).settled_fee)==17,"three originals can produce POOR actual result; do not infer good from song count or income")

func recovery_and_queries() -> void:
 var legacy: Dictionary=base.duplicate(true)
 legacy["gig_history"]=[{"venue":"Old room","day":1,"fee":0}]
 var old: Dictionary=legacy.duplicate(true)
 check(bool(Review.validate(legacy).ok) and Review.latest(legacy).is_empty() and int(Review.view(legacy).seq)==0 and legacy==old,"untracked legacy history gets NO fabricated poor review or migration")
 check(bool(Review.eligibility(legacy,"local","guarantee").ok),"legacy missing actual success is neutral, never default false/poor")
 var poor: Dictionary=reviewed()
 if poor.is_empty(): return
 for offer in ["standard","guestlist","guarantee"]:
  var before: Dictionary=poor.duplicate(true)
  var option: Dictionary=Review.eligibility(poor,"local",offer)
  check(poor==before and bool(option.ok)==(offer!="guarantee") and bool(option.restricted)==(offer=="guarantee"),"ONLY guarantee pauses after actual latest poor show; query is pure")
  if offer=="guarantee":check(not str(option.message).is_empty() and str(option.recovery).contains("successful"),"locked offer explains recoverable successful-show requirement")
 var rehearsal: Dictionary=Practice.resolve(poor,"tighten")
 check(bool(rehearsal.get("ok",false)) and not bool(Review.eligibility(rehearsal.state,"local","guarantee").ok),"rehearsal alone NEVER clears actual poor-review restriction")
 var blocked: Dictionary=Live.resolve(poor,"book","guarantee",false)
 check(not bool(blocked.get("ok",false)),"stale enabled guarantee click revalidates restriction at real live commit")
 check(bool(Live.resolve(poor,"book","standard",false).get("ok",false)) and bool(Live.resolve(poor,"book","guestlist",false).get("ok",false)),"normal original standard/guestlist hometown recovery remains available")
 var confirmed: Dictionary=stage(3,"guarantee",poor,8,100)
 var expected: Dictionary=original_perform(confirmed)
 var actual: Dictionary=Live.resolve(confirmed,"perform")
 check(bool(actual.get("ok",false)) and strip_review(actual.state)==strip_review(expected.state) and bool(Review.latest(actual.state).success),"already confirmed guarantee is honoured; booking gate never blocks actual settlement")
 check(bool(Review.eligibility(actual.state,"local","guarantee").ok),"next actual successful show restores guarantee")
 check(str(Review.latest(actual.state).body).contains("has recovered"),"actual poor-to-good transition explicitly reports restored promoter confidence")
 var copy: Dictionary=Review.latest(actual.state);copy["success"]=false
 var view: Dictionary=Review.view(actual.state);view.records.clear()
 check(bool(Review.latest(actual.state).success) and Review.view(actual.state).records.size()==2,"view/latest are independent deep copies")
func trimming_and_replay() -> void:
 var state: Dictionary=base.duplicate(true)
 var first_before: Dictionary={}
 for index in range(85):
  var before: Dictionary=stage(0 if index==0 else 3,"standard",state,4+index*20,0 if index==0 else 100)
  var original: Dictionary=original_perform(before)
  if not check(bool(original.get("ok",false)),"independent original show for review-history cap"): return
  var result: Dictionary=apply_review(before,original.state)
  if not check(bool(result.get("ok",false)),"new original show records across50/80caps"): return
  if index==0:first_before=before.duplicate(true)
  state=result.state
 var data: Dictionary=Review.view(state)
 check(int(data.seq)==85 and data.records.size()==80 and data.seen_ids.size()==85 and state.gig_history.size()==50,"permanent85seen IDs survive80review/50original history caps")
 check(int((data.records[0] as Dictionary).seq)==6 and int(data.last_poor_seq)==1 and int(data.last_success_seq)==85,"trim retains correct counter history without losing poor/success checkpoints")
 var replay: Dictionary=apply_review(first_before,state)
 check(bool(replay.get("ok",false)) and replay.state==state and str(replay.message).is_empty(),"old settled ID replay after record trimming cannot duplicate or regenerate review")
 var identical: Dictionary=apply_review(state,state)
 check(bool(identical.ok) and identical.state==state,"view/reload already-recorded state is idempotent")
 var poor: Dictionary=reviewed()
 var latest_copy: Dictionary=Review.latest(poor)
 var replay_before: Dictionary=stage()
 var repeated: Dictionary=apply_review(replay_before,poor)
 check(bool(repeated.ok) and repeated.state==poor and Review.latest(repeated.state)==latest_copy,"same settled show never increments review sequence twice")
 var extended: Dictionary=poor.duplicate(true)
 extended[Review.KEY]["future_notes"]={"keep":[9]}
 extended[Review.KEY].records[0]["future_record_note"]="retain"
 var next: Dictionary=reviewed(3,extended,24,100)
 check(next[Review.KEY].future_notes=={"keep":[9]} and str((next[Review.KEY].records[0] as Dictionary).future_record_note)=="retain" and next.unknown_review_sentinel=={"keep":[2,7]},"unknown top/record/original-career fields survive next recorded show")

func malformed_and_terminal() -> void:
 var poor: Dictionary=reviewed()
 if poor.is_empty(): return
 for kind in ["version","negative_seq","counter_ahead","seen_type","seen_zero","record_success","negative_fee","bad_day","record_without_seen","duplicate_record"]:
  var corrupt: Dictionary=poor.duplicate(true)
  var data: Dictionary=corrupt[Review.KEY]
  var first: Dictionary=(data.records as Array)[0]
  match kind:
   "version":data.version=2
   "negative_seq":data.seq=-1
   "counter_ahead":data.last_poor_seq=2
   "seen_type":data.seen_ids=[]
   "seen_zero":data.seen_ids[first.id]=0
   "record_success":first.success="false"
   "negative_fee":first.settled_fee=-1
   "bad_day":first.completed_day=first.scheduled_day-1
   "record_without_seen":data.seen_ids.erase(first.id)
   "duplicate_record":data.records.append(first.duplicate(true))
  var input: Dictionary=corrupt.duplicate(true)
  check(not bool(Review.validate(corrupt).get("ok",true)) and not bool(Review.eligibility(corrupt,"local","guarantee").get("ok",true)) and corrupt==input,"known malformed review metadata rejects without mutation: "+kind)
  rejected(corrupt,corrupt)
 var before: Dictionary=stage()
 var original: Dictionary=original_perform(before)
 var missing: Dictionary=original.state.duplicate(true)
 (missing.gig_history.back() as Dictionary).erase("success")
 rejected(before,missing)
 var wrong: Dictionary=original.state.duplicate(true);wrong.gig_history.back()["venue_id"]="bristol"
 rejected(before,wrong)
 var uncleared: Dictionary=original.state.duplicate(true);uncleared.booked_show=before.booked_show.duplicate(true)
 rejected(before,uncleared)
 var no_booking: Dictionary=before.duplicate(true);no_booking.erase("booked_show")
 rejected(no_booking,original.state)
 var extra: Dictionary=original.state.duplicate(true);extra.gig_history.append((extra.gig_history.back() as Dictionary).duplicate(true))
 rejected(before,extra)
 var terminal: Dictionary={"cash":0,"tour_day":1}
 for index in range(14):
  var after: Dictionary=terminal.duplicate(true);after.tour_day=int(terminal.tour_day)+1
  var result: Dictionary=Finance.apply(terminal,after,"zero_day_fixture")
  if not check(bool(result.get("ok",false)),"existing actual finance builds terminal fixture"): return
  terminal=result.state
 terminal[Review.KEY]=poor[Review.KEY].duplicate(true)
 var stable: Dictionary=terminal.duplicate(true)
 check(not bool(Finance.guard(terminal).get("ok",true)) and Review.latest(terminal)==Review.latest(poor) and terminal==stable,"review display cannot bypass or mutate existing terminal finance guard")

func actual_finance_and_save() -> void:
 var before: Dictionary=stage()
 var original: Dictionary=original_perform(before)
 var reviewed_result: Dictionary=apply_review(before,original.state)
 if not check(bool(reviewed_result.get("ok",false)),"real saved review fixture valid"): return
 var accounted: Dictionary=Finance.apply(before,reviewed_result.state,"live:perform")
 if not check(bool(accounted.get("ok",false)),"original settlement and review account in one finance result"): return
 check(int(accounted.state.cash)==106 and int(accounted.state.finance_v1.totals.income["Gig fees"])==11 and int(accounted.state.finance_v1.totals.outgoing.Travel)==5 and int(accounted.state.finance_v1.seq)==1,"independent grossfee11−travel5 gives106; reviews never pay twice")
 var prior: Dictionary=Finance.apply({"cash":0,"tour_day":1},{"cash":0,"tour_day":14},"zero_days",[],[0,0,0,0,0,0,0,0,0,0,0,0,0])
 if check(bool(prior.get("ok",false)),"thirteen true zero closings build rescue fixture"):
  var zero_before: Dictionary=stage(0,"standard",{},14,40)
  zero_before.cash=0;zero_before[Finance.KEY]=prior.state[Finance.KEY].duplicate(true)
  var zero_original: Dictionary=original_perform(zero_before)
  var zero_review: Dictionary=apply_review(zero_before,zero_original.state)
  var zero_account: Dictionary=Finance.apply(zero_before,zero_review.state,"live:perform")
  check(bool(zero_account.get("ok",false)) and int(zero_account.state.cash)==11 and int(zero_account.state.finance_v1.totals.outgoing.Travel)==0 and int(zero_account.state.finance_v1.broke_days)==0 and not Finance.is_over(zero_account.state),"poor hometown fee11 rescues NONterminal13-day run; actual travel0 despite tariff5")
 model.game.career=accounted.state
 var snapshot: Dictionary=model.snapshot()
 check(model.save_draft(),"actual C27 owner saves finance+review under original schema1")
 var loaded: RefCounted=Opening.new()
 check(loaded.load_draft() and loaded.snapshot()==snapshot and int(snapshot.schema_version)==1 and str(loaded.screen)=="play" and str(loaded.game.phase)=="play","actual C27 disk reload preserves full review/finance/cast/schema without invented phase")
 check(not bool(Review.eligibility(loaded.game.career,"local","guarantee").ok) and loaded.game.career.unknown_review_sentinel=={"keep":[2,7]},"saved restriction and original unknowns survive real reload")
 var replay: Dictionary=Review.apply(before,loaded.game.career)
 check(bool(replay.ok) and replay.state==loaded.game.career,"saved result inspection never appends another review")
func run() -> void:
 var path: String=ProjectSettings.globalize_path("user://")
 if not check(path.begins_with(SAFE),"strict fresh isolated S49 userdata guard"): quit(1);return
 for item in [Opening.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  if not check(not FileAccess.file_exists(item),"fresh isolated path "+item): quit(1);return
 protected_initial=files(false)
 if fixture():
  numeric_and_live_parity();recovery_and_queries();trimming_and_replay();malformed_and_terminal();actual_finance_and_save()
 check(files(false)==protected_initial,"all original legacy3/C26 file bytes untouched")
 print("S49_REVIEW_TEST_RESULT ",JSON.stringify({"pass":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info(),"user_data":path,"method":"independent originalCalendar/Promoter/Night/Story/Life and numeric11/14/33/35 expectations; puremetadata/dedup/recovery; actualC27schema1 save/load; native failed-save proof separate"}))
 quit(0 if failures.is_empty() else 1)
