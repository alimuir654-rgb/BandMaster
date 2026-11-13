extends RefCounted
## Native conversational turns. No time, save, reveal or resolver ownership.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")

static func turn(parent: Node,speaker: String,text: String,node_name: String,paper: bool=true) -> Label:
 var panel:=PanelContainer.new();panel.name=node_name+"Turn";panel.mouse_filter=Control.MOUSE_FILTER_PASS
 panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 panel.add_theme_stylebox_override("panel",Poster.control_stock(Poster.PAPER if paper else Poster.INK,12))
 parent.add_child(panel)
 var body:=VBoxContainer.new();body.add_theme_constant_override("separation",5);body.mouse_filter=Control.MOUSE_FILTER_PASS;panel.add_child(body)
 var byline: Label=Poster.label(speaker.to_upper(),16,Poster.INK if paper else Poster.GOLD)
 byline.name=node_name+"Speaker";body.add_child(byline)
 var words: Label=Poster.label(text,20,Poster.INK if paper else Poster.PAPER)
 words.name=node_name;words.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_child(words)
 return words

static func reply(button: Button,on_paper: bool=false) -> void:
 Poster.choice_style(button)
 if on_paper:
  for state in ["normal","hover","pressed","hover_pressed","disabled"]:
   var selected: bool=state in ["pressed","hover_pressed"]
   button.add_theme_stylebox_override(state,Poster.control_stock(Poster.GOLD if selected else Poster.INK,10))
   button.add_theme_color_override("font_"+state+"_color",Poster.INK if selected else Poster.PAPER)
  button.add_theme_color_override("font_color",Poster.PAPER)
  button.add_theme_color_override("font_focus_color",Poster.PAPER)
 button.custom_minimum_size.y=52
 button.mouse_filter=Control.MOUSE_FILTER_PASS
 button.set_meta("conversation_reply",true)
