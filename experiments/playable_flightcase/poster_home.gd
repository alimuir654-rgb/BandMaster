extends RefCounted
## Saved facts and existing guarded routes; no new director or career writes.
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
const DirectionCard=preload("res://experiments/playable_flightcase/direction_card.gd")
const Launcher=preload("res://experiments/playable_flightcase/career_launcher.gd")
const Recordings=preload("res://experiments/playable_flightcase/recording_rules.gd")
static func render(host,parent: Node,compact: bool) -> void:
 var state: Dictionary=host.game.career
 var mast: Label=P.label(str(state.get("band_name","YOUR BAND")).to_upper(),54 if compact else 74,P.PAPER);mast.name="PosterBandMasthead";parent.add_child(mast)
 if host.poster_activities_open:
  parent.add_child(P.label("MAKE TODAY COUNT",26,P.GOLD))
  Launcher.render(host,parent,compact)
  parent.add_child(host._button("BACK TO YOUR BAND  ↑","PosterActivitiesAction",host._toggle_poster_activities))
  return
 parent.add_child(P.label(str(host.game.genre).to_upper()+" · "+str(state.get("vibe","Unpolished")).to_upper(),18,P.GOLD))
 var columns:=GridContainer.new();columns.columns=1 if compact else 2;columns.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_theme_constant_override("h_separation",14);columns.add_theme_constant_override("v_separation",12);parent.add_child(columns)
 var facts: VBoxContainer=P.block(columns,P.GOLD)
 var fanrow:=HBoxContainer.new();fanrow.add_theme_constant_override("separation",14);facts.add_child(fanrow)
 var fans: Label=P.label("%d FANS" % int(state.get("fans",0)),32);fans.name="PosterFans";fanrow.add_child(fans)
 var buzz: Label=P.label("BUZZ %s  /  PRESS %s" % [str(state.get("buzz","NOT RECORDED")),str(state.get("press","NOT RECORDED"))],18);buzz.name="PosterPublicReach";fanrow.add_child(buzz)
 var demos: Array=Recordings.sessions(state)
 var demo_line: String="DEMO / STILL TO COME"
 if not demos.is_empty():
  var latest: Dictionary=demos.back()
  demo_line="DEMO / "+("OUT LOCALLY" if latest.get("released",false) else "READY TO RELEASE")+" · %d TRACKS" % (latest.get("tracks",[]) as Array).size()
 var demo: Label=P.label(demo_line,20);demo.name="PosterDemoStatus";facts.add_child(demo)
 var booking: Variant=state.get("booked_show",{})
 if booking is Dictionary and not booking.is_empty():
  var show: Label=P.label("NEXT / %s · DAY %s" % [str(booking.get("venue_snapshot",{}).get("venue",booking.get("venue","SAVED SHOW"))),str(booking.get("day","NOT RECORDED"))],20);show.name="CareerSavedShowAgreement";facts.add_child(show)
 else:facts.add_child(P.label("NEXT SHOW / THE DIARY'S OPEN",20))
 var milestone: VBoxContainer=P.block(columns)
 var view: Dictionary=host._goal_direction()
 var title: Label=P.label("NEXT MILESTONE / "+str(view.get("title","YOUR BAND")),24);title.name="PosterMilestone";milestone.add_child(title)
 var progress: PackedStringArray=[]
 for requirement in view.get("requirements",[]):
  progress.append("%s %s/%s" % [str(requirement.label),str(requirement.current),str(requirement.target)] if requirement.get("recorded",true) else str(requirement.label)+" / NOT RECORDED")
 milestone.add_child(P.label(" · ".join(progress) if not progress.is_empty() else str(view.get("description","")),18))
 var week: Dictionary=host.BandWeek.offer(state)
 var needs_week: bool=week.get("ok",false) and week.get("changed",false)
 if needs_week:
  var editable: bool=false
  for person in host.Situation.members(state):
   if person.editable:editable=true;break
  needs_week=editable and host.Booking.guard_commitment(state,"recorded_context",0).get("ok",false)
 var next: VBoxContainer=P.block(parent,P.BLUE)
 next.add_child(P.label("WHAT'S THE NEXT MOVE?",26,P.PAPER))
 var route: String=str(view.get("route",""))
 var reasons: Dictionary={"create":"A set starts with songs. Bring another original into the room.","tighten":"Give the set some time together. Check who's around before you book the room.","gigs":"Get out of the practice room. See what's on the live circuit.","calendar":"Check the diary and plan the next band day."}
 next.add_child(P.label("Find an evening that fits. Put work and family commitments in the diary together." if needs_week else (str(reasons.get(route,view.get("description","Choose where the band goes next."))) if view.get("ok",false) else str(view.get("message","Review the current band goal."))),20,P.PAPER))
 if needs_week:next.add_child(host._button("PLAN OUR WEEK  →","PosterNextAction",host._open_situation,true))
 elif view.get("ok",false) and not route.is_empty():next.add_child(host._button(str(view.get("route_label","LET'S GO"))+"  →","PosterNextAction",host._goal_preparation.bind(route),true))
 parent.add_child(host._button("CHOOSE SOMETHING ELSE  →","PosterActivitiesAction",host._toggle_poster_activities))
 var details:=VBoxContainer.new();details.visible=host.poster_details_open;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 parent.add_child(host._button("BAND PULSE & GOALS  −" if host.poster_details_open else "BAND PULSE & GOALS  +","PosterPulseAction",host._toggle_poster_details));parent.add_child(details)
 var paper: VBoxContainer=host._paper(details,compact)
 DirectionCard.goal(host,paper,compact)
 for entry in [["READINESS","readiness"],["BAND MORALE","morale"],["TENSION","tension"]]:
  host._copy(paper,str(entry[0]),18)
  paper.add_child(host.C.meter(int(state.get(str(entry[1]),0)),"notepaper"))
 host._copy(paper,"%d FINISHED ORIGINALS" % int(state.get("songs",0)),18)
