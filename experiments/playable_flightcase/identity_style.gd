extends RefCounted
## Cosmetic data only. The optional v1 token never changes taste, money or time.
const KEY := "identity_style_v1"
const FONTS := ["blockprint","condensed","handpainted","mono"]
const INKS := ["charcoal","ivory","oxblood","burnt_amber","faded_teal","cobalt","forest","muted_violet"]
const FONT_LABELS := ["BLOCKPRINT","CONDENSED","HANDPAINTED","MONO"]
const INK_LABELS := ["CHARCOAL","IVORY","OXBLOOD","BURNT AMBER","FADED TEAL","COBALT","FOREST","MUTED VIOLET"]
const FONT_FILES := {
 "blockprint":"res://experiments/playable_flightcase/fonts/identity/Anton-Regular.ttf",
 "condensed":"res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf",
 "handpainted":"res://experiments/playable_flightcase/fonts/identity/PermanentMarker-Regular.ttf",
 "mono":"res://experiments/playable_flightcase/fonts/identity/IBMPlexMono-Regular.ttf"
}
const INK_HEX := {"charcoal":"24211d","ivory":"f3ecda","oxblood":"752d34","burnt_amber":"884714","faded_teal":"285b60","cobalt":"293f83","forest":"324b39","muted_violet":"62465e"}
static var _font_cache: Dictionary = {}

static func defaults() -> Dictionary:
 return {"version":1,"font":"blockprint","ink":"charcoal"}

static func valid(value: Variant) -> bool:
 if not value is Dictionary:
  return false
 return typeof(value.get("version"))==TYPE_INT and value["version"]==1 and value.get("font") is String and FONTS.has(value["font"]) and value.get("ink") is String and INKS.has(value["ink"])

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
