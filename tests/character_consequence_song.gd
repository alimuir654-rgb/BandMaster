extends "res://tests/recorded_steady_test.gd"
## Compose current interaction memory with the real recorded-song and gig APIs.
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const Booking=preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const Journey=preload("res://experiments/playable_flightcase/gig_journey.gd")
const Flow=preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar=preload("res://Scripts/gig_calendar.gd")

func day_action() -> bool:
 var before: Dictionary=owner.game.career.duplicate(true)
 var view: Dictionary=Situation.inspect_rehearsal(before)
 var jam: Dictionary=owner.game.informal_practice(view.attendee_indices)
 if not check(jam.get("ok",false),"real ordinary day"):return false
 var tracked: Dictionary=Situation.after_action(before,owner.game.career)
 if not check(tracked.ok,"one ordinary situation chain"):return false
 var account: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
 if not check(account.ok,"one ordinary finance chain"):return false
 owner.game.career=account.state
 return owner.save_draft()

func run() -> void:
 owner=Owner.new()
 if not check(owner.load_draft(),"reopen actual native audition/formation/practice save"):finish_song();return
 var connections: Dictionary=owner.game.career[Connections.KEY].duplicate(true)
 var title: String="FIRST NIGHT TOGETHER"
 if not check(next_available_evening(),"actual available writing evening"):finish_song();return
 var value: Dictionary=take(Bank.HOOKS[-1])
 if not check(owner.begin_workbench(title,0,owner.workbench_expected(),value).ok,"real new recorded song in actual formed band"):finish_song();return
 for stage in range(3):
  if not next_available_evening():finish_song();return
  value.stage=stage
  var tried: Dictionary=owner.workbench_action("producer_try",owner.workbench_expected(),{"recipe":value,"title":title,"leader_index":0})
  if not check(tried.ok,"real current source trial "+str(stage)):finish_song();return
  var project: Dictionary=owner.workbench_view().project
  var offer: Dictionary=Recipe.offer(project.fragment.producer_recipe,project.target.respondent_ref)
  if not check(owner.workbench_action("producer_offer",owner.workbench_expected(),{"choice":"keep","offer_id":offer.offer_id}).ok,"real bandmate response"):finish_song();return
  if not check(paid().ok,"real original paid writing stage"):finish_song();return
 check(owner.game.career[Connections.KEY]==connections,"songwriting preserves audition connections exactly")
 check(owner.game.career[Bank.USES].records.size()==3,"only songwriting consumes one source per instrumentalist")
 check(owner.game.career.song_catalogue.size()==1,"one actual finished original")
 if not next_available_evening():finish_song();return
 var before: Dictionary=owner.game.career.duplicate(true)
 var view: Dictionary=Situation.inspect_rehearsal(before)
 var rehearsed: Dictionary=owner.game.rehearse_attending(view.attendee_indices,{"focus":"precision","effort":"steady"})
 if not check(rehearsed.ok,"actual second rehearsal of the new band"):finish_song();return
 var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,owner.game.career),"practice:tighten")
 if not check(accounted.ok,"one rehearsal finance chain"):finish_song();return
 owner.game.career=accounted.state
 check(owner.save_draft(),"save contextual rehearsal alongside frozen song")
 var promised: Dictionary=owner.game.career[Connections.KEY].duplicate(true)
 for record in promised.records.values():check(record.practices==2,"only actual two rehearsals counted")
 var state: Dictionary=owner.game.career.duplicate(true)
 var request: Dictionary={"venue_id":"local","offer_id":"standard","travel_plan":"drive_home","session_drummer":false,"day":int(state.tour_day)+3}
 var booked: Dictionary=Live.book_selected(state,request,Booking.expected(state))
 if not check(booked.ok,"book actual first room: "+str(booked.get("message",""))):finish_song();return
 accounted=Finance.apply(state,booked.state,"live:book")
 if not check(accounted.ok,"one booking finance chain"):finish_song();return
 owner.game.career=accounted.state
 for _day in range(3):
  if not day_action():finish_song();return
 var begun: Dictionary=Journey.begin(owner.game.career,Flow.booking_id(Calendar.pending(owner.game.career)))
 if not check(begun.ok,"begin actual first gig"):finish_song();return
 owner.game.career=begun.state
 for _beat in range(18):
  var visit: Dictionary=Journey.active(owner.game.career)
  var phase: String=str(visit.phase)
  var result: Dictionary
  if phase=="wrap_ready":
   before=owner.game.career.duplicate(true)
   result=Live.wrap_journey(before,Journey.expected(before))
   if not check(result.ok,"finish actual first gig"):break
   accounted=Finance.apply(before,result.state,"live:perform",result.get("flows",[]),result.get("closing_balances",[]))
   if not check(accounted.ok,"one gig finance chain"):break
   owner.game.career=accounted.state
   check(owner.save_draft(),"save first gig")
   check(not Flow.last_receipt(owner.game.career).is_empty(),"actual first gig saved receipt")
   check(owner.game.career[Connections.KEY]==promised,"gig/navigation cannot farm rehearsal rapport")
   check(owner.game.career[Bank.USES].records.size()==3,"gig never consumes source again")
   var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"entire audition/song/rehearsal/gig strict reload")
   finish_song();return
  elif phase=="soundcheck":result=Journey.checkpoint(owner.game.career,"soundcheck",Journey.expected(owner.game.career),Flow.default_plan(owner.game.career))
  elif phase=="performing":result=Journey.checkpoint(owner.game.career,"finish_song",Journey.expected(owner.game.career),{"song_id":visit.plan.song_ids[visit.cursor],"cursor":visit.cursor})
  elif phase=="choice":result=Journey.checkpoint(owner.game.career,"choice",Journey.expected(owner.game.career),{"intent":"moment"})
  else:result=Journey.checkpoint(owner.game.career,"advance",Journey.expected(owner.game.career))
  if not check(result.ok,"actual saved gig checkpoint "+phase):break
  owner.game.career=result.state
 check(false,"bounded actual gig terminates")
 finish_song()

func finish_song() -> void:
 print("CHARACTER_SONG_GIG_TEST "+JSON.stringify({"checks":checks,"failures":failures,"listening":false,"physical_device":false}))
 owner=null;call_deferred("quit",0 if failures.is_empty() else 1)
