extends RefCounted
## Native screen-print presentation. No gameplay, IO or save state.
const FONT=preload("res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf")
const INK=Color("191b1a")
const PAPER=Color("eee8d8")
const GOLD=Color("e7b83d")
const RUST=Color("a64a32")
const BLUE=Color("294a5a")
static func stock(color: Color=PAPER,margin: int=16) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new();style.bg_color=color;style.set_content_margin_all(margin)
 return style
static func label(text: String,points: int=20,color: Color=INK) -> Label:
 var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 result.add_theme_font_override("font",FONT);result.add_theme_font_size_override("font_size",points);result.add_theme_color_override("font_color",color)
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return result
static func button(text: String,primary: bool=false,color: Color=PAPER) -> Button:
 var result:=Button.new();result.text=text;result.custom_minimum_size.y=52
 result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.mouse_filter=Control.MOUSE_FILTER_PASS
 result.add_theme_font_override("font",FONT);result.add_theme_font_size_override("font_size",20)
 for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
  var style: StyleBoxFlat=stock(GOLD if primary else color,12)
  if state=="hover":style.bg_color=style.bg_color.lightened(0.1)
  if state in ["pressed","hover_pressed"]:style.bg_color=style.bg_color.darkened(0.15)
  if state=="disabled":style.bg_color=Color("9a998e")
  if state=="focus":
   style.bg_color=Color.TRANSPARENT;style.border_color=Color("fff7d8");style.set_border_width_all(3)
  result.add_theme_stylebox_override(state,style)
  result.add_theme_color_override("font_"+state+"_color",INK)
 result.add_theme_color_override("font_color",INK)
 return result
static func block(parent: Node,color: Color=PAPER) -> VBoxContainer:
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",stock(color));panel.mouse_filter=Control.MOUSE_FILTER_PASS;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",10);box.mouse_filter=Control.MOUSE_FILTER_PASS;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(box)
 return box
