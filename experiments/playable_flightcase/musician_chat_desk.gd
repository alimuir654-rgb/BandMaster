extends RefCounted
## A musician-led poster conversation; all mutations belong to the existing owner.
const Chat=preload("res://experiments/playable_flightcase/musician_chat.gd")
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Cast=preload("res://experiments/character_cast/catalogue.gd")
const Situation=preload("res://experiments/playable_flightcase/situation_core.gd")

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
 if not str(host.notice).is_empty():words(parent,str(host.notice),18,Poster.GOLD)
 var topics:=HFlowContainer.new();topics.add_theme_constant_override("h_separation",6);topics.add_theme_constant_override("v_separation",6);parent.add_child(topics)
 for pair in [["direction","OUR MUSIC"],["time","MAKING TIME"],["pressure","HOW WE'RE DOING"]]:
  var action: Button=host._button(str(pair[1]),"ChatTopic_"+str(pair[0]),host._chat_topic.bind(str(pair[0])))
  action.toggle_mode=true;action.set_pressed_no_signal(host.chat_topic==pair[0]);topics.add_child(action)
 var row: Dictionary=Chat.record(state,id)
 var plan: Dictionary=row.get("plan",{})
 if not plan.is_empty():
  var heading: String="WHAT YOU AGREED" if plan.status=="pending" else "WHAT HAPPENED"
  words(parent,heading,20,Poster.GOLD)
  words(parent,str(plan.note),18)
  if plan.status=="pending":words(parent,"Agreed on DAY %d · through DAY %d. Check their work commitments before making the booking." % [int(plan.day),int(plan.due_day)],16)
 var paper:=PanelContainer.new();paper.name="MusicianChatPaper";paper.mouse_filter=Control.MOUSE_FILTER_PASS
 paper.add_theme_stylebox_override("panel",Poster.control_stock(Poster.PAPER,20));parent.add_child(paper)
 var transcript:=VBoxContainer.new();transcript.add_theme_constant_override("separation",10);transcript.mouse_filter=Control.MOUSE_FILTER_PASS;paper.add_child(transcript)
 var view: Dictionary=Chat.options(state,id,host.chat_topic)
 if view.get("available",false):
  words(transcript,str(person.get("name","Bandmate"))+":",18,Poster.INK)
  words(transcript,str(view.opening),21,Poster.INK)
  for choice in view.choices:
   var action: Button=host._button(str(Chat.LABELS[choice]),"ChatReply_"+str(choice),host._chat_answer.bind(str(choice),host.chat_expected.duplicate(true),int(host._render_generation)))
   transcript.add_child(action)
 else:
  if not row.get("turns",[]).is_empty():
   var turn: Dictionary=row.turns.back()
   words(transcript,str(person.get("name","Bandmate"))+": "+str(turn.opening),19,Poster.INK)
   words(transcript,"YOU: "+str(Chat.LABELS[turn.choice]),18,Poster.INK)
   words(transcript,str(person.get("name","Bandmate"))+": "+str(turn.reply),20,Poster.INK)
  words(transcript,str(view.get("message","Come back when you can talk.")),16,Poster.INK)
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
