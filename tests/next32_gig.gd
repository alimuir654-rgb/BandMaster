extends "res://tests/recorded_steady_test.gd"
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Incident=preload("res://experiments/playable_flightcase/gig_incident.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
var first_soundcheck: Dictionary={}
func step(action: String,payload: Dictionary={}) -> bool:
 var result: Dictionary=Journey.checkpoint(owner.game.career,action,Journey.expected(owner.game.career),payload)
 if not check(result.get("ok",false),"actual show "+action+": "+str(result.get("message",""))):return false
 owner.game.career=result.state
 if not check(owner.save_draft(),"persist "+action):return false
 var reloaded=Owner.new()
 return check(reloaded.load_draft() and reloaded.snapshot()==owner.snapshot(),"strict saved checkpoint "+action)
func advance_day() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var view: Dictionary=Situation.inspect_rehearsal(before)
 var jam: Dictionary=owner.game.informal_practice(view.attendee_indices)
 if not jam.get("ok",false):return false
 var result: Dictionary=Finance.apply(before,Live.after_practice(before,owner.game.career),"practice:jam")
 if not result.get("ok",false):return false
 owner.game.career=result.state
 return owner.save_draft()
func run() -> void:
 if not check(fixture() and next_available_evening(),"actual new band and available writing evening"):done_next();return
 var value: Dictionary=take("indie29_guitar90_01")
 if not check(owner.begin_workbench("FIRST NIGHT TOGETHER",0,owner.workbench_expected(),value).ok,"real initial draft"):done_next();return
 for stage in range(3):
  if not next_available_evening():done_next();return
  value.stage=stage
  if not trial(value) or not check(paid().ok,"original paid songwriting stage "+str(stage)):done_next();return
 check(owner.game.career.song_catalogue.size()==1,"actual one-original opening set")
 var state: Dictionary=owner.game.career.duplicate(true)
 var request: Dictionary={"venue_id":"local","offer_id":"standard","day":int(state.tour_day)+3,"travel_plan":"drive_home","session_drummer":false}
 request[Circuit.BILL]=Circuit.proposal(state,"local","fit","standard").bill
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 if not check(booked.ok,"original negotiated opening booking"):done_next();return
 var accounted: Dictionary=Finance.apply(state,booked.state,"live:book")
 if not check(accounted.ok,"original booking accounts"):done_next();return
 owner.game.career=accounted.state
 for _day in range(3):check(advance_day(),"original booked-date approach")
 var before: Dictionary=owner.game.career.duplicate(true)
 # Legacy entry remains untouched; new UI explicitly opts into enriched visits.
 var legacy: Dictionary=Journey.begin(before)
 check(legacy.ok and not Journey.active(legacy.state).has(Incident.KEY),"legacy caller/checkpoints unchanged")
 var begun: Dictionary=Journey.begin(before,"",true)
 if not check(begun.ok,"enriched visit saved before first display"):done_next();return
 # Measure the retained V22 connective path through actual model dispatch.
 var old_night: Dictionary=legacy.state;var old_taps: int=1
 for _beat in range(20):
  var v: Dictionary=Journey.active(old_night)
  var action: String="advance";var args: Dictionary={}
  match str(v.phase):
   "set_out":action="arrive_soundcheck"
   "soundcheck":action="soundcheck";args=Flow.default_plan(old_night)
   "performing":action="finish_song";args={"song_id":v.plan.song_ids[v.cursor],"cursor":v.cursor}
   "wrap_ready":
    check(Live.wrap_journey(old_night,Journey.expected(old_night)).ok,"retained V22 original settlement")
    old_taps+=1;break
  var moved: Dictionary=Journey.checkpoint(old_night,action,Journey.expected(old_night),args)
  if not check(moved.ok,"retained V22 measured action "+action):done_next();return
  old_night=moved.state;old_taps+=1
 check(old_taps==9,"actual retained V22 one-song path uses9 main actions")
 owner.game.career=begun.state
 if not step("arrive_soundcheck"):done_next();return
 first_soundcheck=owner.game.career.duplicate(true)
 var incident: Dictionary=Journey.active(first_soundcheck)[Incident.KEY]
 check(incident.kind=="rushed_check" and incident.choice=="" and Incident.copy(Journey.active(first_soundcheck)).speaker=="PROMOTER","one-song opener gets real promoter situation")
 for change in ["actor_id","actor_name","bill_slot"]:
  var forged: Dictionary=first_soundcheck.duplicate(true)
  forged[Journey.KEY].active[Incident.KEY].context[change]="unrelated"
  forged[Journey.KEY].active[Incident.KEY].context_hash=Incident.seal(forged[Journey.KEY].active[Incident.KEY])
  check(not Journey.validate(forged).ok,"incident must bind actual "+change)
 var wrong_kind: Dictionary=first_soundcheck.duplicate(true);wrong_kind[Journey.KEY].active[Incident.KEY].kind="tired_member"
 check(not Journey.validate(wrong_kind).ok,"incident kind requires pinned fatigue evidence")
 var plan: Dictionary=Flow.default_plan(first_soundcheck)
 check(plan.song_ids.size()==1,"default locked plan contains actual one original")
 check(not Journey.checkpoint(first_soundcheck,"soundcheck",Journey.expected(first_soundcheck),plan).ok,"unanswered situation cannot silently pass")
 var chosen: Dictionary=Journey.checkpoint(first_soundcheck,"soundcheck_answer",Journey.expected(first_soundcheck),{"choice":"check"})
 check(chosen.ok and chosen.state.cash==first_soundcheck.cash and chosen.state.tour_day==first_soundcheck.tour_day,"explicit answer uses no invented fee/day")
 var resolved: Dictionary=Journey.active(chosen.state)[Incident.KEY]
 check(resolved.choice=="check" and chosen.state.readiness==first_soundcheck.readiness+resolved.outcome.readiness,"actual preparedness consequence saved once")
 check(not Journey.checkpoint(chosen.state,"soundcheck_answer",Journey.expected(chosen.state),{"choice":"go"}).ok,"cannot replace/farm chosen answer")
 var bad: Dictionary=chosen.state.duplicate(true);bad[Journey.KEY].active[Incident.KEY].version=2
 check(not Journey.validate(bad).ok,"future incident held without reset")
 bad=chosen.state.duplicate(true);bad[Journey.KEY].active[Incident.KEY].outcome.readiness=99
 check(not Journey.validate(bad).ok,"forged consequence held")
 check(step("soundcheck_answer",{"choice":"check"}),"persist real answer")
 if not step("soundcheck",Flow.default_plan(owner.game.career)):done_next();return
 check(Journey.active(owner.game.career).context==Journey.Policy.capture(owner.game.career,Journey.active(owner.game.career).plan).context,"original context freezes AFTER actual incident effect")
 if not step("take_stage"):done_next();return
 check(Journey.active(owner.game.career).phase=="performing","one click carries backstage/entrance into performance")
 var visit: Dictionary=Journey.active(owner.game.career)
 if not step("finish_song",{"song_id":visit.plan.song_ids[0],"cursor":0}):done_next();return
 check(Journey.active(owner.game.career).phase=="after_set","one-song live set reaches aftermath")
 if not step("scene_support",{"band_id":"northbound_static","choice":"help"}) or not step("pack_and_leave"):done_next();return
 check(Journey.active(owner.game.career).phase=="wrap_ready","one carry-through packs cases and returns lift")
 before=owner.game.career.duplicate(true);var token: Dictionary=Journey.expected(before)
 var wrapped: Dictionary=Live.wrap_journey(before,token)
 if not check(wrapped.ok,"original once-only show settlement"):done_next();return
 accounted=Finance.apply(before,wrapped.state,"live:perform",wrapped.get("flows",[]),wrapped.get("closing_balances",[]))
 if not check(accounted.ok,"original show ledger chain"):done_next();return
 owner.game.career=accounted.state;check(owner.save_draft(),"final whole-night save")
 var receipt: Dictionary=Flow.last_receipt(owner.game.career)
 check(receipt.journey_v1[Incident.KEY]==resolved,"after-show receipt retains exact situation and answer")
 check(not Live.wrap_journey(owner.game.career,token).ok,"wrap cannot settle twice")
 check(owner.game.career.song_catalogue.size()==1,"no invented repertoire")
 # Same question/intent has different grounded consequences, pinned before display.
 for readiness in [20,70]:
  var variant: Dictionary=first_soundcheck.duplicate(true);variant.erase(Journey.KEY);variant.readiness=readiness
  var i: Dictionary=Incident.make(variant);var v: Dictionary={Incident.KEY:i}
  var r: Dictionary=Incident.resolve(variant,v,"go")
  check(r.ok and (r.state.readiness<readiness if readiness<45 else r.state.readiness>readiness),"same rushed go depends on actual preparation "+str(readiness))
 var tired: Dictionary=first_soundcheck.duplicate(true);tired.members[1].fatigue=80
 var i: Dictionary=Incident.make(tired)
 check(i.kind=="tired_member" and i.context.actor_id==tired.members[1].candidate_id,"actual tired musician earns named scenario")
 var later: Dictionary=tired.duplicate(true);later.members[1].fatigue=5;later.gig_history=[{"success":true}]
 check(Incident.make(later).kind=="monitor_balance","later fresh room gets different supported scenario")
 # Original illness seam may rebase context, but never rerolls situation/choice.
 var modified: Dictionary=first_soundcheck.duplicate(true);modified.readiness=maxi(0,modified.readiness-2)
 var rebased: Dictionary=Journey.rebase_owned_action(first_soundcheck,modified,Journey.expected(first_soundcheck))
 check(rebased.ok and Journey.active(rebased.state)[Incident.KEY].kind==incident.kind and Journey.active(rebased.state)[Incident.KEY].context.readiness==modified.readiness,"original incident owner seam retains situation and current preparation")
 done_next()
func done_next() -> void:
 print("NEXT32_GIG "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 owner=null;call_deferred("quit",0 if failures.is_empty() else 1)
