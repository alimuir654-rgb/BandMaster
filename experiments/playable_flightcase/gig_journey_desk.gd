extends RefCounted
## Native journey composition. Explicit owner callbacks alone mutate/save state.
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Journey = preload("res://experiments/playable_flightcase/gig_journey.gd")
const Scene = preload("res://experiments/playable_flightcase/gig_journey_scene.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const ShowDesk = preload("res://experiments/playable_flightcase/show_desk.gd")
const Circuit=preload("res://experiments/playable_flightcase/scene_circuit.gd")
const Crowd=preload("res://experiments/playable_flightcase/crowd_reaction.gd")
const Incident=preload("res://experiments/playable_flightcase/gig_incident.gd")
const ARRIVAL := "res://experiments/playable_flightcase/art/s53_arrival.png"
const ROAD := "res://experiments/playable_flightcase/art/a07_road_travel_v1.png"
const ROAD_SHA := "1b12bb89a6ec154c73ed24e8f25fe88ecfe2070d8f95dc3494a993402e2d4bec"
const ROOM := "res://experiments/playable_flightcase/art/opening_stage.png"
const CROWD := "res://experiments/playable_flightcase/art/s53_stage.png"
const TITLES := {"begin":"THE BAND'S NIGHT","set_out":"MEET THE LIFT","travel":"ACROSS TOWN","arrival":"THE LOAD-IN DOOR","load_in":"CARRY IT INSIDE","soundcheck":"FIND THE ROOM","backstage":"A MOMENT WITH THE BAND","stage_entrance":"INTO THE LIGHT","performing":"THE SET","choice":"READ THE ROOM","reaction":"LET IT LAND","after_set":"THE LAST NOTE","pack_up":"PACKING UP","wrap_ready":"BACK TO THE LIFT"}

static func active(host) -> bool:
 return host.game!=null and (Journey.locked(host.game.career) or Journey.eligible(host.game.career))

static func _voice(state: Dictionary, view: Dictionary) -> Dictionary:
 var visit: Dictionary=view.get("active",{})
 var actor: Dictionary=visit.get("context",{}).get("actor",{})
 if not actor.is_empty():return actor
 var phase: String=str(view.get("phase",""))
 var people: Array=[]
 for index in range(state.get("members",[]).size()):
  var person: Dictionary=state["members"][index]
  if str(person.get("life_status","active"))=="active":people.append({"slot":index,"candidate_id":str(person.get("candidate_id","")),"name":str(person.get("name","Bandmate")),"role":str(person.get("role","Musician")),"fatigue":int(person.get("fatigue",0)),"pressure":0})
 if phase=="soundcheck":
  for id in ["cast_marcus","cast_bex"]:
   for person in people:
    if person["candidate_id"]==id:return person
 if phase=="load_in":
  for person in people:
   if str(person["role"]).to_lower() in ["drums","drummer"]:return person
 return people[0] if not people.is_empty() else {"name":"THE BAND","candidate_id":"","fatigue":0,"pressure":0}

static func _text(phase: String, state: Dictionary, visit: Dictionary, actor: Dictionary) -> String:
 var venue: String=str(Calendar.pending(state).get("venue","the room"))
 var songs: Array=visit.get("plan",{}).get("song_snapshots",[])
 var cursor: int=int(visit.get("cursor",0))
 var next_song: String=str(songs[cursor].get("title","the next one")) if cursor<songs.size() else "the next one"
 var history: Dictionary=actor.get("history",{})
 match phase:
  "begin","set_out":return "%s tonight. Just us and that room. Cases in, then we're off." % venue
  "travel":return ("The agreed trip takes us to %s. Next stop: the load-in door." % str(Calendar.pending(state).get("city","the venue"))) if Booking.modern(state) else "The lift takes us across town. Next stop: the load-in door."
  "arrival":return "That's our door. Let's get the gear in before we think about the set."
  "load_in":return "Set up where we can see each other. We start together."
  "soundcheck":
   if actor.get("candidate_id")=="cast_marcus":return "Let's get the order straight before we walk out."
   if actor.get("candidate_id")=="cast_bex":return "Show me the order. I want to know where these songs are going."
   return "Let's agree the songs and the way we want to play them. This is still our soundcheck."
  "backstage":
   if int(actor.get("fatigue",0))>=50:return "I could use a breath before we go out. Stay with me."
   if bool(actor.get("recorded_history",false)) and int(history.get("excluded",0))>0:return "I've been out of the room for some of this. Tell me the plan before we go on."
   if bool(actor.get("recorded_history",false)) and int(history.get("kept",0))>0:return "We got that rehearsal in. Let's trust what we worked on."
   if actor.get("candidate_id") in ["cast_maya","cast_nina"] and not songs.is_empty():return "%s. Right. I want that in my head before we go." % str(songs[0].get("title","Our first song"))
   return "We've got our set. A breath, then we go on together."
  "stage_entrance":return "We're here now. Give me the count-in."
  "performing":
   if songs.is_empty():return "No originals in tonight's set. Stay together and keep this short."
   return "%s. Stay with me, then look up at the room." % next_song
  "choice":return ("The room feels a little warmer. A breath, or straight into %s?" if int(visit.get("vibe",40))>=42 else "I can't read this room yet. A breath, or straight into %s?") % next_song
  "reaction":return ("A breath, then %s. I'm with you." if visit.get("intent")=="moment" else "Straight into %s, then. Keep an eye on me.") % next_song
  "after_set":return "That was the last one. Let it land before we start packing." if not songs.is_empty() else "That's the short set. Let's get everything back to the lift."
  "pack_up":return "Gear away first. We can talk about %s on the way back." % str(songs[-1].get("title","tonight")) if not songs.is_empty() else "Gear away first. We can talk about tonight on the way back."
  "wrap_ready":return "The gear is back at the lift. Let's settle the night and head home."
 return "The saved night is here when you're ready."

static func render(host, parent: Node, compact: bool) -> void:
 var state: Dictionary=host.game.career
 var view: Dictionary=Journey.view(state)
 host._gig_presentation_valid=bool(view.get("ok",false))
 host._gig_presentation_token=Journey.Policy.fingerprint(view.get("active",{})) if host._gig_presentation_valid else ""
 if not bool(view.get("ok",false)):
  parent.add_child(C.label(str(view.get("message","This saved night needs attention.")),18))
  return
 var phase: String=str(view["phase"])
 var visit: Dictionary=view["active"]
 var act: String="1 / ARRIVAL & SOUNDCHECK" if phase in ["begin","set_out","travel","arrival","load_in","soundcheck"] else ("3 / AFTER THE SET" if phase in ["after_set","pack_up","wrap_ready"] else "2 / ON STAGE")
 var act_heading: Label=C.label(act,18);act_heading.name="JourneyAct";parent.add_child(act_heading)
 var actor: Dictionary=_voice(state,view)
 var plan_focus: bool=phase=="soundcheck" and visit.has(Incident.KEY) and not Incident.pending(visit)
 var pending_situation: bool=phase=="soundcheck" and Incident.pending(visit)
 var situation_copy: Dictionary=Incident.copy(visit) if pending_situation else {}
 var source: Dictionary=Cast.by_id(str(actor.get("candidate_id","")))
 var image_path: String=ROAD if phase=="travel" else (ARRIVAL if phase in ["begin","set_out","arrival","pack_up","wrap_ready"] else (CROWD if phase in ["stage_entrance","performing","choice","reaction"] else ROOM))
 var caption: String=str(Calendar.pending(state).get("venue","THE LANTERN ROOM"))+" · "+str(Calendar.pending(state).get("city","HOMETOWN"))
 var short: bool=host.size.x>host.size.y and host.size.y<800
 var paired: bool=host.size.x>host.size.y and host.size.x>=1180
 var soundcheck_workspace: bool=phase=="soundcheck" and host.size.x<=host.size.y
 var scene=Scene.new()
 scene.configure({"title":str(situation_copy.title) if pending_situation else ("ON THE ROAD TO "+str(Calendar.pending(state).get("city","THE SHOW"))) if phase=="travel" and Booking.modern(state) else str(TITLES.get(phase,"TONIGHT")),"image":image_path,"travel":phase=="travel","source_sha256":ROAD_SHA if phase=="travel" else "","caption":caption,"speaker":str(situation_copy.speaker) if pending_situation else str(actor.get("name","THE BAND")),"portrait":"" if pending_situation else str(source.get("portrait_preview","")),"text":"" if plan_focus else (str(situation_copy.text) if pending_situation else _text(phase,state,visit,actor)),"fresh":bool(host._journey_fresh),"side_by_side":paired,"soundcheck_workspace":soundcheck_workspace},bool(host.reduced_motion),maxf(280,host.size.x-88),short)
 parent.add_child(scene)
 if phase in ["stage_entrance","performing","choice","reaction","after_set"]:
  var reaction: String=Crowd.live(visit)
  Crowd.apply(scene.image_view,reaction)
  var room_caption: Label=C.label(str(Crowd.CAPTIONS[reaction]),16);room_caption.name="GigCrowdCaption";parent.add_child(room_caption)
 host._journey_fresh=false
 if plan_focus:scene.note.hide()
 if not str(host.notice).is_empty():
  var notice: Label=C.label(str(host.notice),16);notice.name="JourneySaveNotice";parent.add_child(notice)
 if pending_situation:
  parent.add_child(C.label("£0 EXTRA · NO EXTRA CAREER DAY",16))
  return # The choices stay in the dock; plan follows the answer.
 var context: Node=scene.context_column if short or paired else parent
 if phase=="soundcheck":
  var situation: Dictionary=Incident.copy(visit)
  if not situation.is_empty():
   var feedback: Label=C.label(str(situation.text),16);feedback.name="SoundcheckSavedAnswer";feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;context.add_child(feedback)
  host._sync_show_draft()
  var hardware_parent: Node=context
  var set_parent: Node=context
  if paired:
   var workbench: HBoxContainer=HBoxContainer.new()
   workbench.name="JourneySoundcheckColumns"
   workbench.add_theme_constant_override("separation",16)
   workbench.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   context.add_child(workbench)
   var hardware_column: VBoxContainer=VBoxContainer.new()
   hardware_column.name="JourneyHardwareColumn"
   hardware_column.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
   workbench.add_child(hardware_column)
   var set_column: VBoxContainer=VBoxContainer.new()
   set_column.name="JourneySetColumn"
   set_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   workbench.add_child(set_column)
   hardware_parent=hardware_column
   set_parent=set_column
  if soundcheck_workspace:
   # Keep the actual set first without adding navigation or local saved state.
   # The unchanged factory adds its paper before optional shout/incident rows;
   # place the full hardware immediately after that paper in the same scroll.
   var paper_index: int=context.get_child_count()
   ShowDesk.journey_soundcheck(host,context,state)
   ShowDesk.controls(host,context,compact)
   context.move_child(context.get_child(context.get_child_count()-1),paper_index+1)
  else:
   ShowDesk.controls(host,hardware_parent,compact)
   ShowDesk.journey_soundcheck(host,set_parent,state)
 elif phase in ["performing","choice","reaction","after_set","pack_up","wrap_ready"]:
  var set_title: Label=C.label("TONIGHT'S SET",16)
  set_title.name="JourneySetlistHeading"
  context.add_child(set_title)
  var songs: Array=visit.get("plan",{}).get("song_snapshots",[])
  if songs.is_empty():context.add_child(C.label("No originals selected · a short set",16))
  for index in range(songs.size()):
   var row: RichTextLabel=RichTextLabel.new()
   row.name="JourneySong_%d" % index
   row.bbcode_enabled=true
   row.fit_content=true
   row.scroll_active=false
   row.mouse_filter=Control.MOUSE_FILTER_IGNORE
   row.add_theme_font_override("normal_font",C.Poster.FONT)
   row.add_theme_font_size_override("normal_font_size",16)
   var title: String=str(songs[index].get("title","Original")).replace("[","［").replace("]","］")
   row.text=("[s]"+str(index+1)+". "+title+"[/s]  ✓") if index<int(visit.get("cursor",0)) else ("▶ " if index==int(visit.get("cursor",0)) and phase=="performing" else "")+str(index+1)+". "+title
   row.set_meta("completed",index<int(visit.get("cursor",0)))
   context.add_child(row)
  var meter: HBoxContainer=C.meter(int(visit.get("vibe",40)),"flightcase")
  meter.name="JourneyVibeMeter"
  meter.set_meta("kind","modelled_live_room")
  context.add_child(C.label("ROOM VIBE",16))
  context.add_child(meter)
 var bill: Dictionary=Booking.terms(state).get(Circuit.BILL,{})
 if not bill.is_empty():
  var position: Label=C.label(str({"opening":"OPENING SUPPORT","main_support":"MAIN SUPPORT","headline":"HEADLINER"}.get(bill.slot,"SHARED BILL")),18)
  position.name="JourneyBillPosition";context.add_child(position)
  _peers(host,context,state,visit,bill,phase)

static func _peers(host,parent: Node,state: Dictionary,visit: Dictionary,bill: Dictionary,phase: String) -> void:
 var encounter: Dictionary=visit.get(Circuit.ENCOUNTER,Circuit.encounter_empty())
 var token: Dictionary=Journey.expected(state)
 if phase=="backstage":
  if Circuit.above(bill).is_empty():
   parent.add_child(C.label("You're closing tonight. The support bands are getting ready for their own sets.",18));return
  parent.add_child(C.label("OTHER VOICES ON THE BILL",22))
  parent.add_child(C.label("The acts above you have been doing this longer. Their way of playing may or may not fit your band. Hearing them out uses no extra career day.",18))
  for id in Circuit.above(bill):
   var band: Dictionary=Circuit.BANDS[id]
   parent.add_child(C.label(str(band.name)+": "+str(band.advice),19))
   if encounter.advice.is_empty():_button(host,parent,"TRY "+str(band.name)+"'S IDEA","SceneAdvice_"+str(id),"scene_advice",token,{"band_id":id,"choice":"try"})
  if encounter.advice.is_empty():_button(host,parent,"TRUST THE SET WE REHEARSED","SceneAdviceOwn","scene_advice",token,{"band_id":"","choice":"own_set"})
  else:parent.add_child(C.label("YOUR ANSWER IS SAVED · "+("Trust our set." if encounter.advice.choice=="own_set" else "Try "+str(Circuit.BANDS[encounter.advice.band_id].name)+"'s suggestion."),18))
 elif phase=="after_set":
  parent.add_child(C.label("THE NIGHT ISN'T JUST YOUR SET",22))
  parent.add_child(C.label("Stay for another act or lend a hand with their gear. This happens within tonight's agreed trip: £0 and no extra career day. You can also focus on getting your own band home.",18))
  if encounter.support.is_empty():
   for id in bill.lineup:
    if id=="player":continue
    var band: Dictionary=Circuit.BANDS[id]
    if id in Circuit.above(bill):_button(host,parent,"STAY FOR "+str(band.name),"SceneWatch_"+str(id),"scene_support",token,{"band_id":id,"choice":"watch"})
    _button(host,parent,"HELP "+str(band.name)+" WITH GEAR","SceneHelp_"+str(id),"scene_support",token,{"band_id":id,"choice":"help"})
   for id in bill.context.get("favors",{}):
    if id in bill.lineup:_button(host,parent,"ASK "+str(Circuit.BANDS[id].name)+" TO RETURN THE HAND","SceneFavor_"+str(id),"scene_support",token,{"band_id":id,"choice":"call_favor","favor_id":bill.context.favors[id]})
   _button(host,parent,"LOOK AFTER OUR OWN GEAR","SceneOwnGear","scene_support",token,{"band_id":"","choice":"own_gear"})
  else:parent.add_child(C.label("SAVED · "+("Look after our own gear." if encounter.support.choice=="own_gear" else ("Help " if encounter.support.choice=="help" else ("Call in a hand from " if encounter.support.choice=="call_favor" else "Stay for "))+str(Circuit.BANDS[encounter.support.band_id].name)+"."),18))

static func _button(host,parent: Node,text: String,name: String,action: String,expected: Dictionary,payload: Dictionary = {}) -> Button:
 var button: Button=host._button(text,name,host._commit_journey.bind(action,expected.duplicate(true),payload.duplicate(true),int(host._render_generation)),true)
 if name.begins_with("Scene"):button.set_meta("scene_peer_choice",true)
 if name.begins_with("GigAnswer_"):button.set_meta("journey_event_choice",true)
 parent.add_child(button)
 return button

static func dock(host, parent: Node, _compact: bool) -> void:
 var state: Dictionary=host.game.career
 var view: Dictionary=Journey.view(state)
 if not bool(view.get("ok",false)):
  parent.add_child(C.label("Your saved night has been retained. Return to the menu to use a compatible build.",16))
  return
 var visit: Dictionary=view["active"]
 var phase: String=str(view["phase"])
 var token: Dictionary=view["expected"]
 if host.size.x<=host.size.y and phase in ["performing","choice","reaction","after_set"]:
  var count: int=visit["plan"]["song_snapshots"].size()
  var cursor: int=int(visit["cursor"])
  var position: String="SHORT SET · NO ORIGINALS SELECTED"
  if count>0:
   if phase=="after_set":position="SET COMPLETE · %d OF %d" % [cursor,count]
   else:position=("PLAYING" if phase=="performing" else "NEXT")+" · SONG %d OF %d · %d COMPLETE" % [cursor+1,count,cursor]
  var summary: Label=C.label(position,16)
  summary.name="JourneySetPosition"
  parent.add_child(summary)
 if phase=="begin":
  _button(host,parent,"HEAD TO THE VENUE  ›","JourneyMainAction","begin_arrive",{}, {"booking_id":Flow.booking_id(Calendar.pending(state))})
  parent.add_child(host._button("OPEN THE CALENDAR","JourneyCalendarAction",host._navigate.bind("calendar")))
 elif phase=="choice":
  _button(host,parent,"GIVE THE ROOM A MOMENT","JourneyChoiceMomentAction","live_intent",token,{"intent":"moment"})
  _button(host,parent,"KEEP THE SET MOVING","JourneyChoiceMovingAction","live_intent",token,{"intent":"moving"})
 elif phase=="performing":
  var ids: Array=visit.get("plan",{}).get("song_ids",[])
  if ids.is_empty():_button(host,parent,"END THE SHORT SET  ›","JourneyMainAction","end_short_set",token)
  else:_button(host,parent,"FINISH SONG  ›","JourneyFinishSongAction","finish_song",token,{"song_id":ids[int(visit["cursor"])],"cursor":int(visit["cursor"])})
 elif phase=="soundcheck" and Incident.pending(visit):
  for answer in Incident.copy(visit).choices:_button(host,parent,str(answer[1]),"GigAnswer_"+str(answer[0]),"soundcheck_answer",token,{"choice":answer[0]})
 elif phase=="soundcheck":
  var checked: Dictionary=Flow.check_plan(state,host.show_draft)
  var action: Button=_button(host,parent,"SAVE TONIGHT'S SHOW PLAN  ›","JourneyMainAction","soundcheck",token)
  action.disabled=bool(host.busy) or Incident.pending(visit) or not bool(checked.get("ok",false))
 elif phase in ["backstage","stage_entrance"]:
  _button(host,parent,"TAKE THE STAGE  ›","JourneyMainAction","take_stage",token)
 elif phase in ["after_set","pack_up"]:
  _button(host,parent,"GEAR AWAY & HEAD HOME  ›","JourneyMainAction","pack_and_leave",token)
 elif phase=="wrap_ready":
  var days: int=int(Booking.terms(state).get("tariff",{}).get("duration",1))
  if Booking.modern(state):
   var tariff: Dictionary=Booking.terms(state)["tariff"]
   var transport: int=mini(int(tariff["travel"]),int(state.get("cash",0))) if Calendar.pending(state).get("venue_id")=="local" else int(tariff["travel"])
   var cost: int=transport+int(tariff["accommodation"])+(25 if Booking.terms(state)["session_drummer"] else 0)
   parent.add_child(C.label("£%d costs at settlement · %d career day(s)" % [cost,days],16))
  else:parent.add_child(C.label("Settle the original show costs · 1 career day",16))
  _button(host,parent,"WRAP THE NIGHT & HEAD HOME  ›","JourneyWrapAction","wrap",token)
 elif phase in ["set_out","travel","arrival","load_in"]:
  parent.add_child(C.label("The agreed trip and load-in carry straight through. Your set and soundcheck decisions come next.",16))
  _button(host,parent,"TRAVEL & LOAD IN  ›","JourneyMainAction","arrive_soundcheck",token)
 else:
  var names: Dictionary={"set_out":"SET OUT  ›","travel":"ARRIVE AT THE VENUE  ›","arrival":"CARRY THE GEAR IN  ›","load_in":"START SOUNDCHECK  ›","backstage":"READY TO GO ON  ›","stage_entrance":"START THE SET  ›","reaction":"BACK TO THE SET  ›","after_set":"PACK UP TOGETHER  ›","pack_up":"BACK TO THE LIFT  ›"}
  _button(host,parent,str(names.get(phase,"CONTINUE  ›")),"JourneyMainAction","advance",token)
 if not visit.is_empty():
  var options: Button=host._button("SHOW OPTIONS","JourneyShowOptionsAction",host._ask_journey_options.bind(token.duplicate(true),int(host._render_generation)))
  parent.add_child(options)
