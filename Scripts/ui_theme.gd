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
 var normal := _button_surface(fill, primary)
 normal.border_color = colors["accent"] if primary else colors["secondary"]
 item.add_theme_stylebox_override("normal",normal)
 var hovered := _button_surface(fill.lightened(0.09),primary)
 hovered.border_color = colors["accent"]
 item.add_theme_stylebox_override("hover",hovered)
 var pressed := _button_surface(fill.darkened(0.13),primary)
 pressed.shadow_size = 1
 item.add_theme_stylebox_override("pressed",pressed)
 item.add_theme_stylebox_override("disabled",_button_surface(colors["panel"].darkened(0.12),false))
 var focus := flat(Color.TRANSPARENT,12)
 focus.border_color = colors["accent"]
 focus.set_border_width_all(2)
 item.add_theme_stylebox_override("focus",focus)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  item.add_theme_color_override(key,foreground)
 item.add_theme_color_override("font_disabled_color",MUTED.darkened(0.18))
 item.add_theme_font_size_override("font_size",16)
 return item

static func themed_progress(bar: ProgressBar, genre_id: String, kind: String = "accent") -> void:
 progress(bar)
 var colors := palette(genre_id)
 var fill: Color = colors.get(kind,colors["accent"])
 var foreground := style(fill,5)
 foreground.shadow_size = 0
 foreground.set_border_width_all(0)
 foreground.set_content_margin_all(0)
 bar.add_theme_stylebox_override("fill",foreground)


static func style(fill: Color, radius: int = 12) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.set_corner_radius_all(radius)
 box.set_content_margin_all(13)
 box.border_color = Color("#384554")
 box.set_border_width_all(1)
 box.shadow_color = Color(0,0,0,0.25)
 box.shadow_size = 5
 return box

# Compact, flat tactile surfaces. Kept central so new and genre-themed actions match.
static func _button_surface(fill: Color, primary: bool) -> StyleBoxFlat:
 var surface := StyleBoxFlat.new()
 surface.bg_color = fill
 surface.set_corner_radius_all(8)
 surface.content_margin_left = 18.0
 surface.content_margin_right = 18.0
 surface.content_margin_top = 14.0
 surface.content_margin_bottom = 14.0
 surface.border_color = fill.lightened(0.22)
 surface.border_width_bottom = 2 if primary else 1
 surface.shadow_color = Color(0,0,0,0.18)
 surface.shadow_size = 2
 return surface

static func button(label: String, primary: bool = false) -> Button:
 var item := WoldButton.new()
 item.shape = WoldButton.Shape.PRIMARY if primary else WoldButton.Shape.SECONDARY
 item.text = label
 item.custom_minimum_size.y = 56
 item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 item.focus_mode = Control.FOCUS_ALL
 var fill := AMBER if primary else PANEL
 var foreground := BG if primary else WHITE
 var normal := _button_surface(fill,primary)
 if primary:
  normal.border_color = AMBER.lightened(0.18)
 else:
  normal.border_color = Color("#415063")
 item.add_theme_stylebox_override("normal",normal)
 var hover := _button_surface(fill.lightened(0.09),primary)
 hover.border_color = AMBER if primary else Color("#71849A")
 item.add_theme_stylebox_override("hover",hover)
 var pressed := _button_surface(fill.darkened(0.12),primary)
 pressed.shadow_size = 1
 item.add_theme_stylebox_override("pressed",pressed)
 item.add_theme_stylebox_override("disabled",_button_surface(Color("#19222D"),false))
 var focus := StyleBoxFlat.new()
 focus.bg_color = Color(0,0,0,0)
 focus.set_corner_radius_all(13)
 focus.border_color = AMBER
 focus.set_border_width_all(2)
 item.add_theme_stylebox_override("focus",focus)
 for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  item.add_theme_color_override(key,foreground)
 item.add_theme_color_override("font_disabled_color",Color("#81909D"))
 item.add_theme_font_size_override("font_size",16)
 return item

static func progress(bar: ProgressBar) -> void:
 bar.show_percentage = false
 bar.custom_minimum_size.y = 10
 var back := style(Color("#0D1520"),5)
 back.set_content_margin_all(0)
 back.shadow_size = 0
 var fill := style(AMBER,5)
 fill.set_content_margin_all(0)
 fill.shadow_size = 0
 fill.set_border_width_all(0)
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
