extends RefCounted
## One new-booking journey over the original hometown models and real artwork.
## All callbacks edit host draft or invoke ONE explicit host transaction.
const Booking = preload("res://experiments/playable_flightcase/gig_booking_rules.gd")
const BookingDesk = preload("res://experiments/playable_flightcase/gig_booking_desk.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Hardware = preload("res://experiments/playable_flightcase/show_hardware.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
const Direction = preload("res://experiments/playable_flightcase/career_direction.gd")
const DirectionCard = preload("res://experiments/playable_flightcase/direction_card.gd")
const ARRIVAL := "res://experiments/playable_flightcase/art/s53_arrival.png"
const STAGE := "res://experiments/playable_flightcase/art/s53_stage.png"
const ROOM := "res://experiments/playable_flightcase/art/opening_stage.png"
const APPROACHES := ["tight","crowd","wild"]

static func active(host) -> bool:
 return host.game!=null and Flow.managed(host.game.career)

static func phase(host) -> String:
 return Flow.phase(host.game.career)

static func hero(parent: Node, path: String, height: float, available_width: float = 0.0) -> TextureRect:
 var photo := TextureRect.new()
 photo.name = "ShowScenePlate"
 photo.texture = load(path if ResourceLoader.exists(path) else ROOM) as Texture2D
 photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 photo.custom_minimum_size.y = height
 photo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if available_width>0.0:
  var width: float=minf(620.0,available_width)
  photo.custom_minimum_size=Vector2(width,width*941.0/1672.0)
  photo.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
 photo.focus_mode = Control.FOCUS_NONE
 photo.clip_contents = true
 parent.add_child(photo)
 return photo

static func _copy(parent: Node, value: String, points: int = 16, muted: bool = false) -> Label:
 var label: Label = C.paper_label(value,points,muted)
 parent.add_child(label)
 return label

static func render(host, parent: Node, compact: bool) -> void:
 var state: Dictionary = host.game.career
 if Booking.modern(state):
  BookingDesk.render_agreement(host,parent,compact,state)
  return
 var booking: Dictionary = Calendar.pending(state)
 var current: String = Flow.phase(state)
 var body: VBoxContainer = host._paper(parent,compact)
 if not str(host.notice).is_empty():
  _copy(body,str(host.notice))
 var title: Label = _copy(body,str(booking.get("venue","YOUR SHOW")).to_upper(),24)
 title.name = "ShowVenue"
 _copy(body,"%s  /  SHOW DAY %d" % [str(booking.get("city","")),int(booking.get("day",0))],16,true)
 var agreement: String=str(state.get("promoter_offer",{}).get("offer_id","standard"))
 _copy(body,"AGREEMENT / "+str(Promoter.OFFERS.get(agreement,{}).get("label",agreement)),16,true)
 var names: PackedStringArray=[]
 for member in state.get("members",[]):
  if member is Dictionary and str(member.get("life_status","active"))=="active":names.append(str(member.get("name","Musician")))
 _copy(body,"PLAYING / "+" · ".join(names),16,true)
 if bool(booking.get("session_drummer",false)):_copy(body,"SESSION DRUMMER / £25 AT SETTLEMENT",16,true)
 if current=="invalid":
  _copy(body,str(Flow.validate(state).get("message","The saved show needs attention.")))
  _copy(body,"Your booking is retained. You can cancel using its original terms.")
  return
 var titles := {"preparation":"BEFORE THE FIRST CHORD","travel":"THE LOCAL LIFT","arrival":"AT THE LOAD-IN DOOR","soundcheck":"MAKE THIS ROOM YOURS","stage":"THE ROOM IS WAITING","overdue":"THE DATE HAS PASSED"}
 _copy(body,str(titles.get(current,"TONIGHT'S SHOW")),20)
 var prose: VBoxContainer=body
 if current!="soundcheck":
  if compact:
   hero(body,STAGE if current=="stage" else ARRIVAL,180.0,maxf(100.0,host.size.x-96.0))
  else:
   var scene_row := HBoxContainer.new()
   scene_row.add_theme_constant_override("separation",24)
   body.add_child(scene_row)
   var scene := VBoxContainer.new()
   scene_row.add_child(scene)
   hero(scene,STAGE if current=="stage" else ARRIVAL,220.0,minf(620.0,maxf(280.0,(host.size.x-128.0)*0.48)))
   prose=VBoxContainer.new()
   prose.add_theme_constant_override("separation",8)
   prose.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   scene_row.add_child(prose)
 match current:
  "preparation":
   _copy(prose,"%d DAYS TO PREPARE" % maxi(0,int(booking.get("day",0))-int(state.get("tour_day",1))),20)
   _copy(prose,"%d finished originals available. Choose their order at soundcheck. Writing and rehearsal each use one real day." % int(state.get("songs",0)))
   _copy(prose,"A local lift is arranged. No vehicle is purchased. Travel is paid once after the show, up to £5; a hired drummer is separate.")
   _material_warning(prose,int(state.get("songs",0)))
   prose.add_child(host._button("WRITE AN ORIGINAL  ›","LiveWriteAction",host._practice.bind("create")))
   prose.add_child(host._button("REHEARSE THE SET  ›","LiveRehearseAction",host._practice.bind("tighten")))
  "travel":
   _copy(prose,"Your band has a local lift to %s. The ride is arranged; load in with the band." % str(booking.get("venue","the venue")))
   _copy(prose,"TRAVEL UP TO £%d  /  PAID AFTER THE SHOW" % mini(5,int(state.get("cash",0))),16)
   _copy(prose,"When you are ready, take the lift to the load-in door. There is no charge until the show is settled.")
  "arrival":
   _copy(prose,"The lift is here. The load-in door is open. %s is the room you have been preparing for." % str(booking.get("venue","This venue")))
   _copy(prose,"%d active players  •  TENSION %d / 100" % [_active_count(state),int(state.get("tension",0))])
   _copy(prose,"Take a moment, then carry the gear inside for soundcheck. No performance has been settled yet.")
  "soundcheck":
   _copy(prose,"Choose the originals and their order. The rotary and fader edit a free draft; SAVE SHOW PLAN commits it once.")
   _setlist(host,body,state)
   var shout: Button = C.button("THANK "+str(booking.get("venue","THE VENUE")).to_upper(),"flightcase","tab",true)
   shout.name = "ShowShoutoutAction"
   shout.set_pressed_no_signal(str(host.show_draft.get("shoutout","none"))=="thankvenue")
   shout.pressed.connect(func():host._show_edit("shoutout","none" if str(host.show_draft.get("shoutout","none"))=="thankvenue" else "thankvenue"))
   body.add_child(shout)
   _copy(prose,"Thanking the venue is optional. Decide how you want to address the room.")
   var incident: Dictionary = Backstage.incident(state)
   if not incident.is_empty():
    _copy(prose,"BACKSTAGE / "+str(incident.get("name","A bandmate")),20)
    for option in incident.get("options",[]):
     prose.add_child(host._button(str(option.get("label","Respond")),"LiveIncident_"+str(option.get("id","")),host._commit_live.bind("incident",str(option.get("id","")))))
  "stage":
   var plan: Dictionary = booking[Flow.FLOW_KEY].get("plan",{})
   _copy(prose,"The house lights fall. Your band is about to play %s. Stay here as long as you need." % str(booking.get("venue","this room")))
   _copy(prose,"AGREED APPROACH / "+str(plan.get("approach","tight")).to_upper())
   for index in range(plan.get("song_snapshots",[]).size()):
    _copy(prose,"%d. %s" % [index+1,str(plan["song_snapshots"][index].get("title",""))])
   _material_warning(prose,plan.get("song_ids",[]).size())
   _copy(prose,"TAKE THE STAGE opens the final confirmation. No timer starts the show for you.")
  "overdue":
   _copy(prose,"This booking was due on day %d. Resolve the missed date with its original consequences; there is no show payout." % int(booking.get("day",0)))
 if current!="overdue":
  prose.add_child(host._button("CANCEL THIS BOOKING","LiveCancelBookingAction",host._ask_live_confirmation.bind("cancel")))

static func _active_count(state: Dictionary) -> int:
 var count := 0
 for member in state.get("members",[]):
  if member is Dictionary and str(member.get("life_status","active"))=="active":count+=1
 return count

static func _material_warning(parent: Node, count: int) -> void:
 if count==0:
  var warning: Label = _copy(parent,"NO ORIGINALS SELECTED\nA set without your own material may bring a disappointing payout. Travel and any session drummer still cost money.")
  warning.name = "ShowNoOriginalsWarning"
  warning.add_theme_color_override("font_color",Color("943e31"))

static func _setlist(host, body: Node, state: Dictionary) -> void:
 var selected: Array = host.show_draft.get("song_ids",[])
 _copy(body,"THE SETLIST / %d OF 3" % selected.size(),20)
 var catalogue: Variant=state.get("song_catalogue",[])
 if not catalogue is Array:
  _copy(body,"The completed-song catalogue needs attention before choosing a set.")
  return
 var ordered: Array=[]
 for chosen in selected:
  for song in catalogue:
   if song is Dictionary and str(song.get("id",""))==str(chosen):
    ordered.append(song)
    break
 for song in catalogue:
  if song is Dictionary and not selected.has(str(song.get("id",""))):ordered.append(song)
 var available_heading := false
 for song in ordered:
  if not song is Dictionary:continue
  var id: String = str(song.get("id",""))
  if id.is_empty():continue
  var index: int = selected.find(id)
  if index<0 and not available_heading:
   _copy(body,"AVAILABLE ORIGINALS",20)
   available_heading=true
  _copy(body,(str(index+1)+". " if index>=0 else "")+str(song.get("title","UNTITLED")),16)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",6)
  body.add_child(row)
  var choice: Button = host._button("REMOVE" if index>=0 else "ADD TO SET","ShowSong_"+id.replace(":","_"),host._show_song_toggle.bind(id))
  choice.disabled = index<0 and selected.size()>=3
  row.add_child(choice)
  if index>=0:
   var song_audio=preload("res://experiments/playable_flightcase/song_audio.gd")
   song_audio.attach(body,song,func():return is_instance_valid(host) and host.is_visible_in_tree() and host.show_draft.get("song_ids",[]).has(id))
   var up: Button = host._button("UP","ShowUp_"+id.replace(":","_"),host._show_song_move.bind(id,-1))
   up.disabled=index==0
   row.add_child(up)
   var down: Button = host._button("DOWN","ShowDown_"+id.replace(":","_"),host._show_song_move.bind(id,1))
   down.disabled=index==selected.size()-1
   row.add_child(down)
 if state.get("song_catalogue",[]).is_empty():_copy(body,"There are no completed originals. An unfinished draft cannot be put in the set.")
 _material_warning(body,selected.size())

static func controls(host, parent: Node, _compact: bool) -> void:
 host._sync_show_draft()
 var housing:=PanelContainer.new();housing.add_theme_stylebox_override("panel",Poster.control_stock(Poster.INK,12))
 housing.name = "ShowPerformanceDesk"
 housing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 parent.add_child(housing)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 housing.add_child(column)
 var row := VBoxContainer.new()
 row.add_theme_constant_override("separation",8)
 column.add_child(row)
 for role in ["approach","intensity"]:
  var field := VBoxContainer.new()
  field.add_theme_constant_override("separation",0)
  row.add_child(field)
  var caption: Label = C.label("APPROACH" if role=="approach" else "INTENSITY",16)
  caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  field.add_child(caption)
  var control = Hardware.new()
  control.name = "ShowApproachControl" if role=="approach" else "ShowIntensityControl"
  var initial: float = float(APPROACHES.find(str(host.show_draft.get("approach","tight")))*50) if role=="approach" else float(host.show_draft.get("intensity",50))
  control.configure(role,initial)
  control.level_changed.connect(func(value: float):host._show_edit(role,APPROACHES[clampi(roundi(value/50.0),0,2)] if role=="approach" else roundi(value)))
  field.add_child(control)
  var reading: Label = C.label("",16)
  reading.name = "ShowApproachValue" if role=="approach" else "ShowIntensityValue"
  reading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  field.add_child(reading)
 var preview: Label = C.label("",16)
 preview.name = "ShowPolicyPreview"
 preview.custom_minimum_size.x = 290
 column.add_child(preview)
 refresh(host)

static func refresh(host) -> void:
 if not active(host):return
 var draft: Dictionary = host.show_draft
 var shout: Button=host.find_child("ShowShoutoutAction",true,false) as Button
 if shout!=null:shout.set_pressed_no_signal(str(draft.get("shoutout","none"))=="thankvenue")
 var approach: Label = host.find_child("ShowApproachValue",true,false) as Label
 var intensity: Label = host.find_child("ShowIntensityValue",true,false) as Label
 var preview: Label = host.find_child("ShowPolicyPreview",true,false) as Label
 var checked: Dictionary = Flow.check_plan(host.game.career,draft) if not draft.is_empty() else {"ok":false}
 if approach!=null:approach.text=str(draft.get("approach","tight")).to_upper()
 if intensity!=null:
  var level: int=int(draft.get("intensity",50))
  intensity.text="CONTROLLED" if level<35 else ("STEADY" if level<70 else "ALL-OUT")
 if preview!=null:
  if bool(checked.get("ok",false)):
   preview.text="Your show plan is ready to save. How it lands will be decided onstage."
   preview.tooltip_text=""
  else:preview.text=str(checked.get("message","Choose a valid show plan."))
 var commitment: Label=host.find_child("LiveCommitment",true,false) as Label
 var main: Button=host.find_child("LiveMainAction",true,false) as Button
 if main==null:main=host.find_child("JourneyMainAction",true,false) as Button
 if Flow.phase(host.game.career)=="soundcheck":
  if commitment!=null:commitment.text="%d ORIGINALS · £0 / 0 DAYS TO SAVE PLAN" % draft.get("song_ids",[]).size()
  if main!=null:main.disabled=bool(host.busy) or not bool(checked.get("ok",false))

static func dock(host, parent: Node, _compact: bool) -> void:
 var state: Dictionary=host.game.career
 if Booking.modern(state):
  BookingDesk.agreement_dock(host,parent,state)
  return
 var booking: Dictionary=Calendar.pending(state)
 var current: String=Flow.phase(state)
 var id: String=Flow.booking_id(booking)
 var commitment: Label=C.label("SHOW DAY %d · TRAVEL UP TO £%d AT SETTLEMENT" % [int(booking.get("day",0)),mini(5,int(state.get("cash",0)))],16)
 commitment.name="LiveCommitment"
 parent.add_child(commitment)
 var text: String=""
 var action: Callable
 match current:
  "preparation":text="PREPARE IN THE PRACTICE ROOM  ›";action=host._practice.bind("")
  "travel":text="TAKE THE LOCAL LIFT  ›";action=host._commit_live.bind("depart","",false,id,current)
  "arrival":text="GO TO SOUNDCHECK  ›";action=host._commit_live.bind("advance","",false,id,current)
  "soundcheck":text="SAVE TONIGHT'S SHOW PLAN  ›";action=host._commit_live.bind("soundcheck","",false,id,current)
  "stage":text="TAKE THE STAGE  ›";action=host._ask_live_confirmation.bind("perform")
  "overdue":text="RESOLVE MISSED SHOW  ›";action=host._commit_live.bind("expire","",false,id,current)
  _:text="REVIEW CANCELLATION";action=host._ask_live_confirmation.bind("cancel")
 var main: Button=host._button(text,"LiveMainAction",action,true)
 parent.add_child(main)
 refresh(host)

static func receipt(host, parent: Node, compact: bool, data: Dictionary) -> void:
 var body: VBoxContainer=host._paper(parent,compact)
 _copy(body,"THE SHOW IS IN THE BOOKS",16,true)
 _copy(body,str(data.get("venue","YOUR SHOW")),26)
 var scene: Container=VBoxContainer.new() if compact else HBoxContainer.new()
 scene.name="ShowReceiptScene"
 scene.mouse_filter=Control.MOUSE_FILTER_PASS
 scene.add_theme_constant_override("separation",12)
 body.add_child(scene)
 var art_width: float=maxf(100.0,host.size.x-96.0) if compact else maxf(200.0,minf(620.0,(host.size.x-120.0)*0.46))
 hero(scene,STAGE,150.0 if compact else 210.0,art_width)
 var words: VBoxContainer=host._box(8)
 words.name="ShowReceiptSummary"
 scene.add_child(words)
 var note: Label=Ink.new()
 note.name="CareerReceiptNote"
 note.text="Your show is saved."
 note.add_theme_color_override("font_color",Color("29241f"))
 if bool(host._fresh_receipt):note.visible_characters=0
 words.add_child(note)
 var cash_delta: int=int(data.get("cash_after",0))-int(data.get("cash_before",0))
 _copy(words,"GROSS FEE £%d · CASH %s£%d" % [int(data.get("settled_fee",0)),"+" if cash_delta>=0 else "-",absi(cash_delta)],16,true)
 DirectionCard.pills(words,data.get("effects"))
 var factors: Array=Direction.factors(data)
 if not factors.is_empty():
  _copy(words,"FROM YOUR SAVED SET",16,true)
  for factor in factors:
   var line: Label=_copy(words,str(factor["text"]))
   line.name="ShowFactor_"+str(factor["kind"])
 DirectionCard.goal(host,words,compact)
 var disclosure: Button=host._button("HIDE DETAILS" if bool(host.show_receipt_details_open) else "DETAILS  ›","ShowReceiptDetailsAction",host._toggle_show_details)
 body.add_child(disclosure)
 var details:=VBoxContainer.new()
 details.name="ShowReceiptDetails"
 details.mouse_filter=Control.MOUSE_FILTER_PASS
 details.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 details.add_theme_constant_override("separation",8)
 details.visible=bool(host.show_receipt_details_open)
 body.add_child(details)
 _copy(details,"DAY %d → %d  /  £%d → £%d" % [int(data.get("day_before",0)),int(data.get("day_after",0)),int(data.get("cash_before",0)),int(data.get("cash_after",0))])
 var expenses: Variant=data.get("expenses")
 if expenses is Dictionary:
  var cost_line: Label=_copy(details,"FEE £%d · TRAVEL £%d · SESSION £%d" % [int(data.get("settled_fee",0)),int(expenses.get("travel_paid",0)),int(expenses.get("session_paid",0))])
  if data.get("version")==2:cost_line.text="FEE £%d · TRANSPORT £%d · ROOM £%d · SESSION £%d" % [int(data.get("settled_fee",0)),int(expenses.get("travel_paid",0)),int(expenses.get("accommodation_paid",0)),int(expenses.get("session_paid",0))]
  cost_line.name="ShowReceiptExpenses"
 else:
  _copy(details,"GROSS FEE £%d · EARLIER COST DETAIL NOT RECORDED" % int(data.get("settled_fee",0)))
 var effects: Variant=data.get("effects")
 if effects is Dictionary:
  for field in ["fans","reputation","morale","tension","readiness"]:
   var change: Variant=effects.get(field)
   if change is Dictionary:
    var line: Label=_copy(details,"%s  %d → %d  (%+d)" % [str(field).to_upper(),int(change.get("before",0)),int(change.get("after",0)),int(change.get("delta",0))])
    line.name="ShowOutcomeDetail_"+str(field)
 var narrative: Label=Ink.new()
 narrative.name="ShowReceiptFullNarrative"
 narrative.text=str(data.get("message","The completed show is saved."))
 narrative.visible_characters=-1
 narrative.add_theme_color_override("font_color",Color("29241f"))
 details.add_child(narrative)
 _copy(details,"GROSS FEE £%d · %d ORIGINALS" % [int(data.get("settled_fee",0)),int(data.get("originals_played",0))])
 for index in range(data.get("plan",{}).get("song_snapshots",[]).size()):
  _copy(details,"%d. %s" % [index+1,str(data["plan"]["song_snapshots"][index].get("title",""))])
  preload("res://experiments/playable_flightcase/song_audio.gd").attach(details,data.plan.song_snapshots[index],func():return is_instance_valid(host) and host.is_visible_in_tree() and details.is_visible_in_tree())
 var response_index := 0
 for point in data.get("responses",[]):
  _copy(details,str(point.get("title","SAVED RESPONSE")),20)
  var row := HBoxContainer.new()
  row.name="ShowResponseRow_%d" % response_index
  row.add_theme_constant_override("separation",8)
  details.add_child(row)
  row.add_child(Kit.PassiveMeter.new("notepaper",int(point.get("meter_score",6))))
  var mood: Label=C.paper_label(str(point.get("mood","steady")).to_upper(),16)
  mood.name="ShowResponseMood_%d" % response_index
  mood.autowrap_mode=TextServer.AUTOWRAP_OFF
  mood.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
  mood.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  row.add_child(mood)
  _copy(details,str(point.get("text","")))
  response_index+=1
 _copy(details,"Saved modelled summary: three illustrative bands, no attendance or microphone measurement.",16,true)


static func journey_soundcheck(host, parent: Node, state: Dictionary) -> void:
 # Existing controls, completed-song ordering and optional original incident.
 # Only the owning journey controller commits the plan and checkpoints.
 # The existing setlist uses paper ink, so retain its matching paper surface.
 var compact: bool=host.size.x<840 or host.size.x<host.size.y
 var paper: VBoxContainer=host._paper(parent,compact)
 paper.name="JourneySoundcheckPaper"
 _setlist(host,paper,state)
 var shout: Button=C.button("THANK "+str(Calendar.pending(state).get("venue","THE VENUE")).to_upper(),"flightcase","tab",true)
 shout.name="ShowShoutoutAction"
 shout.set_pressed_no_signal(str(host.show_draft.get("shoutout","none"))=="thankvenue")
 shout.pressed.connect(func():host._show_edit("shoutout","none" if str(host.show_draft.get("shoutout","none"))=="thankvenue" else "thankvenue"))
 parent.add_child(shout)
 var incident: Dictionary=Backstage.incident(state)
 if not incident.is_empty():
  parent.add_child(C.label(str(incident.get("name","A bandmate"))+" · BEFORE THE SET",20))
  for option in incident.get("options",[]):
   var button: Button=host._button(str(option.get("label","Respond")),"JourneyIncident_"+str(option.get("id","")),host._commit_journey.bind("incident",host._journey_expected(),{"choice":str(option.get("id",""))},int(host._render_generation)))
   parent.add_child(button)
