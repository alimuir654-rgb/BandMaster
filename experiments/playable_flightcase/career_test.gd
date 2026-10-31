extends SceneTree
# SCRATCH headless proof. Root supplies the exact bridge in the isolated runtime.
# No UI/input/device claims; only the genuine C27 fixture writes its own draft.
const Bridge = preload("res://experiments/playable_flightcase/career_bridge.gd")
const OpeningModel = preload("res://experiments/playable_flightcase/opening_state.gd")
const Gear = preload("res://Scripts/gear_shop.gd")
const Calendar = preload("res://Scripts/gig_calendar.gd")
const Story = preload("res://Scripts/career_story.gd")
const Life = preload("res://Scripts/member_life.gd")
const SAFE_ROOT := "/workspace/work/unify/s45/"
var output := "/workspace/work/unify/s45/bridge-test"
var model
var base: Dictionary = {}
var checks: int = 0
var bridge_calls: int = 0
var failures: Array[String] = []
var observations: Array = []
var protected_initial: Dictionary = {}

func _init() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
 call_deferred("run")

func check(ok: bool, message: String) -> bool:
 checks += 1
 if not ok:
  failures.append(message)
  push_error("S45_CAREER_BRIDGE_TEST "+message)
 return ok

func disk_files(include_c27: bool=true) -> Dictionary:
 var result: Dictionary = {}
 var paths: Array = ["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]
 if include_c27: paths.append(OpeningModel.SAVE_PATH)
 for path in paths:
  result[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result

func step(label: String, result: Variant) -> bool:
 return check(bool(result.get("ok",false)) if result is Dictionary else bool(result),"genuine C27 fixture: "+label)

func fixture() -> bool:
 model = OpeningModel.new()
 if not step("begin",model.begin_new()): return false
 if not step("Indie rock",model.set_genre("Indie rock")): return false
 if not step("recruit phase",model.to_recruit()): return false
 for id in ["cast_jack","cast_zoe","cast_casey"]:
  if not step("recruit "+id,model.recruit(id)): return false
 if not step("Jack voice",model.choose_vocal("cast_jack")): return false
 if not step("lineup",model.confirm_lineup()): return false
 if not step("naming",model.start_naming()): return false
 if not step("propose",model.submit_name("QA UNIFIED BAND","Raw")): return false
 if not step("lock name",model.lock_name()): return false
 if not step("identity",model.start_identity()): return false
 if not step("design",model.set_identity("Wordmark","Amber / Charcoal","Unpolished")): return false
 if not step("finish identity",model.finish_identity()): return false
 if not step("play",model.start_playing()): return false
 base = model.game.career.duplicate(true)
 var reloaded := OpeningModel.new()
 return check(reloaded.load_draft() and reloaded.snapshot()==model.snapshot() and int(base.cash)==250 and int(base.tour_day)==1,"real C27 formation survives actual isolated disk reload")

func original_result(state: Dictionary, verb: String, item: String, member: int=-1) -> Dictionary:
 # Original CareerHub's exact successful composition and source strings.
 var result: Dictionary
 var source := ""
 match verb:
  "buy": result = Gear.buy(state,item)
  "assign":
   source = "gear:assign"
   result = Gear.assign(state,item,member)
  "service":
   source = "gear:service"
   result = Gear.service(state,item)
  _: return {"ok":false,"message":"Unknown equipment action."}
 if bool(result.get("ok",false)):
  result["state"] = Life.refresh(Calendar.expire(Story.observe(state,result["state"],source)))
 return result

func dispatch(state: Dictionary, verb: String, item: String, member: int=-1) -> Dictionary:
 var before: Dictionary = state.duplicate(true)
 var saved: Dictionary = disk_files()
 var owner: Dictionary = model.snapshot()
 var result: Dictionary = Bridge.gear_action(state,verb,item,member)
 bridge_calls += 1
 check(state==before,"bridge input immutable: "+verb+" "+item)
 check(model.snapshot()==owner and disk_files()==saved,"pure bridge has no model/disk side effects: "+verb+" "+item)
 observations.append({"verb":verb,"item":item,"member":member,"ok":bool(result.get("ok",false)),"message":str(result.get("message","")),"cash":result.get("state",{}).get("cash",null),"day":result.get("state",{}).get("tour_day",null)})
 return result

func parity(state: Dictionary, verb: String, item: String, member: int=-1) -> Dictionary:
 var before: Dictionary = state.duplicate(true)
 var expected: Dictionary = original_result(state,verb,item,member)
 check(state==before,"original oracle input immutable")
 var actual: Dictionary = dispatch(state,verb,item,member)
 check(actual==expected,"exact original Gear→Story→Calendar→Life result/message parity: "+verb+" "+item)
 return actual

func rejected(state: Dictionary, verb: String, item: String, member: int=-1) -> bool:
 var result := dispatch(state,verb,item,member)
 return check(not bool(result.get("ok",false)),"rejected action cannot settle: "+verb+" "+item)

func case_original_parity() -> void:
 for item in Gear.ITEMS:
  var result := parity(base,"buy",str(item.id))
  if not check(bool(result.get("ok",false)),"original catalogue item can be bought from real cash250"): return
  var state: Dictionary = result.state
  check(int(state.cash)==250-int(item.price) and int(state.tour_day)==2,"exact original purchase cost/day")
  check(int(Gear.record(state,str(item.id)).get("condition",-1))==int(item.condition),"catalogue's authored condition retained")
  check(not bool(parity(state,"buy",str(item.id)).get("ok",true)),"duplicate purchase fails identically")
 var bought := parity(base,"buy","amp")
 if not bool(bought.get("ok",false)): return
 var assigned := parity(bought.state,"assign","amp",0)
 if not check(bool(assigned.get("ok",false)),"canonical Guitarist Jack receives amp"): return
 var assigned_state: Dictionary = assigned.state
 check(int(assigned_state.cash)==185 and int(assigned_state.tour_day)==2,"original assignment is free/instant")
 check(not bool(parity(assigned_state,"assign","amp",0).get("ok",true)),"original repeated assignment remains no-op rejection")
 var serviced := parity(assigned_state,"service","amp")
 check(bool(serviced.get("ok",false)) and int(serviced.state.cash)==160 and int(serviced.state.tour_day)==3 and int(Gear.record(serviced.state,"amp").condition)==100,"service uses exact25 cash/day and capped condition")
 var poor: Dictionary = base.duplicate(true)
 poor.cash = 0
 check(not bool(parity(poor,"buy","amp").get("ok",true)),"insufficient purchase exact rejection")
 var poor_owned: Dictionary = assigned_state.duplicate(true)
 poor_owned.cash = 24
 check(not bool(parity(poor_owned,"service","amp").get("ok",true)),"insufficient service exact rejection")
 check(not bool(parity(base,"buy","unknown").get("ok",true)),"unknown item exact rejection")
 check(not bool(parity(base,"service","amp").get("ok",true)),"unowned service exact rejection")
 rejected(base,"invented","amp")
 check(not bool(parity(bought.state,"assign","amp",2).get("ok",true)),"drummer incompatible with original amp")
 check(not bool(parity(bought.state,"assign","amp",-1).get("ok",true)),"negative member index rejected")
 check(not bool(parity(bought.state,"assign","amp",99).get("ok",true)),"out-of-range member index rejected")

func case_compatibility_and_lead() -> void:
 var before: Dictionary = base.duplicate(true)
 var saved := disk_files()
 check(Bridge.compatible(base,"amp",0) and Bridge.compatible(base,"amp",1),"original guitar/bass amp compatibility")
 check(Bridge.compatible(base,"drums",2) and not Bridge.compatible(base,"amp",2),"original drums role compatibility")
 check(Bridge.compatible(base,"mics",0) and Bridge.compatible(base,"pa",0),"explicit selected instrumental lead is eligible for voice gear")
 check(not Bridge.compatible(base,"mics",1) and not Bridge.compatible(base,"pa",2),"non-lead instrumentalists never gain vocal compatibility")
 check(not Bridge.compatible(base,"unknown",0) and not Bridge.compatible(base,"amp",-1) and not Bridge.compatible(base,"amp",99),"unknown item/member compatibility rejects safely")
 check(base==before and disk_files()==saved,"compatibility read has no mutation or save")
 var bought := parity(base,"buy","mics")
 if not bool(bought.get("ok",false)): return
 var source: Dictionary = bought.state
 # Independent oracle: run the original resolver over one temporary Singer
 # role, then restore canonical member/holder roles BEFORE the original chain.
 var proxy: Dictionary = source.duplicate(true)
 proxy.members[0].role = "Singer"
 var raw: Dictionary = Gear.assign(proxy,"mics",0)
 if not check(bool(raw.get("ok",false)),"original role-only oracle accepts temporary Singer voice"): return
 var expected: Dictionary = raw.duplicate(true)
 expected.state.members = (source.members as Array).duplicate(true)
 expected.state.gear_records.mics.holder_role = str(source.members[0].role)
 expected.state = Life.refresh(Calendar.expire(Story.observe(source,expected.state,"gear:assign")))
 var assigned := dispatch(source,"assign","mics",0)
 if not check(assigned==expected and bool(assigned.get("ok",false)),"lead-voice adapter matches original resolver/settlement composition"): return
 var state: Dictionary = assigned.state
 check(state.members==source.members and str(state.members[0].role)=="Guitarist","voice projection never changes canonical runtime roles/members")
 check(str(state.gear_records.mics.holder_role)=="Guitarist" and Gear.holder_index(state,Gear.record(state,"mics"))==0,"holder metadata remains valid against canonical role")
 check(int(state.cash)==int(source.cash) and int(state.tour_day)==int(source.tour_day),"selected-voice assignment is free and instant")
 rejected(state,"assign","mics",0)
 rejected(source,"assign","mics",1)
 var no_lead: Dictionary = source.duplicate(true)
 no_lead.lead_vocal_candidate_id = ""
 check(not Bridge.compatible(no_lead,"mics",0),"no implicit Singer from an unassigned guitarist")
 rejected(no_lead,"assign","mics",0)
 var inactive: Dictionary = source.duplicate(true)
 inactive.members[0].life_status = "leave"
 inactive.members[0].available_day = 99
 rejected(inactive,"assign","mics",0)
 var stale_role: Dictionary = state.duplicate(true)
 stale_role.gear_records.mics.holder_role = "Singer"
 var stale_before: Dictionary = stale_role.duplicate(true)
 check(Gear.holder_index(stale_role,Gear.record(stale_role,"mics"))==-1,"Singer holder role is genuinely stale against canonical Guitarist")
 check(Bridge.compatible(stale_role,"mics",0) and stale_role==stale_before,"compatibility does not repair or adopt stale holder record")
 var fresh_assignment := dispatch(stale_role,"assign","mics",0)
 check(bool(fresh_assignment.get("ok",false)) and str(fresh_assignment.state.gear_records.mics.holder_role)=="Guitarist" and Gear.holder_index(fresh_assignment.state,Gear.record(fresh_assignment.state,"mics"))==0,"only explicit assignment replaces stale projected-holder metadata")
 var replacement: Dictionary = state.duplicate(true)
 replacement.members[0] = model.game._member(model.game.person_by_id("cast_ryan"),0)
 check(Gear.holder_index(replacement,Gear.record(replacement,"mics"))==-1 and not Bridge.compatible(replacement,"mics",0),"actual canonical replacement cannot inherit Jack's gear or lead designation")
 rejected(replacement,"assign","mics",0)

func case_lifecycle_and_story() -> void:
 var state: Dictionary = base.duplicate(true)
 state.van_health = 10
 state.tension = 70
 state.members[1].life_status = "leave"
 state.members[1].available_day = int(state.tour_day)+1
 var result := parity(state,"buy","amp")
 if not check(bool(result.get("ok",false)),"lifecycle fixture purchase succeeds"): return
 var next: Dictionary = result.state
 check(str(next.members[1].life_status)=="active" and not next.members[1].has("available_day"),"original Life.refresh returns an existing member on the committed day")
 check(str(state.members[1].life_status)=="leave" and state.members[1].has("available_day"),"life refresh leaves prior member state immutable")
 var ids: Array = []
 for entry in next.get("career_journal",[]): ids.append(str(entry.get("id","")))
 check(ids.count("van_crisis")==1 and ids.count("band_fracture")==1,"original Story.observe milestones retain exact once-only semantics")
 var again := parity(next,"buy","mics")
 if not bool(again.get("ok",false)): return
 ids.clear()
 for entry in again.state.get("career_journal",[]): ids.append(str(entry.get("id","")))
 check(ids.count("van_crisis")==1 and ids.count("band_fracture")==1,"later gear action does not duplicate milestone history")

func case_show_day_and_expiry() -> void:
 var booking: Dictionary = Calendar.book(base,"local","tight")
 if not check(bool(booking.get("ok",false)),"actual original calendar builds booking fixture"): return
 var show: Dictionary = booking.state.duplicate(true)
 show.tour_day = int(Calendar.pending(show).day)
 check(Bridge.show_day(show) and not Bridge.show_day(base),"show-day predicate agrees with actual pending calendar")
 rejected(show,"buy","amp")
 var owned: Dictionary = Gear.buy(base,"amp").state
 owned.booked_show = Calendar.pending(show)
 owned.tour_day = int(show.tour_day)
 check(Bridge.show_day(owned),"owned fixture is actual show day")
 rejected(owned,"assign","amp",0)
 rejected(owned,"service","amp")
 var overdue: Dictionary = booking.state.duplicate(true)
 overdue.tour_day = int(Calendar.pending(overdue).day)+1
 overdue.reputation = 20
 var old_morale: int = int(overdue.morale)
 check(not Bridge.show_day(overdue),"overdue day is not falsely locked as show day")
 var result := parity(overdue,"buy","amp")
 if not check(bool(result.get("ok",false)),"overdue fixture can run original gear settlement"): return
 var next: Dictionary = result.state
 check(Calendar.pending(next).is_empty() and int(next.reputation)==12 and int(next.morale)==old_morale-6,"original Calendar.expire applies one missed-show penalty")
 var ids: Array = []
 for entry in next.get("career_journal",[]): ids.append(str(entry.get("id","")))
 var missed_id := "missed:%d:local" % int(Calendar.pending(overdue).day)
 check(ids.count(missed_id)==1,"one missed-show journal entry")
 var second := parity(next,"buy","mics")
 if not bool(second.get("ok",false)): return
 ids.clear()
 for entry in second.state.get("career_journal",[]): ids.append(str(entry.get("id","")))
 check(ids.count(missed_id)==1 and int(second.state.reputation)==12 and int(second.state.morale)==old_morale-6,"later successful action cannot expire the same booking twice")
 var invalid_overdue: Dictionary = overdue.duplicate(true)
 invalid_overdue.cash = 0
 var untouched: Dictionary = invalid_overdue.duplicate(true)
 rejected(invalid_overdue,"buy","amp")
 check(invalid_overdue==untouched and not Calendar.pending(invalid_overdue).is_empty(),"failed gear action cannot settle unrelated overdue booking")

func case_unknown_condition() -> void:
 var legacy: Dictionary = base.duplicate(true)
 legacy.owned_equipment = ["amp"]
 var before: Dictionary = legacy.duplicate(true)
 var record: Dictionary = Gear.record(legacy,"amp")
 check(int(record.condition)==-1 and int(record.holder_index)==-1 and legacy==before,"legacy inspection leaves unknown condition/ownership truthful and immutable")
 var result := parity(legacy,"service","amp")
 if not check(bool(result.get("ok",false)),"original unknown equipment can be assessed"): return
 check(int(result.state.gear_records.amp.condition)==80 and int(result.state.cash)==225 and int(result.state.tour_day)==2,"original assessment condition80 costs25 and1day")
 var perfect: Dictionary = result.state.duplicate(true)
 perfect.gear_records.amp.condition = 100
 check(not bool(parity(perfect,"service","amp").get("ok",true)),"already perfect equipment cannot be serviced again")
 check(not bool(parity(legacy,"service","unknown").get("ok",true)),"unknown service item rejects without repair")

func case_c27_save_roundtrip() -> void:
 var source: Dictionary = base.duplicate(true)
 source.s45_passthrough = {"note":"QA future fields survive","integer":7,"truth":true,"nested":["original",{"unknown":42}]}
 var initial_snapshot: Dictionary = model.snapshot()
 var bought := dispatch(source,"buy","mics")
 if not bool(bought.get("ok",false)): return
 var assigned := dispatch(bought.state,"assign","mics",0)
 if not bool(assigned.get("ok",false)): return
 model.game.career = assigned.state.duplicate(true)
 if not check(model.save_draft(),"explicit C27 owner save writes current bridge result"): return
 var saved := FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)
 var resumed := OpeningModel.new()
 if not check(resumed.load_draft() and resumed.snapshot()==model.snapshot(),"actual C27 file roundtrip retains exact gear/voice/unknown state"): return
 check(resumed.game.career.s45_passthrough==source.s45_passthrough and str(resumed.game.career.members[0].role)=="Guitarist","unknown fields and canonical role survive file reload")
 check(Gear.holder_index(resumed.game.career,Gear.record(resumed.game.career,"mics"))==0,"canonical mic holder remains valid after reload")
 for key in ["schema_version","screen","lead_vocal_id","formed_once","change_counter","name_offer","name_locked","name_settled","name_delta","logo","palette","vibe","identity_complete"]:
  check(resumed.snapshot().get(key)==initial_snapshot.get(key),"gear adapter preserves existing C27 envelope field "+key)
 for key in ["band_name","genre","lead_vocal_candidate_id","lead_vocal_stats","name_chemistry_delta","logo","palette","vibe","action_count","action_counters","song_catalogue","current_song_draft","song_draft_progress"]:
  check(resumed.game.career.get(key)==source.get(key),"gear adapter preserves unrelated career field "+key)
 rejected(resumed.game.career,"assign","mics",0)
 check(FileAccess.get_file_as_bytes(OpeningModel.SAVE_PATH)==saved,"repeated assignment after reload does not write the saved career")

func run() -> void:
 var user_dir := ProjectSettings.globalize_path("user://")
 var output_path := ProjectSettings.globalize_path(output)
 var safe: bool = check(user_dir.begins_with(SAFE_ROOT) and output_path.begins_with(SAFE_ROOT),"fresh S45 XDG/output path guard before writes")
 for path in [OpeningModel.SAVE_PATH,"user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  safe = check(not FileAccess.file_exists(path),"fresh isolated fixture path "+path) and safe
 if not safe:
  print("S45_CAREER_BRIDGE_TEST_REFUSED ",JSON.stringify({"errors":failures,"user_data":user_dir}))
  quit(1)
  return
 output = output_path
 if not check(DirAccess.make_dir_recursive_absolute(output)==OK,"scratch test output directory"):
  quit(1)
  return
 protected_initial = disk_files(false)
 if fixture():
  for method in ["case_original_parity","case_compatibility_and_lead","case_lifecycle_and_story","case_show_day_and_expiry","case_unknown_condition","case_c27_save_roundtrip"]:
   call(method)
   if not failures.is_empty(): break
 check(disk_files(false)==protected_initial,"headless bridge proof never wrote original production/C26 save paths")
 var result: Dictionary = {"pass":failures.is_empty(),"checks":checks,"bridge_calls":bridge_calls,"errors":failures,"engine":Engine.get_version_info(),"user_data":user_dir,"actual_fixture":base,"observations":observations,"method":"HEADLESS genuine C27 model/save fixture; exact original Gear + Story.observe + Calendar.expire + Life.refresh oracle; explicit selected-voice adapter edge cases; no native input/device claim","bridge_resource":"res://experiments/playable_flightcase/career_bridge.gd","bridge_sha256":FileAccess.get_sha256("res://experiments/playable_flightcase/career_bridge.gd")}
 var receipt := FileAccess.open(output+"/result.json",FileAccess.WRITE)
 if receipt==null:
  push_error("S45_CAREER_BRIDGE_TEST could not write receipt")
  quit(1)
  return
 receipt.store_string(JSON.stringify(result,"  "))
 receipt.close()
 print("S45_CAREER_BRIDGE_TEST_RESULT ",JSON.stringify(result))
 if failures.is_empty(): print("S45 CAREER BRIDGE TESTS PASSED")
 quit(0 if failures.is_empty() else 1)
