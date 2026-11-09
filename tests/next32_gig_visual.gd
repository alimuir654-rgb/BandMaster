extends "res://tests/band_stories_visual.gd"
const Incident=preload("res://experiments/playable_flightcase/gig_incident.gd")
var primary_taps:=0
func act(name: String) -> bool:
 primary_taps+=1
 return await tap(name)
func run() -> void:
 Input.emulate_mouse_from_touch=true;Input.emulate_touch_from_mouse=true
 owner=Owner.new()
 if not check(owner.begin_new(),"new main-app journey"):finish_next_gig();return
 await mount();await tap("Genre_Indie_rock");await tap("GenreNextAction")
 for entry in [["cast_jack","Guitarist","guitar"],["cast_zoe","Bassist","bass"]]:
  if not await audition(entry[0],entry[1],entry[2]):finish_next_gig();return
 await person("cast_casey","Drummer")
 await tap("CharacterIdea_0");await tap("CharacterIdea_1");await tap("CharacterIdeaStop")
 await tap("AuditionAction");await tap("RecruitAction")
 check(owner.game.roster.size()==3,"Casey real notes and independent recorded samples route")
 check(owner.choose_vocal("cast_jack").ok,"same canonical lead selection")
 scene._render();await settle()
 if scene.find_child("ReviewLineupAction",true,false)!=null:await tap("ReviewLineupAction")
 if not await tap("StartAction"):finish_next_gig();return
 var field: LineEdit=scene.find_child("FreeBandName",true,false)
 if not check(field!=null,"real naming entry"):finish_next_gig();return
 field.text="NIGHT BUS CLUB";field.text_changed.emit(field.text)
 await tap("NameSubmitAction");await tap("NameLockAction");await tap("IdentityFinishAction")
 check(owner.screen=="complete" and owner.remaining()==15,"actual audition receipts use new185 talent including voice")
 await capture("earned-band")
 await tap("StartPlayAction")
 if not await write_original():finish_next_gig();return
 scene._open_career_desk();await settle()
 if not await tap("PosterNav_gigs") or not await tap("BookingVenue_local") or not await tap("BookingPitch_fit") or not await tap("BookingOffer_standard"):finish_next_gig();return
 await capture("promoter-agreement")
 if not await tap("BookingCommitAction") or not await tap("BookingConfirmAction"):finish_next_gig();return
 for _day in range(3):check(await advance_day(),"real booked-night approach")
 scene._open_career_desk("gigs");await settle()
 primary_taps=0
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="soundcheck" and Incident.pending(Journey.active(owner.game.career)),"one action reaches saved promoter situation")
 check(scene.find_child("JourneyMainAction",true,false)==null,"no planner commitment shown behind unanswered situation")
 for id in ["GigAnswer_check","GigAnswer_go"]:
  var b: Control=scene.find_child(id,true,false)
  if not check(b!=null and not b.disabled and root.get_visible_rect().encloses(b.get_global_rect()),"actual choice enabled and visible without scrolling "+id):finish_next_gig();return
 await capture("soundcheck-situation")
 var before: Dictionary=owner.snapshot();var old_token: Dictionary=Journey.expected(owner.game.career);var old_generation: int=int(scene._career_view._render_generation)
 await failure_action("GigAnswer_check","saved promoter answer")
 check(owner.snapshot()==before,"failed answer retained whole owner")
 var error_label: Label=scene.find_child("JourneySaveNotice",true,false)
 check(error_label!=null and error_label.is_visible_in_tree() and error_label.text.contains("could not be saved"),"actual failed answer shows retry feedback")
 if not await act("GigAnswer_check"):finish_next_gig();return
 check(not Incident.pending(Journey.active(owner.game.career)),"choice saved in actual dispatcher")
 var answered: Dictionary=owner.snapshot()
 scene._career_view._commit_journey("soundcheck_answer",old_token,{"choice":"go"},old_generation);await settle()
 check(owner.snapshot()==answered,"stale original choice cannot replace answer")
 await capture("soundcheck-plan")
 scene._home();await settle();scene._continue();await settle();scene._open_career_desk("gigs");await settle()
 check(owner.snapshot()==answered and Journey.validate(owner.game.career).ok,"Menu/resume retains exact situation and result")
 await failure_action("JourneyMainAction","soundcheck frozen context")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="backstage","saved plan leaves original backstage decision")
 await capture("backstage-advice")
 await tap("SceneAdviceOwn")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="performing","no entrance Next screen")
 await capture("on-stage")
 if not await act("JourneyFinishSongAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="after_set","one original reaches aftermath")
 await capture("after-set")
 await tap("SceneHelp_northbound_static")
 if not await act("JourneyMainAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).phase=="wrap_ready","packing and lift carried through together")
 await capture("settlement")
 await failure_action("JourneyWrapAction","final once-only show settlement")
 if not await act("JourneyWrapAction"):finish_next_gig();return
 check(Journey.active(owner.game.career).is_empty() and not Flow.last_receipt(owner.game.career).is_empty(),"one real original show receipt")
 var receipt: Dictionary=Flow.last_receipt(owner.game.career)
 check(receipt.journey_v1[Incident.KEY].choice=="check","whole-night receipt remembers promoter answer")
 var durable=Owner.new();check(durable.load_draft() and durable.snapshot()==owner.snapshot(),"whole recruitment-to-first-gig strict disk reload")
 check(primary_taps==7,"7 primary journey actions including new situation, previously9 connective path")
 await capture("night-result")
 finish_next_gig()
func finish_next_gig() -> void:
 print("NEXT32_GIG_VISUAL "+JSON.stringify({"checks":checks,"failures":failures,"viewport":str(root.size),"primary_gig_actions":primary_taps,"other_deliberate_decisions":"advice and helping another band are separate optional decisions","physical_device":false,"listening":false}))
 if is_instance_valid(scene):scene.free()
 owner=null;await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)
