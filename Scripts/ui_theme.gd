extends RefCounted

const BG := Color("#0D1118")
const PANEL := Color("#1A2430")
const ALT := Color("#253444")
const AMBER := Color("#F0B44D")
const WHITE := Color("#F2F0E9")
const MUTED := Color("#B0BAC5")

static func style(fill: Color, radius: int = 14) -> StyleBoxFlat:
 var box := StyleBoxFlat.new()
 box.bg_color = fill
 box.set_corner_radius_all(radius)
 box.set_content_margin_all(16)
 box.border_color = Color("#334357")
 box.set_border_width_all(1)
 return box

static func button(label: String, primary: bool = false) -> Button:
 var item := Button.new()
 item.text = label
 item.custom_minimum_size.y = 64
 item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var fill := AMBER if primary else ALT
 var foreground := BG if primary else WHITE
 item.add_theme_stylebox_override("normal",style(fill))
 item.add_theme_stylebox_override("hover",style(fill.lightened(0.10)))
 item.add_theme_stylebox_override("pressed",style(fill.darkened(0.08)))
 item.add_theme_color_override("font_color",foreground)
 item.add_theme_color_override("font_hover_color",foreground)
 item.add_theme_color_override("font_pressed_color",foreground)
 item.add_theme_font_size_override("font_size",16)
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
