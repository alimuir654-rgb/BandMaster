extends SceneTree
## Independent S57 model/IO/font-chain proof. Root alone executes this script.
## No production userdata, UI input simulation, optical or device claim.
const Opening = preload("res://experiments/playable_flightcase/opening_state.gd")
const Game = preload("res://experiments/playable_flightcase/session.gd")
const Names = preload("res://experiments/playable_flightcase/name_rules.gd")
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const SAFE := "/workspace/work/identity-20261101/s57/"
const TRIO := ["cast_jack","cast_zoe","cast_casey"]
const ADORED := ["cast_jack","cast_ben","cast_marcus"]
const FONTS := ["blockprint","condensed","handpainted","mono"]
const INKS := ["charcoal","ivory","oxblood","burnt_amber","faded_teal","cobalt","forest","muted_violet"]
const LOOK := {"logo":"Stamp","palette":"White / Ink","vibe":"Atmospheric"}
# Explicit independently inventoried font-intake set; this tests the chain,
# not that any single primary face contains all glyphs or shapes all languages.
const GLYPHS := [0x00A3,0x0027,0x2019,0x2018,0x2014,0x2013,0x2022,0x2192,0x2713,0x00E9,0x00C9,0x00E1,0x00C1,0x00F6,0x00D6,0x00FC,0x00DC,0x00E7,0x00C7,0x00F1,0x00D1,0x00E5,0x00C5,0x00F8,0x00D8,0x00DF,0x1E9E,0x0153,0x0152,0x0142,0x0141,0x0159,0x0158,0x011B,0x011A,0x0107,0x0106,0x011F,0x011E,0x0130,0x0131,0x03A9,0x0394,0x03A3,0x03B1,0x03B2,0x03B3,0x0416,0x042F,0x0414,0x0430,0x0431,0x0432,0x96E8,0x0301]

class CountingOpening extends Opening:
 var saves: int=0
 var loads: int=0
 func save_draft() -> bool:
  saves+=1
  return super.save_draft()
 func load_draft() -> bool:
  loads+=1
  return super.load_draft()

var checks: int=0
var failures: Array[String]=[]
var evidence: Array=[]
var protected_initial: Dictionary={}

func _init() -> void:
 call_deferred("run")

func verify(ok: bool, message: String) -> bool:
 checks+=1
 if not ok:
  failures.append(message)
  push_error("S57_IDENTITY_TEST "+message)
 return ok

func okay(value: Variant) -> bool:
 return bool(value.get("ok",false)) if value is Dictionary else value is bool and value

func typed_equal(left: Variant, right: Variant) -> bool:
 if typeof(left)!=typeof(right):return false
 if left is Dictionary:
  if left.size()!=right.size():return false
  for key in left:
   if not right.has(key) or not typed_equal(left[key],right[key]):return false
  return true
 if left is Array:
  if left.size()!=right.size():return false
  for index in range(left.size()):
   if not typed_equal(left[index],right[index]):return false
  return true
 return left==right

func disk() -> PackedByteArray:
 return FileAccess.get_file_as_bytes(Opening.SAVE_PATH) if FileAccess.file_exists(Opening.SAVE_PATH) else PackedByteArray()

func protected_files() -> Dictionary:
 var result: Dictionary={}
 for path in ["user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  result[path]=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
 return result

func named_fixture(ids: Array=TRIO) -> CountingOpening:
 var model: CountingOpening=CountingOpening.new()
 for action in [model.begin_new,model.set_genre.bind("Post-punk"),model.to_recruit]:
  if not verify(okay(action.call()),"genuine C27 initial fixture step"):return null
 for id in ids:
  if not verify(okay(model.recruit(str(id))),"genuine C27 selected identity "+str(id)):return null
 for action in [model.choose_vocal.bind("cast_jack"),model.confirm_lineup,model.start_naming]:
  if not verify(okay(action.call()),"genuine C27 naming fixture step"):return null
 return model

func identity_fixture(intent: String="Playful", ids: Array=TRIO) -> CountingOpening:
 var model: CountingOpening=named_fixture(ids)
 if model==null:return null
 for action in [model.submit_name.bind("Étoile Noire",intent),model.lock_name,model.start_identity]:
  if not verify(okay(action.call()),"genuine C27 identity fixture step"):return null
 return model

func no_change(model: CountingOpening, action: Callable, label: String) -> void:
 var before: Dictionary=model.snapshot().duplicate(true)
 var bytes: PackedByteArray=disk()
 var calls: int=model.saves
 verify(not okay(action.call()),label+" rejects")
 verify(typed_equal(model.snapshot(),before),label+" preserves whole typed snapshot")
 verify(disk()==bytes and model.saves==calls,label+" performs no save and preserves old bytes")

func blocked_save(model: CountingOpening, action: Callable, label: String) -> bool:
 var temporary: String=ProjectSettings.globalize_path(Opening.SAVE_PATH+".identity-tmp")
 if not verify(not FileAccess.file_exists(temporary) and not DirAccess.dir_exists_absolute(temporary),label+" uses a fresh temporary path"):return false
 var before: Dictionary=model.snapshot().duplicate(true)
 var bytes: PackedByteArray=disk()
 var game_object: Object=model.game
 var calls: int=model.saves
 if not verify(DirAccess.make_dir_absolute(temporary)==OK,label+" creates an actual isolated temporary-directory blocker"):return false
 var result: Variant=action.call()
 # Remove ONLY the empty directory created above, including on a failed check.
 var removed: Error=DirAccess.remove_absolute(temporary)
 verify(removed==OK,label+" removes only its own empty blocker")
 verify(not okay(result),label+" reports the actual FileAccess failure")
 verify(model.saves==calls+1,label+" attempts one real super.save_draft call")
 verify(model.game==game_object and typed_equal(model.snapshot(),before),label+" rolls back the whole typed state on the same game object")
 verify(disk()==bytes,label+" preserves the previous valid file byte-for-byte")
 verify(not FileAccess.file_exists(temporary) and not DirAccess.dir_exists_absolute(temporary),label+" leaves no temporary artifact")
 evidence.append({"case":label,"actual_save_attempts":model.saves-calls,"old_bytes_preserved":disk()==bytes})
 return failures.is_empty()

func case_tastes_and_name_boundaries() -> void:
 # Exact independently authored expectations, not a calculation copied from
 # lock_name. The complete catalogue is a data fixture, not a playable roster.
 var rows: Array=Cast.people()
 if verify(rows.size()==18,"the approved source taste fixture has eighteen canonical IDs"):
  var counts: Dictionary={"Raw":[8,3,7],"Dark":[5,2,11],"Playful":[1,9,8],"Dreamy":[4,4,10]}
  for intent in ["Raw","Dark","Playful","Dreamy"]:
   var got: Array=[0,0,0]
   for raw in Names.reactions(rows,intent,"Post-punk"):
    var row: Dictionary=raw
    var position: int=["love","dislike","accept"].find(str(row.get("reaction","")))
    if position>=0:got[position]+=1
   verify(got==counts[intent],"original eighteen-source taste counts remain exact for "+intent)
 var model: CountingOpening=named_fixture()
 if model==null:return
 for invalid in [" ","X".repeat(37),"BAD\nNAME"]:
  no_change(model,model.submit_name.bind(invalid,"Raw"),"invalid name boundary")
 no_change(model,model.submit_name.bind("Valid name","not-an-intent"),"unknown original naming intent")
 var calls: int=model.saves
 verify(okay(model.submit_name("Étoile Noire","Playful")) and model.saves==calls+1,"Unicode proposal saves once")
 var expected: Array=["dislike","dislike","accept"]
 var reactions: Array=model.name_reactions()
 verify(reactions.size()==3,"one original reaction per actual chosen member")
 if reactions.size()==3:
  for index in range(3):verify(reactions[index].get("id")==TRIO[index] and reactions[index].get("reaction")==expected[index],"original trio taste is independent of font/name spelling")
 var before: Dictionary=model.snapshot().duplicate(true)
 var bytes: PackedByteArray=disk()
 calls=model.saves
 verify(okay(model.submit_name("éTOILE nOIRE","Playful")),"case-insensitive repeated proposal is accepted as the same idea")
 verify(typed_equal(model.snapshot(),before) and disk()==bytes and model.saves==calls,"same proposal cannot reroll, save or increment counters")
 if not blocked_save(model,model.rethink_name,"blocked rethink"):return
 calls=model.saves
 verify(okay(model.rethink_name()) and model.name_revisions==1 and model.name_offer.is_empty() and model.saves==calls+1,"retry consumes the one free rethink once")
 no_change(model,model.lock_name,"blank proposal cannot lock")
 verify(okay(model.submit_name("Étoile Noire","Playful")),"genuine second proposal")
 no_change(model,model.rethink_name,"second rethink stays refused")
 if not blocked_save(model,model.lock_name,"blocked name lock"):return
 calls=model.saves
 verify(okay(model.lock_name()) and model.saves==calls+1 and model.name_delta==-2 and model.screen=="name_milestone","lock retry saves once with exact original minus-two consequence")
 no_change(model,model.lock_name,"repeated successful name lock")
 var loaded: CountingOpening=CountingOpening.new()
 verify(loaded.load_draft() and typed_equal(loaded.snapshot(),model.snapshot()),"actual disk resumes the named milestone without reroll")
 var proposal: CountingOpening=named_fixture()
 if proposal!=null:
  blocked_save(proposal,proposal.submit_name.bind("Saved idea","Raw"),"blocked first proposal")

func formation_oracle(model: CountingOpening, style: Dictionary, delta: int, look: Dictionary) -> Dictionary:
 # The protected original formation module supplies every other career field.
 var original=Game.new()
 original.genre=model.game.genre
 original.roster=model.game.roster.duplicate(true)
 original.phase=model.game.phase
 original.career=model.game.career.duplicate(true)
 var person: Dictionary=original.person_by_id("cast_jack")
 var result: Dictionary=original.launch_with_vocals("cast_jack",model.vocal_scores(person))
 if not verify(okay(result),"protected original formation oracle accepts the genuine trio"):return {}
 var career: Dictionary=original.career.duplicate(true)
 career["band_name"]="Étoile Noire"
 career["morale"]=55+delta
 career["name_chemistry_delta"]=delta
 for member in career["members"]:member["morale"]=55+delta
 for field in ["logo","palette","vibe"]:career[field]=look[field]
 if not style.is_empty():career[Style.KEY]=style.duplicate(true)
 return career

func case_all_styles_and_reload() -> void:
 verify(Style.FONTS==FONTS and Style.INKS==INKS,"four declared type directions and eight declared inks remain available")
 var finishes: int=0
 for font_id in FONTS:
  for ink_id in INKS:
   var model: CountingOpening=identity_fixture()
   if model==null:return
   var style: Dictionary={"version":1,"font":font_id,"ink":ink_id}
   var immutable_style: Dictionary=style.duplicate(true)
   var before: Dictionary=model.snapshot().duplicate(true)
   var bytes: PackedByteArray=disk()
   var calls: int=model.saves
   var preview: Dictionary=Style.effective(style)
   preview["qa_free_preview"]={"nested":[7]}
   verify(typed_equal(model.snapshot(),before) and disk()==bytes and model.saves==calls and style==immutable_style,"free style query has no model, save, alias or taste effects")
   var expected: Dictionary=formation_oracle(model,style,-2,LOOK)
   var result: Dictionary=model.finish_identity(style,LOOK)
   if not verify(okay(result),"finish genuine identity for "+font_id+"/"+ink_id):return
   finishes+=1
   verify(model.saves==calls+1 and model.screen=="complete" and model.identity_complete,"one explicit finish saves once and advances once")
   verify(model.game.career==expected,"style changes only declared identity fields over original formation, including exact minus-two morale")
   verify(model.game.career["cash"]==250 and model.game.career["tour_day"]==1 and model.game.career["readiness"]==18 and model.change_counter==before["change_counter"],"all cosmetic combinations preserve original money, day, readiness and counters")
   verify(model.identity_style==style and model.game.career[Style.KEY]==style and style==immutable_style,"committed style is copied consistently without mutating caller")
   var saved: Dictionary=model.snapshot().duplicate(true)
   var saved_bytes: PackedByteArray=disk()
   no_change(model,model.finish_identity.bind(style,LOOK),"duplicate identity finish")
   verify(disk()==saved_bytes,"duplicate cannot replace even identical valid bytes")
   var loaded: CountingOpening=CountingOpening.new()
   verify(loaded.load_draft() and typed_equal(loaded.snapshot(),saved),"actual JSON disk roundtrip preserves completed style and original roster")
   calls=loaded.saves
   verify(loaded.start_playing() and loaded.saves==calls+1,"actual saved identity enters first practice once")
   no_change(loaded,loaded.start_playing,"repeated completed handoff")
   var playing: CountingOpening=CountingOpening.new()
   verify(playing.load_draft() and typed_equal(playing.snapshot(),loaded.snapshot()) and playing.game.career["morale"]==53,"play Continue preserves style and one original penalty")
 verify(finishes==32,"all four by eight style combinations completed real save and reload")

func case_legacy_unknown_and_invalid() -> void:
 var legacy: CountingOpening=identity_fixture("Raw",ADORED)
 if legacy==null:return
 verify(legacy.name_delta==3,"Jack, Ben and Marcus genuinely love Raw for exact plus-three consequence")
 for values in [["Novel logo","White / Ink","Atmospheric"],["Stamp","new hex palette","Atmospheric"],["Stamp","White / Ink","new vibe"]]:
  no_change(legacy,legacy.set_identity.bind(values[0],values[1],values[2]),"legacy strict identity enum")
 verify(legacy.set_identity("Monogram","Red / Black","Wry"),"legacy three-argument identity API still saves")
 var expected: Dictionary=formation_oracle(legacy,{},3,{"logo":"Monogram","palette":"Red / Black","vibe":"Wry"})
 verify(okay(legacy.finish_identity()) and legacy.game.career==expected,"no-argument legacy finish retains original plus-three formation")
 verify(not legacy.snapshot().has(Style.KEY) and not legacy.game.career.has(Style.KEY),"legacy absent style remains absent in schema1")
 var old: Dictionary=legacy.snapshot().duplicate(true)
 var loaded: CountingOpening=CountingOpening.new()
 verify(loaded.load_draft() and typed_equal(loaded.snapshot(),old),"legacy absent-style actual disk reload is unchanged")
 var model: CountingOpening=identity_fixture()
 if model==null:return
 var style: Dictionary={"version":1,"font":"mono","ink":"muted_violet","future_extension":{"author":"unknown","tokens":[3,{"keep":true}]}}
 verify(okay(model.finish_identity(style,LOOK)),"unknown nested style extensions are accepted alongside valid known fields")
 model.game.career["qa_unknown_career"]={"future":[4,{"keep":"original"}]}
 verify(model.save_draft(),"save unknown nested career extension through real schema1 IO")
 var complete: Dictionary=model.snapshot().duplicate(true)
 loaded=CountingOpening.new()
 verify(loaded.load_draft() and typed_equal(loaded.snapshot(),complete),"unknown style and career extensions survive actual disk reload")
 var copy: Dictionary=loaded.snapshot()
 copy[Style.KEY]["future_extension"]["tokens"].append(99)
 copy["game"]["career"]["qa_unknown_career"]["future"].append(99)
 verify(typed_equal(loaded.snapshot(),complete),"returned snapshots never alias nested style or career data")
 verify(loaded.restore(old) and typed_equal(loaded.snapshot(),old),"restoring a legacy snapshot clears an earlier styled identity rather than leaking stale style")
 var pristine: Dictionary=loaded.snapshot().duplicate(true)
 var bytes: PackedByteArray=disk()
 var malformed: Array=[null,[],false,3,{}, {"version":2,"font":"mono","ink":"charcoal"},{"version":1.0,"font":"mono","ink":"charcoal"},{"version":true,"font":"mono","ink":"charcoal"},{"version":1,"font":"unknown","ink":"charcoal"},{"version":1,"font":"mono","ink":{}},{"version":1,"font":[],"ink":"charcoal"}]
 for value in malformed:
  verify(not Style.valid(value),"malformed present cosmetic token is not treated as a valid style")
  var bad: Dictionary=pristine.duplicate(true)
  bad[Style.KEY]=value
  verify(not loaded.restore(bad) and typed_equal(loaded.snapshot(),pristine) and disk()==bytes,"malformed/future outer style refuses restore without mutation or IO")
 for location in ["missing_career","missing_outer","mismatch","bad_career"]:
  var bad: Dictionary=complete.duplicate(true)
  if location=="missing_career":bad["game"]["career"].erase(Style.KEY)
  elif location=="missing_outer":bad.erase(Style.KEY)
  elif location=="mismatch":bad["game"]["career"][Style.KEY]["ink"]="forest"
  else:bad["game"]["career"][Style.KEY]="corrupt"
  verify(not loaded.restore(bad) and typed_equal(loaded.snapshot(),pristine),"inconsistent committed style is rejected atomically: "+location)

func case_failures_and_retry() -> void:
 var model: CountingOpening=identity_fixture()
 if model==null:return
 var before: Dictionary=model.snapshot().duplicate(true)
 for bad in [{"version":2,"font":"mono","ink":"charcoal"},{"version":1,"font":"missing","ink":"charcoal"}]:
  no_change(model,model.finish_identity.bind(bad,LOOK),"invalid style finish")
 no_change(model,model.finish_identity.bind(Style.defaults(),{"logo":"Wordmark","palette":"wrong","vibe":"Wry"}),"invalid legacy look at finish")
 model.game.phase="play"
 no_change(model,model.finish_identity.bind(Style.defaults(),LOOK),"controlled authoritative formation failure with invalid pre-phase")
 model.game.phase="recruit"
 verify(typed_equal(model.snapshot(),before),"controlled bad-phase fixture restores its own precondition")
 # Opaque in-memory fields expose rollback canonicalisation/type loss. They
 # are injected AFTER the valid disk save, and are never a legacy-save claim.
 model.game.roster[0]["qa_opaque"]={"integer":4,"whole_float":4.0,"fraction":1.5}
 model.game.career["qa_opaque"]={"future":[2,{"keep":true}]}
 var style: Dictionary={"version":1,"font":"handpainted","ink":"cobalt","future_extension":{"keep":[1,2]}}
 var caller_style: Dictionary=style.duplicate(true)
 if not blocked_save(model,model.finish_identity.bind(style,LOOK),"blocked identity finish"):return
 verify(style==caller_style,"failed identity finish retains the caller's independent pending design")
 var calls: int=model.saves
 var expected: Dictionary=formation_oracle(model,style,-2,LOOK)
 verify(okay(model.finish_identity(style,LOOK)) and model.saves==calls+1 and model.game.career==expected,"one retry after real disk failure settles the original formation/morale once")
 no_change(model,model.finish_identity.bind(style,LOOK),"duplicate after successful identity retry")
 var loaded: CountingOpening=CountingOpening.new()
 verify(loaded.load_draft() and loaded.game.career==expected and loaded.identity_style==caller_style,"retry result is an actual valid saved identity")

func no_system_fallback(font: Font, visited: Dictionary, label: String) -> void:
 if font==null:
  verify(false,label+" contains no null font")
  return
 var id: int=font.get_instance_id()
 if visited.has(id):return
 visited[id]=true
 if font is FontFile:verify(not (font as FontFile).allow_system_fallback,label+" explicit FontFile disables OS fallback")
 if font is FontVariation:
  var variation: FontVariation=font as FontVariation
  no_system_fallback(variation.base_font,visited,label)
 for fallback in font.fallbacks:no_system_fallback(fallback,visited,label)

func case_font_chains_and_mark_text() -> void:
 verify(GLYPHS.size()==55,"explicit independently inventoried glyph set contains55 codepoints")
 var present: bool=true
 for font_id in FONTS:present=verify(ResourceLoader.exists(str(Style.FONT_FILES[font_id])),"required bundled face exists for "+font_id) and present
 for path in ["res://experiments/playable_flightcase/fonts/DejaVuSansMono.ttf","res://experiments/playable_flightcase/fonts/identity/NotoSansSC.ttf"]:
  present=verify(ResourceLoader.exists(path),"explicit fallback source exists") and present
 if not present:return
 var approved: Array=Cast.people()
 var distinct: Dictionary={}
 for ink_id in INKS:
  var colour: Color=Style.ink({"version":1,"font":"blockprint","ink":ink_id})
  verify(colour.a==1.0 and not distinct.has(colour.to_html()),"each of eight actual ink choices is opaque and distinct")
  distinct[colour.to_html()]=true
 for font_id in FONTS:
  var face: Font=Style.face({"version":1,"font":font_id,"ink":"charcoal"})
  if not verify(face!=null,"font chain loads for "+font_id):continue
  var missing: Array=[]
  for code in GLYPHS:
   if not face.has_char(int(code)):missing.append(code)
  verify(missing.is_empty(),font_id+" complete explicit55 glyph chain coverage; missing="+str(missing))
  missing=[]
  for code in range(32,127):
   if not face.has_char(code):missing.append(code)
  verify(missing.is_empty(),font_id+" ASCII chain coverage; missing="+str(missing))
  missing=[]
  for person in approved:
   var name: String=str(person.get("name",""))
   for index in range(name.length()):
    var code: int=name.unicode_at(index)
    if not face.has_char(code) and not missing.has(code):missing.append(code)
  verify(missing.is_empty(),font_id+" covers actual approved musician names; missing="+str(missing))
  no_system_fallback(face,{},font_id)
 verify(Style.mark_text("Étoile Noire","Wordmark")=="ÉTOILE NOIRE","native wordmark uses the actual Unicode name")
 verify(Style.mark_text("Étoile Noire","Stamp")=="— ÉTOILE NOIRE —","native stamp retains the full Unicode name")
 verify(Style.mark_text("Étoile Noire","Monogram")=="ÉN","native monogram uses source-name initials")

func run() -> void:
 var userdata: String=ProjectSettings.globalize_path("user://")
 if not verify(userdata.begins_with(SAFE),"REFUSE default/production userdata; explicit fresh S57 XDG is required"):
  finish()
  return
 for path in [Opening.SAVE_PATH,Opening.SAVE_PATH+".identity-tmp","user://tour_save.json","user://band_profile.json","user://player_profile.json","user://c26_playable_sandbox.json"]:
  verify(not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)),"fresh isolated file/directory precondition: "+path)
 if not failures.is_empty():
  finish()
  return
 protected_initial=protected_files()
 for test_case in [case_tastes_and_name_boundaries,case_all_styles_and_reload,case_legacy_unknown_and_invalid,case_failures_and_retry,case_font_chains_and_mark_text]:
  test_case.call()
  if not failures.is_empty():break
 verify(protected_files()==protected_initial,"original production-profile/legacy/C26 bytes remain untouched")
 verify(not FileAccess.file_exists(Opening.SAVE_PATH+".identity-tmp") and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(Opening.SAVE_PATH+".identity-tmp")),"all actual IO attempts leave no temporary identity artifact")
 finish()

func finish() -> void:
 print("S57_IDENTITY_RESULT ",JSON.stringify({"pass":failures.is_empty(),"checks":checks,"failures":failures,"errors":failures,"engine":Engine.get_version_info(),"evidence":evidence,"coverage":"Independent authored taste counts and literal +/-morale over original formation;4x8actual save/reload/duplicate identity cases;legacy absence/enums;unknown nested style/career;malformed present style;controlled original-launch failure;real temporary-directory save failure/typed full rollback/retry;explicit55/ASCII/source-name font-chain coverage and every FontFile OS-fallback flag. No GUI geometry, optical shaping, device or crash-durability claim."}))
 quit(0 if failures.is_empty() else 1)
