extends SceneTree
const Ideas=preload("res://experiments/playable_flightcase/character_audio.gd")
const Cast=preload("res://experiments/character_cast/catalogue.gd")
var checks:=0
var failures: Array=[]
var active:=true
var covered: Array=[]

func _init() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label);push_error(label)

func run() -> void:
 for person in Cast.people():
  var parent:=VBoxContainer.new();parent.size=Vector2(390,600);root.add_child(parent)
  active=true
  Ideas.attach(parent,str(person.id),str(person.roles[0]),func():return active)
  for _i in range(3):await process_frame
  var ideas=parent.find_child("CharacterRecordedIdeas",true,false)
  if person.id=="cast_nina":
   check(ideas==null,"Nina remains honestly held pending listening fit")
   parent.free();continue
  check(ideas!=null,"real recorded control "+str(person.id))
  if ideas!=null:
   covered.append(person.id)
   for material in ideas._materials:
    ideas._play(material);await process_frame
    check(ideas.playing and ideas._player.playing,"actual decode/play "+material)
    ideas.stop();check(not ideas.playing and ideas._player.stream==null,"stop releases stream "+material)
   var first: String=str(ideas._materials[0])
   ideas._play(first);AudioServer.set_bus_mute(0,true)
   await create_timer(0.04).timeout
   check(not ideas.playing,"master mute stops "+str(person.id));AudioServer.set_bus_mute(0,false)
   ideas._play(first);active=false;await create_timer(0.04).timeout
   check(not ideas.playing,"changed selection stops "+str(person.id))
   active=true;ideas._play(first)
   ideas._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
   check(not ideas.playing,"focus loss stops "+str(person.id))
   var row: Dictionary=ideas._registry[first]
   var authority: String=str(row.integration_authority);row.integration_authority="unapproved"
   ideas._play(first);check(not ideas.playing,"unknown authority fails closed "+str(person.id));row.integration_authority=authority
   var original_sha: String=str(row.sha256);row.sha256="00"
   ideas._play(first);check(not ideas.playing,"changed media fails closed "+str(person.id));row.sha256=original_sha
  parent.free()
 check(covered.size()==17 and "cast_tom" in covered,"17 distinct canonical Indie candidates; Nina separately held")
 await create_timer(0.25).timeout
 await process_frame
 print("FEEDBACK47_AUDIO "+JSON.stringify({"checks":checks,"failures":failures,"covered":covered,"Nina":"review-only","Arjun_adjusted":"written-only","listening_verified":false,"physical_Android":false}))
 quit(0 if failures.is_empty() else 1)
