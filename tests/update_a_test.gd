extends "res://tests/band_stories_test.gd"
const Intent=preload("res://experiments/playable_flightcase/rehearsal_intent.gd")

func report_case(base: Dictionary,effort: String,worn: bool,attends: bool=true) -> Dictionary:
 var state: Dictionary=base.duplicate(true);state.tour_day+=1
 state.last_rehearsal_outcome={"focus":"tighten","day":state.tour_day,"direction":{"focus":"listening","effort":effort},"direction_notes":[{"candidate_id":"cast_jack","worn":worn}],"member_changes":[{"candidate_id":"cast_jack" if attends else "cast_zoe"}]}
 return Chat.reconcile(state)

func play_gig(pitch: String,support: Dictionary) -> Dictionary:
 var state: Dictionary=owner.game.career.duplicate(true)
 var offer: Dictionary=Circuit.proposal(state,"local",pitch,"standard")
 if not check(offer.ok,"next real promoter offer"):return {}
 var request: Dictionary={"venue_id":"local","offer_id":offer.bill.offer_id,"day":int(state.tour_day)+3,"travel_plan":"drive_home","session_drummer":false,Circuit.BILL:offer.bill}
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 if not check(booked.ok,"next distinct recorded booking"):return {}
 var accounted: Dictionary=Finance.apply(state,booked.state,"live:book")
 if not check(accounted.ok,"booking original accounts"):return {}
 owner.game.career=accounted.state
 for _day in range(3):
  if not check(advance_day(),"real jam until next show"):return {}
 var begun: Dictionary=Journey.begin(owner.game.career)
 if not check(begun.ok,"second durable visit begins"):return {}
 var current: Dictionary=begun.state
 for action in ["arrive_soundcheck","soundcheck","advance","advance","end_short_set","scene_support","advance","advance"]:
  var payload: Dictionary=Flow.default_plan(current) if action=="soundcheck" else (support if action=="scene_support" else {})
  var result: Dictionary=Journey.checkpoint(current,action,Journey.expected(current),payload)
  if not check(result.ok,"actual journey "+action+": "+str(result.get("message",""))):return {}
  current=result.state
 var wrapped: Dictionary=Live.wrap_journey(current,Journey.expected(current))
 if not check(wrapped.ok,"original wrap settles once"):return {}
 var final: Dictionary=Finance.apply(current,wrapped.state,"live:wrap")
 if not check(final.ok,"original wrap accounting"):return {}
 owner.game.career=final.state
 if not check(owner.save_draft(),"save scene consequences"):return {}
 return wrapped

func run() -> void:
 if not check(fresh(),"actual owner fixture"):done();return
 var initial: Dictionary=owner.snapshot()
 owner.game.career.members[0].fatigue=75
 check(owner.save_draft(),"isolated fatigue scenario saved")
 check(owner.answer_musician(owner.snapshot(),"cast_jack","pressure","push_on").ok,"promise made while tired")
 var pending: Dictionary=owner.game.career.duplicate(true)
 check(Chat.record(report_case(pending,"steady",true).state,"cast_jack").plan.status=="kept","tired promise followed by gentle actual session kept")
 check(Chat.record(report_case(pending,"push",false).state,"cast_jack").plan.status=="kept","recovered player can push without stale fatigue penalty")
 check(Chat.record(report_case(pending,"push",true).state,"cast_jack").plan.status=="strained","actual tired hard session strains agreement")
 check(Chat.record(report_case(pending,"push",true,false).state,"cast_jack").plan.status=="pending","absent musician not judged by another player's effort")
 var healthy: Dictionary=initial.game.career.duplicate(true)
 healthy=Chat.answer(healthy,"cast_jack","direction","prepare_set",Chat.fingerprint(healthy)).state
 check(Chat.record(report_case(healthy,"push",true).state,"cast_jack").plan.status=="strained","healthy earlier promise cannot excuse actual worn-out hard session")
 var legacy: Dictionary=pending.duplicate(true);legacy.tour_day+=1;legacy.last_rehearsal_outcome={"focus":"tighten","day":legacy.tour_day,"member_changes":[{"candidate_id":"cast_jack"}]}
 var old: Dictionary=Chat.reconcile(legacy).state
 check(Chat.record(old,"cast_jack").plan.status=="kept" and Chat.record(old,"cast_jack").plan.note.contains("wasn't recorded"),"legacy unknown pace recorded honestly")
 check(Chat.reconcile(old).state==old,"resolved promise retained byte-for-byte")
 var before: Dictionary=owner.snapshot()
 for topic in Chat.TOPICS:
  check(Chat.options(owner.game.career,"cast_jack",topic).ok,"free pending check-in "+topic)
 check(owner.snapshot()==before,"check-in never extends deadlines or rewards")
 fail_saved(func():return owner.revise_musician(owner.snapshot(),"cast_jack","rest"),"explicit plan revision")
 check(owner.revise_musician(before,"cast_jack","rest").ok,"explicit revision saved")
 var revised: Dictionary=owner.snapshot();var row: Dictionary=Chat.record(owner.game.career,"cast_jack")
 check(Chat.turn_label(row.turns.back()).contains("RECOVER"),"revised history names actual recovery choice")
 check(row.plan.kind=="rest" and row.plan.revision_count==1 and row.plan_history_v1.records.size()==1,"original promise retained in bounded durable history")
 check(row.plan_history_v1.records[0].plan==pending[Chat.KEY].records.cast_jack.plan,"revision never rewrites previous promise")
 check(row.plan.identity!=row.plan_history_v1.records[0].identity,"revision has distinct durable identity")
 check(revised.game.career.cash==before.game.career.cash and revised.game.career.tour_day==before.game.career.tour_day and row.rapport==0,"revision costs no cash/day and creates no rapport")
 check(not owner.revise_musician(before,"cast_jack","write").ok and not owner.revise_musician(revised,"cast_jack","write").ok and owner.snapshot()==revised,"stale or repeat revision cannot extend forever")
 var load_owner=Owner.new();check(load_owner.load_draft() and load_owner.snapshot()==revised,"revision exact typed reload")
 var broken: Dictionary=owner.game.career.duplicate(true);broken[Chat.KEY].records.cast_jack.plan_history_v1.records[0].plan.due_day+=1
 check(not Chat.validate(broken).ok,"malformed historical window held")
 var voices: Array=[]
 for id in ["cast_arjun","cast_hannah","cast_ellis"]:voices.append(Chat.Situations.opening(id,"direction",""))
 check(voices[0]!=voices[1] and voices[1]!=voices[2] and not voices.has(""),"three source-grounded distinct musician voices")
 check(fresh(),"new actual band for scene chain")
 var state: Dictionary=owner.game.career.duplicate(true)
 var v1: Dictionary=Circuit._offer(Circuit.context(state,"local"),"crowd","guarantee")
 check(v1.version==1 and v1.offer_id=="standard" and Circuit.bill_valid(v1),"v1 constructor and saved bill remain original")
 for pitch in Circuit.PITCHES:
  var offer: Dictionary=Circuit.proposal(state,"local",pitch,"standard")
  check(offer.ok and offer.bill.version==2 and Circuit.bill_valid(offer.bill),"versioned credible pitch "+pitch)
 var fit: Dictionary=Circuit.proposal(state,"local","fit","standard").bill
 var crowd: Dictionary=Circuit.proposal(state,"local","crowd","standard").bill
 check(fit.set_limit==1 and fit.slot=="opening" and crowd.offer_id=="guestlist","short set and guest list are distinct obligations")
 var request: Dictionary={"venue_id":"local","offer_id":"standard","day":int(state.tour_day)+3,"travel_plan":"drive_home","session_drummer":false,Circuit.BILL:fit}
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 check(booked.ok and Flow.set_limit(booked.state)==1,"actual modern booking enforces short-set cap")
 var cap: Dictionary=Flow.default_plan(booked.state);cap.song_ids=["a","b"]
 check(not Flow.check_plan(booked.state,cap).ok,"state-aware validator rejects too many originals")
 var helped: Dictionary=play_gig("fit",{"choice":"help","band_id":"northbound_static"})
 if helped.is_empty():done();return
 var favor: Dictionary=owner.game.career[Circuit.KEY].favors.northbound_static.duplicate(true)
 check(favor.used_by.is_empty() and owner.game.career[Circuit.KEY].processed.has(favor.source_commitment_id),"help earns one source-bound unspent favour")
 var scene: Dictionary=Circuit.proposal(owner.game.career,"local","scene","standard")
 check(scene.ok and scene.bill.slot=="main_support" and scene.bill.context.favors.northbound_static==favor.id,"real local support advances return bill and carries favour")
 before=owner.snapshot();Circuit.proposal(owner.game.career,"local","scene","standard")
 check(owner.snapshot()==before,"negotiation preview never consumes favour")
 var returned: Dictionary=play_gig("scene",{"choice":"call_favor","band_id":"northbound_static","favor_id":favor.id})
 if returned.is_empty():done();return
 var end: Dictionary=owner.game.career[Circuit.KEY]
 check(end.favors.northbound_static.used_by!=favor.source_commitment_id and not end.favors.northbound_static.used_by.is_empty(),"later actual wrap consumes the earlier favour once")
 check(Circuit.available_favors(owner.game.career).is_empty(),"consumed favour unavailable on future bills")
 check(end.receipts.back().facts.fatigue_per_active_member==-2 and end.receipts.back().facts.note.contains("return the hand"),"specific practical consequence and named receipt")
 load_owner=Owner.new();check(load_owner.load_draft() and load_owner.snapshot()==owner.snapshot(),"two-gig reciprocal history exact reload")
 broken=owner.game.career.duplicate(true);broken[Circuit.KEY].favors.northbound_static.used_by="gig-commitment:999:local:999"
 check(not Circuit.validate(broken).ok,"forged favour consumption has no settled source")
 var malformed: Dictionary=owner.game.career.duplicate(true)
 malformed[Circuit.KEY].favors.northbound_static.used_by=favor.source_commitment_id
 check(not Circuit.validate(malformed).ok,"same-show favour consumption held")
 malformed=owner.game.career.duplicate(true);malformed[Circuit.KEY].receipts.back().encounter.support={"choice":"own_gear","band_id":""}
 check(not Circuit.validate(malformed).ok,"unrelated show receipt cannot prove favour consumption")
 done()

func done() -> void:
 print("UPDATE_A_TEST "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false}))
 owner=null
 quit(0 if failures.is_empty() else 1)
