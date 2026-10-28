extends SceneTree
const Model = preload("res://Scripts/recruitment_catalogue_v3.gd")
const Meter = preload("res://poc/ldtd_recruitment_meter.gd")
const Scene = preload("res://poc/ldtd_recruitment_v3.tscn")
var failures: int = 0

func _initialize() -> void:
 call_deferred("_run")

func _check(result: bool, message: String) -> void:
 if not result:
  failures += 1
  push_error("V3 RECRUITMENT FAILURE: "+message)

func _run() -> void:
 var all_genres := Model.genres()
 _check(all_genres.size()>=4,"several real genres remain available")
 var independent_ids: Dictionary={}
 var found_women := false
 var found_men := false
 var found_hybrid := false
 for g in all_genres:
  for role in Model.ROLE_TABS:
   var candidates: Array=Model.pool(str(g),str(role))
   _check(candidates.size()==6,str(g)+" "+str(role)+" has six browseable musicians")
   var seen: Dictionary={}
   for p in candidates:
    var id: String=str(p["id"])
    _check(not seen.has(id),"no duplicate choices in "+str(g)+" "+str(role))
    seen[id]=true
    independent_ids[id]=true
    _check((p["roles"] as Array).has(role),"candidate covers listed tab "+id)
    _check(Model.stats_for(p,str(role)).size()==6,"six role-specific attributes "+id)
    _check(Model.cost(p)>=12 and Model.cost(p)<=70,"bounded candidate cost "+id)
    _check(int(p["bands"])>=0 and int(p["experience_years"])>=0,"real career history "+id)
    _check(not str(p["story"]).is_empty() and not str(p["friction"]).is_empty(),"meaningful written trade-off "+id)
    found_women = found_women or str(p["gender"])=="Woman"
    found_men = found_men or str(p["gender"])=="Man"
    found_hybrid = found_hybrid or (p["roles"] as Array).size()>1
 _check(found_women and found_men,"UK mixed gender selection")
 _check(found_hybrid,"singer/instrumentalists exist")
 _check(independent_ids.size()>=30,"diverse stable identities")
 var singer: Dictionary={}
 var bass: Dictionary={}
 var drums: Dictionary={}
 for p in Model.people():
  if str(p["id"])=="alex":
   singer=p
  elif str(p["id"])=="sam":
   bass=p
  elif str(p["id"])=="jo":
   drums=p
 _check(not singer.is_empty() and not bass.is_empty() and not drums.is_empty(),"verified legacy portraits retain actual people IDs")
 var three: Array=[singer,bass,drums]
 _check(Model.viable(three),"three-piece with singing guitarist, bass and drums covers all essentials")
 _check(Model.spent(three)<=Model.MAX_TALENT,"valid three-person budget")
 _check(not Model.can_add(three,singer),"hybrid person cannot be double recruited via guitar tab")
 var four := three.duplicate(true)
 for p in Model.people():
  if str(p["id"])=="martha_reed":
   four.append(p)
 _check(Model.viable(four),"four-piece has no artificial lineup penalty")
 _check(Model.spent(four)==Model.spent(three)+Model.cost(four[3]),"fourth member has no headcount tax")
 _check(not Model.viable([singer,bass]),"two musicians cannot immediately form a complete band")
 _check(Model.spent(four)<Model.MAX_TALENT,"four-piece leaves some headroom")
 var fifth: Dictionary={}
 var sixth: Dictionary={}
 for p in Model.people():
  if str(p["id"])=="nia_griffiths":
   fifth=p
  elif str(p["id"])=="chloe_barker":
   sixth=p
 _check(Model.incremental_cost(four,fifth)==Model.cost(fifth)+6,"fifth recruit advertises six-point organisational tax")
 var five := four.duplicate(true)
 five.append(fifth)
 _check(Model.incremental_cost(five,sixth)==Model.cost(sixth)+12,"sixth recruit advertises twelve-point organisational tax")
 _check(Model.incremental_cost(three,singer)==0,"cannot charge twice for same person")
 var unaffordable := four.duplicate(true)
 for p in Model.people():
  if str(p["id"])=="aisha_khan" or str(p["id"])=="tom_hargreaves":
   unaffordable.append(p)
 _check(Model.spent(unaffordable)>Model.MAX_TALENT,"star-heavy six-piece exceeds talent budget")
 var m := Meter.new()
 get_root().add_child(m)
 await process_frame
 _check(m.focus_mode==Control.FOCUS_NONE and m.mouse_filter==Control.MOUSE_FILTER_IGNORE,"read-only meter cannot steal input")
 m.value=0
 _check(m.value==0,"zero has genuine zero value")
 m.value=10
 _check(m.value==10,"ten has genuine full value")
 m.queue_free()
 var view: Control=Scene.instantiate()
 get_root().add_child(view)
 for i in range(3):
  await process_frame
 _check(view.step==0 and view.band_name.is_empty(),"genre FIRST and name LAST")
 _check(view.roster.is_empty(),"starting with no precommitted band")
 view._continue()
 _check(view.step==1 and view.role=="Singer","singer recruitment follows genre")
 _check(view._pool().size()==6,"six candidates visible")
 view._set_role("Guitarist")
 _check(view.role=="Guitarist" and view._pool().size()==6,"five role tab switching")
 view._set_role("Singer")
 var old_genre: String=view.genre
 view._current=singer
 view._member_action()
 _check(Model.contains(view.roster,"alex"),"one hybrid selected")
 view._current=bass
 view._member_action()
 view._current=drums
 view._member_action()
 _check(view.roster.size()==3 and Model.viable(view.roster),"three real people make valid hybrid lineup")
 view._continue()
 _check(view.step==2,"name requested after qualifying lineup")
 view.band_name="Northern Static"
 view._continue()
 _check(view.completed and view.band_name=="Northern Static","complete isolated preview without save writes")
 _check(view.genre==old_genre,"genre identity maintained")
 view.queue_free()
 for i in range(3):
  await process_frame
 if failures==0:
  print("LDTD RECRUITMENT V3 ALL DETERMINISTIC AND UI CONTRACT TESTS PASSED")
 quit(0 if failures==0 else 1)
