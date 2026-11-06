extends RefCounted
## One authored arrangement palette. No runtime synthesis or objective music grading.
const VERSION := "producer_raw_dark_v2"
const Sound = preload("res://experiments/playable_flightcase/band_sound.gd")
const Mixing = preload("res://experiments/playable_flightcase/mixing_recipe.gd")
const MANIFEST := "res://experiments/playable_flightcase/audio/producer_raw_dark.json"
const STAGES := ["FIND THE RIFF","BRING IN THE BAND","SHAPE THE CHORUS"]
const FIELDS := ["pace","energy","originality","theme"]
const VALUES := [["driving","urgent"],["open","full"],["familiar","angular"],["home","escape"]]
const TITLES := ["PACE","ENERGY","ORIGINALITY","LYRICAL DIRECTION"]
const LABELS := [["DRIVING","URGENT"],["OPEN","FULL"],["DIRECT","ANGULAR"],["HOME","ESCAPE"]]
const CRAFT := [0,1,1,0,2,0,-1,1,1,0,2,-1,0,1,-2,0]
const REASONS := [
 "The open pulse leaves a clear landing for the low-root phrase.",
 "The open pulse gives the unresolved phrase room to travel.",
 "The offbeat figure pulls against a familiar low-root cadence.",
 "Both the offbeat figure and unresolved ending leave the hook unsettled.",
 "The full backbeat supports a direct hook with a firm low-root landing.",
 "The full backbeat pushes forward while the ending stays open.",
 "Dense accompaniment competes with the offbeat low-root figure.",
 "The offbeat answers leave a useful gap in the full, outward-moving phrase.",
 "The quick pulse gives the open low-root hook a clear arc.",
 "A quick pulse and low phrase keep the open arrangement moving.",
 "The quick, spare backing makes room for the angular answering hook.",
 "Quick syncopation and an unresolved ending can obscure the main hook.",
 "The urgent full arrangement needs a clean low-root landing.",
 "The direct low hook cuts through the urgent full backing.",
 "The busy backing crowds the quick offbeat low-root phrase.",
 "The busy outward phrase depends on keeping its answering gaps clear."
]

static func valid(value: Variant) -> bool:
 if value is Dictionary and value.get("version")==3:return Mixing.valid(value)
 if not value is Dictionary or value.size()!=9:return false
 if not (value.get("version") is int or value.get("version") is float) or value.version!=2:return false
 if not value.get("palette") is String or not value.get("hook") is String:return false
 if value.get("palette")!="raw_dark_v1" or value.get("hook")!="low_riff_v1" or not Sound.supported(value.get("brief")):return false
 if not (value.get("stage") is int or value.get("stage") is float) or value.stage not in [0,1,2]:return false
 for i in range(4):
  if not value.get(FIELDS[i]) is String or value[FIELDS[i]] not in VALUES[i]:return false
 return true

static func recipe(index: int=4,brief: Dictionary={"genre":"Indie rock","name_intent":"Raw","vibe":"Unpolished"},stage: int=0) -> Dictionary:
 if index<0 or index>15 or not Sound.supported(brief) or stage not in [0,1,2]:return {}
 var result: Dictionary={"version":2,"palette":"raw_dark_v1","hook":"low_riff_v1","brief":brief.duplicate(true),"stage":stage}
 for i in range(4):result[FIELDS[i]]=VALUES[i][(index>>(3-i))&1]
 return result

static func audio_id(value: Dictionary) -> String:
 if Mixing.valid(value):return "mix_"+Mixing.scenario_key(value)
 return "raw_s%d_%02d" % [int(value.stage),index(value)] if valid(value) else ""

static func written(value: Dictionary) -> String:
 if Mixing.valid(value):return Mixing.written(value)
 if not valid(value):return "The saved arrangement needs review."
 var pace: String="104 BPM" if value.pace=="driving" else "132 BPM"
 var pulse: String="space between the low attacks" if value.energy=="open" else "a dense, locked low pulse"
 var phrase: String=("offbeat accents and clipped answer figures" if int(value.stage)==2 else "offbeat low accents") if value.originality=="angular" else "a recurring direct low riff"
 var ending: String="lands back on D, with the same dark weight" if value.theme=="home" else "leaves on C, still unresolved"
 var layer: String=["Distorted low guitar on its own","The same riff with bass and drums","The same band arrangement with a low chorus answer"][int(value.stage)]
 return "%s. %s; %s; %s. The ending %s." % [layer,pace,pulse,phrase,ending]

static func index(value: Dictionary) -> int:
 if Mixing.valid(value):return Mixing.index(value)
 if not valid(value):return -1
 var result:=0
 for i in range(4):result=result*2+VALUES[i].find(value[FIELDS[i]])
 return result

static func material(value: Dictionary) -> Dictionary:
 if Mixing.valid(value):return Mixing.material(value)
 if not valid(value):return {}
 var home: bool=value.theme=="home"
 return {"lines":[{"id":"hook:1","text":"Home as a place you cannot quite return to" if home else "Escape without a clean way out"},{"id":"hook:2","text":"Return to the low D with its weight intact" if home else "Leave the low C unresolved"}],"refrain_line_id":"hook:2","sections":{"verse":"hook:1","chorus":"hook:2"},"producer_recipe":value.duplicate(true)}

static func material_matches(value: Dictionary) -> bool:
 if Mixing.valid(value.get("producer_recipe")):return Mixing.material_matches(value)
 if not valid(value.get("producer_recipe")):return false
 var authored:=material(value.producer_recipe)
 if not value.get("lines") is Array or value.lines.size()!=2 or not value.get("sections") is Dictionary:return false
 for i in range(2):
  if not value.lines[i] is Dictionary:return false
  for key in ["id","text"]:
   if not value.lines[i].get(key) is String or value.lines[i][key]!=authored.lines[i][key]:return false
 if not value.get("refrain_line_id") is String or value.refrain_line_id!=authored.refrain_line_id:return false
 for key in ["verse","chorus"]:
  if not value.sections.get(key) is String or value.sections[key]!=authored.sections[key]:return false
 return true

static func skills_ok(state: Dictionary) -> bool:
 if not state.get("members") is Array:return false
 var count:=0
 for person in state.members:
  if not person is Dictionary:return false
  if person.get("life_status","active")!="active":continue
  var skill=person.get("skill")
  if not (skill is int or skill is float) or not is_finite(float(skill)) or float(skill)!=floor(float(skill)) or float(skill)<0 or float(skill)>100:return false
  count+=1
 return count>0

static func craft(state: Dictionary,value: Dictionary) -> Dictionary:
 if Mixing.valid(value):return Mixing.craft(state,value)
 if not valid(value) or not skills_ok(state):return {"ok":false}
 var sum:=0;var count:=0
 for person in state.members:
  if person.get("life_status","active")=="active":sum+=int(person.skill);count+=1
 var mean: float=float(sum)/count
 var capacity: int=1+int(mean>=35)+int(mean>=55)+int(mean>=75)
 var demand: int=1+VALUES[0].find(value.pace)+VALUES[1].find(value.energy)+VALUES[2].find(value.originality)
 var id:=index(value)
 return {"ok":true,"model":"producer_raw_craft_v2","delta":clampi(int(CRAFT[id])-absi(capacity-demand),-3,3),"capacity":capacity,"demand":demand,"active_skill_sum":sum,"active_count":count,"reason":REASONS[id]}

static func summary(value: Dictionary) -> String:
 if Mixing.valid(value):return Mixing.summary(value)
 if not valid(value):return "Arrangement needs review"
 return "%s · %s · %s · %s" % [LABELS[0][VALUES[0].find(value.pace)],LABELS[1][VALUES[1].find(value.energy)],LABELS[2][VALUES[2].find(value.originality)],LABELS[3][VALUES[3].find(value.theme)]]

static func offer(value: Dictionary,respondent: Dictionary) -> Dictionary:
 if Mixing.valid(value):return Mixing.offer(value,respondent)
 if not valid(value) or respondent.is_empty():return {}
 var field: String=["energy","originality","theme"][int(value.stage)]
 var choices: Array=VALUES[FIELDS.find(field)]
 var choice: String=choices[1-choices.find(value[field])]
 var id: String=JSON.stringify([value.palette,value.hook,value.brief.genre,value.brief.name_intent,value.brief.vibe,int(value.stage),value.pace,value.energy,value.originality,value.theme,int(respondent.get("slot",-1)),str(respondent.get("member_id","")),str(respondent.get("candidate_id","")),str(respondent.get("name","")),str(respondent.get("bio_sha256",""))]).sha256_text()
 return {"kind":"raw_change","field":field,"value":choice,"stage":int(value.stage),"recipe":value.duplicate(true),"offer_id":id}

static func request_ok(request: Dictionary) -> bool:
 if Mixing.valid(request.get("recipe")):return Mixing.request_ok(request)
 if request.size()!=6 or not request.get("kind") is String or not request.get("field") is String or not request.get("value") is String or not request.get("offer_id") is String:return false
 if request.kind!="raw_change" or not valid(request.get("recipe")) or not (request.get("stage") is int or request.get("stage") is float):return false
 if request.stage!=request.recipe.stage or request.offer_id.length()!=64 or not request.offer_id.is_valid_hex_number(false):return false
 var field: String=request.field
 return field in FIELDS and request.value in VALUES[FIELDS.find(field)] and request.value!=request.recipe[field]

static func note(respondent: Dictionary,value: Dictionary,context: Dictionary) -> Dictionary:
 if Mixing.valid(value):return Mixing.note(respondent,value,context)
 if not valid(value):return {"ok":false,"message":"This arrangement needs review."}
 var request: Dictionary=offer(value,respondent)
 var suggestions: Dictionary={"energy":{"open":"Could we strip out some repeated attacks? Let the weight come from the gaps.","full":"Could the low riff hit harder, with a fuller pulse?"},"originality":{"familiar":"Could we bring the accents back onto a direct repeating phrase?","angular":"Could we clip the phrase and push a few accents off the beat?"},"theme":{"home":"Could we let it land back on the low D? Home can still feel uneasy.","escape":"Could we leave it hanging on C? It would feel like getting out without finding an answer."}}
 var text: String="Keep the low riff’s weight."
 if not request.is_empty():text+=" "+str(suggestions[request.field][request.value])+" Try it against your take, or read the difference and keep your direction."
 return {"ok":true,"message":"","note":{"text":text,"request":request,"source_kind":"authored","content_version":VERSION,"respondent_ref":respondent.duplicate(true),"day":int(context.day),"delivery":"written_note"}}
