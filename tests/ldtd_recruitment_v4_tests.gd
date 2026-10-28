extends SceneTree
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
const Scene = preload("res://poc/ldtd_recruitment_v4.tscn")
const Meter = preload("res://poc/ldtd_recruitment_meter.gd")
var failures:=0
func _initialize() -> void:
 call_deferred("_run")
func _check(yes:bool,msg:String) -> void:
 if not yes:
  failures+=1
  push_error("V4 FAILURE: "+msg)
func _run() -> void:
 var view:Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(5):await process_frame
 _check(view.step==0 and view.roster.is_empty() and view.band_name.is_empty(),"genre is first, no band/name auto-created")
 _check(view.get_class()=="Control","native root")
 view._next()
 _check(view.step==1,"musician profiles after genre")
 _check(view._current().has("experience_years"),"experience dossier sources authoritative candidate")
 _check(view._current().has("friction"),"personality trade-off present")
 view._show_dossier()
 _check(view._bio_open and view.find_children("*","AcceptDialog",true,false).is_empty(),"mobile profile uses art-backed paper, never stock Godot popups")
 view._close_dossier()
 _check(not view._bio_open,"can return to auditions without mutating roster")
 _check(Model.pool(view.genre,"Singer").size()==6,"six real role candidates")
 view._move(1)
 _check(view.candidate_index==1,"transport next changes singer")
 view._move(-1)
 _check(view.candidate_index==0,"transport previous reverses without duplicate")
 view._set_role("Guitarist")
 _check(view.role=="Guitarist" and view.candidate_index==0,"role tabs route independently")
 view._set_role("Singer")
 var person:Dictionary=view._current()
 _check(person["id"]=="alex","existing portrait is correctly linked to legacy Alex identity")
 # Nia is the canonical candidate, not fictional imagegen's Nia Carter.
 var nia_index:int=-1
 var singers:Array=Model.pool(view.genre,"Singer")
 for i in range(singers.size()):
  if str(singers[i]["id"])=="nia_griffiths":nia_index=i
 _check(nia_index>=0,"Nia Griffiths reachable through canonical Singer role")
 if nia_index>=0:
  view._choose_candidate(nia_index)
  var nia:Dictionary=view._current()
  _check(str(nia["id"])=="nia_griffiths" and str(nia["name"])=="Nia Griffiths" and str(view.selected.get("id",""))=="nia_griffiths","native selected identity is canonical Nia")
  _check(Model.cost(nia)==45 and Model.incremental_cost(view.roster,nia)==45,"Nia cost derived from canonical catalogue")
  # The portrait's identity/status metadata is checked in actual native
  # xvfb capture rather than attempting to inspect a headless null window.
  _check(not ResourceLoader.exists("res://Art/Portraits/indie/nia_griffiths.webp"),"canonical Nia portrait master is not present/approved")
  _check(Model.stats_for(nia,"Singer")==[8,6,9,6,9,7],"Nia's six singer stats are model-backed and immutable")
  # Runtime UI text/portrait assertions are done by the xvfb native capture
  # at 390x844 and 1280x720. Headless DisplayServer supplies no drawable
  # window, so find_children() cannot validate an unrendered scene here.
  _check(Model.MAX_TALENT-Model.spent(view.roster)==200,"initial pool starts at 200")
  view._add_remove()
  _check(Model.contains(view.roster,"nia_griffiths") and Model.spent(view.roster)==45 and Model.MAX_TALENT-Model.spent(view.roster)==155,"recruit Nia spends exactly 45")
  view._add_remove()
  _check(view.roster.is_empty() and Model.spent(view.roster)==0 and Model.MAX_TALENT-Model.spent(view.roster)==200,"removing Nia restores exact 200 pool")
  view._choose_candidate(0)
  _check(str(view._current()["id"])=="alex","candidate switching back restores Alex")
 view._add_remove()
 _check(Model.contains(view.roster,"alex") and view.roster.size()==1,"single singer/guitar hybrid recruited")
 view._add_remove()
 _check(view.roster.is_empty(),"same recruit toggles remove")
 var three:Array=[]
 for member in Model.people():
  if ["alex","sam","jo"].has(str(member["id"])):
   three.append(member)
 view.roster=three.duplicate(true)
 view._next()
 _check(view.step==2,"name LAST after valid hybrid 3-piece")
 view._name_edit("Northbound Lines")
 view._next()
 _check(view.completed and view.band_name=="Northbound Lines","name completes local preview")
 var stat:=Meter.new()
 get_root().add_child(stat)
 for i in range(2):await process_frame
 _check(stat.focus_mode==Control.FOCUS_NONE and stat.mouse_filter==Control.MOUSE_FILTER_IGNORE,"stats passive")
 _check(not view.has_method("_style"),"legacy flat helper absent")
 view.queue_free()
 stat.queue_free()
 if failures==0:print("LDTD V4 RECRUITMENT MODEL AND ART-SEMANTICS PASSED")
 quit(0 if failures==0 else 1)
