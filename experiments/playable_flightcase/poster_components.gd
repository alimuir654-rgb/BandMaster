extends RefCounted
## Print materials and live typography; every word/action remains native.
const FONT=preload("res://experiments/playable_flightcase/fonts/identity/BarlowCondensed-SemiBold.ttf")
const DISPLAY=preload("res://experiments/playable_flightcase/fonts/identity/Anton-Regular.ttf")
const MARKER=preload("res://experiments/playable_flightcase/fonts/identity/PermanentMarker-Regular.ttf")
const ATLAS_PATH="res://experiments/playable_flightcase/art/poster/print_materials_v1.png"
const INK=Color("191b1a")
const PAPER=Color("eee8d8")
const GOLD=Color("e7b83d")
const RUST=Color("a64a32")
const BLUE=Color("456c82")
static var _atlas_ref: WeakRef
static var _display_ref: WeakRef
static func atlas() -> Texture2D:
 var current: Texture2D=_atlas_ref.get_ref() as Texture2D if _atlas_ref!=null else null
 if current!=null:return current
 if FileAccess.file_exists(ATLAS_PATH) and not FileAccess.file_exists(ATLAS_PATH+".import"):
  var image: Image=Image.load_from_file(ATLAS_PATH)
  if image!=null:current=ImageTexture.create_from_image(image)
 elif ResourceLoader.exists(ATLAS_PATH):current=load(ATLAS_PATH) as Texture2D
 if current!=null:_atlas_ref=weakref(current)
 return current
static func display_font() -> Font:
 var current: Font=_display_ref.get_ref() as Font if _display_ref!=null else null
 if current==null:
  var face:=FontVariation.new();face.base_font=DISPLAY
  face.variation_transform=Transform2D(Vector2(1,0),Vector2(0.10,1),Vector2.ZERO)
  current=face;_display_ref=weakref(current)
 return current
static func cell(index: int) -> AtlasTexture:
 var texture:=AtlasTexture.new();texture.atlas=atlas();texture.region=Rect2((index%3)*512,int(index/3)*512,512,512);texture.filter_clip=true
 return texture
static func stock_index(color: Color) -> int:
 if color==RUST:return 2
 if color==BLUE:return 3
 if color==INK:return 4
 if color.r>0.7 and color.g>0.45 and color.b<0.5:return 1
 return 0
static func stock(color: Color=PAPER,margin: int=20) -> StyleBoxTexture:
 var style:=StyleBoxTexture.new();style.texture=atlas();var index: int=stock_index(color);style.region_rect=Rect2((index%3)*512+12,int(index/3)*512+12,488,488);style.set_texture_margin_all(24);style.set_content_margin_all(margin);style.content_margin_left=maxi(24,margin);style.content_margin_right=maxi(24,margin)
 return style
static func label(text: String,points: int=20,color: Color=INK) -> Label:
 var result:=Label.new();result.text=text;result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 result.add_theme_font_override("font",DISPLAY if points>=24 else FONT);result.add_theme_font_size_override("font_size",points);result.add_theme_color_override("font_color",color)
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE;result.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 return result
static func masthead(text: String,width: float,preferred: int=78) -> Label:
 var points: int=preferred
 var face: Font=display_font()
 var longest: String=text
 while points>28 and face.get_string_size(longest,HORIZONTAL_ALIGNMENT_LEFT,-1,points).x>width-18:points-=1
 return label(text,points,PAPER)
static func button(text: String,primary: bool=false,color: Color=PAPER) -> Button:
 var result:=Button.new();result.text=text;result.custom_minimum_size.y=52
 result.size_flags_horizontal=Control.SIZE_EXPAND_FILL;result.mouse_filter=Control.MOUSE_FILTER_PASS
 result.add_theme_font_override("font",FONT);result.add_theme_font_size_override("font_size",20)
 var material: Color=GOLD if primary else color
 var foreground: Color=PAPER if stock_index(material) in [2,3,4] else INK
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var style: StyleBoxTexture=control_stock(material,14)
  if state in ["pressed","hover_pressed"]:style.modulate_color=Color(0.90,0.90,0.90)
  if state=="hover":style.modulate_color=Color(1.05,1.05,1.05)
  if state=="disabled":style.modulate_color=Color(0.7,0.7,0.7)
  result.add_theme_stylebox_override(state,style)
  result.add_theme_color_override("font_"+state+"_color",foreground)
 var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=GOLD;focus.set_border_width_all(2)
 result.add_theme_stylebox_override("focus",focus);result.add_theme_color_override("font_color",foreground);result.add_theme_color_override("font_focus_color",foreground)
 return result
static func control_stock(material: Color=PAPER,margin: int=14) -> StyleBoxTexture:
 var style: StyleBoxTexture=stock(material,margin)
 var index: int=stock_index(material)
 style.region_rect=Rect2((index%3)*512+64,int(index/3)*512+64,384,384)
 style.set_texture_margin_all(8);style.set_content_margin_all(margin)
 return style
static func backdrop_texture() -> AtlasTexture:
 var texture: AtlasTexture=cell(4);texture.region=Rect2(576,576,384,384)
 return texture
static func choice_style(button: Button) -> void:
 button.add_theme_font_override("font",FONT);button.add_theme_font_size_override("font_size",17)
 button.custom_minimum_size=Vector2(0,48)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:
  var face: StyleBoxTexture=control_stock(GOLD if state in ["pressed","hover_pressed"] else PAPER,6)
  if state=="disabled":face.modulate_color=Color(0.7,0.7,0.7)
  button.add_theme_stylebox_override(state,face)
  button.add_theme_color_override("font_"+state+"_color",INK)
 button.add_theme_color_override("font_color",INK);button.add_theme_color_override("font_focus_color",INK)
 var focus:=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=GOLD;focus.set_border_width_all(2)
 button.add_theme_stylebox_override("focus",focus)
static func quiet(text: String) -> Button:
 var result: Button=button(text)
 for state in ["normal","hover","pressed","hover_pressed","disabled"]:result.add_theme_stylebox_override(state,StyleBoxEmpty.new());result.add_theme_color_override("font_"+state+"_color",PAPER)
 result.add_theme_color_override("font_color",PAPER);result.add_theme_color_override("font_focus_color",PAPER);result.add_theme_font_override("font",FONT)
 return result
static func block(parent: Node,color: Color=PAPER,margin: int=20) -> VBoxContainer:
 var panel:=PanelContainer.new();panel.add_theme_stylebox_override("panel",stock(color,margin));panel.mouse_filter=Control.MOUSE_FILTER_PASS;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",7);box.mouse_filter=Control.MOUSE_FILTER_PASS;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;panel.add_child(box)
 return box
static func background() -> Control:
 var base:=ColorRect.new();base.color=INK;base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);base.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var texture:=TextureRect.new();texture.texture=cell(4);texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;texture.stretch_mode=TextureRect.STRETCH_SCALE;texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);texture.mouse_filter=Control.MOUSE_FILTER_IGNORE;base.add_child(texture)
 return base
