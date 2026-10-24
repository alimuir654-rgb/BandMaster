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
 box.set_content_margin_all(14)
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
 return item
