extends RefCounted
## Quiet navigation/disclosures use native focus and the existing ink palette.
## Commitments retain the original material action surface.
static func quiet(button: Button,paper: bool=false) -> void:
 var empty:=StyleBoxEmpty.new()
 empty.content_margin_left=8;empty.content_margin_right=8
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:button.add_theme_stylebox_override(state,empty)
 var ink:=Color("29241f") if paper else Color("e6dfcf")
 for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:button.add_theme_color_override(state,ink)
 button.add_theme_color_override("font_disabled_color",Color("756b5a") if paper else Color("999182"))
 button.custom_minimum_size.y=44
 button.mouse_filter=Control.MOUSE_FILTER_PASS
 button.set_meta("control_role","navigation_or_disclosure")
