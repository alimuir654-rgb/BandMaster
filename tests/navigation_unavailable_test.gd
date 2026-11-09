extends "res://tests/band_stories_test.gd"
const Day=preload("res://experiments/playable_flightcase/day_navigation.gd")

func run() -> void:
 if not check(fresh(),"canonical actual band"):done();return
 var seen: Dictionary={}
 var quiet_before: Dictionary={}
 for _day in range(7):
  var before: Dictionary=owner.game.career.duplicate(true)
  var view: Dictionary=Day.inspect(before)
  if not check(view.get("ok",false),"actual evening view"):done();return
  seen[view.count]=true
  check(owner.game.career==before,"availability/preview is read-only")
  var raw: Dictionary=owner.game.informal_practice(view.attendance.attendee_indices)
  if not check(raw.ok,"actual ordinary day resolver"):done();return
  check(int(owner.game.career.tour_day)==int(before.tour_day)+1,"one day only")
  check(int(owner.game.career.get("readiness",0))==int(before.get("readiness",0)),"informal day never adds full rehearsal readiness")
  check(owner.game.career.get("band_work_counters",{}).get("rehearse",0)==before.get("band_work_counters",{}).get("rehearse",0),"no formal rehearsal counter credit")
  for index in range(before.members.size()):
   var expected: int=mini(100,int(before.members[index].skill)+1) if index in view.attendance.attendee_indices else int(before.members[index].skill)
   check(int(owner.game.career.members[index].skill)==expected,"only actual attending musician practises "+str(index))
  if view.count==0:
   quiet_before=before.duplicate(true)
   check(owner.game.career.members==before.members and owner.game.career.relationships==before.relationships,"empty evening gives no absent-player or relationship rewards")
   check(owner.game.career.get("song_catalogue",[])==before.get("song_catalogue",[]) and owner.game.career.get("recorded_phrase_uses_v1",{})==before.get("recorded_phrase_uses_v1",{}),"quiet day consumes no song or phrase")
   check(view.preview_label.contains("QUIET"),"zero availability describes legal quiet route")
  elif view.count==1:check(view.preview_label.contains("SOLO") and view.names.size()==1,"solo preview names actual one musician")
  else:check(view.preview_label.contains("JAM") and view.names.size()==view.count,"jam preview names actual attendees")
  var tracked: Dictionary=Situation.after_action(before,owner.game.career)
  if not check(tracked.ok,"actual work history tracked"):done();return
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,tracked.state),"practice:jam")
  if not check(accounted.ok,"original calendar finances applied once"):done();return
  owner.game.career=accounted.state
  if not check(owner.save_draft(),"owned actual day save"):done();return
 check(seen.has(0) and seen.has(1) and (seen.has(2) or seen.has(3)),"authored week includes zero solo and group cases")
 if not quiet_before.is_empty():
  var planned: Dictionary=Situation.reschedule(quiet_before)
  check(planned.ok and int(planned.state.tour_day)==int(quiet_before.tour_day),"agreeing a future rehearsal never spends a day")
  if planned.ok:
   var view: Dictionary=Day.inspect(planned.state)
   check(not view.rehearsal_available and view.rehearsal_reason.contains(str(planned.plan.day)),"future agreement shows actual day and useful alternative")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"actual passed evenings typed reload")
 done()

func done() -> void:
 print("NAVIGATION_UNAVAILABLE_TEST "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false}))
 owner=null;quit(0 if failures.is_empty() else 1)
