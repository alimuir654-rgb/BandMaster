extends RefCounted
## A musician-led poster conversation; all mutations belong to the existing owner.
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Cast=preload("res://experiments/character_cast/catalogue.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")
const Conversation=preload("res://experiments/playable_flightcase/conversation_panel.gd")

static func words(parent: Node,text: String,points: int=18,color: Color=Poster.PAPER) -> Label:
 var label: Label=Poster.label(text,points,color)
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(label)
 return label

static func render(host,parent: Node,compact: bool) -> void:
 var state: Dictionary=host.game.career
 var checked: Dictionary=Chat.validate(state)
 if not checked.ok:words(parent,checked.message);return
 var person: Dictionary=Chat.member(state,host.chat_member_id)
 if person.is_empty():words(parent,"Choose someone from your current band.");return
 var id: String=str(person.candidate_id)
 var hero:=HBoxContainer.new();hero.add_theme_constant_override("separation",14);parent.add_child(hero)
 var photo:=TextureRect.new();photo.name="MusicianChatPortrait";photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 photo.custom_minimum_size=Vector2(110,120) if compact else Vector2(175,175);photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var source: String=str(Cast.by_id(id).get("portrait_preview",""))
 if not source.is_empty() and ResourceLoader.exists(source):photo.texture=load(source)
 hero.add_child(photo)
 var intro:=VBoxContainer.new();intro.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hero.add_child(intro)
 words(intro,str(person.get("name","Bandmate")).to_upper(),30)
 words(intro,str(person.get("role","Musician")),18,Poster.GOLD)
 words(intro,"A MOMENT TO TALK",16)
 words(parent,"£0 · No career day used. Any plans you make still need an actual evening together.",16)
 if not str(host.notice).is_empty() and not str(host.notice).begins_with(str(person.get("name","Bandmate"))+":"):words(parent,str(host.notice),18,Poster.GOLD)
 var topics:=HFlowContainer.new();topics.add_theme_constant_override("h_separation",6);topics.add_theme_constant_override("v_separation",6);parent.add_child(topics)
 for pair in [["direction","OUR MUSIC"],["time","MAKING TIME"],["pressure","HOW WE'RE DOING"]]:
  var action: Button=host._button(str(pair[1]),"ChatTopic_"+str(pair[0]),host._chat_topic.bind(str(pair[0])))
  action.toggle_mode=true;action.set_pressed_no_signal(host.chat_topic==pair[0]);topics.add_child(action)
 var row: Dictionary=Chat.record(state,id)
 var plan: Dictionary=row.get("plan",{})
 if not plan.is_empty():
  words(parent,"OUR AGREEMENT" if plan.status=="pending" else "WHAT HAPPENED",20,Poster.GOLD)
  if plan.status=="pending":words(parent,"%s · THROUGH DAY %d" % [{"write":"WORK ON A SONG","rehearse":"AN EVENING TO REHEARSE","rest":"ROOM TO RECOVER"}[plan.kind],int(plan.due_day)],18)
  else:words(parent,str(plan.note),20)
 var paper:=PanelContainer.new();paper.name="MusicianChatPaper";paper.mouse_filter=Control.MOUSE_FILTER_PASS
 paper.add_theme_stylebox_override("panel",Poster.control_stock(Poster.PAPER,20));parent.add_child(paper)
 var transcript:=VBoxContainer.new();transcript.add_theme_constant_override("separation",10);transcript.mouse_filter=Control.MOUSE_FILTER_PASS;paper.add_child(transcript)
 var view: Dictionary=Chat.options(state,id,host.chat_topic)
 if view.get("available",false):
  words(transcript,str(person.get("name","Bandmate"))+":",18,Poster.INK)
  words(transcript,str(view.opening),21,Poster.INK)
  for choice in view.choices:
   var action: Button=host._button(str(Chat.LABELS[choice]),"ChatReply_"+str(choice),host._chat_answer.bind(str(choice),host.chat_expected.duplicate(true),int(host._render_generation)))
   Conversation.reply(action,true);transcript.add_child(action)
 else:
  var recent: Array=row.get("turns",[])
  # Show the actual saved exchange immediately. It used to disappear behind
  # a collapsed history button, making a successful answer feel unresponsive.
  if not recent.is_empty() and int(row.get("last_day",0))==int(state.get("tour_day",1)):
   var last: Dictionary=recent.back()
   Conversation.turn(transcript,"YOU",Chat.turn_label(last),"MusicianChatYourReply")
   var reply: Label=Conversation.turn(transcript,str(person.get("name","Bandmate")),str(last.reply),"MusicianChatSavedReply")
   reply.focus_mode=Control.FOCUS_ALL
  else:
   words(transcript,str(person.get("name","Bandmate"))+":",18,Poster.INK)
   words(transcript,str(view.get("opening","Let's make the next evening count.")),21,Poster.INK)
  if plan.get("status")!="pending":words(transcript,str(view.get("message","Come back when you can talk.")),16,Poster.INK)
  if view.get("can_revise",false):
   transcript.add_child(host._button("CHANGE OUR PLAN" if not host.chat_revising else "KEEP OUR CURRENT PLAN","ChatReviseAction",host._chat_disclose.bind(false)))
   if host.chat_revising:
    words(transcript,"Agree a fresh four-day window together. You can revise this promise once. The previous agreement stays in your history. £0 · No career day used.",17,Poster.INK)
    for pair in [["write","MAKE TIME FOR A SONG"],["rehearse","AGREE A REHEARSAL"],["rest","LEAVE ROOM TO RECOVER"]]:
     transcript.add_child(host._button(str(pair[1]),"ChatRevise_"+str(pair[0]),host._chat_revise.bind(str(pair[0]),host.chat_expected.duplicate(true),int(host._render_generation))))
 if not row.get("turns",[]).is_empty():
  parent.add_child(host._button("HIDE OUR CONVERSATION" if host.chat_history_open else "OUR CONVERSATION +","ChatHistoryAction",host._chat_disclose.bind(true)))
  if host.chat_history_open:
   var last: Dictionary=row.turns.back()
   words(parent,"YOU: "+Chat.turn_label(last),18).name="ChatLastReply"
   words(parent,str(person.get("name","Bandmate"))+": "+str(last.reply),18)
   for entry in row.get("plan_history_v1",{}).get("records",[]):
    words(parent,"DAY %d · %s · %s" % [int(entry.plan.day),(str(entry.plan.status) if entry.closed_as=="completed" else str(entry.closed_as)).to_upper(),str(entry.plan.note)],16)
 var current: String="Outside-band circumstances not recorded."
 for context in Situation.members(state):
  if context.id==id:current=Situation.context_text(context,int(state.get("tour_day",1)));break
 words(parent,"CURRENT COMMITMENTS · "+current,16)

static func dock(host,parent: Node) -> void:
 var row: Dictionary=Chat.record(host.game.career,host.chat_member_id)
 var plan: Dictionary=row.get("plan",{})
 if plan.get("status")=="pending":
  if plan.kind=="write":parent.add_child(host._button("TAKE IT TO THE WRITING ROOM ›","ChatNextStep",host._practice.bind("create"),true))
  elif plan.kind=="rehearse":parent.add_child(host._button("TAKE IT TO REHEARSAL ›","ChatNextStep",host._practice.bind("tighten"),true))
  else:parent.add_child(host._button("MAKE TIME TO CLEAR THE AIR ›","ChatNextStep",host._practice.bind("connect"),true))
 parent.add_child(host._button("‹ BACK TO THE BAND","ChatBack",host._navigate.bind("band")))
