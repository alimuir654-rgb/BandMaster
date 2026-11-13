extends RefCounted
## Native saved-fact presentation. Disclosure changes UI visibility only.
const Poster = preload("res://experiments/playable_flightcase/poster_components.gd")

static func _label(parent: Node, text: String, name: String, light_ink: bool=false) -> Label:
 var label: Label=Poster.label(text,16,Poster.PAPER if light_ink else Poster.INK)
 label.name=name
 parent.add_child(label)
 return label

static func strength(parent: Node, summary: Dictionary, key: String, light_ink: bool=false) -> Label:
 return _label(parent,str(summary["strength"]),"SongSummary_"+key+"_Strength",light_ink)

static func details(parent: Node, summary: Dictionary, key: String, light_ink: bool=false, expanded: bool=false, disclosure: bool=true) -> VBoxContainer:
 var body:=VBoxContainer.new()
 body.name="SongSummary_"+key+"_Details"
 body.add_theme_constant_override("separation",5)
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.mouse_filter=Control.MOUSE_FILTER_PASS
 body.visible=expanded or not disclosure
 if disclosure:
  var button: Button=Poster.button("SONG DETAILS  −" if expanded else "SONG DETAILS  +")
  Poster.choice_style(button)
  button.name="SongSummary_"+key+"_Toggle"
  button.toggle_mode=true;button.set_pressed_no_signal(expanded)
  parent.add_child(button)
  button.toggled.connect(func(open: bool):
   if not is_instance_valid(body) or not body.is_inside_tree():return
   body.visible=open
   button.text="SONG DETAILS  −" if open else "SONG DETAILS  +")
 parent.add_child(body)
 for row in [["Readiness","LIVE READINESS",summary["readiness"]],["Recording","RECORDING QUALITY",summary["recording"]],["Reach","REACH / ATTRIBUTED LISTENS",summary["reach"]]]:
  _label(body,str(row[1])+"\n"+str(row[2]),"SongSummary_"+key+"_"+str(row[0]),light_ink)
 _label(body,str(summary["evidence"]),"SongSummary_"+key+"_Evidence",light_ink)
 if not str(summary.get("legacy_note","")).is_empty():
  _label(body,"SAVED SONG NOTE · DATE / VERSION NOT RECORDED\n"+str(summary["legacy_note"]),"SongSummary_"+key+"_LegacyNote",light_ink)
 _label(body,str(summary["identity"]),"SongSummary_"+key+"_Identity",light_ink)
 return body
