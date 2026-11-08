extends "res://tests/recorded_steady_test.gd"
const Connections=preload("res://experiments/playable_flightcase/character_connections.gd")
const Intent=preload("res://experiments/playable_flightcase/rehearsal_intent.gd")
const Encounter=preload("res://experiments/playable_flightcase/audition_encounter.gd")

func fail_saved(action: Callable,label: String) -> void:
 var snapshot: Dictionary=owner.snapshot();var disk: PackedByteArray=FileAccess.get_file_as_bytes(Owner.SAVE_PATH)
 var blocker: String=ProjectSettings.globalize_path(Owner.SAVE_PATH+".identity-tmp")
 check(DirAccess.make_dir_recursive_absolute(blocker)==OK,"inject isolated "+label)
 var result: Dictionary=action.call()
 check(not result.get("ok",true) and owner.snapshot()==snapshot and FileAccess.get_file_as_bytes(Owner.SAVE_PATH)==disk,"whole rollback "+label)
 check(DirAccess.remove_absolute(blocker)==OK,"remove isolated "+label)

func run() -> void:
 owner=Owner.new()
 if not check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"canonical recruitment"):finish_character();return
 check(owner.begin_audition("cast_jack","Guitarist",true).ok,"begin canonical Jack")
 var original_token: Dictionary=owner.audition_expected();check(original_token.size()==4,"legacy four-key token unchanged before talking")
 fail_saved(func():return owner.audition_action("talk",owner.audition_expected(),"working_style:shared"),"question save")
 check(owner.audition_action("talk",original_token,"working_style:shared").ok,"first conversation saved")
 var first: Dictionary=owner.snapshot();var after_first: Dictionary=owner.audition_expected()
 check(after_first.size()==5 and after_first.conversation_revision==1,"independent conversation revision")
 check(not owner.audition_action("talk",original_token,"commitment:dates").ok and owner.snapshot()==first,"old retained first token rejected")
 check(not owner.audition_action("talk",after_first,"working_style:direct").ok and owner.snapshot()==first,"answer cannot be replaced or farmed")
 check(owner.audition_action("talk",after_first,"commitment:dates").ok,"second question saved")
 var completed_talk: Dictionary=owner.snapshot();var durable=Owner.new()
 check(durable.load_draft() and durable.snapshot()==completed_talk,"strict question reload")
 var future: Dictionary=completed_talk.duplicate(true);future[Encounter.KEY].active[Connections.TALK].version=2
 check(Encounter.validate(future).held,"future question data held read-only")
 future=completed_talk.duplicate(true);future[Encounter.KEY].active[Connections.TALK].revision=0
 check(Encounter.validate(future).held,"malformed question count held")
 check(owner.audition_action("request",owner.audition_expected(),"space_for_voice").ok,"original musical request unchanged")
 var invite: Dictionary=owner.audition_expected()
 fail_saved(func():return owner.resolve_audition_response("invite",invite),"original invitation with questions")
 check(owner.resolve_audition_response("invite",invite).ok,"original recruitment authentication retained")
 var invited: Dictionary=owner.snapshot();var budget: int=owner.remaining()
 check(not owner.resolve_audition_response("invite",invite).ok and owner.snapshot()==invited and owner.remaining()==budget,"invitation and questions once-only")
 check(not owner.game.career.has(Connections.KEY),"no premature roster/career effect before formation")
 check(owner.recruit("cast_zoe").ok and owner.recruit("cast_casey").ok and owner.choose_vocal("cast_jack"),"original remainder of lineup")
 check(owner.confirm_lineup(true).ok and owner.submit_name("TEST THE PROMISE","Raw").ok and owner.lock_name(true).ok,"canonical name/identity entry")
 check(owner.set_identity("Wordmark","Amber / Charcoal","Unpolished"),"canonical identity")
 fail_saved(func():return owner.finish_identity(),"formation projection")
 if not check(owner.finish_identity().ok and owner.start_playing(),"formation projects invited conversation atomically"):finish_character();return
 check(Connections.valid(owner.game.career) and owner.game.career[Connections.KEY].records.size()==1,"only genuine interviewed current member recorded")
 var record: Dictionary=owner.game.career[Connections.KEY].records.cast_jack
 check(record.rapport==0 and record.practices==0 and record.conversation.answers.working_style=="shared","authored base stats unchanged; expectations stored")
 var before_projection: Dictionary=owner.game.career.duplicate(true)
 check(Connections.project(owner.snapshot(),before_projection).state==before_projection,"projection idempotent")
 durable=Owner.new();check(durable.load_draft() and durable.snapshot()==owner.snapshot(),"formed connections strict reload")
 if not check(next_available_evening(),"canonical available evening"):finish_character();return
 owner.game.career[Connections.KEY]["qa_unknown_wrapper"]={"keep":[7,"word"]}
 owner.game.career[Connections.KEY].records.cast_jack["qa_unknown_record"]={"keep":[8,"another"]}
 var base: Dictionary=owner.game.career.duplicate(true)
 var attendance: Dictionary=Situation.inspect_rehearsal(base)
 var unsupported: Dictionary=base.duplicate(true);unsupported[Connections.KEY].version=2
 owner.game.career=unsupported;var failed: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"precision","effort":"push"})
 check(not failed.ok and owner.game.career==unsupported,"future relationship context rejected before spending")
 owner.game.career=base.duplicate(true)
 check(not owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"wrong","effort":"push"}).ok and owner.game.career==base,"invalid practice plan does not spend")
 var outcomes: Array=[]
 for fatigue in [0,85]:
  owner.game.career=base.duplicate(true)
  for member in owner.game.career.members:member.fatigue=fatigue
  var prior: Dictionary=owner.game.career.duplicate(true)
  var played: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"precision","effort":"push"})
  if not check(played.ok,"same explicit practice at fatigue "+str(fatigue)):finish_character();return
  check(owner.game.career.cash==prior.cash-15 and owner.game.career.tour_day==prior.tour_day+1 and owner.game.career.action_count==prior.action_count+1,"original rehearsal fee/day/action once")
  check(Connections.valid(owner.game.career) and owner.game.career[Connections.KEY].records.cast_jack.practices==1,"one attended consequence application")
  check(played.outcome.member_changes[0].changes.fatigue.after==owner.game.career.members[0].fatigue,"report matches actual member outcome")
  outcomes.append({"ready":int(owner.game.career.readiness)-int(prior.readiness),"stress":int(owner.game.career.tension)-int(prior.tension),"rapport":int(owner.game.career[Connections.KEY].records.cast_jack.rapport)})
 check(outcomes[0].ready>outcomes[1].ready and outcomes[0].stress<outcomes[1].stress and outcomes[0].rapport>outcomes[1].rapport,"same push has different supported consequences for fresh and exhausted band")
 owner.game.career=base.duplicate(true)
 var listen: Dictionary=owner.game.rehearse_attending(attendance.attendee_indices,{"focus":"listening","effort":"steady"})
 check(owner.game.career[Connections.KEY].qa_unknown_wrapper==base[Connections.KEY].qa_unknown_wrapper and owner.game.career[Connections.KEY].records.cast_jack.qa_unknown_record==base[Connections.KEY].records.cast_jack.qa_unknown_record,"unknown connection wrapper and record fields retained")
 check(listen.ok and owner.game.career[Connections.KEY].records.cast_jack.rapport>0 and owner.game.career.members[0].loyalty>base.members[0].loyalty,"honoured shared audition direction changes actual trust/loyalty")
 check(listen.outcome.direction_notes[0].text.contains("audition"),"saved feedback explains remembered audition")
 check(owner.game.career.relationships==base.relationships,"player rapport does not manufacture pair bonds")
 var after: Dictionary=owner.game.career.duplicate(true)
 var post: Dictionary=Connections.project(owner.snapshot(),after)
 check(post.ok and post.state==after,"reopening projection does not duplicate practice effects")
 var legacy: Dictionary=base.duplicate(true);legacy.erase(Connections.KEY)
 owner.game.career=legacy.duplicate(true)
 check(owner.game.rehearse_attending(attendance.attendee_indices).ok and not owner.game.career.has(Connections.KEY),"legacy absent has no invented audition relationship")
 await planned_evening_cases(base)
 # New no-question requests still have an impact; old receipts are not invented.
 owner=Owner.new()
 check(owner.begin_new() and owner.set_genre("Indie rock") and owner.to_recruit(),"fresh minimal musical audition")
 check(owner.begin_audition("cast_jack","Guitarist",true).ok and owner.audition_action("request",owner.audition_expected(),"own_part").ok and owner.resolve_audition_response("invite",owner.audition_expected()).ok,"new musical request without optional questions")
 var minimal: Dictionary=owner.snapshot()
 var row: Dictionary=minimal[Encounter.KEY].heard_by_candidate.cast_jack
 check(row[Connections.TALK].revision==0 and row[Connections.TALK].answers.is_empty(),"empty marker never invents an answer")
 var numeric_career: Dictionary=base.duplicate(true);numeric_career.erase(Connections.KEY)
 var current_projection: Dictionary=Connections.project(minimal,numeric_career)
 check(current_projection.ok and current_projection.state[Connections.KEY].records.cast_jack.request=="own_part","actual musical choice projects without questions")
 minimal[Encounter.KEY].last_result.erase(Connections.TALK);minimal[Encounter.KEY].heard_by_candidate.cast_jack.erase(Connections.TALK)
 check(Connections.project(minimal,numeric_career).state==numeric_career,"legacy absent conversation has no invented interaction memory")
 finish_character()

func advance_day() -> bool:
 var prior: Dictionary=owner.game.career.duplicate(true)
 var view: Dictionary=Situation.inspect_rehearsal(prior)
 var jam: Dictionary=owner.game.informal_practice(view.attendee_indices)
 if not check(jam.ok,"canonical day before planned rehearsal"):return false
 var tracked: Dictionary=Situation.after_action(prior,owner.game.career)
 if not check(tracked.ok,"canonical plan-day situation chain"):return false
 var accounted: Dictionary=Finance.apply(prior,Live.after_practice(prior,tracked.state),"practice:jam")
 if not check(accounted.ok,"canonical plan-day finance chain"):return false
 owner.game.career=accounted.state
 return true

func planned_evening_cases(base: Dictionary) -> void:
 owner.game.career=base.duplicate(true)
 for _day in range(7):
  if Situation.inspect_rehearsal(owner.game.career).get("conflict",false):break
  if not advance_day():return
 var offered: Dictionary=Situation.reschedule(owner.game.career,owner.game.career.duplicate(true))
 if not check(offered.ok,"actual work clash creates real agreed evening"):return
 owner.game.career=offered.state
 for _day in range(15):
  if int(owner.game.career.tour_day)==int(offered.plan.day):break
  if not advance_day():return
 var due: Dictionary=owner.game.career.duplicate(true)
 var view: Dictionary=Situation.inspect_rehearsal(due)
 if not check(view.plan_status=="due" and not view.conflict,"actual due all-available evening"):return
 var result: Dictionary=owner.game.rehearse_attending(view.attendee_indices,{"focus":"listening","effort":"steady"})
 if not check(result.ok,"original practice fulfils actual plan"):return
 check(Intent.kept_evening(owner.game.career,result.outcome,"cast_jack"),"actual attendance and original participant receives kept-evening evidence")
 check(owner.game.career[Connections.KEY].records.cast_jack.rapport==mini(20,int(due[Connections.KEY].records.cast_jack.rapport)+2),"shared direction plus real kept evening applied once")
 check(result.outcome.reason.contains("agreed this evening and kept it"),"saved note states only real fulfilled promise")
 var nonparticipant: Dictionary=owner.game.career.duplicate(true)
 for plan in nonparticipant[Situation.KEY].plans:
  if plan.id==result.outcome.attendance.plan_id:plan.participant_ids.erase("cast_jack")
 check(not Intent.kept_evening(nonparticipant,result.outcome,"cast_jack"),"attending guest outside actual plan cannot earn kept-evening credit")
 owner.game.career=due.duplicate(true);owner.game.career.members[0].life_status="inactive"
 view=Situation.inspect_rehearsal(owner.game.career)
 result=owner.game.rehearse_attending(view.attendee_indices,{"focus":"listening","effort":"steady"})
 if not check(result.ok,"remaining actual musicians can practise after roster change"):return
 check(str(result.outcome.attendance.plan_id).is_empty(),"due but incomplete original participants is not fulfilled")
 check(not Intent.kept_evening(owner.game.career,result.outcome,"cast_zoe"),"no false date-only credit for an actual attendee")
 check(owner.game.career[Connections.KEY].records.cast_jack==due[Connections.KEY].records.cast_jack,"absent musician gets no invented practice, rapport or penalty")

func finish_character() -> void:
 print("CHARACTER_CONSEQUENCE_TEST "+JSON.stringify({"checks":checks,"failures":failures,"physical_device":false,"listening":false}))
 owner=null;call_deferred("quit",0 if failures.is_empty() else 1)
