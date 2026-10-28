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

 # 16:00 cross-role deterministic contract: six distinct canonical choices
 # in every genre/role pool. Navigation and tab changes cannot spend points.
 for genre_name in Model.genres():
  for role_name in Model.ROLE_TABS:
   var choices:Array=Model.pool(str(genre_name),str(role_name))
   _check(choices.size()==6,"six candidate affordances: "+str(genre_name)+" / "+str(role_name))
   var unique_ids:Dictionary={}
   for option in choices:
    var option_id:String=str(option.get("id",""))
    _check(not option_id.is_empty() and not unique_ids.has(option_id),"unique catalogue person: "+str(genre_name)+" / "+str(role_name)+" / "+option_id)
    unique_ids[option_id]=true
    _check((option["roles"] as Array).has(str(role_name)),"candidate qualified for tab "+str(role_name))
    _check(Model.labels_for(str(role_name)).size()==6 and Model.stats_for(option,str(role_name)).size()==6,"six source-backed stats for "+option_id)
 for role_name in Model.ROLE_TABS:
  view._set_role(str(role_name))
  var options:Array=Model.pool(view.genre,view.role)
  _check(options.size()==6,"live six choices in "+str(role_name))
  for position in range(options.size()):
   view._choose_candidate(position)
   var chosen:Dictionary=view._current()
   _check(str(chosen["id"])==str(options[position]["id"]) and str(view.selected.get("id",""))==str(chosen["id"]),"live candidate "+str(position)+" bound in "+str(role_name))
   _check(view.roster.is_empty() and Model.MAX_TALENT-Model.spent(view.roster)==200,"browsing never spends budget")
  view._move(1)
  _check(view.candidate_index==0 and str(view._current()["id"])==str(options[0]["id"]),"sixth-to-first transport wraps "+str(role_name))
  view._move(-1)
  _check(view.candidate_index==options.size()-1 and str(view._current()["id"])==str(options[options.size()-1]["id"]),"first-to-sixth transport wraps "+str(role_name))
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

 # Dual-role candidate cannot be paid for twice when reached through
 # Singer and Keyboardist tabs; removing her from either role refunds once.
 var aisha_singer_index:int=-1
 for i in range(Model.pool(view.genre,"Singer").size()):
  if str(Model.pool(view.genre,"Singer")[i]["id"])=="aisha_khan":aisha_singer_index=i
 _check(aisha_singer_index>=0,"dual-role Aisha visible in singer six")
 if aisha_singer_index>=0:
  view._set_role("Singer")
  view._choose_candidate(aisha_singer_index)
  var aisha_cost:int=Model.incremental_cost(view.roster,view._current())
  view._add_remove()
  _check(Model.contains(view.roster,"aisha_khan") and view.roster.size()==1 and Model.spent(view.roster)==aisha_cost,"first dual-role recruit exactly once")
  view._set_role("Keyboardist")
  var aisha_keys_index:int=-1
  var key_choices:Array=Model.pool(view.genre,"Keyboardist")
  for i in range(key_choices.size()):
   if str(key_choices[i]["id"])=="aisha_khan":aisha_keys_index=i
  _check(aisha_keys_index>=0,"same dual-role ID reachable via keys")
  if aisha_keys_index>=0:
   view._choose_candidate(aisha_keys_index)
   _check(str(view.selected.get("id",""))=="aisha_khan","keys tab preserved recruited identity")
   view._add_remove()
   _check(view.roster.is_empty() and Model.spent(view.roster)==0 and Model.MAX_TALENT-Model.spent(view.roster)==200,"cross-tab remove refunds once")

 # Budget guard: build a legitimate, <=200-point roster, then prove the
 # actual Godot add handler refuses a sixth singer it cannot afford.
 view.roster.clear()
 view._set_role("Singer")
 var blocked_target:Dictionary=Model.pool(view.genre,"Singer")[5]
 var fullish:Array=[]
 for option in Model.people():
  if str(option["id"])==str(blocked_target["id"]):continue
  if Model.can_add(fullish,option):fullish.append(option)
  if not Model.can_add(fullish,blocked_target):break
 _check(not Model.can_add(fullish,blocked_target) and Model.spent(fullish)<=200,"construct valid over-budget candidate case")
 if not Model.can_add(fullish,blocked_target):
  view.roster=fullish.duplicate(true)
  view._choose_candidate(5)
  var before_spent:int=Model.spent(view.roster)
  var before_count:int=view.roster.size()
  view._add_remove()
  _check(view.roster.size()==before_count and Model.spent(view.roster)==before_spent and not Model.contains(view.roster,str(blocked_target["id"])),"disabled unaffordable recruit does not alter model roster")
 view.roster.clear()
 view._set_role("Singer")
 view._choose_candidate(0)
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
