extends RefCounted
## Versioned creative intent. Playback, local input and paid settlement stay separate.
const Sound = preload("res://experiments/playable_flightcase/band_sound.gd")
const VERSION := "mixing_desk_v1"
const MANIFEST := "res://experiments/playable_flightcase/audio/mixing_desk_v1.json"
const FIELDS := ["tone","pace","energy","originality","groove","shape","theme"]
const VALUES := [["warm","gritty","biting"],["slow","driving","urgent"],["open","full"],["familiar","angular"],["straight","loose"],["build","burst"],["personal","streetlife","escape"]]
const LABELS := [["WARM","GRITTY","BITING"],["SLOW","DRIVING","FAST"],["RESTRAINED","FIERCE"],["SIMPLE","LAYERED"],["STRAIGHT","LOOSE"],["BUILD","BURST"],["PERSONAL","STREETLIFE","ESCAPE"]]
const TITLES := ["TONE","PACE","ENERGY","COMPLEXITY","GROOVE","SHAPE","LYRICAL DIRECTION"]
const STAGES := ["FIND THE FEEL","BUILD THE SONG","MAKE THE TAKE"]
const TEMPOS := [88,104,132]
const HOOKS := ["low_riff_v1","bass_current_v1","picked_afterhours_v1"]
const HOOK_LABELS := ["LOW RIFF","BASS CURRENT","AFTER HOURS"]
const HOOK_NOTES := ["Clipped low guitar · D / B♭ / C","Bass-led syncopation · a new progression","Picked electric · darker open spaces"]

static func whole(value: Variant,low: int,high: int) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=low and float(value)<=high

static func valid(value: Variant) -> bool:
 if not value is Dictionary or not whole(value.get("version"),3,4) or not whole(value.get("stage"),0,2):return false
 if value.version==3 and value.size()!=12:return false
 if value.version==4 and (value.size()!=13 or not value.get("voice") is String or value.voice!="off"):return false
 for key in value:
  if not key is String:return false
 if not value.get("palette") is String or value.palette!="mixing_desk_v1" or not value.get("hook") is String or not Sound.valid(value.get("brief")):return false
 if value.hook not in HOOKS or (value.version==3 and value.hook!="low_riff_v1"):return false
 for i in range(FIELDS.size()):
  if not value.get(FIELDS[i]) is String or value[FIELDS[i]] not in VALUES[i]:return false
 return true

static func recipe(brief: Dictionary,stage: int=0,composition_index: int=0) -> Dictionary:
 if not Sound.valid(brief) or stage not in [0,1,2]:return {}
 return {"version":4,"palette":"mixing_desk_v1","hook":HOOKS[posmod(composition_index,HOOKS.size())],"voice":"off","brief":brief.duplicate(true),"stage":stage,"tone":"gritty","pace":"driving","energy":"full","originality":"familiar","groove":"straight","shape":"build","theme":"personal"}

static func same_composition(first: Dictionary,second: Dictionary) -> bool:
 return valid(first) and valid(second) and first.version==second.version and first.hook==second.hook and first.get("voice","off")==second.get("voice","off")

static func foundation(value: Dictionary) -> String:
 return HOOK_LABELS[HOOKS.find(value.hook)] if valid(value) else "REVIEW FOUNDATION"

static func label(value: Dictionary,field: String) -> String:
 var index: int=FIELDS.find(field)
 return str(LABELS[index][VALUES[index].find(value[field])]) if valid(value) and index>=0 else "REVIEW"

static func scenario_key(value: Dictionary) -> String:
 if not valid(value):return ""
 return "%s_%s_%s_%s_%s" % [value.pace,value.energy,value.originality,value.theme,value.groove]

static func audio_supported(value: Dictionary) -> bool:
 return valid(value) and (Sound.supported(value.brief) if value.hook=="low_riff_v1" else value.brief.genre=="Indie rock")

static func index(value: Dictionary) -> int:
 if not valid(value):return -1
 return ((((VALUES[1].find(value.pace)*2+VALUES[2].find(value.energy))*2+VALUES[3].find(value.originality))*3+VALUES[6].find(value.theme))*2+VALUES[4].find(value.groove))

static func summary(value: Dictionary) -> String:
 if not valid(value):return "This saved direction needs review."
 var words: Array[String]=[]
 for field in FIELDS:words.append(label(value,field))
 return (foundation(value)+" · " if value.version==4 else "")+" · ".join(words)

static func written(value: Dictionary) -> String:
 if not valid(value):return "This saved direction needs review."
 var theme: String={"personal":"Something personal, held close.","streetlife":"Life outside the practice room.","escape":"Getting out without a clean answer."}[value.theme]
 var parts: String=["The guitar finds the feel","Bass and drums join the idea","An answering guitar shapes the take"][int(value.stage)]
 if value.hook=="bass_current_v1":parts=["The bass finds the feel","Guitar and drums join the bass","An answering guitar shapes the take"][int(value.stage)]
 var phrasing: String="a clear repeated figure" if value.originality=="familiar" else "clipped figures and answering details"
 var arc: String="an opening that grows into the phrase" if value.shape=="build" else "the current parts arriving together"
 var touch: String="restrained attacks" if value.energy=="open" else "firmer attacks"
 if value.hook!="low_riff_v1":
  touch="a quieter dynamic balance" if value.energy=="open" else "a pushed dynamic balance"
  phrasing="a spare main phrase, without the final answering part" if value.originality=="familiar" else "the main phrase and an answering part in the finished take"
  if int(value.stage)==2:parts="The band makes the take"
 var feel: String="a straight pulse" if value.groove=="straight" else "a little space behind the offbeats"
 var composition: String=(foundation(value)+". "+HOOK_NOTES[HOOKS.find(value.hook)]+". ") if value.version==4 else ""
 return composition+"%s: %s at %d BPM, %s and %s. %s; %s. %s" % [parts,label(value,"tone").to_lower(),TEMPOS[VALUES[1].find(value.pace)],touch,phrasing,feel,arc,theme]

static func material(value: Dictionary) -> Dictionary:
 if not valid(value):return {}
 var themes: Dictionary={"personal":"Something personal, held close","streetlife":"Life outside the practice room","escape":"Getting out without a clean answer"}
 return {"lines":[{"id":"hook:1","text":themes[value.theme]},{"id":"hook:2","text":"%s / %s / %s / %s / %s / %s" % [label(value,"tone"),label(value,"pace"),label(value,"energy"),label(value,"originality"),label(value,"groove"),label(value,"shape")]}],"refrain_line_id":"hook:2","sections":{"verse":"hook:1","chorus":"hook:2"},"producer_recipe":value.duplicate(true)}

static func material_matches(value: Dictionary) -> bool:
 if not valid(value.get("producer_recipe")):return false
 var expected: Dictionary=material(value.producer_recipe)
 if not value.get("lines") is Array or value.lines.size()!=2 or not value.get("sections") is Dictionary:return false
 for i in range(2):
  if not value.lines[i] is Dictionary:return false
  for key in ["id","text"]:
   if not value.lines[i].get(key) is String or value.lines[i][key]!=expected.lines[i][key]:return false
 if not value.get("refrain_line_id") is String or not value.sections.get("verse") is String or not value.sections.get("chorus") is String:return false
 return value.refrain_line_id==expected.refrain_line_id and value.sections.verse==expected.sections.verse and value.sections.chorus==expected.sections.chorus

static func offer(value: Dictionary,respondent: Dictionary) -> Dictionary:
 if not valid(value) or respondent.is_empty():return {}
 var field: String=["energy","groove","originality"][int(value.stage)]
 var choices: Array=VALUES[FIELDS.find(field)]
 var next: String=choices[1-choices.find(value[field])]
 var pin: Array=[VERSION,value.brief.genre,value.brief.name_intent,value.brief.vibe,int(value.stage)]
 if value.version==4:pin.append(value.hook);pin.append(value.voice)
 for key in FIELDS:pin.append(value[key])
 for key in ["slot","member_id","candidate_id","name","role","bio_sha256"]:pin.append(respondent.get(key))
 return {"kind":"raw_change","field":field,"value":next,"stage":int(value.stage),"recipe":value.duplicate(true),"offer_id":JSON.stringify(pin).sha256_text()}

static func request_ok(request: Dictionary) -> bool:
 if request.size()!=6 or request.get("kind")!="raw_change" or not valid(request.get("recipe")) or not whole(request.get("stage"),0,2) or request.stage!=request.recipe.stage:return false
 for key in request:
  if not key is String:return false
 if not request.get("kind") is String:return false
 if not request.get("field") is String or not request.get("value") is String or not request.get("offer_id") is String or request.offer_id.length()!=64 or not request.offer_id.is_valid_hex_number(false):return false
 var field: String=request.field
 return field in FIELDS and request.value in VALUES[FIELDS.find(field)] and request.value!=request.recipe[field]

static func note(respondent: Dictionary,value: Dictionary,context: Dictionary) -> Dictionary:
 if not valid(value):return {"ok":false,"message":"This direction needs review."}
 var request: Dictionary=offer(value,respondent)
 var text: String="Keep this direction beside the next take."
 if not request.is_empty():
  var words: Dictionary={"energy":{"open":"Back off the attack. Let the spaces carry some weight.","full":"Give the riff a firmer attack. Keep the parts together."},"groove":{"straight":"Try it right on the beat. Keep that pulse steady.","loose":"Let those offbeats hang back a little. Keep the pace."},"originality":{"familiar":"Keep the phrase simple. Give the chorus a clear way in.","angular":"Let an answering figure through. Give the chorus another edge."}}
  text=words[request.field][request.value]
 return {"ok":true,"message":"","note":{"text":text,"request":request,"source_kind":"authored","content_version":VERSION,"respondent_ref":respondent.duplicate(true),"day":int(context.day),"delivery":"written_note"}}

static func _craft_from_context(value: Dictionary,sum: int,count: int) -> Dictionary:
 var mean: float=float(sum)/count
 var capacity: int=1+int(mean>=35)+int(mean>=55)+int(mean>=75)
 var demand: int=1+int(value.pace=="urgent")+int(value.energy=="full")+int(value.originality=="angular")
 var coherence: int=0
 if value.tone=="biting" and value.energy=="full" and value.originality=="angular":coherence-=1
 if value.tone=="warm" and value.energy=="open":coherence+=1
 if value.groove=="loose" and value.pace=="urgent" and value.originality=="angular":coherence-=1
 elif value.groove=="loose" and value.energy=="open":coherence+=1
 if value.shape=="build" and value.originality=="angular":coherence+=1
 elif value.shape=="burst" and value.energy=="full" and value.originality=="familiar":coherence+=1
 if value.theme=="streetlife" and value.groove=="straight":coherence+=1
 elif value.theme=="escape" and value.shape=="build":coherence+=1
 elif value.theme=="personal" and value.tone=="warm":coherence+=1
 var delta: int=clampi(clampi(coherence,-2,2)-absi(capacity-demand),-3,3)
 var reason: String="The parts and the song's shape hold together in the finished take." if delta>0 else ("The take keeps its direction; the band can keep tightening it." if delta==0 else "The band's finished take needs more room and tighter phrasing to carry this direction.")
 return {"ok":true,"model":"mixing_craft_v1","delta":delta,"capacity":capacity,"demand":demand,"active_skill_sum":sum,"active_count":count,"reason":reason}

static func craft(state: Dictionary,value: Dictionary) -> Dictionary:
 if not valid(value) or not state.get("members") is Array:return {"ok":false}
 var sum: int=0
 var count: int=0
 for member in state.members:
  if not member is Dictionary:return {"ok":false}
  if member.get("life_status","active")!="active":continue
  if not whole(member.get("skill"),0,100):return {"ok":false}
  sum+=int(member.skill);count+=1
 return _craft_from_context(value,sum,count) if count>0 and count<=6 else {"ok":false}

static func receipt_ok(receipt: Dictionary,value: Dictionary) -> bool:
 var context: Variant=receipt.get("context")
 if not valid(value) or receipt.get("model")!="mixing_craft_v1" or not context is Dictionary or context.size()!=4:return false
 if not whole(context.get("active_count"),1,6) or not whole(context.get("active_skill_sum"),0,int(context.active_count)*100) or not whole(context.get("capacity"),1,4) or not whole(context.get("demand"),1,4):return false
 if not whole(receipt.get("base_quality"),0,100) or not whole(receipt.get("final_quality"),1,100) or not whole(receipt.get("delta"),-3,3):return false
 var expected: Dictionary=_craft_from_context(value,int(context.active_skill_sum),int(context.active_count))
 return context.capacity==expected.capacity and context.demand==expected.demand and receipt.delta==expected.delta and receipt.reason==expected.reason and receipt.final_quality==clampi(int(receipt.base_quality)+int(receipt.delta),1,100)
