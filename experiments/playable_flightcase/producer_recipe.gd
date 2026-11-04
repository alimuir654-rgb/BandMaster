extends RefCounted
## One authored arrangement palette. No runtime synthesis or objective music grading.
const VERSION := "producer_indie_v1"
const FIELDS := ["pace","energy","originality","theme"]
const VALUES := [["driving","urgent"],["open","full"],["familiar","angular"],["home","escape"]]
const TITLES := ["PACE","ENERGY","ORIGINALITY","LYRICAL DIRECTION"]
const LABELS := [["DRIVING","URGENT"],["OPEN","FULL"],["DIRECT","ANGULAR"],["HOME","ESCAPE"]]
const CRAFT := [0,1,1,0,2,0,-1,1,1,0,2,-1,0,1,-2,0]
const REASONS := [
 "The open pulse leaves a clear landing for the homeward phrase.",
 "The open pulse gives the rising, unresolved phrase room to travel.",
 "The offbeat figure pulls against a familiar homeward cadence.",
 "Both the offbeat figure and unresolved ending leave the hook unsettled.",
 "The full backbeat supports a direct hook with a firm homeward landing.",
 "The full backbeat pushes forward while the ending stays open.",
 "Dense accompaniment competes with the offbeat homeward figure.",
 "The offbeat answers leave a useful gap in the full, outward-moving phrase.",
 "The quick pulse gives the open homeward hook a clear arc.",
 "A quick pulse and rising line keep the open arrangement moving.",
 "The quick, spare backing makes room for the angular answering hook.",
 "Quick syncopation and an unresolved ending can obscure the main hook.",
 "The urgent full arrangement needs a clean homeward landing.",
 "The direct rising hook cuts through the urgent full backing.",
 "The busy backing crowds the quick offbeat homeward phrase.",
 "The busy outward phrase depends on keeping its answering gaps clear."
]

static func valid(value: Variant) -> bool:
 if not value is Dictionary or value.size()!=5:return false
 var version=value.get("version")
 if not (version is int or version is float) or not is_finite(float(version)) or float(version)!=1.0:return false
 for i in range(4):
  if not value.get(FIELDS[i]) is String or value[FIELDS[i]] not in VALUES[i]:return false
 return true

static func recipe(index: int=4) -> Dictionary:
 if index<0 or index>15:return {}
 var result: Dictionary={"version":1}
 for i in range(4):result[FIELDS[i]]=VALUES[i][(index>>(3-i))&1]
 return result

static func index(value: Dictionary) -> int:
 if not valid(value):return -1
 var result:=0
 for i in range(4):result=result*2+VALUES[i].find(value[FIELDS[i]])
 return result

static func material(value: Dictionary) -> Dictionary:
 if not valid(value):return {}
 var home: bool=value.theme=="home"
 return {"lines":[{"id":"hook:1","text":"A light in the upstairs window" if home else "The last street turns into open road"},{"id":"hook:2","text":"A place to come back to" if home else "Leave the ending open"}],"refrain_line_id":"hook:2","sections":{"verse":"hook:1","chorus":"hook:2"},"producer_recipe":value.duplicate(true)}

static func material_matches(value: Dictionary) -> bool:
 if not valid(value.get("producer_recipe")):return false
 var authored:=material(value.producer_recipe)
 if not value.get("lines") is Array or value.lines.size()!=2 or not value.get("sections") is Dictionary:return false
 for i in range(2):
  if not value.lines[i] is Dictionary:return false
  for key in ["id","text"]:
   if value.lines[i].get(key)!=authored.lines[i][key]:return false
 if value.get("refrain_line_id")!=authored.refrain_line_id:return false
 for key in ["verse","chorus"]:
  if value.sections.get(key)!=authored.sections[key]:return false
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
 if not valid(value) or not skills_ok(state):return {"ok":false}
 var sum:=0;var count:=0
 for person in state.members:
  if person.get("life_status","active")=="active":sum+=int(person.skill);count+=1
 var mean: float=float(sum)/count
 var capacity: int=1+int(mean>=35)+int(mean>=55)+int(mean>=75)
 var demand: int=1+VALUES[0].find(value.pace)+VALUES[1].find(value.energy)+VALUES[2].find(value.originality)
 var id:=index(value)
 return {"ok":true,"model":"producer_craft_v1","delta":clampi(int(CRAFT[id])-absi(capacity-demand),-3,3),"capacity":capacity,"demand":demand,"active_skill_sum":sum,"active_count":count,"reason":REASONS[id]}

static func summary(value: Dictionary) -> String:
 if not valid(value):return "Arrangement needs review"
 return "%s · %s · %s · %s" % [LABELS[0][VALUES[0].find(value.pace)],LABELS[1][VALUES[1].find(value.energy)],LABELS[2][VALUES[2].find(value.originality)],LABELS[3][VALUES[3].find(value.theme)]]

static func note(respondent: Dictionary,value: Dictionary,context: Dictionary) -> Dictionary:
 if not valid(value):return {"ok":false,"message":"This arrangement needs review."}
 var text: String=("The guitar answers sit off the beat. " if value.originality=="angular" else "The guitar keeps returning to the same hook. ")
 text+=("The bass and drums keep the space open. " if value.energy=="open" else "The full bass-and-drum pulse pushes underneath it. ")
 text+=("Let's give that returning phrase a clear landing." if value.theme=="home" else "Let's keep the last phrase reaching forward.")
 if respondent.is_empty():text="No other active bandmate has a response recorded. "+text
 return {"ok":true,"message":"","note":{"text":text,"request":{},"source_kind":"authored","content_version":VERSION,"respondent_ref":respondent.duplicate(true),"day":int(context.day),"delivery":"written_note"}}
