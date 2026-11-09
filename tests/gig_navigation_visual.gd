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
 var career=scene._career_view
 check(career.booking_step=="pitch" and scene.find_child("BookingOffer_standard",true,false)==null and scene.find_child("BookingDay_%d" % int(career.booking_draft.day),true,false)==null,"pitch encounter shows only current question")
 await choice_fold(["BookingPitch_fit","BookingPitch_crowd","BookingPitch_scene"],"pitch")
 await tap("BookingPitch_fit")
 check(career.booking_step=="terms" and not career.booking_draft.has(Circuit.BILL),"pitch advances conversation without accepting default terms")
 check((scene.find_child("BookingPromoterReply",true,false) as Label).text.contains("short opening set"),"promoter responds to chosen pitch")
 await choice_fold(["BookingOffer_standard","BookingOffer_guarantee","BookingOffer_guestlist"],"terms")
 await capture("booking-needs-terms")
 await tap("BookingOffer_standard")
 check(career.booking_step=="agreement" and career.booking_draft.has(Circuit.BILL),"explicit terms produce actual frozen proposal")
 check((scene.find_child("BookingCommitAction",true,false) as Button).text.contains("AGREE"),"actual proposal has explicit agreement action")
 var first: int=int(owner.game.career.tour_day)+3;var last: int=first+11
 var days: Array=[]
 for day in range(first,last+1):
  var button: Button=scene.find_child("BookingDay_%d" % day,true,false) as Button
  check(button!=null and button.size.y>=48,"all original legal dates retain minimum target %d" % day)
  days.append(day)
 await tap("BookingDay_%d" % last)
 check(int(career.booking_draft.day)==last,"last legal day selectable")
 await tap("BookingDay_%d" % first)
 check(int(career.booking_draft.day)==first,"first legal day selectable")
 await tap("BookingBillToggle")
 check(scene.find_child("BookingBill_player",true,false)!=null,"actual full lineup accessible on demand")
 await capture("full-bill")
 await tap("BookingBillToggle")
 var local_draft: Dictionary=career.booking_draft.duplicate(true)
 await tap("BookingBackAction")
 check(career.booking_step=="terms" and career.booking_draft==local_draft,"Back preserves full local agreement")
 await tap("BookingReturnOffer")
 check(career.booking_step=="agreement" and career.booking_draft==local_draft,"return to actual offer preserves date and trip")
 await tap("BookingBackAction");await tap("BookingBackAction")
 check(career.booking_step=="pitch" and career.booking_draft==local_draft,"Back revisits pitch without erasing draft")
 await tap("BookingPitch_crowd")
 check(career.booking_step=="terms" and not career.booking_draft.has(Circuit.BILL),"changed pitch clears old offer")
 check((scene.find_child("BookingPromoterReply",true,false) as Label).text.contains("haven't seen"),"unproven following gets source-grounded response")
 await tap("BookingOffer_guarantee")
 check(career.booking_draft.offer_id=="guestlist" and career.booking_draft[Circuit.BILL].asked=="guarantee","asked terms stay distinct from actual counteroffer")
 var actual: Dictionary=Circuit.proposal(owner.game.career,"local","crowd","guarantee")
 check((scene.find_child("BookingPromoterReply",true,false) as Label).text==actual.reply,"counteroffer uses verbatim authoritative dialogue")
 unchanged(before,"all negotiation and revisited steps")
 await capture("counteroffer")
 await tap("BookingBackAction");await tap("BookingBackAction");await tap("BookingBackAction")
 check(career.booking_step=="rooms","conversation Back returns to room selection")
 unchanged(before,"choose another room")
 await tap("BookingVenue_local")
 check(career.booking_pitch.is_empty() and not career.booking_draft.has(Circuit.BILL),"room selection invalidates previous proposal")
 await tap("BookingPitch_fit");await tap("BookingOffer_standard")
 await reveal(scene.find_child("BookingOnlyTrip",true,false));await capture("travel")
 await tap("BookingCommitAction");await capture("final-agreement");await tap("BookingKeepEditingAction");unchanged(before,"decline final confirmation")
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

func capture(label: String) -> void:
 await super.capture(label)
 if is_instance_valid(scene._career_view._live_dialog):return
 var image: Image=Image.load_from_file(output+"-"+label+".png")
 for key in ["BookingPromoterHeading","BookingReviewVenue"]:
  var node: Control=scene.find_child(key,true,false)
  if node==null or not scene._career_view._scroll.get_global_rect().encloses(node.get_global_rect()):continue
  var physical: Rect2=root.get_final_transform()*node.get_global_rect()
  var rect: Rect2i=Rect2i(physical).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
  check(rect.size.x>0 and rect.size.y>0,"presence physical image bounds "+label+" "+key)
  var ink: int=0
  for y in range(rect.position.y,rect.end.y):
   for x in range(rect.position.x,rect.end.x):
    var pixel: Color=image.get_pixel(x,y)
    if pixel.r>0.55 and pixel.g>0.5 and pixel.b>0.4:ink+=1
  check(ink>80,"actual visible presence ink "+label+" "+key)

func choice_fold(names: Array,label: String) -> void:
 var clip: Rect2=scene._career_view._scroll.get_global_rect()
 for name in names:
  var button: Button=scene.find_child(name,true,false) as Button
  check(button!=null and clip.encloses(button.get_global_rect()) and button.size.y>=48,"first fold current choice "+label+" "+name)
 check(scene._career_view._scroll.scroll_vertical==0,"new conversation starts at top "+label)

func unchanged(before: Dictionary,label: String) -> void:
 check(owner.snapshot()==before,"free unchanged "+label)

func finish() -> void:
 print("GIG_NAVIGATION_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"baseline":baseline,"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
