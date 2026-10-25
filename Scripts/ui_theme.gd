extends RefCounted

const BG := Color("#0D1118")
const PANEL := Color("#151D28")
const ALT := Color("#222E3D")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#B0BAC5")
const Genres = preload("res://Scripts/genre_profiles.gd")
static func palette(genre_id: String) -> Dictionary:
 var id := Genres.normalize(genre_id)
 var profile: Dictionary = Genres.PROFILES[id]
 return {"bg":Color(str(profile["background"])),"panel":Color(str(profile["panel"])),"alt":Color(str(profile["surface"])),"accent":Color(str(profile["accent"])),"secondary":Color(str(profile["secondary"])),"highlight":Color(str(profile["highlight"])),"text":WHITE}
static func themed_button(label: String, genre_id: String, primary: bool = false) -> Button:
 var colors := palette(genre_id)
 var item := button(label,primary)
 var fill: Color = colors["accent"] if primary else colors["alt"]
 var foreground: Color = colors["bg"] if primary else WHITE
 item.add_theme_stylebox_override("normal",style(fill))
 item.add_theme_stylebox_override("hover",style(fill.lightened(0.10)))
 item.add_theme_stylebox_override("pressed",style(fill.darkened(0.12)))
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  item.add_theme_color_override(key,foreground)
 return item
static func themed_progress(bar: ProgressBar, genre_id: String, kind: String = "accent") -> void:
 progress(bar)
 var colors := palette(genre_id)
 var fill: Color = colors.get(kind,colors["accent"])
 var foreground := style(fill,9)
 foreground.set_content_margin_all(0)
 bar.add_theme_stylebox_override("fill",foreground)


static func style(fill: Color, radius: int = 14) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.set_corner_radius_all(radius)
 box.set_content_margin_all(14)
 box.border_color = Color("#2A3747")
 box.set_border_width_all(1)
 box.shadow_color = Color(0,0,0,0.18)
 box.shadow_size = 4
 return box

static func button(label: String, primary: bool = false) -> Button:
 var item := Button.new()
 item.text = label
 item.custom_minimum_size.y = 56
 item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var fill := AMBER if primary else ALT
 var foreground := BG if primary else WHITE
 item.add_theme_stylebox_override("normal",style(fill))
 item.add_theme_stylebox_override("hover",style(fill.lightened(0.10)))
 item.add_theme_stylebox_override("pressed",style(fill.darkened(0.08)))
 item.add_theme_color_override("font_color",foreground)
 item.add_theme_color_override("font_hover_color",foreground)
 item.add_theme_color_override("font_pressed_color",foreground)
 item.add_theme_font_size_override("font_size",15)
 item.add_theme_color_override("font_focus_color",foreground)
 item.add_theme_stylebox_override("focus",style(AMBER.darkened(0.52),12))
 item.add_theme_stylebox_override("disabled",style(Color("#1A212A"),12))
 item.add_theme_color_override("font_disabled_color",Color("#687482"))
 item.add_theme_color_override("font_hover_pressed_color",foreground)
 return item

static func progress(bar: ProgressBar) -> void:
 bar.show_percentage = false
 bar.custom_minimum_size.y = 20
 var back := style(Color("#101923"),9)
 back.set_content_margin_all(0)
 var fill := style(AMBER,9)
 fill.set_content_margin_all(0)
 bar.add_theme_stylebox_override("background",back)
 bar.add_theme_stylebox_override("fill",fill)

static func flat(fill: Color, radius: int = 0) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.set_corner_radius_all(radius)
 box.set_content_margin_all(0)
 return box

static func accent_card() -> StyleBoxFlat:
 var box := style(PANEL,12)
 box.border_color = Color("#3E4B5A")
 box.border_width_left = 4
 box.border_color = AMBER.darkened(0.16)
 return box
