extends RefCounted
## Saved facts and existing guarded routes; no new director or career writes.
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
const DirectionCard=preload("res://experiments/playable_flightcase/direction_card.gd")
const Launcher=preload("res://experiments/playable_flightcase/career_launcher.gd")
const Recordings=preload("res://experiments/playable_flightcase/recording_rules.gd")
static func render(host,parent: Node,compact: bool) -> void:
 var state: Dictionary=host.game.career
 var mast: Label=P.label(str(state.get("band_name","YOUR BAND")).to_upper(),64 if compact else 84,P.PAPER);mast.name="PosterBandMasthead";parent.add_child(mast)
 parent.add_child(P.label("SMALL ROOMS. BIG PLANS.",20,P.GOLD))
 var grid:=GridContainer.new();grid.columns=1 if compact else 2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",14);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(grid)
 var milestone: VBoxContainer=P.block(grid)
 milestone.add_child(P.label("ON THE WAY UP",24))
 DirectionCard.goal(host,milestone,compact)
 var facts: VBoxContainer=P.block(grid,P.GOLD)
 var fans: Label=P.label("%d FANS" % int(state.get("fans",0)),38);fans.name="PosterFans";facts.add_child(fans)
 var buzz: Label=P.label("BUZZ %s  /  LOCAL PRESS %s" % [str(state.get("buzz","NOT RECORDED")),str(state.get("press","NOT RECORDED"))],20);buzz.name="PosterPublicReach";facts.add_child(buzz)
 facts.add_child(P.label("Your current reach. A radio pitch isn't a promise of airplay.",18))
 var demos: Array=Recordings.sessions(state)
 var demo_line: String="DEMO / STILL TO COME"
 if not demos.is_empty():
  var latest: Dictionary=demos.back()
  demo_line="DEMO / "+("OUT LOCALLY" if latest.get("released",false) else "RECORDED, NOT RELEASED")+" · %d TRACKS" % (latest.get("tracks",[]) as Array).size()
 var demo: Label=P.label(demo_line,22);demo.name="PosterDemoStatus";facts.add_child(demo)
 var booking: Variant=state.get("booked_show",{})
 if booking is Dictionary and not booking.is_empty():
  var show: Label=P.label("NEXT SHOW / %s · DAY %s" % [str(booking.get("venue_snapshot",{}).get("venue",booking.get("venue","SAVED SHOW"))),str(booking.get("day","NOT RECORDED"))],22);show.name="CareerSavedShowAgreement";facts.add_child(show)
 else:facts.add_child(P.label("NEXT SHOW / THE DIARY'S OPEN",22))
 var next: VBoxContainer=P.block(parent,P.BLUE)
 next.add_child(P.label("WHAT'S THE NEXT MOVE?",28,P.PAPER))
 var view: Dictionary=host._goal_direction()
 var route: String=str(view.get("route",""))
 var reasons: Dictionary={"create":"A set starts with songs. Bring another original into the room.","tighten":"Give the set some time together. Check who's around before you book the room.","gigs":"Get out of the practice room. See what's on the live circuit.","calendar":"Check the diary and make a plan for the next band day."}
 next.add_child(P.label(str(reasons.get(route,view.get("description","Choose where the band goes next."))) if view.get("ok",false) else str(view.get("message","Review the current band goal.")),20,P.PAPER))
 if view.get("ok",false) and not route.is_empty():next.add_child(host._button(str(view.get("route_label","LET'S GO"))+"  →","PosterNextAction",host._goal_preparation.bind(route),true))
 var choices: Button=host._button("CHOOSE SOMETHING ELSE  ↓" if not host.poster_activities_open else "CLOSE THE NOTICEBOARD  ↑","PosterActivitiesAction",host._toggle_poster_activities)
 parent.add_child(choices)
 if host.poster_activities_open:Launcher.render(host,parent,compact)
 var details:=VBoxContainer.new();details.visible=host.poster_details_open;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var disclosure: Button=host._button("BAND PULSE  −" if host.poster_details_open else "BAND PULSE  +","PosterPulseAction",host._toggle_poster_details);parent.add_child(disclosure);parent.add_child(details)
 # Existing inert meters stay byte-for-byte owned by their original component.
 var paper: VBoxContainer=host._paper(details,compact)
 for entry in [["READINESS","readiness"],["BAND MORALE","morale"],["TENSION","tension"]]:
  host._copy(paper,str(entry[0]),18)
  paper.add_child(host.C.meter(int(state.get(str(entry[1]),0)),"notepaper"))
 host._copy(paper,"%d FINISHED ORIGINALS" % int(state.get("songs",0)),18)
