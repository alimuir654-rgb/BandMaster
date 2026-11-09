extends "res://tests/band_stories_visual.gd"

func first_goal() -> bool:
 if not fresh() or not await write_original():return false
 for _session in range(2):
  for _day in range(7):
   if Situation.inspect_rehearsal(owner.game.career).attendee_indices.size()>=2:break
   if not await advance_day():return false
  var before: Dictionary=owner.game.career.duplicate(true)
  var attendance: Dictionary=Situation.inspect_rehearsal(before)
  var played: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"precision","effort":"steady"})
  if not check(played.get("ok",false),"actual attended paid rehearsal"):return false
  var accounted: Dictionary=Finance.apply(before,Live.after_practice(before,owner.game.career),"practice:tighten")
  if not accounted.ok:return false
  owner.game.career=accounted.state
  if not owner.save_draft():return false
 return check(int(owner.game.career.songs)==1 and int(owner.game.career.action_counters.rehearse)==2,"actual one finished song and exactly two formal rehearsals")

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(await first_goal(),"owner progress reproduced"):finish();return
 await mount();scene._open_career_home();await settle()
 var goal: Dictionary=scene._career_view._goal_direction()
 check(goal.get("ready",false) and goal.get("id")=="find_sound","actual completed first-goal state")
 var before: Dictionary=owner.snapshot()
 await capture("first-goal-home")
 if baseline:
  var button: Button=scene.find_child("PosterNextAction",true,false) as Button
  check(button==null or not button.text.contains("GIG"),"baseline loses explicit first-gig next step")
  await tap("PosterNav_gigs");await tap("BookingVenue_local")
  var confirm: Button=scene.find_child("BookingCommitAction",true,false) as Button
  check(confirm!=null and confirm.disabled,"baseline confirm disabled before explicit promoter choices")
  await capture("booking-before-pitch")
  unchanged(before,"baseline booking browse")
  finish();return
 var next: Button=scene.find_child("PosterNextAction",true,false) as Button
 if not check(next!=null and next.text.contains("FIRST GIG"),"completed first goal offers genuine booking route"):finish();return
 await tap("PosterNextAction");unchanged(before,"first-gig discovery")
 if not await tap("BookingVenue_local"):finish();return
 await capture("booking-before-pitch")
 check((scene.find_child("BookingCommitAction",true,false) as Button).text.contains("PITCH"),"fixed dock explains missing pitch")
 await tap("BookingCommitAction")
 check(scene._career_view.booking_pitch.is_empty() and not scene._career_view.booking_draft.has(Circuit.BILL),"guided focus never selects a pitch or bill")
 check(root.gui_get_focus_owner().name=="BookingPitch_fit","guide reveals actual pitch control")
 await tap("BookingPitch_fit")
 check(not scene._career_view.booking_draft.has(Circuit.BILL),"pitch alone never accepts default terms")
 check((scene.find_child("BookingCommitAction",true,false) as Button).text.contains("TERMS"),"fixed dock explains missing terms")
 await capture("booking-needs-terms")
 await tap("BookingCommitAction")
 check(root.gui_get_focus_owner().name=="BookingOffer_standard","guide reveals actual terms control")
 await tap("BookingOffer_standard")
 check(scene._career_view.booking_draft.has(Circuit.BILL),"explicit terms produce actual frozen proposal")
 check((scene.find_child("BookingCommitAction",true,false) as Button).text.contains("CONFIRM"),"proposal now offers real confirmation")
 await tap("BookingPitch_crowd")
 check(not scene._career_view.booking_draft.has(Circuit.BILL) and (scene.find_child("BookingCommitAction",true,false) as Button).text.contains("TERMS"),"changed pitch clears terms and restores guidance")
 await tap("BookingOffer_guarantee")
 check(scene._career_view.booking_draft.offer_id=="guestlist","unproven following receives original actual counteroffer")
 unchanged(before,"all negotiation and guided steps")
 await capture("counteroffer")
 await tap("BookingBackAction");unchanged(before,"choose another room")
 await tap("BookingVenue_local");await tap("BookingPitch_fit");await tap("BookingOffer_standard")
 await tap("BookingCommitAction");await tap("BookingKeepEditingAction");unchanged(before,"decline final confirmation")
 await tap("BookingCommitAction");await failure_action("BookingConfirmAction","first-gig-booking")
 check(scene._career_view.booking_draft.has(Circuit.BILL),"failed save retains actual proposal")
 await tap("BookingCommitAction");await tap("BookingConfirmAction")
 var terms: Dictionary=Booking.terms(owner.game.career)
 check(not terms.is_empty() and terms.venue_snapshot.id=="local" and int(terms.day)>=int(before.game.career.tour_day)+3,"actual future hometown booking saved")
 check(int(owner.game.career.cash)==int(before.game.career.cash) and int(owner.game.career.tour_day)==int(before.game.career.tour_day),"original booking uses no upfront fee or career day")
 check(owner.game.career.get("career_chapters_claimed",{})==before.game.career.get("career_chapters_claimed",{}),"navigation never claims a chapter or reward")
 await capture("first-gig-saved")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"booking exact typed reload")
 finish()

func unchanged(before: Dictionary,label: String) -> void:
 check(owner.snapshot()==before,"free unchanged "+label)

func finish() -> void:
 print("GIG_NAVIGATION_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"baseline":baseline,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
