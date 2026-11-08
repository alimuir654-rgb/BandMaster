extends "res://tests/recorded_steady_test.gd"
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")

func fresh() -> bool:
 owner=Owner.new()
 if not owner.begin_new() or not owner.set_genre("Indie rock") or not owner.to_recruit():return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not owner.recruit(id).get("ok",false):return false
 return owner.choose_vocal("cast_jack").get("ok",false) and owner.confirm_lineup(true).get("ok",false) and owner.submit_name("NIGHT BUS CLUB","Raw").get("ok",false) and owner.lock_name(true).get("ok",false) and owner.finish_identity().get("ok",false) and owner.start_playing()

func fail_saved(action: Callable,label: String) -> void:
 var before: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject isolated "+label)
 var result: Dictionary=action.call()
 check(not result.get("ok",true) and owner.snapshot()==before and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole memory/file rollback "+label)
 check(DirAccess.remove_absolute(blocker)==OK,"remove only isolated "+label)

func advance_day() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var attendance: Dictionary=Situation.inspect_rehearsal(before)
 if not attendance.get("ok",false):return false
 var played: Dictionary=owner.game.informal_practice(attendance.attendee_indices)
 if not played.get("ok",false):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not tracked.get("ok",false):return false
 var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
 if not accounted.get("ok",false):return false
 owner.game.career=accounted.state
 return owner.save_draft()

func run() -> void:
 if not check(fresh(),"canonical actual owner band"):done();return
 var initial: Dictionary=owner.snapshot()
 check(not owner.game.career.has(Chat.KEY) and not owner.game.career.has(Circuit.KEY),"legacy absent memory stays absent")
 check(Chat.options(owner.game.career,"cast_jack","direction").available and owner.snapshot()==initial,"reading real chat remains free")
 fail_saved(func():return owner.answer_musician(owner.snapshot(),"cast_jack","direction","prepare_set"),"musician reply")
 var old: Dictionary=owner.snapshot()
 check(owner.answer_musician(old,"cast_jack","direction","prepare_set").ok,"contextual promise saved")
 var now: Dictionary=owner.snapshot()
 check(now.game.career.cash==old.game.career.cash and now.game.career.tour_day==old.game.career.tour_day,"conversation uses no cash/day")
 check(not owner.answer_musician(old,"cast_jack","pressure","push_on").ok and owner.snapshot()==now,"stale reply cannot overwrite or farm")
 check(not owner.answer_musician(now,"cast_jack","time","agree_evening").ok and owner.snapshot()==now,"pending promise cannot be farmed")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==now,"actual dialogue/plan typed reload")
 var future: Dictionary=now.game.career.duplicate(true);future[Chat.KEY].version=2
 check(not Chat.validate(future).ok and not Chat.reconcile(future).ok,"future chat is held, never reset")
 var bad: Dictionary=now.game.career.duplicate(true);bad[Chat.KEY].records.cast_jack.plan.due_day+=1
 check(not Chat.validate(bad).ok,"tampered promise window held")
 bad=now.game.career.duplicate(true);bad[Chat.KEY].records.cast_jack.plan.push="false"
 check(not Chat.validate(bad).ok,"string push cannot drive strained outcome")
 bad=now.game.career.duplicate(true);bad[Chat.KEY].records.cast_jack.plan.source_report="not-a-hash"
 check(not Chat.validate(bad).ok,"invalid report binding held")
 var clear: Dictionary=now.game.career.duplicate(true)
 var clear_result: Dictionary=owner.game.clear_air()
 check(clear_result.get("ok",false),"actual Clear Air counterexample")
 if clear_result.get("ok",false):check(Chat.record(Chat.reconcile(owner.game.career).state,"cast_jack").plan.status=="pending","Clear Air cannot fulfil an agreed rehearsal")
 owner.game.career=clear
 var actual_evening:=false
 for _day in range(4):
  var attendance: Dictionary=Situation.inspect_rehearsal(owner.game.career)
  if 0 in attendance.get("attendee_indices",[]):actual_evening=true;break
  if not advance_day():break
 if check(actual_evening,"real work commitments leave promised evening"):
  var before: Dictionary=owner.game.career.duplicate(true)
  var attendance: Dictionary=Situation.inspect_rehearsal(before)
  var played: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices)
  check(played.get("ok",false),"real attended paid rehearsal")
  if played.get("ok",false):
   var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,owner.game.career),"practice:tighten")
   check(accounted.ok,"original rehearsal accounts")
   owner.game.career=accounted.state
   check(owner.save_draft(),"save actual rehearsal with promise")
   check(Chat.record(owner.game.career,"cast_jack").plan.status=="kept","actual attended report fulfils promise")
   var remembered: Dictionary=owner.snapshot();check(owner.save_draft() and owner.snapshot()==remembered,"free save never credits promise twice")
 var expired: Dictionary=now.game.career.duplicate(true);expired.tour_day=int(expired[Chat.KEY].records.cast_jack.plan.due_day)+1
 var resolved: Dictionary=Chat.reconcile(expired)
 check(resolved.ok and Chat.record(resolved.state,"cast_jack").plan.status=="missed","pure deadline counterexample remembers missed plan")
 check(Chat.opening(resolved.state,"cast_jack","direction").contains("never happened"),"missed plan earns different later scenario")
 check(Chat.reconcile(resolved.state).state==resolved.state,"missed agreement once-only")
 var tired: Dictionary=now.game.career.duplicate(true);tired.erase(Chat.KEY);tired.members[0].fatigue=70
 var pushed: Dictionary=Chat.answer(tired,"cast_jack","pressure","push_on",Chat.fingerprint(tired))
 check(pushed.ok and pushed.message.contains("tired"),"same intent respects current fatigue")
 var strained: Dictionary=pushed.state.duplicate(true);strained.tour_day=int(strained.tour_day)+1
 strained.last_rehearsal_outcome={"focus":"tighten","day":strained.tour_day,"member_changes":[{"candidate_id":"cast_jack"}]}
 var strained_result: Dictionary=Chat.reconcile(strained)
 check(strained_result.ok and Chat.record(strained_result.state,"cast_jack").plan.status=="kept" and Chat.record(strained_result.state,"cast_jack").plan.effort_evidence=="unknown","legacy pace is unknown rather than inferred from earlier promise")
 var absent: Dictionary=now.game.career.duplicate(true);absent.tour_day=int(absent.tour_day)+1;absent.last_rehearsal_outcome={"focus":"tighten","day":absent.tour_day,"member_changes":[{"candidate_id":"cast_zoe"}]}
 check(Chat.record(Chat.reconcile(absent).state,"cast_jack").plan.status=="pending","another musician's rehearsal cannot fulfil Jack's promise")
 var compatible: Dictionary=now.game.career.duplicate(true);compatible[Chat.KEY].extra={"future_hint":"retained"}
 check(Chat.reconcile(compatible).state[Chat.KEY].extra==compatible[Chat.KEY].extra,"unknown compatible chat fields retained")
 var counter: Dictionary=Circuit.proposal(initial.game.career,"local","crowd","guarantee")
 check(counter.ok and counter.counteroffer and counter.bill.slot=="opening" and counter.bill.offer_id=="guestlist","new band receives genuine opening-slot counteroffer")
 var established: Dictionary=initial.game.career.duplicate(true);established.reputation=45;established.fans=90;established.gig_history=[{"success":true},{"success":true},{"success":true},{"success":true},{"success":true}]
 var better: Dictionary=Circuit.proposal(established,"local","crowd","guarantee")
 check(better.ok and not better.counteroffer and better.bill.slot=="headline" and better.bill.offer_id=="guarantee","isolated status oracle changes terms and bill position")
 check(Circuit.above(counter.bill).size()==2 and Circuit.above(better.bill).is_empty(),"advice only comes from acts higher on actual bill")
 var changed_bill: Dictionary=counter.bill.duplicate(true);changed_bill.slot="headline"
 check(not Circuit.bill_valid(changed_bill),"forged bill position refused")
 changed_bill=counter.bill.duplicate(true);changed_bill.version=3
 check(not Circuit.bill_valid(changed_bill),"future bill held")
 if not check(fresh(),"fresh canonical negotiation and gig"):done();return
 var state: Dictionary=owner.game.career.duplicate(true)
 var request: Dictionary={"venue_id":"local","offer_id":"standard","day":int(state.tour_day)+3,"travel_plan":"drive_home","session_drummer":false}
 var legacy: Dictionary=Live.prepare_booking(state,request,Booking.expected(state))
 request[Circuit.BILL]=Circuit.proposal(state,"local","fit","standard").bill
 var quote: Dictionary=Live.prepare_booking(state,request,Booking.expected(state))
 check(legacy.ok and quote.ok and legacy.quote==quote.quote,"shared bill does not alter original tariff/date/travel quote")
 var forged: Dictionary=request.duplicate(true);forged[Circuit.BILL].context.fans+=1
 check(not Live.prepare_booking(state,forged,Booking.expected(state)).ok,"changed band context cannot reuse offer")
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 if not check(booked.ok,"original booking commits frozen shared bill"):done();return
 var accounted: Dictionary=Finance.apply(state,booked.state,"live:book");check(accounted.ok,"original free booking accounts")
 owner.game.career=accounted.state;check(owner.save_draft(),"actual booking persistence")
 var saved_terms: Dictionary=Booking.terms(owner.game.career)
 check(saved_terms[Circuit.BILL].slot=="opening" and saved_terms.tariff.fee==35,"opening slot beside original fixed agreement")
 for _day in range(3):check(advance_day(),"actual free jam until booked night")
 var begin: Dictionary=Journey.begin(owner.game.career)
 if not check(begin.ok,"actual saved gig begins"):done();return
 var current: Dictionary=begin.state
 var arrived: Dictionary=Journey.checkpoint(current,"arrive_soundcheck",Journey.expected(current));check(arrived.ok,"real agreed trip and load in");current=arrived.get("state",current)
 var plan: Dictionary=Flow.default_plan(current)
 var sound: Dictionary=Journey.checkpoint(current,"soundcheck",Journey.expected(current),plan)
 if not check(sound.ok,"actual soundcheck plan"):done();return
 current=sound.state
 var token: Dictionary=Journey.expected(current)
 var advice: Dictionary=Journey.checkpoint(current,"scene_advice",token,{"band_id":"glass_arcade","choice":"try"})
 if not check(advice.ok,"guarded higher-band advice inside existing backstage phase"):done();return
 check(advice.state.tour_day==current.tour_day and advice.state.cash==current.cash,"advice checkpoint uses no extra day/cash")
 var duplicate: Dictionary=Journey.checkpoint(advice.state,"scene_advice",token,{"band_id":"glass_arcade","choice":"try"})
 check(duplicate.ok and not duplicate.changed,"identical checkpoint replay is no-op")
 check(not Journey.checkpoint(advice.state,"scene_advice",Journey.expected(advice.state),{"band_id":"northbound_static","choice":"try"}).ok,"cannot replace or farm advice")
 current=advice.state
 for _i in range(2):
  var moved: Dictionary=Journey.checkpoint(current,"advance",Journey.expected(current));check(moved.ok,"actual stage entry");current=moved.get("state",current)
 var short: Dictionary=Journey.checkpoint(current,"end_short_set",Journey.expected(current));check(short.ok,"real no-originals short set");current=short.get("state",current)
 var help: Dictionary=Journey.checkpoint(current,"scene_support",Journey.expected(current),{"band_id":"northbound_static","choice":"help"})
 check(help.ok,"help actual other band after set");current=help.get("state",current)
 for _i in range(2):
  var moved: Dictionary=Journey.checkpoint(current,"advance",Journey.expected(current));check(moved.ok,"actual packup");current=moved.get("state",current)
 var wrapped: Dictionary=Live.wrap_journey(current,Journey.expected(current))
 if not check(wrapped.ok,"original wrap resolves shared scene once"):done();return
 check(Circuit.validate(wrapped.state).ok and wrapped.state[Circuit.KEY].bands.northbound_static.supported==1,"durable band support contact earned once")
 check(wrapped.state[Circuit.KEY].venues.local.supported==1,"venue hears about actual support")
 var still_poor: Dictionary=wrapped.state.duplicate(true);still_poor.reputation=45;still_poor.fans=90;still_poor.gig_history.append({"success":true})
 var restricted: Dictionary=Circuit.proposal(still_poor,"local","crowd","guarantee")
 check(restricted.ok and restricted.counteroffer and restricted.bill.context.guarantee_restricted,"original poor-hometown-review restriction overrides isolated favourable standing oracle")
 check(not restricted.reply.contains("I'll add the usual"),"counteroffer never also promises rejected guarantee")
 var next_offer: Dictionary=Circuit.proposal(wrapped.state,"local","scene","standard")
 check(next_offer.ok and next_offer.reply.contains("mentioned"),"earned support changes next promoter conversation")
 var broken: Dictionary=wrapped.state.duplicate(true);broken[Circuit.KEY].processed["gig-commitment:bad"]=true
 check(not Circuit.validate(broken).ok,"malformed durable scene identity held")
 broken=wrapped.state.duplicate(true);broken[Circuit.KEY].receipts.append(broken[Circuit.KEY].receipts[0].duplicate(true))
 check(not Circuit.validate(broken).ok,"duplicate scene receipt held")
 broken=wrapped.state.duplicate(true);broken[Circuit.KEY].receipts[0].facts={}
 check(not Circuit.validate(broken).ok,"untyped scene facts held")
 broken=wrapped.state.duplicate(true);broken[Circuit.KEY].receipts[0].bill=Circuit.proposal(established,"bristol","crowd","guarantee").bill
 check(not Circuit.validate(broken).ok,"cross-venue bill cannot attach to local commitment")
 broken=wrapped.state.duplicate(true);broken[Circuit.KEY].version=2
 check(not Circuit.validate(broken).ok,"future scene wrapper held")
 var headline_encounter: Dictionary=Circuit.encounter_empty();headline_encounter.support={"choice":"watch","band_id":"northbound_static"}
 check(not Circuit.encounter_valid(headline_encounter,better.bill),"headliner cannot watch an earlier set after their own")
 check(wrapped.state[Circuit.KEY].receipts.back().facts.fans_delta==-1,"unprepared band's borrowed advice harms while support helps")
 var neutral: Dictionary=current.duplicate(true);neutral[Journey.KEY].active.context.readiness=75;neutral[Journey.KEY].active.context.actor.fatigue=10
 var helpful: Dictionary=Circuit.settle(neutral,wrapped.state.duplicate(true),neutral[Journey.KEY].active)
 check(not helpful.ok,"settled identity cannot credit again even through direct policy")
 var raw_after: Dictionary=wrapped.state.duplicate(true);raw_after.erase(Circuit.KEY)
 helpful=Circuit.settle(neutral,raw_after,neutral[Journey.KEY].active)
 check(helpful.ok and helpful.facts.fans_delta==3,"isolated prepared-band oracle makes same advice useful")
 check(not Live.wrap_journey(wrapped.state,Journey.expected(current)).ok,"terminal show cannot settle again")
 done()

func done() -> void:
 print("BAND_STORIES_TEST "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false}))
 owner=null
 quit(0 if failures.is_empty() else 1)
