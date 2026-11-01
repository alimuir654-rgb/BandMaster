extends RefCounted
## One new-booking journey over the original hometown models and real artwork.
## All callbacks edit host draft or invoke ONE explicit host transaction.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Flow = preload("res://experiments/playable_flightcase/show_flow.gd")
const Hardware = preload("res://experiments/playable_flightcase/show_hardware.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Promoter = preload("res://Scripts/promoter_meetings.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Backstage = preload("res://Scripts/gig_backstage_incident.gd")
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
   _copy(prose,"Thanking this actual venue takes a beat: quality -1, with +2 extra fans after a successful set of originals. It is optional.")
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
  var warning: Label = _copy(parent,"UNDERPREPARED / NO COMPLETED ORIGINALS\nThis new booking pays at most £5 gross with no originals selected. Travel and any session drummer are still charged.")
  warning.name = "ShowNoOriginalsWarning"
  warning.add_theme_color_override("font_color",Color("943e31"))

static func _setlist(host, body: Node, state: Dictionary) -> void:
 var selected: Array = host.show_draft.get("song_ids",[])
 _copy(body,"THE SETLIST / %d OF 3" % selected.size(),20)
 for song in state.get("song_catalogue",[]):
  if not song is Dictionary:continue
  var id: String = str(song.get("id",""))
  if id.is_empty():continue
  var index: int = selected.find(id)
  _copy(body,(str(index+1)+". " if index>=0 else "")+str(song.get("title","UNTITLED")),16)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",6)
  body.add_child(row)
  var choice: Button = host._button("REMOVE" if index>=0 else "ADD TO SET","ShowSong_"+id.replace(":","_"),host._show_song_toggle.bind(id))
  choice.disabled = index<0 and selected.size()>=3
  row.add_child(choice)
  if index>=0:
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
 var housing: PanelContainer = Kit.frame("flightcase","inset")
 housing.name = "ShowPerformanceDesk"
 housing.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 parent.add_child(housing)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",4)
 housing.add_child(column)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
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
   var projection: Dictionary=checked["projection"]
   var approach_rules: Dictionary=Gigs.APPROACHES.get(str(draft.get("approach","tight")),Gigs.APPROACHES["tight"])
   preview.text="QUALITY %+d · REACH %+d\nFATIGUE +%d · TENSION %+d" % [int(projection["quality_modifier"])+int(approach_rules["quality"]),int(projection["successful_extra_fans"])+int(approach_rules["fan_bonus"]),int(projection["extra_fatigue"]),int(projection["extra_tension"])+int(approach_rules["tension"])]
   preview.tooltip_text="Added plan modifiers. Fan reach needs a successful original set; fatigue applies to each active performer. Reliability is the deterministic margin to the original quality threshold, not a probability or audio reading."
  else:preview.text=str(checked.get("message","Choose a valid show plan."))
 var commitment: Label=host.find_child("LiveCommitment",true,false) as Label
 var main: Button=host.find_child("LiveMainAction",true,false) as Button
 if Flow.phase(host.game.career)=="soundcheck":
  if commitment!=null:commitment.text="%d ORIGINALS · £0 / 0 DAYS TO SAVE PLAN" % draft.get("song_ids",[]).size()
  if main!=null:main.disabled=bool(host.busy) or not bool(checked.get("ok",false))

static func dock(host, parent: Node, _compact: bool) -> void:
 var state: Dictionary=host.game.career
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
 _copy(body,"DAY %d → %d  /  £%d → £%d" % [int(data.get("day_before",0)),int(data.get("day_after",0)),int(data.get("cash_before",0)),int(data.get("cash_after",0))])
 var expenses: Variant=data.get("expenses")
 if expenses is Dictionary:
  var cost_line: Label=_copy(body,"FEE £%d · TRAVEL £%d · SESSION £%d" % [int(data.get("settled_fee",0)),int(expenses.get("travel_paid",0)),int(expenses.get("session_paid",0))])
  cost_line.name="ShowReceiptExpenses"
 else:
  _copy(body,"GROSS FEE £%d · EARLIER COST DETAIL NOT RECORDED" % int(data.get("settled_fee",0)))
 var effects: Variant=data.get("effects")
 if effects is Dictionary:
  for field in ["fans","reputation","morale","tension","readiness"]:
   var change: Variant=effects.get(field)
   if change is Dictionary:
    var line: Label=_copy(body,"%s  %d → %d  (%+d)" % [str(field).to_upper(),int(change.get("before",0)),int(change.get("after",0)),int(change.get("delta",0))])
    line.name="ShowOutcome_"+str(field)
 hero(body,STAGE,150.0 if compact else 210.0,maxf(100.0,host.size.x-96.0))
 var note: Label=Ink.new()
 note.name="CareerReceiptNote"
 note.text=str(data.get("message","The completed show is saved."))
 note.add_theme_color_override("font_color",Color("29241f"))
 body.add_child(note)
 if bool(host._fresh_receipt):note.visible_characters=0
 _copy(body,"GROSS FEE £%d · %d ORIGINALS" % [int(data.get("settled_fee",0)),int(data.get("originals_played",0))])
 for index in range(data.get("plan",{}).get("song_snapshots",[]).size()):
  _copy(body,"%d. %s" % [index+1,str(data["plan"]["song_snapshots"][index].get("title",""))])
 for point in data.get("responses",[]):
  _copy(body,str(point.get("title","SAVED RESPONSE")),20)
  var row := HBoxContainer.new()
  row.add_theme_constant_override("separation",8)
  body.add_child(row)
  row.add_child(Kit.PassiveMeter.new("notepaper",int(point.get("meter_score",6))))
  row.add_child(C.paper_label(str(point.get("mood","steady")).to_upper(),16))
  _copy(body,str(point.get("text","")))
 _copy(body,"Saved modelled summary: three illustrative bands, no attendance or microphone measurement.",16,true)
