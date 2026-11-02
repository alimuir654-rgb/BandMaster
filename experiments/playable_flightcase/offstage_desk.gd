extends RefCounted
## Native offstage presentation only. Queries never resolve or save an action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Rules = preload("res://experiments/playable_flightcase/offstage_rules.gd")
const Live = preload("res://experiments/playable_flightcase/live_bridge.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Gigs = preload("res://Scripts/uk_gig_circuit.gd")
const Social = preload("res://Scripts/band_social.gd")
const Opportunities = preload("res://Scripts/career_opportunities.gd")

static func focus_name(_host) -> String:
 return "OffstageMainAction"

static func _copy(host, parent: Node, text: String, node_name: String = "", points: int = 16, muted: bool = false) -> Label:
 var label: Label = host._copy(parent,text,points,muted)
 if not node_name.is_empty():label.name=node_name
 return label

static func _mode(host, pending: Array) -> String:
 return "invite" if str(host.offstage_mode)=="invite" and not pending.is_empty() else "outing"

static func _activity(host, state: Dictionary) -> Dictionary:
 var choices: Array = Rules.activities(state)
 for raw in choices:
  if str(raw.get("id",""))==str(host.offstage_activity):return raw
 return choices[0] if not choices.is_empty() else {}

static func _response(host, state: Dictionary, invitation: Dictionary) -> Dictionary:
 var options: Array = Rules.response_options(state,str(invitation.get("id","")))
 for raw in options:
  if str(raw.get("id",""))==str(host.offstage_choice) and str(raw.get("id",""))!="decline":return raw
 for raw in options:
  if str(raw.get("id",""))!="decline":return raw
 return {}

static func _choice(parent: Node, text: String, node_name: String, callback: Callable, busy: bool) -> Button:
 var button: Button = C.button(text,"flightcase","tab",true)
 button.name=node_name
 button.disabled=busy
 button.pressed.connect(callback)
 parent.add_child(button)
 return button

static func render(host, parent: Node, compact: bool) -> void:
 var state: Dictionary = host.game.career
 var pending: Array = Rules.pending(state)
 var mode: String = _mode(host,pending)
 var body: VBoxContainer = host._paper(parent,compact)
 _copy(host,body,"LIFE OFFSTAGE","OffstageHeading",26)
 _copy(host,body,"Time together, local music and the people you meet along the way.","OffstageIntroduction")
 if not str(host.notice).is_empty():_copy(host,body,str(host.notice),"OffstageNotice")
 if not pending.is_empty():
  var navigation: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
  navigation.add_theme_constant_override("separation",8)
  body.add_child(navigation)
  var plan: Button = _choice(navigation,"PLAN AN OUTING","OffstagePlanAction",host._offstage_show.bind("outing"),bool(host.busy))
  plan.set_pressed_no_signal(mode=="outing")
  var saved: Button = _choice(navigation,"SAVED INVITATION","OffstageSavedInviteAction",host._offstage_show.bind("invite"),bool(host.busy))
  saved.set_pressed_no_signal(mode=="invite")
 if mode=="invite":
  _invitation(host,body,state,pending[0])
 else:
  _outing(host,body,state)
 _contacts(host,parent,compact,state)
 refresh_plans(host)

static func _outing(host, body: Node, state: Dictionary) -> void:
 _copy(host,body,"CHOOSE YOUR EVENING","OffstageActivityHeading",20)
 for row in Rules.activities(state):
  var id: String = str(row.get("id",""))
  _choice(body,"%s  •  £%d" % [str(row.get("title","OUTING")),int(row.get("cost",0))],"OffstageOption_"+id,host._select_offstage_activity.bind(id),bool(host.busy))
 _copy(host,body,"","OffstageActivityDescription")
 _copy(host,body,"","OffstageActivityEffects")
 _copy(host,body,"","OffstageEligibility")
 _copy(host,body,"Each outing takes one day and charges only for active bandmates. Selecting a plan is free; the bottom action commits and saves it.","OffstageOutingNote",16,true)
 _copy(host,body,"Getting to know the local music scene can lead to introductions as the band's story develops.","OffstageMilestoneNote",16,true)

static func _invitation(host, body: Node, state: Dictionary, invitation: Dictionary) -> void:
 var id: String = str(invitation.get("id",""))
 _copy(host,body,str(invitation.get("title","SAVED INVITATION")),"OffstageInviteTitle",22)
 _copy(host,body,str(invitation.get("role","Business contact"))+"  •  MET ON DAY %d" % int(invitation.get("source_day",1)),"OffstageInviteRole",16,true)
 _copy(host,body,str(invitation.get("description","")),"OffstageInviteDescription")
 if id==Rules.PROMOTER:
  var venue: Dictionary = Gigs.get_venue("local")
  _copy(host,body,"STANDARD OFFER  /  %s, day %d. £0 now; up to £%d travel at the show. The venue's base fee is £%d; the final fee follows the actual set and promoter terms." % [str(venue.get("venue","The Lantern Room")),int(state.get("tour_day",1))+Calendar.LEAD_DAYS,int(venue.get("travel",0)),int(venue.get("fee",0))],"OffstageInviteTerms")
 for row in Rules.response_options(state,id):
  var choice: String = str(row.get("id",""))
  if choice=="decline":continue
  _choice(body,str(row.get("label","CHOOSE RESPONSE")),"OffstageResponse_"+choice,host._select_offstage_response.bind(choice),bool(host.busy))
 _copy(host,body,"","OffstageResponseDescription")
 _copy(host,body,"","OffstageEligibility")
 for row in Rules.response_options(state,id):
  if str(row.get("id",""))!="decline":continue
  var decline: Button = C.button("DECLINE THE INTRODUCTION","flightcase","tab")
  decline.name="OffstageDeclineAction"
  decline.disabled=bool(host.busy) or not bool(row.get("enabled",false))
  decline.pressed.connect(_decline_current.bind(host))
  body.add_child(decline)
  _copy(host,body,str(row.get("description","")),"OffstageDeclineNote",16,true)

static func _contacts(host, parent: Node, compact: bool, state: Dictionary) -> void:
 var body: VBoxContainer = host._paper(parent,compact)
 _copy(host,body,"YOUR SAVED CONTACTS","OffstageContactsHeading",20)
 var list := VBoxContainer.new()
 list.name="OffstageContacts"
 list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 list.add_theme_constant_override("separation",16)
 body.add_child(list)
 var contacts: Dictionary = Rules.view(state).get("contacts",{})
 if contacts.is_empty():
  _copy(host,list,"No business contacts recorded yet. A successful outing can introduce people without changing your musician lineup.","OffstageEmptyContacts")
 for key in contacts.keys():
  if not contacts[key] is Dictionary:continue
  var contact: Dictionary = contacts[key]
  var entry := VBoxContainer.new()
  entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  entry.add_theme_constant_override("separation",4)
  list.add_child(entry)
  _copy(host,entry,str(contact.get("role","Business contact")).to_upper(),"",18)
  var activity: String = str(contact.get("source_action",""))
  var source: String = str(Social.ACTIVITIES.get(activity,{}).get("label","an earlier outing"))
  _copy(host,entry,"MET ON DAY %d  /  %s" % [int(contact.get("met_day",contact.get("source_day",1))),source],"",16,true)
  _copy(host,entry,str(contact.get("description","")))
 _copy(host,body,"Keep track of the people you meet. These introductions do not change your musician lineup.","OffstageContactsNote",16,true)

static func dock(host, parent: Node, _compact: bool) -> void:
 var commitment: Label = C.label("",16)
 commitment.name="OffstageCommitment"
 parent.add_child(commitment)
 var main: Button = C.button("CONFIRM OUTING","flightcase","action")
 main.name="OffstageMainAction"
 # Read the current free plan at the actual click, not a stale bound choice.
 main.pressed.connect(_commit_selected.bind(host))
 parent.add_child(main)
 refresh_plans(host)

static func refresh_plans(host) -> void:
 var state: Dictionary = host.game.career
 var pending: Array = Rules.pending(state)
 var mode: String = _mode(host,pending)
 var selected: Dictionary = _response(host,state,pending[0]) if mode=="invite" else _activity(host,state)
 if mode=="outing":
  for row in Rules.activities(state):
   var option: Button = host.find_child("OffstageOption_"+str(row.get("id","")),true,false) as Button
   if option!=null:
    option.set_pressed_no_signal(str(row.get("id",""))==str(selected.get("id","")))
    option.disabled=bool(host.busy)
  var description: Label = host.find_child("OffstageActivityDescription",true,false) as Label
  if description!=null:description.text="%s  /  %d ACTIVE BANDMATES\n%s" % [str(selected.get("title","OUTING")),int(selected.get("active",0)),str(Social.ACTIVITIES.get(str(selected.get("id","")),{}).get("text",""))]
  var effects: Label = host.find_child("OffstageActivityEffects",true,false) as Label
  if effects!=null:
   effects.text=""
   effects.visible=false
 else:
  for row in Rules.response_options(state,str(pending[0].get("id",""))):
   var option: Button = host.find_child("OffstageResponse_"+str(row.get("id","")),true,false) as Button
   if option!=null:
    option.set_pressed_no_signal(str(row.get("id",""))==str(selected.get("id","")))
    option.disabled=bool(host.busy)
  var description: Label = host.find_child("OffstageResponseDescription",true,false) as Label
  if description!=null:
   description.text=str(selected.get("description",""))
   if str(pending[0].get("id",""))==Rules.SCOUT:
    for rule in Opportunities.get_event("first_feature").get("choices",[]):
     if str(rule.get("id",""))==str(selected.get("id","")):description.text=str(rule.get("text",""))
 var eligibility: Label = host.find_child("OffstageEligibility",true,false) as Label
 if eligibility!=null:
  eligibility.text=str(selected.get("reason","")) if not bool(selected.get("enabled",false)) else ("Ready to accept the selected response." if mode=="invite" else "Ready to save this outing.")
 var commitment: Label = host.find_child("OffstageCommitment",true,false) as Label
 var main: Button = host.find_child("OffstageMainAction",true,false) as Button
 if commitment==null or main==null:return
 if Live.show_day(state):
  commitment.text="TONIGHT'S SHOW COMES FIRST"
  main.text="GO TO TONIGHT'S SHOW  ›"
  main.disabled=bool(host.busy)
  return
 var cost: int = int(selected.get("cost",0))
 var days: int = int(selected.get("days",0))
 var cash: int = int(state.get("cash",0))
 commitment.text="£%d  •  %d DAY%s  •  £%d AFTER" % [cost,days,"" if days==1 else "S",cash-cost] if cash>=cost else "£%d AVAILABLE  •  NEED £%d MORE" % [cash,cost-cash]
 main.text="ACCEPT SELECTED RESPONSE  ›" if mode=="invite" else "CONFIRM OUTING  ›"
 main.disabled=bool(host.busy) or not bool(selected.get("enabled",false))

static func _commit_selected(host) -> void:
 if bool(host.busy):return
 var state: Dictionary = host.game.career
 if Live.show_day(state):
  host._navigate("gigs")
  return
 var pending: Array = Rules.pending(state)
 if _mode(host,pending)=="invite":
  var invitation: Dictionary = pending[0]
  var selected: Dictionary = _response(host,state,invitation)
  host._commit_offstage("respond",str(invitation.get("id","")),str(selected.get("id","")))
 else:
  var selected: Dictionary = _activity(host,state)
  host._commit_offstage("outing",str(selected.get("id","")),"")

static func _decline_current(host) -> void:
 if bool(host.busy):return
 var pending: Array = Rules.pending(host.game.career)
 if not pending.is_empty():host._commit_offstage("respond",str(pending[0].get("id","")),"decline")
