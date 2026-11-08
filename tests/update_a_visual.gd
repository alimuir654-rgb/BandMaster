extends "res://tests/band_stories_visual.gd"
var finishing:=false

func run() -> void:
 await super.run()
 if not failures.is_empty():finishing=true;await finish();return
 await tap("CareerReceiptContinueAction")
 scene._career_view._navigate("band");await settle();await tap("CareerTalk_cast_jack")
 await tap("ChatTopic_time");await tap("ChatReply_agree_evening")
 var first: Dictionary=Chat.record(owner.game.career,"cast_jack").plan.duplicate(true)
 await tap("ChatReviseAction")
 await reveal(scene.find_child("ChatRevise_rest",true,false));await capture("revise-offer")
 await failure_action("ChatRevise_rest","revision")
 await tap("ChatReviseAction");await tap("ChatRevise_rest")
 var row: Dictionary=Chat.record(owner.game.career,"cast_jack")
 check(row.plan.kind=="rest" and row.plan_history_v1.records.back().plan==first,"actual revision preserves exact original promise")
 await tap("ChatHistoryAction");await reveal(scene.find_child("ChatHistoryAction",true,false));await capture("promise-history")
 check((scene.find_child("ChatLastReply",true,false) as Label).text.contains("RECOVER"),"visible revision history matches chosen recovery")
 var before: Dictionary=owner.snapshot()
 await tap("ChatTopic_pressure")
 check(owner.snapshot()==before,"pending topic check-in is free and read-only")
 scene._career_view._navigate("home");await settle()
 var home: Button=scene.find_child("PosterPromiseAction",true,false) as Button
 check(home!=null,"home foregrounds current named agreement")
 if home!=null:await reveal(home);await capture("home-promise");await tap("PosterPromiseAction")
 check(scene._career_view.page=="musician_chat" and owner.snapshot()==before,"home reminder opens actual agreement without mutation")
 scene._career_view._navigate("gigs");await settle()
 if scene.find_child("BookingRestartAction",true,false)!=null:await tap("BookingRestartAction")
 if not await tap("BookingVenue_local"):finishing=true;await finish();return
 await tap("BookingPitch_scene");await tap("BookingOffer_standard")
 var bill: Dictionary=scene._career_view.booking_draft.get(Circuit.BILL,{})
 check(bill.get("slot")=="main_support" and bill.get("context",{}).get("favors",{}).has("northbound_static"),"actual earned support shapes return bill")
 await reveal(scene.find_child("BookingPromoterReply",true,false));await capture("return-promoter")
 await tap("BookingCommitAction");await tap("BookingConfirmAction")
 for _day in range(3):check(await advance_day(),"actual evenings to second show")
 scene._career_view._navigate("gigs");await settle()
 for _step in range(5):
  if not await tap("JourneyMainAction"):finishing=true;await finish();return
 if not check(Journey.active(owner.game.career).get("phase")=="performing","second actual selected set begins"):finishing=true;await finish();return
 await tap("JourneyFinishSongAction")
 await reveal(scene.find_child("SceneFavor_northbound_static",true,false));await capture("call-in-favor")
 var favor: Dictionary=owner.game.career[Circuit.KEY].favors.northbound_static.duplicate(true)
 await failure_action("SceneFavor_northbound_static","favour checkpoint")
 await tap("SceneFavor_northbound_static")
 check(owner.game.career[Circuit.KEY].favors.northbound_static==favor,"checkpoint does not consume favour before wrap")
 await tap("JourneyMainAction");await tap("JourneyMainAction")
 await failure_action("JourneyWrapAction","favour wrap")
 check(owner.game.career[Circuit.KEY].favors.northbound_static==favor,"failed wrap retains unspent favour")
 await tap("JourneyWrapAction")
 check(not owner.game.career[Circuit.KEY].favors.northbound_static.used_by.is_empty(),"actual saved second wrap consumes favour")
 var aftermath: Label=scene.find_child("ShowNamedAftermath",true,false) as Label
 check(aftermath!=null and aftermath.text.contains("return the hand"),"named practical consequence visible before details")
 if aftermath!=null:await reveal(aftermath)
 await capture("favor-returned")
 var reload=Owner.new();check(reload.load_draft() and reload.snapshot()==owner.snapshot(),"native two-show revision/favour exact reload")
 finishing=true;await finish()

func finish() -> void:
 if not finishing:return
 print("UPDATE_A_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null
 await process_frame
 quit(0 if failures.is_empty() else 1)
