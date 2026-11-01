extends RefCounted
## Radio-specific owner of explicit checkpoint/save callbacks. Shell is passive.
const Flow = preload("res://experiments/playable_flightcase/radio_visit_rules.gd")
const Promotion = preload("res://experiments/playable_flightcase/promotion_rules.gd")
const Recording = preload("res://experiments/playable_flightcase/recording_rules.gd")
const Scene = preload("res://experiments/playable_flightcase/activity_scene.gd")
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const ART = preload("res://experiments/playable_flightcase/art/radio_student_studio_v3.png")
const ART_PATH := "res://experiments/playable_flightcase/art/radio_student_studio_v3.png"
const ART_SHA := "f860a57c7fc7d3ba17a693fbabb844303b20b69443a6666e29d41889bbf28bda"

static func _cookie(host) -> Dictionary:
 var visit: Dictionary=Flow.active(host.game.career)
 var revision: int=int(visit.get("revision",-1)) if Flow._whole(visit.get("revision",-1)) else -1
 return {"generation":int(host._render_generation),"id":str(visit.get("id","")),"phase":str(visit.get("phase","none")),"revision":revision,"selection":host.promotion_selection.duplicate(true)}

static func _button(host, parent: Node, text: String, name: String, verb: String, arg: String="", primary: bool=false, enabled: bool=true) -> Button:
 var button: Button=host._button(text,name,perform.bind(host,verb,arg,_cookie(host)),primary)
 button.disabled=bool(host.busy) or not enabled
 parent.add_child(button)
 return button

static func _selected(host) -> Dictionary:
 var selected: Dictionary=host.promotion_selection
 return Promotion.selection(host.game.career,str(selected.get("id","")),str(selected.get("fingerprint","")),int(selected.get("index",-1)))

static func _begin_eligibility(host) -> Dictionary:
 var selected: Dictionary=host.promotion_selection
 return Flow.begin(host.game.career,str(selected.get("id","")),str(selected.get("fingerprint","")),int(selected.get("index",-1)))

static func _note(parent: Node, text: String, name: String) -> Label:
 var note: Label=Ink.new()
 note.name=name
 note.text=text
 note.focus_mode=Control.FOCUS_NONE
 note.mouse_filter=Control.MOUSE_FILTER_IGNORE
 note.add_theme_color_override("font_color",Color("29241f"))
 parent.add_child(note)
 return note

static func _scene(host, parent: Node, compact: bool, text: String, progress: String="", note_name: String="StudioNote", interactive: bool=false, fresh: bool=false) -> Dictionary:
 return Scene.render(host,parent,compact,{"heading":"STUDENT RADIO","speaker":"STUDENT PRESENTER","text":text,"progress":progress,"texture":ART,"source":ART_PATH,"raw_sha256":ART_SHA,"note_name":note_name,"interactive":interactive,"fresh":fresh})

static func render(host, parent: Node, compact: bool) -> void:
 if not Flow.locked(host.game.career):
  _brief(host,parent,compact)
  return
 var data: Dictionary=Flow.view(host.game.career)
 var visit: Dictionary=data["visit"]
 var token: String=str(visit.get("id",""))+":"+str(visit.get("revision",""))
 var fresh: bool=host.has_meta("radio_reveal_pending") and str(host.get_meta("radio_reveal_pending"))==token
 if fresh:host.remove_meta("radio_reveal_pending")
 var nodes: Dictionary=_scene(host,parent,compact,str(data["text"]),"VISIT %d / 7" % (int(data["progress"])+1) if bool(data["ok"]) else "SAVED VISIT HELD","StudioNote",bool(data["ok"]),fresh)
 if bool(data["ok"]) and not visit.is_empty():
  var selected: Dictionary=Promotion.selection(host.game.career,str(visit["demo_id"]),str(visit["source_fingerprint"]),int(visit["demo_index"]))
  if bool(selected.get("ok",false)):
   var session: Dictionary=selected["session"]
   var tracks: Array=session.get("tracks",[])
   var context: String="ON THE DESK / "+str(tracks[0].get("title","UNTITLED")) if not tracks.is_empty() else "TRACK DETAILS NOT RECORDED"
   if tracks.size()>1:context+=" + %d MORE" % (tracks.size()-1)
   var label: Label=Scene.copy(host,nodes["words"],context,"StudioDemoContext",16,true)
   nodes["words"].move_child(label,0)
   var details: VBoxContainer=_details(host,nodes["body"],session,"visit")
   _demo_details(host,details,session)
 if not str(host.notice).is_empty():Scene.copy(host,nodes["words"],str(host.notice),"StudioNotice")
 if fresh:(nodes["note"] as Label).call_deferred("begin",bool(host.reduced_motion))
 for choice in data["choices"]:Scene.copy(host,nodes["words"],str(choice["hint"]),"StudioHint_"+str(choice["id"]),16,true)
 if bool(data["can_finish"]):
  var preview: Dictionary=Flow.preview_finish(host.game.career,str(visit["id"]),int(visit["revision"]))
  if bool(preview.get("ok",false)):Scene.pills(host,nodes["words"],host.game.career,preview["state"],true)
  else:Scene.copy(host,nodes["words"],str(preview.get("message","The visit cannot be wrapped up.")),"StudioEligibility")

static func _brief(host, parent: Node, compact: bool) -> void:
 var selected: Dictionary=_selected(host)
 var completed: bool=bool(selected.get("completed",false))
 var saved: Dictionary=selected.get("saved_response",{})
 var text: String="Your demo. Two questions. At your pace."
 if completed:text="This radio campaign is already saved. No interview transcript was recorded." if saved.is_empty() or not saved.has("interview_v1") else "Your student-radio visit is saved. Read the replies and the response whenever you like."
 if not bool(selected.get("ok",false)):text=str(selected.get("message","Choose a saved released demo."))
 var nodes: Dictionary=_scene(host,parent,compact,text,"SAVED RESPONSE" if completed else "BEFORE THE VISIT")
 if not str(host.notice).is_empty():Scene.copy(host,nodes["words"],str(host.notice),"StudioNotice")
 if completed and not saved.is_empty():Scene.pills(host,nodes["words"],saved["before"],saved["after"],false)
 var details: VBoxContainer=_details(host,nodes["body"],selected.get("session",{}),"saved" if completed else "brief")
 if not completed:Scene.copy(host,details,"Visit the student-radio room with this released demo. Two questions, at your pace. £20 and one day only at the final wrap.","StudioVisitBrief")
 if bool(selected.get("ok",false)):_demo_details(host,details,selected["session"])
 if completed:
  if not saved.is_empty():Scene.copy(host,details,"SAVED DAY %d → %d  •  £%d → £%d" % [int(saved["before"]["tour_day"]),int(saved["after"]["tour_day"]),int(saved["before"]["cash"]),int(saved["after"]["cash"])],"PromotionSavedFacts")
  _note(details,str(saved.get("message","This demo's radio campaign was already completed. Its detailed response was not saved with this legacy record.")),"PromotionSavedNote")
  if not saved.is_empty():_transcript(host,details,saved)
 Scene.copy(host,details,"No radio audio or live broadcast is provided.","PromotionAudio",16,true)

static func _demo_details(host, parent: Node, session: Dictionary) -> void:
 var id: String=str(session.get("id",""))
 Scene.copy(host,parent,"DEMO ID / "+id if not id.is_empty() else "LEGACY DEMO / ID NOT RECORDED","PromotionDemoId",16,true)
 var lines: PackedStringArray=[]
 for track in session.get("tracks",[]):lines.append(str(track.get("title","UNTITLED")))
 Scene.copy(host,parent,"\n".join(lines) if not lines.is_empty() else "TRACK DETAILS NOT RECORDED","PromotionTracks",20)
 Scene.copy(host,parent,"SAVED SONG LINKS" if session.has("song_links_v1") else "LEGACY RECORDING / SONG LINKS NOT RECORDED","PromotionLinks",16,true)

static func _details(host, parent: Node, session: Dictionary, context: String) -> VBoxContainer:
 var key: String="studio_details_"+context+"_"+Recording.fingerprint(session)
 var opened: bool=bool(host.get_meta(key)) if host.has_meta(key) else false
 var body: VBoxContainer=host._box(8)
 body.name="PromotionDetailsBody"
 body.visible=opened
 var button: Button=host._button("HIDE DETAILS" if opened else "DETAILS  ›","PromotionDetailsAction",_toggle_details.bind(host,body,key))
 button.toggle_mode=true
 button.set_pressed_no_signal(opened)
 parent.add_child(button)
 parent.add_child(body)
 return body

static func _toggle_details(host, body: Control, key: String) -> void:
 if not is_instance_valid(host) or not is_instance_valid(body) or not body.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy):return
 if str(host.page)!="recording":return
 body.visible=not body.visible
 host.set_meta(key,body.visible)
 var button: Button=body.get_parent().get_node_or_null("PromotionDetailsAction") as Button
 if button!=null:
  button.text="HIDE DETAILS" if body.visible else "DETAILS  ›"
  button.set_pressed_no_signal(body.visible)

static func _transcript(host, parent: Node, saved: Dictionary) -> void:
 var transcript: Variant=saved.get("interview_v1")
 if not transcript is Dictionary or not transcript.get("questions") is Array:return
 for row in transcript["questions"]:
  if not row is Dictionary:continue
  Scene.copy(host,parent,str(row.get("question","")),"",16,true)
  _note(parent,str(row.get("answer","")),"StudioSavedAnswer_"+str(row.get("question_id","")))

static func dock(host, parent: Node, compact: bool) -> void:
 if not Flow.locked(host.game.career):
  var selected: Dictionary=_selected(host)
  var done: bool=bool(selected.get("completed",false))
  var eligibility: Dictionary={"ok":true} if done else _begin_eligibility(host)
  var terms: Label=Scene.copy(host,parent,"SAVED RESPONSE  •  FREE TO READ" if done else "£20  •  1 DAY AT THE FINAL WRAP\nStarting and answering do not spend either.","PromotionCommitment")
  terms.add_theme_color_override("font_color",Color("efe9da"))
  if not done:
   if not bool(eligibility.get("ok",false)):
    var reason: Label=Scene.copy(host,parent,str(eligibility.get("message","This visit cannot begin.")),"StudioEligibility")
    reason.add_theme_color_override("font_color",Color("f0c78b"))
   _button(host,parent,"ENTER THE STUDIO","StudioStartAction","begin","",true,bool(eligibility.get("ok",false)))
  _button(host,parent,"BACK TO RECORDINGS","PromotionBackAction","back")
  return
 var data: Dictionary=Flow.view(host.game.career)
 var visit: Dictionary=data["visit"]
 var confirmation: bool=host.has_meta("studio_cancel_confirm") and bool(host.get_meta("studio_cancel_confirm"))
 var terms: Label=Scene.copy(host,parent,"DISCARD THIS UNFINISHED VISIT? NO COST OR DAY." if confirmation else ("FINAL WRAP  •  £20 / 1 DAY" if bool(data["can_finish"]) else "VISIT SAVED  •  NOTHING SPENT YET"),"StudioCommitment")
 terms.add_theme_color_override("font_color",Color("efe9da"))
 if confirmation:
  _button(host,parent,"KEEP THE VISIT","StudioCancelKeepAction","keep")
  _button(host,parent,"CANCEL THIS VISIT","StudioCancelConfirmAction","cancel","",true,bool(data["can_cancel"]) or bool(data["can_discard"]))
 elif bool(data["ok"]):
  if not (data["choices"] as Array).is_empty():
   var choices: Container=VBoxContainer.new() if compact else HBoxContainer.new()
   choices.add_theme_constant_override("separation",6)
   parent.add_child(choices)
   for choice in data["choices"]:
    var caption: String={"craft":"THE SONGWRITING","live_energy":"THE BAND'S ENERGY","invite":"BRING A FRIEND","critical_craft":"LISTEN CLOSELY"}[str(choice["id"])]
    var button: Button=_button(host,choices,caption,"StudioChoice_"+str(choice["id"]),"answer",str(choice["id"]),true)
    button.tooltip_text=str(choice["text"])+" "+str(choice["hint"])
  elif bool(data["can_finish"]):
   var preview: Dictionary=Flow.preview_finish(host.game.career,str(visit["id"]),int(visit["revision"]))
   _button(host,parent,"WRAP UP  •  £20 / 1 DAY","StudioFinishAction","finish","",true,bool(preview.get("ok",false)))
  else:_button(host,parent,"CONTINUE","StudioContinueAction","advance","",true)
 if not confirmation:
  var free:=HBoxContainer.new()
  free.add_theme_constant_override("separation",6)
  parent.add_child(free)
  _button(host,free,"PAUSE / MENU","StudioPauseAction","pause")
  _button(host,free,"CANCEL VISIT","StudioCancelAction","ask_cancel","",false,bool(data["can_cancel"]) or bool(data["can_discard"]))

static func recovery_dock(host, parent: Node) -> void:
 var confirmed: bool=host.has_meta("studio_cancel_confirm") and bool(host.get_meta("studio_cancel_confirm"))
 _button(host,parent,"CONFIRM DISCARD RADIO VISIT" if confirmed else "UNFINISHED RADIO VISIT OPTIONS","StudioCancelConfirmAction" if confirmed else "StudioCancelAction","cancel" if confirmed else "ask_cancel")

static func perform(host, verb: String, arg: String, cookie: Dictionary) -> void:
 if not is_instance_valid(host) or not host.is_inside_tree() or not host.is_visible_in_tree() or bool(host.busy) or is_instance_valid(host._live_dialog):return
 if host.game==null or host.opening_owner==null or int(host._render_generation)!=int(cookie["generation"]):return
 if str(host.page) not in ["recording","finance"] or bool(host.receipt_open):return
 var current: Dictionary=_cookie(host)
 for key in ["id","phase","revision"]:
  if current[key]!=cookie[key]:return
 if verb=="begin" and current["selection"]!=cookie["selection"]:return
 if str(host.page)=="finance" and verb not in ["ask_cancel","cancel","keep"]:return
 if verb in ["advance","answer","finish"]:
  var note: Label=host.find_child("StudioNote",true,false) as Label
  if note!=null and bool(note.call("is_revealing")):
   note.call("finish_now")
   return
 if verb=="pause":
  host._menu()
  return
 if verb in ["ask_cancel","keep"]:
  host.set_meta("studio_cancel_confirm",verb=="ask_cancel")
  host._pending_focus="StudioCancelKeepAction" if verb=="ask_cancel" else "StudioContinueAction"
  host._render()
  return
 if verb=="back":
  host.recording_mode="archive"
  host._pending_focus="RecordingSelectAction"
  host._render()
  return
 host.busy=true
 var before: Dictionary=host.game.career.duplicate(true)
 var result: Dictionary
 match verb:
  "begin":
   var chosen: Dictionary=host.promotion_selection
   result=Flow.begin(before,str(chosen.get("id","")),str(chosen.get("fingerprint","")),int(chosen.get("index",-1)))
  "advance":result=Flow.advance(before,str(cookie["id"]),str(cookie["phase"]),int(cookie["revision"]))
  "answer":result=Flow.answer(before,str(cookie["id"]),"focus" if cookie["phase"]=="question1" else "invitation",arg,int(cookie["revision"]))
  "finish":result=Flow.finish(before,str(cookie["id"]),int(cookie["revision"]))
  "cancel":
   if not host.has_meta("studio_cancel_confirm") or not bool(host.get_meta("studio_cancel_confirm")):
    host.busy=false
    return
   result=Flow.cancel(before,str(cookie["id"]),int(cookie["revision"])) if bool(Flow.validate(before).get("ok",false)) else Flow.discard(before,true)
  _:result={"ok":false,"message":"Unknown studio action."}
 if not bool(result.get("ok",false)):
  host.busy=false
  host.notice=str(result.get("message","This radio-visit action is unavailable."))
  host._render()
  return
 if bool(result.get("changed",false)):
  host.game.career=result["state"]
  if not bool(host.opening_owner.save_draft()):
   host.game.career=before
   host.busy=false
   host.notice="The visit checkpoint could not be saved. Your previous band and visit state are retained."
   host._render()
   return
 host.notice=""
 host.set_meta("studio_cancel_confirm",false)
 if bool(result.get("settled",false)):
  host._recording_present(result,before,"radio")
  return
 host.busy=false
 if Flow.locked(host.game.career):
  host.recording_mode="visit"
  var visit: Dictionary=Flow.active(host.game.career)
  if bool(result.get("changed",false)):host.set_meta("radio_reveal_pending",str(visit.get("id",""))+":"+str(visit.get("revision","")))
  host._pending_focus="StudioNote"
 else:
  host.recording_mode="archive"
  host._pending_focus="RecordingSelectAction"
 if bool(result.get("changed",false)):
  host._scroll_position=0
  if is_instance_valid(host._scroll):host._scroll.scroll_vertical=0
 host._render()

static func receipt(host, parent: Node, compact: bool) -> void:
 var saved: Dictionary=host.receipt
 var session: Dictionary=saved.get("session",{})
 var radio: Dictionary=(session.get("campaigns",{}) as Dictionary).get("radio",{})
 var response: Dictionary=radio.get("receipt_v1",{})
 var text: String="%d new listeners found your band." % (int(response["after"]["fans"])-int(response["before"]["fans"])) if not response.is_empty() else "Your student-radio visit is saved."
 var nodes: Dictionary=_scene(host,parent,compact,text,"SAVED RESPONSE","CareerReceiptNote",true,bool(host._fresh_receipt))
 if not response.is_empty():Scene.pills(host,nodes["words"],response["before"],response["after"],false)
 var details: VBoxContainer=_details(host,nodes["body"],session,"receipt")
 Scene.copy(host,details,"DAY %d → %d\n£%d → £%d" % [int(saved.get("day_before",1)),int(saved.get("day_after",1)),int(saved.get("cash_before",0)),int(saved.get("cash_after",0))],"RecordingReceiptFacts")
 _note(details,str(saved.get("text","Saved.")),"PromotionFullResponse")
 _demo_details(host,details,session)
 if not response.is_empty():_transcript(host,details,response)
