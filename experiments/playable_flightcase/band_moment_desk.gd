extends RefCounted
## Player-paced local reading; only explicit final choices own a transaction.
const Rules = preload("res://experiments/playable_flightcase/band_moment_rules.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const Card = preload("res://experiments/playable_flightcase/direction_card.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const Direction = preload("res://experiments/playable_flightcase/career_direction.gd")
const Finance = preload("res://experiments/playable_flightcase/finance_policy.gd")
const Radio = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const PHASES := ["intro","first_quote","second_quote","choices"]

static func _copy(host, parent: Node, text: String, name: String, points: int=16, muted: bool=false) -> Label:
 var label: Label=host._copy(parent,text,points,muted)
 if not name.is_empty():label.name=name
 return label

static func _note(parent: Node, text: String, name: String, interactive: bool=false, fresh: bool=false) -> Label:
 var note: Label=Ink.new()
 note.name=name
 note.text=text
 note.add_theme_color_override("font_color",Color("29241f"))
 if not interactive:
  note.mouse_filter=Control.MOUSE_FILTER_IGNORE
  note.focus_mode=Control.FOCUS_NONE
 if fresh:note.visible_characters=0
 parent.add_child(note)
 return note

static func _cookie(host) -> Dictionary:
 return {"generation":int(host._render_generation),"epoch":int(host.band_moment_epoch),"phase":str(host.band_moment_phase),"owner":host.get_instance_id()}

static func _button(host, parent: Node, text: String, name: String, verb: String, choice: String="", primary: bool=false, enabled: bool=true) -> Button:
 var button: Button=host._button(text,name,act.bind(host,verb,choice,_cookie(host)),primary)
 button.disabled=bool(host.busy) or not enabled
 parent.add_child(button)
 return button

static func entries(host, parent: Node) -> void:
 var current: Dictionary=Rules.current(host.game.career)
 if bool(current["available"]):
  var action: Button=host._button("A REHEARSAL CONVERSATION","BandMomentOpenAction",open.bind(host,false,int(host._render_generation)))
  parent.add_child(action)
 elif not bool(current["ok"]):_copy(host,parent,str(current["message"]),"BandMomentAvailability")
 var saved: Dictionary=Rules.latest(host.game.career)
 if not (saved.get("moment",{}) as Dictionary).is_empty():parent.add_child(host._button("LAST REHEARSAL CONVERSATION","BandMomentSavedAction",open.bind(host,true,int(host._render_generation))))

static func _priority(host) -> bool:
 if Finance.is_over(host.game.career):
  host._navigate("finance")
  return false
 if Radio.locked(host.game.career):
  host._navigate("recording")
  return false
 var booking: Dictionary=Direction.booking_guard(host.game.career)
 if not bool(booking["ok"]):
  host.notice=str(booking["message"])
  host._render()
  return false
 if bool(booking["due"]):
  host._navigate("gigs")
  return false
 return true

static func open(host, replay: bool, generation: int) -> void:
 if not is_instance_valid(host) or not host.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy) or is_instance_valid(host._live_dialog) or host.game==null or host.opening_owner==null:return
 if str(host.page)!="band" or bool(host.receipt_open) or int(host._render_generation)!=generation or not _priority(host):return
 var data: Dictionary=Rules.latest(host.game.career) if replay else Rules.current(host.game.career)
 if not replay and (not bool(data["ok"]) or not bool(data["available"])):
  host.notice=str(data["message"])
  host._render()
  return
 if replay and (data.get("moment",{}) as Dictionary).is_empty():return
 host.band_moment_context={"owner":host.get_instance_id(),"expected":host.game.career.duplicate(true),"data":data.duplicate(true),"replay":replay,"reveal":not replay,"details":false}
 host.band_moment_epoch+=1
 host.band_moment_phase="saved" if replay else "intro"
 host.page="band_moment"
 host.notice=""
 host._pending_focus="BandMomentBackAction" if replay else "BandMomentNote"
 _reset_scroll(host)
 host._render()

static func _reset_scroll(host) -> void:
 host._scroll_position=0
 if is_instance_valid(host._scroll):host._scroll.scroll_vertical=0

static func _people(host, parent: Node, people: Array, compact: bool, portrait_bound: float=0.0) -> void:
 var row:=HBoxContainer.new()
 row.name="BandMomentPeople"
 row.add_theme_constant_override("separation",12)
 row.alignment=BoxContainer.ALIGNMENT_CENTER
 parent.add_child(row)
 for index in range(people.size()):
  var person: Dictionary=people[index]
  var position: String="first" if index==0 else "second"
  var box: VBoxContainer=host._box(4)
  box.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  row.add_child(box)
  var source: Dictionary=Cast.by_id(str(person.get("candidate_id","")))
  var path: String=str(source.get("portrait_preview",""))
  if not path.is_empty() and ResourceLoader.exists(path):
   var texture: Texture2D=load(path) as Texture2D
   var photo:=TextureRect.new()
   photo.name="BandMomentPortrait_"+position
   photo.texture=texture
   photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
   photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   var bound: float=portrait_bound if portrait_bound>0.0 else (120.0 if compact else 160.0)
   photo.custom_minimum_size=Vector2(minf(bound,texture.get_width()),minf(bound,texture.get_height()))
   photo.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
   photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
   photo.focus_mode=Control.FOCUS_NONE
   photo.set_meta("source",path)
   photo.set_meta("candidate_id",str(person.get("candidate_id","")))
   photo.set_meta("source_size",texture.get_size())
   box.add_child(photo)
  var name: Label=_copy(host,box,str(person.get("name","Musician")),"BandMomentName_"+position)
  name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  name.custom_minimum_size.x=portrait_bound if portrait_bound>0.0 else (120.0 if compact else 160.0)

static func render(host, parent: Node, compact: bool) -> void:
 var context: Dictionary=host.band_moment_context
 if bool(context.get("replay",false)):
  _saved(host,parent,compact,context.get("data",{}),false)
  return
 var data: Dictionary=context.get("data",{})
 var body: VBoxContainer=host._paper(parent,compact)
 if not bool(data.get("ok",false)) or not bool(data.get("available",false)):
  _copy(host,body,"Open the current rehearsal conversation from your band page.","BandMomentUnavailable")
  return
 var incident: Dictionary=data["case"]
 if str(host.band_moment_phase)=="choices":
  _decision(host,body,data,compact)
  return
 _copy(host,body,str(incident["title"]),"BandMomentHeading",22)
 _people(host,body,data["participants"],compact)
 var phase: String=str(host.band_moment_phase)
 _copy(host,body,{"intro":"BEFORE THE NEXT REHEARSAL","first_quote":"FIRST VOICE","second_quote":"SECOND VOICE","choices":"YOUR DECISION"}.get(phase,"YOUR DECISION"),"BandMomentPhase",16,true)
 var speaker: String=str(incident["first"]) if phase=="first_quote" else (str(incident["second"]) if phase=="second_quote" else "IN THE REHEARSAL ROOM")
 _copy(host,body,speaker,"BandMomentSpeaker")
 var text: String=str(incident["intro"])
 if phase=="first_quote":text=str(incident["first_line"])
 elif phase=="second_quote":text=str(incident["second_line"])
 elif phase=="choices":text="Both voices have been heard. How will the band handle its next rehearsal?"
 var fresh: bool=bool(context.get("reveal",false))
 var note: Label=_note(body,text,"BandMomentNote",true,fresh)
 context["reveal"]=false
 if fresh:note.call_deferred("begin",bool(host.reduced_motion))
 if not str(host.notice).is_empty():_copy(host,body,str(host.notice),"BandMomentNotice")

static func _decision(host, body: VBoxContainer, data: Dictionary, compact: bool) -> void:
 var incident: Dictionary=data["case"]
 var context: Dictionary=host.band_moment_context
 context["reveal"]=false
 body.add_theme_constant_override("separation",4)
 _copy(host,body,"YOUR DECISION","BandMomentDecisionHeading",16,true)
 var layout: Container=VBoxContainer.new() if compact else HBoxContainer.new()
 layout.add_theme_constant_override("separation",6 if compact else 20)
 body.add_child(layout)
 var portraits: VBoxContainer=host._box(0)
 portraits.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 layout.add_child(portraits)
 _people(host,portraits,data["participants"],compact,80.0)
 var options: VBoxContainer=host._box(4)
 layout.add_child(options)
 for choice in ["listen","keep"]:
  var option: Dictionary={}
  for raw in incident["choices"]:
   if raw["id"]==choice:option=raw
  _copy(host,options,str(option.get("label","")),"BandMomentChoiceLabel_"+choice)
  _copy(host,options,"Make room for both musicians to explain their ideas." if choice=="listen" else "Keep the rehearsal on its current schedule.","BandMomentChoiceIntent_"+choice,16,true)
  var preview: Dictionary=Rules.preview(host.game.career,str(incident["id"]),choice,str(data["fingerprint"]))
  if not bool(preview["ok"]):_copy(host,options,str(preview["message"]),"BandMomentEligibility_"+choice)
 if not str(host.notice).is_empty():_copy(host,body,str(host.notice),"BandMomentNotice")
 var details: VBoxContainer=host._box(8)
 details.name="BandMomentDecisionDetailsBody"
 details.visible=bool(context.get("decision_details",false))
 var disclosure: Button=host._button("HIDE DETAILS" if details.visible else "DETAILS  ›","BandMomentDecisionDetailsAction",_decision_details.bind(host,details))
 body.add_child(disclosure)
 body.add_child(details)
 _copy(host,details,str(incident["title"]),"BandMomentHeading",22)
 _copy(host,details,"YOUR DECISION","BandMomentPhase",16,true)
 _copy(host,details,"IN THE REHEARSAL ROOM","BandMomentSpeaker")
 _note(details,"Both voices have been heard. How will the band handle its next rehearsal?","BandMomentNote")
 for position in ["first","second"]:_copy(host,details,str(incident[position])+": “"+str(incident[position+"_line"])+"”","BandMomentDecisionQuote_"+position,16,true)
 for option in incident["choices"]:_copy(host,details,"Make room for both musicians to explain their ideas." if option["id"]=="listen" else "Keep the rehearsal on its current schedule.","BandMomentChoiceText_"+str(option["id"]),16,true)

static func _decision_details(host, body: Control) -> void:
 if not is_instance_valid(host) or not is_instance_valid(body) or not body.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy) or is_instance_valid(host._live_dialog):return
 if str(host.page)!="band_moment" or bool(host.receipt_open) or str(host.band_moment_phase)!="choices" or bool(host.band_moment_context.get("replay",false)):return
 body.visible=not body.visible
 host.band_moment_context["decision_details"]=body.visible
 var button: Button=body.get_parent().get_node_or_null("BandMomentDecisionDetailsAction") as Button
 if button!=null:button.text="HIDE DETAILS" if body.visible else "DETAILS  ›"

static func _pills(host, parent: Node, saved: Dictionary, prefix: String, show_default: bool=true) -> void:
 var row:=HFlowContainer.new()
 row.name=prefix+"Pills"
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 row.add_theme_constant_override("h_separation",6)
 row.add_theme_constant_override("v_separation",6)
 parent.add_child(row)
 for field in ["trust","morale","tension","readiness"]:
  var before: int=int(saved["trust_before"]) if field=="trust" else int(saved["global_before"][field])
  var after: int=int(saved["trust_after"]) if field=="trust" else int(saved["global_after"][field])
  var delta: int=after-before
  var label: Label=Card._pill(row,"%s %+d" % [field.to_upper(),delta],prefix+"_"+field,signi(delta)*(-1 if field=="tension" else 1))
  label.set_meta("before",before)
  label.set_meta("after",after)
  label.set_meta("delta",delta)
 if show_default and not bool(saved["trust_recorded_before"]):_copy(host,parent,"Trust starts from the original model default; no earlier relationship measurement was saved.",prefix+"TrustDefault",16,true)

static func dock(host, parent: Node) -> void:
 var context: Dictionary=host.band_moment_context
 if bool(context.get("replay",false)):
  _button(host,parent,"BACK TO YOUR BAND","BandMomentBackAction","back")
  return
 var terms: Label=C.label("1 DAY AT YOUR DECISION  •  NO DIRECT CASH COST",16)
 terms.name="BandMomentCommitment"
 terms.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(terms)
 if str(host.band_moment_phase)=="choices":
  var data: Dictionary=context.get("data",{})
  var incident: Dictionary=data.get("case",{})
  for choice in ["listen","keep"]:
   var preview: Dictionary=Rules.preview(host.game.career,str(incident.get("id","")),choice,str(data.get("fingerprint","")))
   _button(host,parent,"LET BOTH BE HEARD" if choice=="listen" else "KEEP ARRANGEMENT","BandMomentChoice_"+choice,"choose",choice,true,bool(preview["ok"]))
 else:_button(host,parent,"CONTINUE","BandMomentContinueAction","next","",true)
 _button(host,parent,"BACK WITHOUT A DECISION","BandMomentBackAction","back")

static func act(host, verb: String, choice: String, cookie: Dictionary) -> void:
 if not is_instance_valid(host) or not host.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy) or is_instance_valid(host._live_dialog):return
 if str(host.page)!="band_moment" or bool(host.receipt_open) or host.game==null or host.opening_owner==null:return
 if cookie["owner"]!=host.get_instance_id() or int(cookie["generation"])!=int(host._render_generation) or int(cookie["epoch"])!=int(host.band_moment_epoch) or str(cookie["phase"])!=str(host.band_moment_phase):return
 var context: Dictionary=host.band_moment_context
 if context.get("owner")!=host.get_instance_id():return
 if verb=="back":
  host.band_moment_epoch+=1
  host._navigate("band")
  return
 if bool(context.get("replay",false)) or not _priority(host):return
 if host.game.career!=context.get("expected"):
  host.notice="The band changed. Go back and open the current conversation again."
  host._render()
  return
 var live: Dictionary=Rules.current(host.game.career)
 var expected: Dictionary=context["data"]
 if not bool(live["available"]) or live["fingerprint"]!=expected["fingerprint"]:
  host.notice="This conversation changed. Open the current case again."
  host._render()
  return
 var note: Label=host.find_child("BandMomentNote",true,false) as Label
 if note!=null and bool(note.call("is_revealing")):
  note.call("finish_now")
  return
 if verb=="next":
  var index: int=PHASES.find(str(host.band_moment_phase))
  if index<0 or index>=PHASES.size()-1:return
  host.band_moment_phase=PHASES[index+1]
  host.band_moment_epoch+=1
  context["reveal"]=true
  host._pending_focus="BandMomentChoice_listen" if str(host.band_moment_phase)=="choices" else "BandMomentNote"
  _reset_scroll(host)
  host._render()
  return
 if verb!="choose" or str(host.band_moment_phase)!="choices":return
 host.busy=true
 var before: Dictionary=host.game.career.duplicate(true)
 var result: Dictionary=Rules.resolve(before,str(live["case"]["id"]),choice,str(live["fingerprint"]))
 if not bool(result["ok"]):
  host.busy=false
  host.notice=str(result["message"])
  host._render()
  return
 host.game.career=result["state"]
 if not bool(host.opening_owner.save_draft()):
  host.game.career=before
  host.busy=false
  host.notice="The decision could not be saved. Your previous band state is retained; you can retry."
  host._render()
  return
 host.band_moment_epoch+=1
 host.notice=""
 host._band_moment_present(result,before)

static func _saved(host, parent: Node, compact: bool, data: Dictionary, fresh: bool) -> void:
 var body: VBoxContainer=host._paper(parent,compact)
 if not bool(data.get("ok",false)):
  _copy(host,body,str(data.get("message","This saved conversation needs validation.")),"BandMomentSavedHeld")
  return
 var moment: Dictionary=data.get("moment",{})
 var saved: Dictionary=data.get("receipt",{})
 _copy(host,body,str(moment.get("title","SAVED REHEARSAL CONVERSATION")),"BandMomentResultHeading",22)
 var people: Array=saved.get("participants",[])
 if people.is_empty():
  for name in moment.get("pair_names",[]):people.append({"name":str(name),"candidate_id":""})
 _people(host,body,people,compact)
 _note(body,str(saved.get("message",moment.get("text","No narrative was saved."))),"CareerReceiptNote" if fresh else "BandMomentResultNote",fresh,fresh and bool(host._fresh_receipt))
 if not saved.is_empty():_pills(host,body,saved,"BandMomentResult")
 else:
  _copy(host,body,"Only the original saved conversation facts are available; global and member changes were not recorded.","BandMomentLegacyFacts",16,true)
  if moment.has("trust_before") and moment.has("trust_after"):_copy(host,body,"SAVED TRUST INPUT  %d → %d" % [int(moment["trust_before"]),int(moment["trust_after"])],"BandMomentLegacyTrust")
 var details: VBoxContainer=host._box(8)
 details.name="BandMomentDetailsBody"
 details.visible=bool(host.band_moment_context.get("details",false))
 var button: Button=host._button("HIDE DETAILS" if details.visible else "DETAILS  ›","BandMomentDetailsAction",_details.bind(host,details))
 body.add_child(button)
 body.add_child(details)
 if not saved.is_empty():_copy(host,details,"DAY %d → %d\n£%d → £%d" % [int(saved["day_before"]),int(saved["day_after"]),int(saved["cash_before"]),int(saved["cash_after"])],"BandMomentReceiptFacts")
 elif moment.has("day"):_copy(host,details,"SAVED DAY %d" % int(moment["day"]),"BandMomentReceiptFacts")
 for side in ["first","second"]:_note(details,str(moment.get(side+"_line","No quote was saved.")),"BandMomentSavedQuote_"+side)
 _copy(host,details,str(moment.get("decision_label","Decision wording was not saved.")),"BandMomentSavedDecision")
 for person in saved.get("participants",[]):
  _copy(host,details,str(person["name"]),"BandMomentSavedMember_"+str(person["index"]))
  for field in Rules.MEMBER_VALUES:
   var before: int=int(person["before"][field])
   var after: int=int(person["after"][field])
   _copy(host,details,"%s %d → %d (%+d)%s" % [field.to_upper(),before,after,after-before," · ORIGINAL DEFAULT" if not bool(person["recorded_before"][field]) else ""],"BandMomentMember_"+str(person["index"])+"_"+field)

static func _details(host, body: Control) -> void:
 if not is_instance_valid(host) or not is_instance_valid(body) or not body.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy):return
 if not (str(host.page)=="band_moment" or (bool(host.receipt_open) and str(host.receipt.get("kind",""))=="band_moment")):return
 body.visible=not body.visible
 host.band_moment_context["details"]=body.visible
 var button: Button=body.get_parent().get_node_or_null("BandMomentDetailsAction") as Button
 if button!=null:button.text="HIDE DETAILS" if body.visible else "DETAILS  ›"

static func receipt(host, parent: Node, compact: bool) -> void:
 _saved(host,parent,compact,Rules.receipt(host.receipt.get("moment",{})),true)
