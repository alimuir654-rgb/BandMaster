extends SceneTree
## Headless original-model/C27 save contract proof. No UI/input/device claims.
## Root copies this scratch file into an exact isolated runtime and runs it.
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Reviews = preload("res://experiments/playable_flightcase/review_policy.gd")
const Career = preload("res://experiments/playable_flightcase/career_bridge.gd")
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const Session = preload("res://experiments/playable_flightcase/session.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Night = preload("res://Scripts/gig_night_flow.gd")
const Incident = preload("res://Scripts/gig_backstage_incident.gd")
const Tour = preload("res://Scripts/tour_itinerary.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Brief = preload("res://Scripts/live_night_briefing.gd")
const SAFE_ROOT := "/workspace/work/unify/s46/"
var output := "/workspace/work/unify/s46/live-model-proof"
var model
var base: Dictionary = {}
var checks := 0
var bridge_calls := 0
var practice_calls := 0
var failures: Array[String] = []
var observations: Array = []
var protected_initial: Dictionary = {}

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
 call_deferred("run")

func check(ok: bool, message: String) -> bool:
 checks += 1
 if not ok:
  failures.append(message)
  push_error("S46_LIVE_MODEL_TEST "+message)
 return ok

func disk_files(include_c27: bool = true) -> Dictionary:
 var paths: Array = ["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if include_c27: paths.append(Opening.SAVE_PATH)
 var result: Dictionary = {}
 for path in paths:
  result[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result

func fixture_step(label: String, result: Variant) -> bool:
 return check(bool(result.get("ok",false)) if result is Dictionary else bool(result),"actual C27 fixture: "+label)

func fixture() -> bool:
 model = Opening.new()
 if not fixture_step("begin",model.begin_new()): return false
 if not fixture_step("genre",model.set_genre("Indie rock")): return false
 if not fixture_step("auditions",model.to_recruit()): return false
 for candidate in ["cast_jack","cast_zoe","cast_casey"]:
  if not fixture_step("recruit "+candidate,model.recruit(candidate)): return false
 if not fixture_step("Jack vocals",model.choose_vocal("cast_jack")): return false
 if not fixture_step("lineup",model.confirm_lineup()): return false
 if not fixture_step("naming",model.start_naming()): return false
 if not fixture_step("proposal",model.submit_name("QA LOCAL LIVE BAND","Raw")): return false
 if not fixture_step("lock",model.lock_name()): return false
 if not fixture_step("identity",model.start_identity()): return false
 if not fixture_step("design",model.set_identity("Wordmark","Amber / Charcoal","Unpolished")): return false
 if not fixture_step("complete",model.finish_identity()): return false
 if not fixture_step("play",model.start_playing()): return false
 base = model.game.career.duplicate(true)
 check(not base.has("van_health") and not base.has("reputation"),"real C27 fixture has no invented tutorial van45/reputation10")
 check(int(base.cash)==250 and int(base.tour_day)==1 and base.members.size()==3,"actual current-band cash/day/lineup retained")
 var resumed := Opening.new()
 return check(resumed.load_draft() and resumed.snapshot()==model.snapshot(),"actual C27 formation saves and reloads unchanged")

func post(before: Dictionary, after: Dictionary, source: String = "") -> Dictionary:
 return Life.refresh(Calendar.expire(Story.observe(before,after,source)))

func original_eligibility(state: Dictionary, hire: bool = false) -> bool:
 var active := 0
 var drummer := false
 for person in state.get("members",[]):
  if person is Dictionary and str(person.get("life_status","active"))=="active":
   active += 1
   if str(person.get("role","")).to_lower().contains("drum"): drummer = true
 var normal: bool = active>=2 and drummer
 if not hire: return normal
 # Original promoter UI only offers this fallback for an insufficient lineup.
 return not normal and active>=1 and bool(Promoter.negotiate(state,"local","standard").get("ok",false)) and bool(Tour.validate(state,"local",Tour.DRIVE,true).get("ok",false))

func original_result(state: Dictionary, verb: String, choice: String = "", hire: bool = false) -> Dictionary:
 var result: Dictionary
 var source := ""
 if verb in ["advance","perform","cancel","expire"] and not choice.is_empty(): return {"ok":false}
 match verb:
  "book":
   if not Promoter.OFFERS.has(choice) or not original_eligibility(state,hire) or (hire and choice!="standard"): return {"ok":false}
   result = Promoter.book(state,"local",choice,hire,Tour.DRIVE)
  "advance":
   if str(Night.stage(state).get("phase",""))!="arrival": return {"ok":false}
   return Night.advance(state)
  "soundcheck":
   result = Night.choose_set(state,choice)
   if not bool(result.get("ok",false)): return result
   var advanced: Dictionary = Night.advance(result.state)
   if not bool(advanced.get("ok",false)): return advanced
   result["state"] = advanced.state
   return result
  "incident":
   source = "backstage"
   result = Incident.resolve(state,choice)
  "perform":
   if not bool(Night.stage(state).get("can_play",false)): return {"ok":false}
   var booking: Dictionary = Calendar.pending(state)
   source = "gig:"+str(booking.get("venue_id",""))
   result = Calendar.perform(state)
   if bool(result.get("ok",false)):
    result["state"] = Night.reset_after_show(Promoter.settle(result.state,state))
    var terms: Dictionary = state.get("promoter_offer",{})
    var history: Array = result.state.get("gig_history",[])
    if not terms.is_empty() and not history.is_empty():
     result["message"] = str(result.get("message","Show finished."))+" Promoter settlement: £%d after the %s agreement." % [int(history.back().get("fee",0)),str(terms.get("offer_id","standard"))]
  "cancel":
   source = "booking_cancel"
   result = Calendar.cancel(state)
  "expire":
   var booking: Dictionary = Calendar.pending(state)
   if booking.is_empty() or int(state.get("tour_day",1))<=int(booking.get("day",0)): return {"ok":false}
   # Original expire returns a career dictionary rather than an action message.
   return {"ok":true,"state":post(state,Calendar.expire(state))}
  _: return {"ok":false}
 if bool(result.get("ok",false)): result["state"] = post(state,result.state,source)
 return result

func dispatch(state: Dictionary, verb: String, choice: String = "", hire: bool = false) -> Dictionary:
 var before: Dictionary = state.duplicate(true)
 var saved: Dictionary = disk_files()
 var owner: Dictionary = model.snapshot()
 var result: Dictionary = Live.resolve(state,verb,choice,hire)
 bridge_calls += 1
 check(state==before,"pure live input immutable: "+verb+" "+choice)
 check(model.snapshot()==owner and disk_files()==saved,"pure live bridge has no owner/disk side effects: "+verb)
 observations.append({"verb":verb,"choice":choice,"hire":hire,"ok":bool(result.get("ok",false)),"message":str(result.get("message","")),"day":result.get("state",{}).get("tour_day",null)})
 return result

func parity(state: Dictionary, verb: String, choice: String = "", hire: bool = false) -> Dictionary:
 var before: Dictionary = state.duplicate(true)
 var expected: Dictionary = original_result(state,verb,choice,hire)
 check(state==before,"unchanged original oracle preserves input: "+verb)
 var actual: Dictionary = dispatch(state,verb,choice,hire)
 var success: bool = bool(expected.get("ok",false))
 check(bool(actual.get("ok",false))==success,"original success/rejection parity: "+verb+" "+choice)
 if success:
  var actual_state: Dictionary = (actual.get("state",{}) as Dictionary).duplicate(true)
  var expected_state: Dictionary = (expected.get("state",{}) as Dictionary).duplicate(true)
  # S49 owns only this additive key. Other commands must preserve it exactly.
  if verb=="perform":
   actual_state.erase(Reviews.KEY)
   expected_state.erase(Reviews.KEY)
  check(actual_state==expected_state,"exact original full state composition except named new review metadata: "+verb+" "+choice)
  if expected.has("message"):
   var original_message: String = str(expected.get("message",""))
   if verb=="perform":
    var report: Dictionary = Reviews.latest(actual.get("state",{}) as Dictionary)
    check(not report.is_empty() and not str(report.get("body","")).is_empty(),"S49 performance has an explicit separately tested factual review")
    original_message+="\n\n"+str(report.get("body",""))
   check(actual.get("message")==original_message,"exact original authored message plus explicit S49 review body: "+verb+" "+choice)
 return actual

func rejected(state: Dictionary, verb: String, choice: String = "", hire: bool = false) -> void:
 check(not bool(parity(state,verb,choice,hire).get("ok",true)),"invalid/no-op action rejects: "+verb+" "+choice)

func eligibility(state: Dictionary, hire: bool) -> void:
 var before: Dictionary = state.duplicate(true)
 var saved: Dictionary = disk_files()
 var actual: Dictionary = Live.booking_eligibility(state,hire)
 check(bool(actual.get("ok",false))==original_eligibility(state,hire),"original promoter-UI lineup/session eligibility")
 check(state==before and disk_files()==saved,"eligibility is read-only")

func practice(state: Dictionary, kind: String) -> Dictionary:
 # Use the protected, real C27 Session APIs, including authored risk/outcome.
 var game := Session.new()
 var snapshot: Dictionary = model.game.snapshot()
 snapshot["career"] = state.duplicate(true)
 if not check(game.restore(snapshot),"real Session accepts current C27 career fixture"): return state
 var before: Dictionary = game.career.duplicate(true)
 var result: Dictionary
 if kind=="create": result = game.write_session("Riff","Verse / Chorus","S46 EXISTING ORIGINAL",0)
 elif kind=="tighten": result = game.rehearse()
 else: result = game.clear_air()
 if not check(bool(result.get("ok",false)),"real existing preparation resolver: "+kind): return state
 var raw: Dictionary = game.career.duplicate(true)
 var saved: Dictionary = disk_files()
 var actual: Dictionary = Live.after_practice(before,raw)
 practice_calls += 1
 check(game.career==raw and disk_files()==saved,"after_practice is pure over the actual Session result")
 if Calendar.pending(before).is_empty():
  check(actual==raw,"no-booking preparation is an exact deep copy, with no new effects")
  return actual
 var expected: Dictionary = post(before,raw)
 var actual_core: Dictionary = actual.duplicate(true)
 var expected_core: Dictionary = expected.duplicate(true)
 actual_core.erase("last_rehearsal_outcome")
 expected_core.erase("last_rehearsal_outcome")
 check(actual_core==expected_core,"preparation exact original Story→expire→Life composition")
 var original_report: Dictionary = raw.get("last_rehearsal_outcome",{})
 var report: Dictionary = actual.get("last_rehearsal_outcome",{})
 check(report.size()==original_report.size(),"postprocessing adds no report schema fields")
 for key in original_report.keys():
  if key not in ["metrics","reason"]: check(report.get(key)==original_report[key],"original report identity/member/source field retained: "+str(key))
 var original_metrics: Dictionary = original_report.get("metrics",{})
 var metrics: Dictionary = report.get("metrics",{})
 check(metrics.size()==original_metrics.size(),"only existing metric rows are reconciled")
 for key in original_metrics.keys():
  if not check(metrics.has(key),"existing report metric retained: "+str(key)): continue
  if not original_metrics[key] is Dictionary: continue
  var row: Dictionary = metrics[key]
  if key in ["cash","tour_day","readiness","morale","tension","cohesion"]:
   var old_value: int = game._cohesion(before) if key=="cohesion" else int(before.get(key,0))
   var new_value: int = game._cohesion(expected) if key=="cohesion" else int(expected.get(key,0))
   check(int(row.get("before",-99999))==old_value and int(row.get("after",-99999))==new_value and int(row.get("delta",-99999))==new_value-old_value,"saved report row describes final original state: "+str(key))
 check(str(report.get("reason","")).begins_with(str(original_report.get("reason",""))),"original practice reason is retained before post-journal text")
 var raw_ids: Array = []
 for entry in raw.get("career_journal",[]):
  if entry is Dictionary: raw_ids.append(str(entry.get("id","")))
 for entry in expected.get("career_journal",[]):
  if entry is Dictionary and not raw_ids.has(str(entry.get("id",""))):
   check(str(report.get("reason","")).contains(str(entry.get("text",""))),"new original post-journal consequence is accessible in saved reason")
 return actual

func booked(offer: String = "standard", state: Dictionary = {}) -> Dictionary:
 var result: Dictionary = parity(base if state.is_empty() else state,"book",offer)
 return result.get("state",{})

func prepared(state: Dictionary) -> Dictionary:
 var current: Dictionary = state.duplicate(true)
 for kind in ["create","tighten","connect"]:
  check(not Live.show_day(current),"preparation allowed before exact booked day")
  var old_day := int(current.get("tour_day",1))
  current = practice(current,kind)
  check(int(current.get("tour_day",1))==old_day+1,"existing preparation advances exactly one day")
 return current

func case_booking_and_preparation() -> void:
 practice(base,"connect")
 for offer in ["standard","guarantee","guestlist"]:
  var current: Dictionary = booked(offer)
  if not check(not current.is_empty(),"real C27 trio books original "+offer): return
  check(int(Calendar.pending(current).get("day",0))==4 and int(current.tour_day)==1 and int(current.cash)==250,"original booking is free, immediate, three days ahead")
  check(not current.has("van_health") and not current.has("reputation"),"booking never imports tutorial van/reputation")
  rejected(current,"book",offer)
  rejected(current,"advance")
  rejected(current,"perform")
  current = prepared(current)
  check(Live.show_day(current) and Career.show_day(current),"both exact original predicates recognise actual third preparation day")
  var before: Dictionary = current.duplicate(true)
  check(not bool(Career.gear_action(current,"buy","amp").get("ok",true)) and current==before,"existing pure gear action is blocked on show day without mutation")
  # Actual practice-UI blocking is a separate native integration test.
  var plain: Dictionary = current.duplicate(true)
  plain.erase("last_rehearsal_outcome")
  var no_report: Dictionary = Live.after_practice(current,plain)
  check(not no_report.has("last_rehearsal_outcome"),"after_practice never invents an absent report")
 for verb in ["unknown","advance","perform","cancel","expire"]: rejected(base,verb)
 for choice in ["","unknown"]: rejected(base,"book",choice)

func case_night_and_settlement() -> void:
 for offer in ["standard","guarantee","guestlist"]:
  var ready: Dictionary = prepared(booked(offer))
  for approach in ["tight","wild","crowd"]:
   var arrival: Dictionary = parity(ready,"advance")
   if not check(bool(arrival.get("ok",false)),"arrival enters soundcheck"): return
   var sound: Dictionary = arrival.state
   check(str(Night.stage(sound).get("phase",""))=="soundcheck" and int(sound.tour_day)==int(ready.tour_day) and int(sound.cash)==int(ready.cash),"arrival staging consumes no day/cash")
   rejected(sound,"advance")
   rejected(sound,"perform")
   rejected(sound,"soundcheck","")
   rejected(sound,"soundcheck","unknown")
   var chosen: Dictionary = parity(sound,"soundcheck",approach)
   if not check(bool(chosen.get("ok",false)),"explicit original approach advances to stage"): return
   var stage: Dictionary = chosen.state
   check(bool(Night.stage(stage).get("can_play",false)) and str(Calendar.pending(stage).get("approach",""))==approach,"original stage and chosen approach retained")
   rejected(stage,"soundcheck",approach)
   var result: Dictionary = parity(stage,"perform")
   if not check(bool(result.get("ok",false)),"original booked show settles"): return
   var after: Dictionary = result.state
   check(Calendar.pending(after).is_empty() and after.get("promoter_offer",{}).is_empty() and str(after.get("gig_night_phase",""))=="arrival","show clears booking/contract and resets next night")
   check(after.gig_history.size()==stage.gig_history.size()+1 and int(after.tour_day)==int(stage.tour_day)+1,"exactly one original local show and original duration")
   check(int(after.get("action_count",0))==int(stage.get("action_count",0)),"performance has no invented action-count increment")
   check(int(after.get("van_health",-1))==0,"original missing-van default0 retained after local show")
   check(str(after.gig_history.back().get("promoter_terms",""))==offer and str(after.gig_history.back().get("approach",""))==approach,"actual original deal and approach saved in history")
   check(not Brief.last_show(after).is_empty(),"existing pure last-show view reads saved history")
   rejected(after,"perform")
   rejected(after,"cancel")
   rejected(after,"expire")
 # An explicit boundary fixture verifies successful deal bonuses as well as poor shows.
 var strong: Dictionary = base.duplicate(true)
 strong.readiness=100
 strong.morale=90
 strong.tension=0
 strong.songs=3
 var results: Dictionary = {}
 for offer in ["standard","guarantee","guestlist"]:
  var current: Dictionary = booked(offer,strong)
  current.tour_day=int(Calendar.pending(current).day)
  current=parity(current,"advance").get("state",{})
  current=parity(current,"soundcheck","tight").get("state",{})
  var outcome: Dictionary=parity(current,"perform")
  if not check(bool(outcome.get("ok",false)),"strong boundary show settles"): return
  results[offer]=outcome.state
  check(bool(outcome.state.gig_history.back().success),"strong original set succeeds without fabricated gameplay bonus")
 check(int(results.guarantee.cash)==int(results.standard.cash)+15 and int(results.guestlist.cash)==int(results.standard.cash)-10,"original promoter fee differences retained exactly")
 check(int(results.guestlist.fans)==int(results.standard.fans)+3,"original successful guest-list fan bonus retained")

func case_lineup_cash_and_incident() -> void:
 eligibility(base,false)
 eligibility(base,true)
 rejected(base,"book","standard",true)
 var away: Dictionary=base.duplicate(true)
 away.members[2].life_status="away"
 away.members[2].available_day=100
 eligibility(away,false)
 eligibility(away,true)
 rejected(away,"book","standard")
 rejected(away,"book","guarantee",true)
 var hired: Dictionary=parity(away,"book","standard",true)
 check(bool(hired.get("ok",false)) and bool(hired.get("state",{}).get("booked_show",{}).get("session_drummer",false)),"original session-drummer fallback is explicit and stored")
 if bool(hired.get("ok",false)):
  var current: Dictionary=hired.state
  current.tour_day=int(Calendar.pending(current).day)
  current=parity(current,"advance").get("state",{})
  current=parity(current,"soundcheck","tight").get("state",{})
  var played: Dictionary=parity(current,"perform")
  check(bool(played.get("ok",false)) and int(played.get("state",{}).get("gig_history",[]).back().get("session_fee",0))==25,"original session drummer costs exactly25 once at settlement")
 var poor: Dictionary=away.duplicate(true)
 poor.cash=29
 eligibility(poor,true)
 rejected(poor,"book","standard",true)
 var none: Dictionary=away.duplicate(true)
 for member in none.members:
  member.life_status="away"
  member.available_day=100
 eligibility(none,false)
 eligibility(none,true)
 rejected(none,"book","standard",true)
 var zero: Dictionary=base.duplicate(true)
 zero.cash=0
 var current: Dictionary=booked("standard",zero)
 check(not current.is_empty(),"original hometown booking remains available at zero cash")
 for ignored in range(3): current=practice(current,"connect")
 current=parity(current,"advance").get("state",{})
 current=parity(current,"soundcheck","crowd").get("state",{})
 var zero_result: Dictionary=parity(current,"perform")
 check(bool(zero_result.get("ok",false)),"zero-cash original hometown recovery loop completes")
 var sound: Dictionary=prepared(booked())
 sound.members[1].fatigue=60
 sound=parity(sound,"advance").get("state",{})
 check(not Incident.incident(sound).is_empty(),"actual Casey/Zoe roster boundary bassist fatigue60 triggers original incident")
 for choice in ["rest","simplify","push"]:
  var result: Dictionary=parity(sound,"incident",choice)
  check(bool(result.get("ok",false)),"original soundcheck illness choice: "+choice)
  if bool(result.get("ok",false)): rejected(result.state,"incident",choice)
 rejected(sound,"incident","")
 rejected(sound,"incident","unknown")
 # Root verified original CareerHub always permits Continue: incident is optional.
 var optional: Dictionary=parity(sound,"soundcheck","tight")
 check(bool(optional.get("ok",false)) and bool(Night.stage(optional.get("state",{})).get("can_play",false)),"unresolved optional incident does not invent a new stage lock")

func case_cancel_expire_and_report_reconciliation() -> void:
 var booking: Dictionary=booked()
 var cancelled: Dictionary=parity(booking,"cancel")
 check(bool(cancelled.get("ok",false)) and int(cancelled.get("state",{}).get("cash",0))==235,"original calendar cancellation fee remains15")
 if bool(cancelled.get("ok",false)): rejected(cancelled.state,"cancel")
 rejected(booking,"expire")
 var overdue: Dictionary=booking.duplicate(true)
 overdue.tour_day=5
 overdue.reputation=20
 var old_morale:=int(overdue.morale)
 var expired: Dictionary=parity(overdue,"expire")
 if not check(bool(expired.get("ok",false)),"original overdue show resolves"): return
 check(Calendar.pending(expired.state).is_empty() and int(expired.state.reputation)==12 and int(expired.state.morale)==old_morale-6,"one original missed-show reputation/morale penalty")
 rejected(expired.state,"expire")
 var prepared_after: Dictionary=practice(overdue,"connect")
 check(Calendar.pending(prepared_after).is_empty(),"successful real preparation expires an overdue booking through original pipeline")
 var same: Dictionary=Live.after_practice(overdue,prepared_after)
 check(int(same.get("reputation",0))==int(prepared_after.get("reputation",0)) and int(same.get("morale",0))==int(prepared_after.get("morale",0)),"postprocessing does not apply missed penalty twice")
 # Reactivation changes the set of active relationship pairs; verify original cohesion.
 var returning: Dictionary=booking.duplicate(true)
 returning.members[1].life_status="away"
 returning.members[1].available_day=int(returning.tour_day)+1
 returning.relationships={"0_1":90,"0_2":20,"1_2":80}
 var refreshed: Dictionary=practice(returning,"connect")
 check(str(refreshed.members[1].life_status)=="active","original Life.refresh returns an existing musician after preparation")
 check(int(refreshed.last_rehearsal_outcome.metrics.cohesion.after)==model.game._cohesion(refreshed),"existing cohesion row includes original post-refresh active pairs")
 for verb in ["advance","perform","cancel","expire"]: rejected(booking,verb,"unexpected")

func save_roundtrip(state: Dictionary, label: String) -> void:
 model.game.career=state.duplicate(true)
 var expected: Dictionary=model.snapshot()
 if not check(model.save_draft(),"actual current owner save: "+label): return
 var saved: PackedByteArray=FileAccess.get_file_as_bytes(Opening.SAVE_PATH)
 var resumed:=Opening.new()
 if not check(resumed.load_draft() and resumed.snapshot()==expected,"actual C27 envelope/unknown-state reload: "+label): return
 var before: Dictionary=resumed.snapshot()
 Brief.briefing(resumed.game.career)
 Brief.last_show(resumed.game.career)
 check(resumed.snapshot()==before and FileAccess.get_file_as_bytes(Opening.SAVE_PATH)==saved,"reading a saved live report never resolves or writes again: "+label)
 for key in ["band_name","genre","lead_vocal_candidate_id","lead_vocal_stats","logo","palette","vibe","name_chemistry_delta"]:
  check(resumed.game.career.get(key)==base.get(key),"canonical identity retained through live save: "+str(key))
 for index in range(base.members.size()):
  check(str(resumed.game.career.members[index].candidate_id)==str(base.members[index].candidate_id) and str(resumed.game.career.members[index].role)==str(base.members[index].role),"original member ID/role retained through saved show")

func case_c27_saved_loop() -> void:
 var source: Dictionary=base.duplicate(true)
 source.s46_unknown={"note":"original future state passes through","integer":7,"truth":true,"nested":[{"unknown":42},"retained"]}
 var current: Dictionary=booked("guarantee",source)
 save_roundtrip(current,"booked")
 current=prepared(current)
 save_roundtrip(current,"actual three preparation days")
 current=parity(current,"advance").get("state",{})
 save_roundtrip(current,"soundcheck")
 current=parity(current,"soundcheck","crowd").get("state",{})
 save_roundtrip(current,"stage")
 current=parity(current,"perform").get("state",{})
 save_roundtrip(current,"settled original report")
 check(current.get("s46_unknown")==source.s46_unknown,"original unknown nested career keys survive complete saved show")
 var saved: Dictionary=disk_files()
 rejected(current,"perform")
 check(disk_files()==saved,"rejected repeat performance leaves current and legacy save bytes unchanged")

func run() -> void:
 var user_dir:=ProjectSettings.globalize_path("user://")
 var output_path:=ProjectSettings.globalize_path(output)
 var safe: bool=check(user_dir.begins_with(SAFE_ROOT) and output_path.begins_with(SAFE_ROOT),"fresh S46 XDG/output guard before all fixture writes")
 for path in [Opening.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe=check(not FileAccess.file_exists(path),"fresh isolated save path: "+path) and safe
 if not safe:
  print("S46_LIVE_MODEL_TEST_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}))
  quit(1)
  return
 output=output_path
 if not check(DirAccess.make_dir_recursive_absolute(output)==OK,"scratch result output directory"):
  quit(1)
  return
 protected_initial=disk_files(false)
 if fixture():
  for method in ["case_booking_and_preparation","case_night_and_settlement","case_lineup_cash_and_incident","case_cancel_expire_and_report_reconciliation","case_c27_saved_loop"]:
   call(method)
   if not failures.is_empty(): break
 check(disk_files(false)==protected_initial,"no production tour/band/player or C26 save IO side effects")
 var result: Dictionary={"pass":failures.is_empty(),"checks":checks,"bridge_calls":bridge_calls,"actual_practice_calls":practice_calls,"errors":failures,"engine":Engine.get_version_info(),"user_data":user_dir,"actual_fixture":base,"observations":observations,"method":"HEADLESS actual C27 formation + protected Session preparation + actual C27 save/reload; unchanged original Promoter/Calendar/GigNight/Backstage/Story/expiry/Life oracle. No UI/input/device/save-failure claim.","bridge_sha256":FileAccess.get_sha256("res://experiments/playable_flightcase/live_bridge.gd")}
 var receipt:=FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:
  push_error("S46_LIVE_MODEL_TEST cannot write result receipt")
  quit(1)
  return
 receipt.store_string(JSON.stringify(result,"  "))
 receipt.close()
 print("S46_LIVE_MODEL_TEST_RESULT ",JSON.stringify(result))
 if failures.is_empty(): print("S46 LIVE MODEL TESTS PASSED")
 quit(0 if failures.is_empty() else 1)
