extends RefCounted
## Cosmetic data only. The optional v1 token never changes taste, money or time.
const KEY := "identity_style_v1"
const FONTS := ["blockprint","condensed","handpainted","mono","stencil","xerox","glitch"]
const INKS := ["charcoal","ivory","oxblood","burnt_amber","faded_teal","cobalt","forest","muted_violet"]
const FONT_LABELS := ["BLOCKPRINT","CONDENSED","HANDPAINTED","MONO","STENCIL","XEROX","GLITCH"]
const INK_LABELS := ["CHARCOAL","IVORY","OXBLOOD","BURNT AMBER","FADED TEAL","COBALT","FOREST","MUTED VIOLET"]
const FINISH_KEY := "print_finish_v1"
const FINISHES := ["plain","underline","rules","brackets"]
const FINISH_LABELS := ["PLAIN","UNDERLINED","DOUBLE RULE","BRACKETED"]
const LAYOUT_KEY="mark_layout_v1"
const LAYOUTS=["straight","stacked","cutout","stencil","xerox","afterhours"]
const LAYOUT_LABELS=["STRAIGHT UP","STACKED","CUT & PASTE","STENCIL","XEROX","AFTER HOURS"]
const LAYOUT_FACES={"straight":"blockprint","stacked":"condensed","cutout":"blockprint","stencil":"stencil","xerox":"xerox","afterhours":"glitch"}
const FONT_FILES := {
 "blockprint":"res://experiments/playable_flightcase/fonts/identity/Anton-Regular.ttf",
 "condensed":"res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf",
 "handpainted":"res://experiments/playable_flightcase/fonts/identity/PermanentMarker-Regular.ttf",
 "mono":"res://experiments/playable_flightcase/fonts/identity/IBMPlexMono-Regular.ttf",
 "stencil":"res://experiments/playable_flightcase/art/feedback47/fonts/BlackOpsOne-Regular.ttf",
 "xerox":"res://experiments/playable_flightcase/art/feedback47/fonts/RubikDirt-Regular.ttf",
 "glitch":"res://experiments/playable_flightcase/art/feedback47/fonts/RubikGlitch-Regular.ttf"
}
const INK_HEX := {"charcoal":"24211d","ivory":"f3ecda","oxblood":"752d34","burnt_amber":"884714","faded_teal":"285b60","cobalt":"293f83","forest":"324b39","muted_violet":"62465e"}
static var _font_cache: Dictionary = {}

static func defaults() -> Dictionary:
 return {"version":1,"font":"blockprint","ink":"charcoal"}

static func valid(value: Variant) -> bool:
 if not value is Dictionary:
  return false
 if not (typeof(value.get("version"))==TYPE_INT and value["version"]==1 and value.get("font") is String and FONTS.has(value["font"]) and value.get("ink") is String and INKS.has(value["ink"])):return false
 if value.has(FINISH_KEY):
  var finish: Variant=value[FINISH_KEY]
  if not (finish is Dictionary and typeof(finish.get("version"))==TYPE_INT and finish.version==1 and typeof(finish.get("kind"))==TYPE_STRING and FINISHES.has(finish.kind)):return false
 if value.has(LAYOUT_KEY):
  var mark: Variant=value[LAYOUT_KEY]
  if not (mark is Dictionary and typeof(mark.get("version"))==TYPE_INT and mark.version==1 and typeof(mark.get("kind"))==TYPE_STRING and LAYOUTS.has(mark.kind)):return false
  if mark.has("cut_variant") and (typeof(mark.cut_variant)!=TYPE_INT or mark.cut_variant<0 or mark.cut_variant>9999):return false
 return true

static func layout_kind(value: Dictionary) -> String:
 return str(value[LAYOUT_KEY]["kind"]) if valid(value) and value.has(LAYOUT_KEY) else "straight"

static func with_layout(value: Dictionary,kind: String) -> Dictionary:
 if not valid(value) or kind not in LAYOUTS:return {}
 var result: Dictionary=value.duplicate(true)
 var token: Dictionary=result.get(LAYOUT_KEY,{}).duplicate(true)
 token["version"]=1;token["kind"]=kind;result[LAYOUT_KEY]=token
 result["font"]=str(LAYOUT_FACES[kind])
 return with_finish(result,"plain")

static func next_cut(value: Dictionary) -> Dictionary:
 var result: Dictionary=with_layout(value,"cutout")
 if result.is_empty():return {}
 var token: Dictionary=result[LAYOUT_KEY]
 token["cut_variant"]=(int(token.get("cut_variant",0))+1)%10000
 var faces: Array=["blockprint","mono","condensed","handpainted","stencil"]
 result["font"]=faces[int(token.cut_variant)%faces.size()]
 return result

static func cut_variant(value: Dictionary) -> int:
 return int(value.get(LAYOUT_KEY,{}).get("cut_variant",0)) if valid(value) else 0

static func layout_text(value: String,logo: String,style: Dictionary,single_line: bool=false) -> String:
 var words: String=mark_text(value,logo)
 if layout_kind(style)!="stacked" or single_line or logo=="Monogram":return words
 var closest: int=-1
 for i in range(words.length()):
  if words[i]==" " and (closest<0 or absf(i-words.length()/2.0)<absf(closest-words.length()/2.0)):closest=i
 if closest>0:return words.substr(0,closest)+"\n"+words.substr(closest+1)
 if words.length()>4:
  var cut: int=ceili(words.length()/2.0)
  return words.substr(0,cut)+"\n"+words.substr(cut)
 return words

static func finish_kind(value: Dictionary) -> String:
 return str(value[FINISH_KEY].kind) if valid(value) and value.has(FINISH_KEY) else "plain"

static func with_finish(value: Dictionary, kind: String) -> Dictionary:
 if not valid(value) or not FINISHES.has(kind):return {}
 var result: Dictionary=value.duplicate(true)
 var token: Dictionary=result.get(FINISH_KEY,{}).duplicate(true)
 token.merge({"version":1,"kind":kind},true)
 result[FINISH_KEY]=token
 return result

static func effective(value: Variant, legacy_palette: String = "") -> Dictionary:
 if valid(value):
  return (value as Dictionary).duplicate(true)
 var result: Dictionary = defaults()
 if legacy_palette=="Amber / Charcoal": result["ink"]="burnt_amber"
 elif legacy_palette=="Red / Black": result["ink"]="oxblood"
 return result

static func ink(value: Dictionary, on_dark: bool = false) -> Color:
 var style: Dictionary = effective(value)
 var result := Color(str(INK_HEX[style["ink"]]))
 # A dark case header is a different proof surface from the cream poster.
 # Keep the ink family visible without placing dark ink on a dark case.
 return result.lerp(Color("f3ecda"),0.70) if on_dark and style["ink"]!="ivory" else result

static func dark_paper(value: Dictionary) -> bool:
 return effective(value)["ink"]=="ivory"

static func face(value: Dictionary) -> Font:
 var kind: String = str(effective(value)["font"])
 if _font_cache.has(kind): return _font_cache[kind] as Font
 var loaded: FontFile = load(str(FONT_FILES[kind])) as FontFile
 var font: FontFile = loaded.duplicate() as FontFile if loaded!=null else null
 if font==null: return ThemeDB.fallback_font
 var original_fallback: FontFile = load("res://experiments/playable_flightcase/fonts/DejaVuSansMono.ttf") as FontFile
 var fallback: FontFile = original_fallback.duplicate() as FontFile if original_fallback!=null else null
 if fallback!=null: fallback.allow_system_fallback=false
 var chain: Array[Font] = []
 var extra: Array[Font] = []
 if fallback!=null: extra.append(fallback)
 var cjk_path := "res://experiments/playable_flightcase/fonts/identity/NotoSansSC.ttf"
 if ResourceLoader.exists(cjk_path):
  var cjk: FontFile = load(cjk_path) as FontFile
  if cjk!=null:
   cjk.allow_system_fallback=false
   var cjk_regular:=FontVariation.new()
   cjk_regular.base_font=cjk
   cjk_regular.variation_opentype={"wght":400.0}
   extra.append(cjk_regular)
 if kind!="mono":
  var mono_source: FontFile=load(str(FONT_FILES["mono"])) as FontFile
  var mono: FontFile=mono_source.duplicate() as FontFile
  mono.allow_system_fallback=false
  mono.fallbacks=extra
  chain.append(mono)
 chain.append_array(extra)
 font.fallbacks=chain
 font.allow_system_fallback=false
 _font_cache[kind]=font
 return font

static func mark_text(full_name: String, logo: String) -> String:
 var result: String = full_name.to_upper()
 if logo=="Monogram":
  result=""
  for part in full_name.split(" ",false):
   result+=part.substr(0,1).to_upper()
  result=result.substr(0,6)
 elif logo=="Stamp":
  result="— "+result+" —"
 return result
