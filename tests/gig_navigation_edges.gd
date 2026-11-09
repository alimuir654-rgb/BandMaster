extends "res://tests/gig_navigation_visual.gd"

func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 if not check(await first_goal(),"actual first-goal edge fixture"):finish();return
 for _day in range(7):
  if Situation.inspect_rehearsal(owner.game.career).attendee_indices.is_empty():break
  if not await advance_day():finish();return
 if not check(Situation.inspect_rehearsal(owner.game.career).attendee_indices.is_empty(),"genuine nobody-free day after first goal"):finish();return
 await mount();scene._open_career_home();await settle()
 var before: Dictionary=owner.snapshot()
 var next: Button=scene.find_child("PosterNextAction",true,false) as Button
 if not check(next!=null and next.text.contains("FIRST GIG"),"future-gig discovery remains visible when nobody is free tonight"):finish();return
 await capture("nobody-free-first-gig")
 await tap("PosterNextAction");await tap("BookingVenue_local")
 var career=scene._career_view
 # UI-only stale draft and invalid date counterexamples; saved career remains untouched.
 career.booking_expected={};career._render();await settle()
 check((scene.find_child("BookingCommitAction",true,false) as Button).text.contains("REVIEW CURRENT"),"stale draft gets fixed visible recovery action")
 await tap("BookingCommitAction")
 check(career.booking_step=="rooms" and career.booking_expected==Booking.expected(owner.game.career),"actual recovery obtains current rooms and token")
 unchanged(before,"stale draft recovery")
 await tap("BookingVenue_local");await tap("BookingPitch_fit");await tap("BookingOffer_standard")
 var valid_day: int=int(career.booking_draft.day)
 career.booking_draft.day=int(owner.game.career.tour_day);career._render();await settle()
 var action: Button=scene.find_child("BookingCommitAction",true,false) as Button
 var reason: Label=scene.find_child("BookingDockNotice",true,false) as Label
 check(action!=null and action.disabled and reason!=null and reason.text.contains("three days"),"actual invalid-date reason visible beside disabled confirmation")
 await capture("invalid-date-reason")
 unchanged(before,"invalid UI-only request")
 career.booking_draft.day=valid_day;career._render();await settle()
 check(not (scene.find_child("BookingCommitAction",true,false) as Button).disabled,"corrected original date restores confirmation")
 await tap("BookingBackAction");await tap("BookingBackAction");await tap("BookingBackAction");await tap("BookingBackAction")
 check(career.page=="home","actual Back returnsHome without booking")
 unchanged(before,"all blocked-day booking previews and Back")
 # A generation-bound response from an old frame cannot answer the next question.
 career._open_booking({});await settle();await tap("BookingVenue_local")
 var old_generation: int=int(career._render_generation)
 var token: Dictionary=career.booking_expected.duplicate(true)
 await tap("BookingPitch_fit")
 var draft: Dictionary=career.booking_draft.duplicate(true)
 career._booking_select("offer_id","guarantee",token,old_generation);await settle()
 check(career.booking_step=="terms" and career.booking_draft==draft,"stale answer cannot accept terms in new conversation")
 career.busy=true;career._booking_back(career._render_generation);career.busy=false
 check(career.booking_step=="terms" and career.booking_draft==draft,"busy owner blocks conversation navigation")
 await tap("BookingOffer_standard");await tap("BookingCommitAction")
 var generation: int=int(career._render_generation)
 career._booking_back(generation);career._booking_toggle_bill(generation)
 check(career.booking_step=="agreement" and not career.booking_bill_open,"modal owns navigation and bill disclosure")
 await tap("BookingKeepEditingAction")
 unchanged(before,"stale busy and modal guards")
 await tap("BookingBackAction");await tap("BookingBackAction");await tap("BookingBackAction");await tap("BookingBackAction")
 # Unknown compatible career data cannot silently disappear during free browsing.
 var extra: Dictionary={"keep":[1,{"fraction":1.25}]}
 owner.game.career["gig27_compatible_probe"]=extra.duplicate(true)
 check(owner.save_draft(),"isolated compatible metadata save")
 career._open_booking({});await settle();await tap("BookingVenue_local");await tap("BookingPitch_fit")
 check(owner.game.career.gig27_compatible_probe==extra,"conversation preserves unknown compatible fields")
 finish()

func finish() -> void:
 print("GIG_NAVIGATION_EDGES "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
