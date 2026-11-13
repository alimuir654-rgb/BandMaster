extends RefCounted
## Native saved-fact presentation. Disclosure changes UI visibility only.
const Poster = preload("res://experiments/playable_flightcase/poster_components.gd")
const Components = preload("res://experiments/playable_flightcase/career_components.gd")
const Launcher = preload("res://experiments/playable_flightcase/career_launcher.gd")

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

## SONG56 is opt-in: rehearsal and setlist keep their existing presentation.
## The original passive meter artwork and input-inert implementation are reused.
static func icon(parent: Node, filename: String, edge: int=32, ink: Color=Poster.INK) -> TextureRect:
 var picture:=TextureRect.new()
 picture.custom_minimum_size=Vector2(edge,edge)
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 picture.focus_mode=Control.FOCUS_NONE
 picture.modulate=ink
 var path: String=Launcher.ICON_ROOT+"native48/"+filename+".png"
 picture.texture=Launcher.icon_texture(path)
 if picture.texture==null:
  path=Launcher.ICON_ROOT+filename+".svg"
  picture.texture=Launcher.icon_texture(path)
 picture.set_meta("source",path)
 parent.add_child(picture)
 return picture

static func heading(parent: Node, title: String, subtitle: String, filename: String) -> void:
 var row:=HBoxContainer.new()
 row.mouse_filter=Control.MOUSE_FILTER_PASS
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 icon(row,filename,38,Poster.GOLD)
 var words:=VBoxContainer.new()
 words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 words.mouse_filter=Control.MOUSE_FILTER_PASS
 row.add_child(words)
 words.add_child(Poster.label(title,28,Poster.PAPER))
 if not subtitle.is_empty():words.add_child(Poster.label(subtitle,16,Poster.PAPER))

static func card(parent: Node, key: String) -> VBoxContainer:
 var body: VBoxContainer=Poster.block(parent,Poster.PAPER,14)
 body.name="SongCard_"+key
 body.add_theme_constant_override("separation",8)
 return body

static func card_title(parent: Node, title: String, number: String, key: String) -> Label:
 var row:=HBoxContainer.new()
 row.mouse_filter=Control.MOUSE_FILTER_PASS
 row.add_theme_constant_override("separation",12)
 parent.add_child(row)
 var mark:=PanelContainer.new()
 mark.mouse_filter=Control.MOUSE_FILTER_PASS
 mark.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 mark.custom_minimum_size=Vector2(42,42)
 mark.add_theme_stylebox_override("panel",Poster.control_stock(Poster.GOLD,5))
 row.add_child(mark)
 var ordinal: Label=Poster.label(number,24)
 ordinal.add_theme_font_override("font",Poster.MARKER)
 ordinal.autowrap_mode=TextServer.AUTOWRAP_OFF
 ordinal.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ordinal.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 mark.add_child(ordinal)
 var label: Label=Poster.label(title,24)
 label.name="SongCard_"+key+"_Title"
 label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.add_child(label)
 return label

static func visual_strength(parent: Node, summary: Dictionary, key: String, captured: bool=false) -> Label:
 var known: bool=bool(summary.get("known_strength",false))
 var quality: int=int(summary["quality"]) if known else 0
 var band: String="NEEDS WORK" if quality<45 else ("PROMISING" if quality<70 else "STRONG")
 var caption: String="CAPTURED SONG STRENGTH" if captured else "SONG STRENGTH"
 _label(parent,caption+(" · "+band if known else " · NOT TRACKED"),"SongSummary_"+key+"_Caption")
 if not known:
  # Unknown is not a zero-valued gauge. A draft has no finished strength.
  var unknown: Label=_label(parent,"UNKNOWN","SongSummary_"+key+"_Strength")
  unknown.set_meta("known_strength",false)
  return unknown
 var meter: HBoxContainer=Components.meter(quality,"notepaper")
 meter.name="SongSummary_"+key+"_Gauge"
 meter.set_meta("known_strength",true)
 meter.set_meta("metric","captured_song_strength" if captured else "song_strength")
 parent.add_child(meter)
 var number: Label=meter.get_node("CareerMeterValue") as Label
 number.name="SongSummary_"+key+"_Strength"
 number.add_theme_font_size_override("font_size",26)
 number.set_meta("known_strength",true)
 return number

static func disclosure(parent: Node, key: String, caption: String="NOTES", toolbar: Node=null) -> VBoxContainer:
 var body:=VBoxContainer.new()
 body.name="SongSummary_"+key+"_Details"
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.mouse_filter=Control.MOUSE_FILTER_PASS
 body.add_theme_constant_override("separation",8)
 body.visible=false
 var toggle: Button=Poster.button(caption+"  +")
 Poster.choice_style(toggle)
 toggle.name="SongSummary_"+key+"_Toggle"
 toggle.toggle_mode=true
 (toolbar if toolbar!=null else parent).add_child(toggle)
 parent.add_child(body)
 toggle.toggled.connect(func(open: bool):
  if not is_instance_valid(body) or not body.is_inside_tree():return
  body.visible=open
  toggle.text=caption+("  −" if open else "  +"))
 return body

static func facts(parent: Node, summary: Dictionary, key: String) -> void:
 _label(parent,str(summary["credits"]),"SongSummary_"+key+"_Credits")
 _label(parent,"FORM · "+str(summary["arrangement"]),"SongSummary_"+key+"_Form")
 _label(parent,"IDEA · "+str(summary["origin"]),"SongSummary_"+key+"_Origin")
 _label(parent,str(summary["finish"]),"SongSummary_"+key+"_Finish")
 for row in [["Readiness","calendar-days","LIVE PREPARATION · NOT TRACKED"],
  ["Recording","cassette-tape","RECORDING · "+str(summary["recording"])],
  ["Reach","megaphone","ATTRIBUTED LISTENS · "+str(summary["reach"])]]:
  var line:=HBoxContainer.new()
  line.mouse_filter=Control.MOUSE_FILTER_PASS
  line.add_theme_constant_override("separation",8)
  parent.add_child(line)
  icon(line,str(row[1]),22)
  _label(line,str(row[2]),"SongSummary_"+key+"_"+str(row[0]))
 _label(parent,str(summary["evidence"]),"SongSummary_"+key+"_Evidence")
 if not str(summary.get("legacy_note","")).is_empty():
  _label(parent,"SAVED SONG NOTE · DATE / VERSION NOT RECORDED\n"+str(summary["legacy_note"]),"SongSummary_"+key+"_LegacyNote")
 _label(parent,str(summary["identity"]),"SongSummary_"+key+"_Identity")
 var history: Array=summary["history"]
 _label(parent,"WRITING HISTORY NOT RECORDED" if history.is_empty() else "WRITING HISTORY\n"+"\n".join(PackedStringArray(history)),"SongSummary_"+key+"_History")

static func notes(parent: Node, summary: Dictionary, key: String, toolbar: Node=null) -> VBoxContainer:
 var body: VBoxContainer=disclosure(parent,key,"NOTES",toolbar)
 facts(body,summary,key)
 return body
