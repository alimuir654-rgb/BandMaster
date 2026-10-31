extends SceneTree
## Root-run pure/original-model/C27 proof. No native or device claims.
const Rules = preload("res://experiments/playable_flightcase/offstage_rules.gd")
const Social = preload("res://Scripts/band_social.gd")
const Story = preload("res://Scripts/career_story.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Life = preload("res://Scripts/member_life.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const SAFE := "/workspace/work/business/s48/"
var checks: int=0
var failures: Array[String]=[]
var model: RefCounted
var base: Dictionary={}
var protected_initial: Dictionary={}

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> bool:
 checks+=1
 if not ok: failures.append(message);push_error("S48_OFFSTAGE_TEST "+message)
 return ok
func files(include_c27: bool=true) -> Dictionary:
 var paths: Array=["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if include_c27: paths.append(Opening.SAVE_PATH)
 var result: Dictionary={}
 for path in paths: result[path]=FileAccess.get_file_as_bytes(str(path)) if FileAccess.file_exists(str(path)) else null
 return result
func fixture_step(result: Variant) -> bool:
 return check(bool(result.get("ok",false)) if result is Dictionary else bool(result),"actual C27 formation API succeeds")
func fixture() -> bool:
 model=Opening.new()
 if not fixture_step(model.begin_new()) or not fixture_step(model.set_genre("Indie rock")) or not fixture_step(model.to_recruit()): return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not fixture_step(model.recruit(id)): return false
 if not fixture_step(model.choose_vocal("cast_jack")) or not fixture_step(model.confirm_lineup()) or not fixture_step(model.start_naming()) or not fixture_step(model.submit_name("QA OFFSTAGE BAND","Raw")) or not fixture_step(model.lock_name()) or not fixture_step(model.start_identity()) or not fixture_step(model.set_identity("Wordmark","Amber / Charcoal","Unpolished")) or not fixture_step(model.finish_identity()) or not fixture_step(model.start_playing()): return false
 base=model.game.career.duplicate(true)
 base["unknown_offstage_sentinel"]={"keep":[8,9]}
 return check(int(base.cash)==250 and int(base.tour_day)==1,"genuine250/day1 canonical trio fixture")
func command(before: Dictionary, verb: String, id: String, choice: String="") -> Dictionary:
 var original: Dictionary=before.duplicate(true)
 var disk: Dictionary=files()
 var result: Dictionary=Rules.outing(before,id) if verb=="outing" else Rules.respond(before,id,choice)
 check(before==original and files()==disk,"pure command never mutates input or disk: "+verb+" "+id)
 return result
func reject(before: Dictionary, verb: String, id: String, choice: String="") -> void:
 var result: Dictionary=command(before,verb,id,choice)
 check(not bool(result.get("ok",false)) and result.get("state",{})==before,"rejected command returns exact previous state")
func event(state: Dictionary, id: String) -> Dictionary:
 var view: Dictionary=Rules.view(state)
 return view.events.get(id,{}) as Dictionary
func post(before: Dictionary, after: Dictionary) -> Dictionary:
 return Life.refresh(Calendar.expire(Story.observe(before,after)))
func original_parity(observed: Dictionary, expected: Dictionary, label: String) -> void:
 var cleaned: Dictionary=observed.duplicate(true)
 cleaned.erase(Rules.KEY)
 var actual_journal: Array=cleaned.get("career_journal",[])
 var original_journal: Array=expected.get("career_journal",[])
 check(actual_journal.size()>=original_journal.size(),"authored encounter does not discard original journal: "+label)
 for index in range(mini(actual_journal.size(),original_journal.size())):
  check(actual_journal[index]==original_journal[index],"original journal rows retained: "+label)
 cleaned["career_journal"]=original_journal.duplicate(true)
 var oracle: Dictionary=expected.duplicate(true);oracle.erase(Rules.KEY)
 check(cleaned==oracle,"all original social/opportunity fields exactly match protected composition: "+label)
func outing_parity() -> void:
 var costs: Dictionary={"watch_gig":15,"drinks":18,"dinner":24}
 for id in costs:
  var original: Dictionary=Social.attend(base,str(id))
  var result: Dictionary=command(base,"outing",str(id))
  if not check(bool(result.get("ok",false)) and bool(original.get("ok",false)),"each actual original outing succeeds"): return
  original_parity(result.state,post(base,original.state),str(id))
  check(int(result.state.cash)==250-int(costs[id]) and int(result.state.tour_day)==2,"independent exact trio15/18/24 cost and one elapsed day")
  check(str(result.finance_action)=="social:"+str(id) and str(result.return_page)=="offstage","command gives explicit source and existing return page")
  var accounted: Dictionary=Finance.apply(base,result.state,str(result.finance_action))
  check(bool(accounted.get("ok",false)) and int(accounted.state.finance_v1.totals.outgoing.get("Social",0))==int(costs[id]),"caller applies dedicated Social cost once after original result")
 var away: Dictionary=base.duplicate(true)
 away.members[2]["life_status"]="away";away.members[2]["available_day"]=2
 var result: Dictionary=command(away,"outing","watch_gig")
 var original: Dictionary=Social.attend(away,"watch_gig")
 if check(bool(result.get("ok",false)),"returning-at-end fixture valid"):
  original_parity(result.state,post(away,original.state),"returning musician")
  check(int(result.state.cash)==240 and str(result.state.members[2].life_status)=="active" and int(result.state.members[2].morale)==55 and int(result.state.members[2].fatigue)==5,"charge only TWO before-active members; returning drummer gets no retroactive outing bonus")
 var poor: Dictionary=base.duplicate(true);poor.cash=14
 reject(poor,"outing","watch_gig")
 var alone: Dictionary=base.duplicate(true);alone.members[1]["life_status"]="away";alone.members[2]["life_status"]="away"
 reject(alone,"outing","watch_gig")
 reject(base,"outing","unknown")
func pending_promoter() -> Dictionary:
 var result: Dictionary=command(base,"outing","watch_gig")
 return result.get("state",{}) as Dictionary
func promoter_and_queries() -> void:
 var legacy: Dictionary=base.duplicate(true);legacy["social_counters"]={"watch_gig":10}
 var original: Dictionary=legacy.duplicate(true)
 var view: Dictionary=Rules.view(legacy)
 var previews: Array=Rules.activities(legacy)
 check(legacy==original and Rules.pending(legacy).is_empty() and not legacy.has(Rules.KEY),"view/activities never backfill historical introductions")
 check(previews.size()==3 and int((previews[0] as Dictionary).cost)==15,"actual activity preview preserves full trio cost")
 var first: Dictionary=command(legacy,"outing","watch_gig")
 if not check(bool(first.get("ok",false)),"first tracked post-upgrade watch succeeds"): return
 var invitation: Dictionary=event(first.state,Rules.PROMOTER)
 check(str(invitation.status)=="pending" and int(invitation.source_counter)==11 and int(invitation.source_day)==2 and str(invitation.source_action)=="watch_gig","legacycount10 still creates exactly one NEW tracked promoter intro")
 check(Rules.view(first.state).contacts.size()==1 and first.state.members.size()==3,"business contact never creates another musician")
 var pending_copy: Array=Rules.pending(first.state)
 (pending_copy[0] as Dictionary)["status"]="tampered"
 var view_copy: Dictionary=Rules.view(first.state);view_copy.contacts.clear()
 check(str(event(first.state,Rules.PROMOTER).status)=="pending" and Rules.view(first.state).contacts.size()==1,"pending/view return deep copies")
 var second: Dictionary=command(first.state,"outing","watch_gig")
 check(bool(second.ok) and event(second.state,Rules.PROMOTER)==invitation and Rules.view(second.state).contacts.size()==1,"another legitimate outing cannot duplicate or refresh pending introduction")
 var declined: Dictionary=command(first.state,"respond",Rules.PROMOTER,"decline")
 check(bool(declined.ok) and int(declined.state.cash)==235 and int(declined.state.tour_day)==2 and str(event(declined.state,Rules.PROMOTER).status)=="declined","explicit decline consumes once with no cash/day")
 reject(declined.state,"respond",Rules.PROMOTER,"accept")
 var later: Dictionary=command(declined.state,"outing","watch_gig")
 check(bool(later.ok) and str(event(later.state,Rules.PROMOTER).status)=="declined" and Rules.pending(later.state).is_empty(),"declined intro is sticky and never regenerated")
 var pending: Dictionary=pending_promoter()
 var expected: Dictionary=Live.resolve(pending,"book","standard",false)
 var accepted: Dictionary=command(pending,"respond",Rules.PROMOTER,"accept")
 if not check(bool(expected.ok) and bool(accepted.ok),"promoter acceptance uses actual original booking"): return
 original_parity(accepted.state,expected.state,"actual standard booking")
 check(int(accepted.state.cash)==235 and int(accepted.state.tour_day)==2 and int(accepted.state.booked_show.day)==5 and accepted.state.gig_history.is_empty(),"booking is £0/day0/currentday+3 and creates NO completed-show reward")
 check(str(event(accepted.state,Rules.PROMOTER).status)=="accepted" and str(accepted.return_page)=="gigs","accepted event persisted and routes to original live desk")
 reject(accepted.state,"respond",Rules.PROMOTER,"accept")
 reject(pending,"respond",Rules.PROMOTER,"careful")
 reject(pending,"respond","unknown","accept")
 var no_drummer: Dictionary=pending.duplicate(true);no_drummer.members[2]["life_status"]="away"
 reject(no_drummer,"respond",Rules.PROMOTER,"accept")
 var booked: Dictionary=Live.resolve(pending,"book","standard",false)
 reject(booked.state,"respond",Rules.PROMOTER,"accept")
 var showday: Dictionary=booked.state.duplicate(true);showday.tour_day=5
 reject(showday,"outing","dinner");reject(showday,"respond",Rules.PROMOTER,"accept")
 var exact: Dictionary=base.duplicate(true);exact.cash=15
 var zero: Dictionary=command(exact,"outing","watch_gig")
 var account: Dictionary=Finance.apply(exact,zero.state,str(zero.finance_action))
 var zero_accept: Dictionary=command(account.state,"respond",Rules.PROMOTER,"accept")
 var booked_account: Dictionary=Finance.apply(account.state,zero_accept.state,str(zero_accept.finance_action))
 check(bool(booked_account.ok) and int(booked_account.state.cash)==0 and int(booked_account.state.finance_v1.broke_days)==1,"normal zero-cash booking is allowed without aging/rescuing one broke day")
func accepted_base() -> Dictionary:
 var pending: Dictionary=pending_promoter()
 var accepted: Dictionary=command(pending,"respond",Rules.PROMOTER,"accept")
 if not check(bool(accepted.get("ok",false)),"scout fixture has actual accepted promoter"): return {}
 var cancelled: Dictionary=Live.resolve(accepted.state,"cancel")
 if not check(bool(cancelled.get("ok",false)),"scout fixture clears original booking by real cancellation"): return {}
 return cancelled.state as Dictionary
func scout_contract() -> void:
 var accepted: Dictionary=accepted_base()
 if accepted.is_empty(): return
 for fans in [24,25]:
  for rep in [9,10]:
   var state: Dictionary=accepted.duplicate(true);state.fans=fans;state.reputation=rep
   var result: Dictionary=command(state,"outing","dinner")
   if not check(bool(result.get("ok",false)),"exact milestone fixture outing succeeds"): return
   check(Rules.view(result.state).contacts.has(Rules.SCOUT)==(fans==25 and rep==10),"exact independent scout boundary fans24/25 AND reputation9/10")
 var no_accept: Dictionary=pending_promoter();no_accept.fans=25;no_accept.reputation=10
 var blocked_scout: Dictionary=command(no_accept,"outing","dinner")
 check(bool(blocked_scout.ok) and not Rules.view(blocked_scout.state).contacts.has(Rules.SCOUT),"pending promoter cannot unlock scout")
 for activity in ["dinner","drinks","watch_gig"]:
  var state: Dictionary=accepted.duplicate(true);state.fans=25;state.reputation=10
  var result: Dictionary=command(state,"outing",activity)
  if not check(bool(result.get("ok",false)),"later any original outing succeeds"): return
  check(str(event(result.state,Rules.SCOUT).status)=="pending" and Rules.view(result.state).contacts.size()==2,"ANY later qualifying outing creates one business scout, not cast")
  var snapshot: Dictionary=result.state.duplicate(true)
  var options: Array=Rules.response_options(result.state,Rules.SCOUT)
  check(options.size()==3 and result.state==snapshot and not (result.state.get("opportunities_seen",{}) as Dictionary).has("first_feature"),"querying scout choices does NOT seed original opportunity")
  for choice in ["open","careful"]:
   var seeded: Dictionary=result.state.duplicate(true)
   var seen: Dictionary=seeded.get("opportunities_seen",{}).duplicate(true);seen["first_feature"]=true;seeded["opportunities_seen"]=seen
   var original: Dictionary=Opportunities.resolve(seeded,"first_feature",choice)
   var response: Dictionary=command(result.state,"respond",Rules.SCOUT,choice)
   if not check(bool(response.get("ok",false)) and bool(original.get("ok",false)),"original first_feature response succeeds"): return
   original_parity(response.state,post(result.state,original.state),"scout "+choice)
   check(int(response.state.cash)==int(result.state.cash) and int(response.state.tour_day)==int(result.state.tour_day)+1 and int(response.state.fans)==25+(15 if choice=="open" else 7),"original interview independent +15/+7fans, £0 and ONE day")
   check(str(response.state.opportunities_resolved.first_feature)==choice and str(event(response.state,Rules.SCOUT).status)=="accepted","original once-resolved feature and contact both persist")
   reject(response.state,"respond",Rules.SCOUT,choice)
  var declined: Dictionary=command(result.state,"respond",Rules.SCOUT,"decline")
  check(bool(declined.ok) and int(declined.state.cash)==int(result.state.cash) and int(declined.state.tour_day)==int(result.state.tour_day),"scout decline is genuinely cash0/day0")
  var again: Dictionary=command(declined.state,"outing",activity)
  check(bool(again.ok) and str(event(again.state,Rules.SCOUT).status)=="declined","scout decline never regenerates on later outing")
  reject(declined.state,"respond",Rules.SCOUT,"open")
 var prior: Dictionary=accepted.duplicate(true);prior.fans=25;prior.reputation=10;prior["opportunities_resolved"]={"first_feature":"careful"}
 var met: Dictionary=command(prior,"outing","dinner")
 check(bool(met.ok) and str(event(met.state,Rules.SCOUT).status)=="already_resolved" and Rules.pending(met.state).is_empty() and met.state.opportunities_resolved==prior.opportunities_resolved,"legacy resolved feature can meet scout but NEVER gets another pending reward")
 reject(met.state,"respond",Rules.SCOUT,"open")
 var consumed: Dictionary=met.state.duplicate(true)
 consumed[Rules.KEY]["contacts"].erase(Rules.SCOUT)
 var retried: Dictionary=command(consumed,"outing","dinner")
 check(bool(retried.ok) and str(event(retried.state,Rules.SCOUT).status)=="already_resolved" and Rules.pending(retried.state).is_empty(),"consumed scout event remains authoritative even when contact metadata is missing")
func invalid_and_terminal() -> void:
 for raw in [{"version":2,"events":{},"contacts":{}},{"version":1,"events":[],"contacts":{}},"invalid"]:
  var state: Dictionary=base.duplicate(true);state[Rules.KEY]=raw
  reject(state,"outing","watch_gig");reject(state,"respond",Rules.PROMOTER,"accept")
 var state: Dictionary=base.duplicate(true);state.cash=0
 for index in range(14):
  var after: Dictionary=state.duplicate(true);after.tour_day=int(state.tour_day)+1
  var accounted: Dictionary=Finance.apply(state,after,"test_zero_day")
  if not check(bool(accounted.get("ok",false)),"real finance creates terminal fixture by14elapsed days"): return
  state=accounted.state
 var pending: Dictionary=pending_promoter()
 state[Rules.KEY]=pending[Rules.KEY].duplicate(true)
 check(Finance.is_over(state),"terminal fixture remains protected by original finance policy")
 reject(state,"outing","watch_gig");reject(state,"respond",Rules.PROMOTER,"accept");reject(state,"respond",Rules.PROMOTER,"decline")
 var unknown: Dictionary=pending.duplicate(true)
 unknown[Rules.KEY]["future_notes"]={"keep":[1,2]}
 var declined: Dictionary=command(unknown,"respond",Rules.PROMOTER,"decline")
 check(bool(declined.ok) and declined.state[Rules.KEY].future_notes=={"keep":[1,2]} and declined.state.unknown_offstage_sentinel=={"keep":[8,9]},"unknown nested contact and original career fields preserved")
func disk_roundtrip() -> void:
 var watched: Dictionary=command(base,"outing","watch_gig")
 var account: Dictionary=Finance.apply(base,watched.state,str(watched.finance_action))
 if not check(bool(account.get("ok",false)),"one original outing accounted for real C27 disk fixture"): return
 model.game.career=account.state
 check(model.save_draft(),"actual C27 owner saves pending contact+finance under schema1")
 var snapshot: Dictionary=model.snapshot()
 var loaded: RefCounted=Opening.new()
 check(loaded.load_draft() and loaded.snapshot()==snapshot and int(snapshot.schema_version)==1 and str(loaded.screen)=="play" and str(loaded.game.phase)=="play","actual pending-intro disk reload preserves complete original schema/finance/cast")
 var accepted: Dictionary=command(loaded.game.career,"respond",Rules.PROMOTER,"accept")
 var booked: Dictionary=Finance.apply(loaded.game.career,accepted.state,str(accepted.finance_action))
 if not check(bool(booked.get("ok",false)),"actual restored intro accepts/book accounts once"): return
 loaded.game.career=booked.state
 check(loaded.save_draft(),"real owner saves accepted original booking/contact atomically")
 var resumed: RefCounted=Opening.new()
 check(resumed.load_draft() and resumed.snapshot()==loaded.snapshot() and int(resumed.game.career.cash)==235 and int(resumed.game.career.tour_day)==2 and int(resumed.game.career.booked_show.day)==5,"actual accepted disk reload retains235/day2/showday5")
 check(int(resumed.game.career.finance_v1.totals.outgoing.Social)==15 and int(resumed.game.career.finance_v1.broke_days)==0 and int(resumed.game.career.finance_v1.seq)==2,"one paid outing plus0day booking: Social15,seq2,zero broke days")
 reject(resumed.game.career,"respond",Rules.PROMOTER,"accept")
func run() -> void:
 var path: String=ProjectSettings.globalize_path("user://")
 if not check(path.begins_with(SAFE),"strict fresh S48 user-data guard"): quit(1);return
 for item in [Opening.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  if not check(not FileAccess.file_exists(item),"fresh isolated save path "+item): quit(1);return
 protected_initial=files(false)
 if fixture():
  outing_parity();promoter_and_queries();scout_contract();invalid_and_terminal();disk_roundtrip()
 check(files(false)==protected_initial,"original legacy3/C26 bytes untouched")
 print("S48_OFFSTAGE_TEST_RESULT ",JSON.stringify({"pass":failures.is_empty(),"checks":checks,"errors":failures,"engine":Engine.get_version_info(),"user_data":path,"method":"independent exact originalSocial/Story/Calendar/Life and originalfirst_feature/book oracles; numeric costs/thresholds; realC27schema1save/load; no native/device claim"}))
 quit(0 if failures.is_empty() else 1)
