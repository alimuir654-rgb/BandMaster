extends RefCounted
## Saved facts, original guarded routes, native poster composition.
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
const DirectionCard=preload("res://experiments/playable_flightcase/direction_card.gd")
const Launcher=preload("res://experiments/playable_flightcase/career_launcher.gd")
const Recordings=preload("res://experiments/playable_flightcase/recording_rules.gd")
const DayNavigation=preload("res://experiments/playable_flightcase/day_navigation.gd")
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Cover=preload("res://experiments/playable_flightcase/demo_cover.gd")
static func render(host,parent: Node,compact: bool) -> void:
 var state: Dictionary=host.game.career
 var width: float=maxf(280,host.size.x-60)
 if host.poster_activities_open:
  var mark=host.BandMark.new()
  mark.name="CareerActivitiesBandName"
  mark.configure(str(state.get("band_name","YOUR BAND")),str(state.get("logo","Wordmark")),host.IdentityStyle.effective(state.get(host.IdentityStyle.KEY,{}),str(state.get("palette",""))),42,true,true,true)
  parent.add_child(mark)
  var prompt: Label=P.label("WHAT'S NEXT?",18,P.PAPER)
  prompt.name="CareerMakePrompt";prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  parent.add_child(prompt)
  Launcher.render(host,parent,compact)
  return
 var mast: Label=P.masthead(str(state.get("band_name","YOUR BAND")).to_upper(),width,68 if compact else 80);mast.name="PosterBandMasthead";parent.add_child(mast)
 var facts: Node=parent
 var actions: Node=parent
 if not compact:
  var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",20);columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(columns)
  var left:=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=1;left.add_theme_constant_override("separation",12);columns.add_child(left);facts=left
  var right:=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.size_flags_stretch_ratio=1;right.add_theme_constant_override("separation",12);columns.add_child(right);actions=right
 var view: Dictionary=host._goal_direction()
 var hero: VBoxContainer=P.block(facts,P.GOLD,12)
 var title: Label=P.label(str(view.get("title","MAKE A START")).to_upper(),30 if compact else 38);title.name="PosterMilestone";hero.add_child(title)
 var progress: PackedStringArray=[]
 for requirement in view.get("requirements",[]):progress.append("%s %s/%s" % [str(requirement.label),str(requirement.current),str(requirement.target)] if requirement.get("recorded",true) else str(requirement.label)+" / NOT RECORDED")
 hero.add_child(P.label(" · ".join(progress) if not progress.is_empty() else str(view.get("description","")),18))
 var records: Array=Recordings.sessions(state)
 var latest: Dictionary=records.back() if not records.is_empty() else {}
 var demo_box: VBoxContainer=P.block(facts,P.PAPER,12)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);demo_box.add_child(row)
 if not latest.is_empty():
  var art:=Cover.new();art.custom_minimum_size=Vector2(92,92);art.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;art.identity=str(latest.get("id","legacy"));row.add_child(art)
 var detail:=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail)
 detail.add_child(P.label("DEBUT DEMO" if records.size()<=1 else "DEMO %d"%records.size(),26))
 var demo_text: String="DEMO / STILL TO COME" if latest.is_empty() else "DEMO / "+("OUT LOCALLY" if latest.get("released",false) else "READY TO RELEASE")+" · %d TRACKS"%(latest.get("tracks",[]) as Array).size()
 var demo: Label=P.label(demo_text,18);demo.name="PosterDemoStatus";detail.add_child(demo)
 if latest.is_empty():detail.add_child(P.label("2–3 originals. Something to say.",18))
 var stats:=GridContainer.new();stats.columns=3;stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stats.add_theme_constant_override("h_separation",5);facts.add_child(stats)
 for entry in [["FANS",str(state.get("fans",0)),P.GOLD],["LOCAL BUZZ",str(state.get("buzz","?")),P.PAPER],["PRESS",str(state.get("press","?")),P.RUST]]:
  var block: VBoxContainer=P.block(stats,entry[2],12);var color: Color=P.PAPER if entry[2]==P.RUST else P.INK
  var value: Label=P.label(str(entry[1]),34,color);value.name="PosterFans" if entry[0]=="FANS" else ("PosterPublicReach" if entry[0]=="LOCAL BUZZ" else "PosterPress");block.add_child(value)
  if entry[0]=="FANS":value.set_meta("public_fans",state.get("fans",0))
  block.add_child(P.label(entry[0],17,color))
 var booking: Variant=state.get("booked_show",{})
 if booking is Dictionary and not booking.is_empty():
  var ticket: VBoxContainer=P.block(actions,P.BLUE,12)
  var date: String="DAY "+str(booking.get("day","NOT RECORDED"));var info: Dictionary=host.CareerDates.info(state,int(booking.get("day",1)))
  if not info.is_empty():date="%s %d %s"%[str(info.weekday_name).to_upper(),int(info.date),str(info.month_name).to_upper()]
  var place: Variant=booking.get("venue_snapshot",{});var venue: String=str(place.get("venue",booking.get("venue","SAVED SHOW"))) if place is Dictionary else str(booking.get("venue","SAVED SHOW"))
  var show: Label=P.label(date+" / "+venue.to_upper(),24,P.PAPER);show.name="CareerSavedShowAgreement";ticket.add_child(show)
 # Rendering only reads durable promises; it never resolves or extends them.
 var promise_id: String="";var promise: Dictionary={}
 if Chat.validate(state).ok:
  for id in state.get(Chat.KEY,{}).get("records",{}):
   var candidate: Dictionary=Chat.record(state,id).get("plan",{})
   if candidate.get("status")=="pending" and (promise.is_empty() or int(candidate.due_day)<int(promise.due_day)) and not Chat.member(state,id).is_empty():promise_id=id;promise=candidate
 if not promise.is_empty():
  var reminder: VBoxContainer=P.block(actions,P.PAPER,12)
  var name: String=str(Chat.member(state,promise_id).get("name","Bandmate"))
  reminder.add_child(P.label(name.to_upper()+" · THROUGH DAY %d"%int(promise.due_day),22))
  reminder.add_child(P.label({"write":"You agreed to make time for a song.","rehearse":"You agreed an evening to rehearse.","rest":"You agreed to leave room to recover."}[promise.kind],18))
  reminder.add_child(host._button("TALK TO "+name.to_upper()+" ›","PosterPromiseAction",host._open_musician_chat.bind(promise_id)))
 var week: Dictionary=host.BandWeek.offer(state);var needs_week: bool=week.get("ok",false) and week.get("changed",false)
 if needs_week:
  var editable:=false
  for person in host.Situation.members(state):
   if person.editable:editable=true;break
  needs_week=editable and host.Booking.guard_commitment(state,"recorded_context",0).get("ok",false)
 var route: String=str(view.get("route",""))
 var reasons: Dictionary={"create":"Find the next song. Bring an idea into the room.","tighten":"Who's around? Make time for a run-through.","gigs":"Book a room. Play loud. See who's listening.","calendar":"Get the diary out. Find your next band day."}
 var evening: Dictionary=DayNavigation.inspect(state)
 var first_gig: bool=view.get("ok",false) and view.get("id")=="find_sound" and view.get("ready",false) and state.get("gig_history",[]).is_empty() and booking is Dictionary and booking.is_empty()
 var blocked_evening: bool=not first_gig and evening.get("ok",false) and int(evening.count)<2 and not needs_week and not host.LiveRules.show_day(state) and host.Booking.guard_commitment(state,"practice",1).get("ok",false)
 var follow_promise: bool=not promise.is_empty() and booking is Dictionary and booking.is_empty() and not needs_week
 var next: VBoxContainer=P.block(actions,P.RUST,12)
 next.add_child(P.label("TONIGHT" if blocked_evening else "YOUR NEXT MOVE",24,P.PAPER))
 var next_words: String=str(reasons.get(route,view.get("description","Choose where the band goes next.")))
 if first_gig:next_words="You have an original and a rehearsed set. Talk to a local promoter about a future date."
 elif blocked_evening:next_words=str(evening.summary)
 elif needs_week:next_words="Find an evening that fits work, family and the band."
 elif follow_promise:next_words={"write":"Bring the idea you agreed into the room.","rehearse":"Make time for the run-through you agreed.","rest":"Leave the next hard push for another evening."}[promise.kind]
 next.add_child(P.label(next_words,18,P.PAPER))
 if first_gig:next.add_child(host._button("FIND YOUR FIRST GIG ›","PosterNextAction",host._open_booking.bind({}),true))
 elif blocked_evening:next.add_child(host._button(str(evening.preview_label),"PosterNextAction",host._practice.bind("jam"),true))
 elif needs_week:next.add_child(host._button("PLAN OUR WEEK  →","PosterNextAction",host._open_situation,true))
 elif follow_promise:next.add_child(host._button({"write":"TAKE IT TO THE WRITING ROOM ›","rehearse":"TAKE IT TO REHEARSAL ›","rest":"MAKE ROOM TO RECOVER ›"}[promise.kind],"PosterNextAction",host._practice.bind({"write":"create","rehearse":"tighten","rest":"connect"}[promise.kind]),true))
 elif view.get("ok",false) and not route.is_empty():next.add_child(host._button(str(view.get("route_label","LET'S GO"))+"  →","PosterNextAction",host._goal_preparation.bind(route),true))
 elif view.get("ok",false):next.add_child(host._button("MAKE A PLAN ›","PosterNextAction",host._toggle_poster_activities,true))
 var choices: Button=P.quiet("Choose something else  →");choices.name="PosterActivitiesAction";choices.pressed.connect(host._toggle_poster_activities);actions.add_child(choices)
 var pulse: Button=P.quiet("Band pulse & goals  −" if host.poster_details_open else "Band pulse & goals  +");pulse.name="PosterPulseAction";pulse.pressed.connect(host._toggle_poster_details);actions.add_child(pulse)
 var details:=VBoxContainer.new();details.visible=host.poster_details_open;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(details)
 var paper: VBoxContainer=host._paper(details,compact);DirectionCard.goal(host,paper,compact)
 for entry in [["READINESS","readiness"],["BAND MORALE","morale"],["TENSION","tension"]]:
  host._copy(paper,str(entry[0]),18);paper.add_child(host.C.meter(int(state.get(str(entry[1]),0)),"notepaper"))
  if entry[1]=="tension":host._copy(paper,"Lower means calmer.",16).name="CareerTensionMeaning"
 host._copy(paper,"%d FINISHED ORIGINALS"%int(state.get("songs",0)),18)
