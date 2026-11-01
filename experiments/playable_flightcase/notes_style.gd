extends RefCounted
## Notes only. Original printed controls, numbers and wordmark stay unchanged.
## Session preference; never a career action or a save-schema field.
const HandSource = preload("res://experiments/playable_flightcase/fonts/Caveat.ttf")
const SymbolsSource = preload("res://experiments/playable_flightcase/fonts/DejaVuSansMono.ttf")
static var handwritten := true
static var _clear: Font
static var _hand: Font

static func _disable_system(font: Font, visited: Dictionary) -> void:
 if font==null or visited.has(font.get_instance_id()):
  return
 visited[font.get_instance_id()] = true
 if font is FontFile:
  (font as FontFile).allow_system_fallback = false
 elif font is FontVariation:
  _disable_system((font as FontVariation).base_font,visited)
 for fallback in font.fallbacks:
  _disable_system(fallback,visited)

static func font(printed: bool = false) -> Font:
 if _clear==null:
  _clear = ThemeDB.fallback_font.duplicate(true) as Font
  _disable_system(_clear,{})
  var symbols: FontFile = SymbolsSource.duplicate(true) as FontFile
  symbols.allow_system_fallback = false
  _clear.fallbacks = [symbols]
  var source: FontFile = HandSource.duplicate(true) as FontFile
  source.allow_system_fallback = false
  source.fallbacks = [_clear]
  var variation := FontVariation.new()
  variation.base_font = source
  variation.variation_opentype = {"wght":500.0}
  variation.fallbacks = [_clear]
  _hand = variation
 return _hand if handwritten and not printed else _clear

static func caption() -> String:
 return "HANDWRITTEN" if handwritten else "CLEAR"

static func apply(note: Label) -> void:
 # Do not change text, visible_characters, reveal epoch, focus or callbacks.
 var compact_caption: bool = note.has_meta("compact_note_caption") and bool(note.get_meta("compact_note_caption"))
 note.add_theme_font_override("font",font(compact_caption))
 note.add_theme_font_size_override("font_size",22 if handwritten and not compact_caption else 16)

static func toggle(tree: SceneTree) -> void:
 handwritten = not handwritten
 for note in tree.get_nodes_in_group("bandmaster_notes"):
  if note is Label:
   apply(note as Label)
