extends RefCounted
## Small reusable native art/speaker/Ink shell. No gameplay, save or phase API.
const Ink = preload("res://experiments/playable_flightcase/ink_note.gd")
const C = preload("res://experiments/playable_flightcase/career_components.gd")

static func copy(host, parent: Node, text: String, name: String, points: int=16, muted: bool=false) -> Label:
 var label: Label=host._copy(parent,text,points,muted)
 if not name.is_empty():label.name=name
 label.mouse_filter=Control.MOUSE_FILTER_IGNORE
 label.focus_mode=Control.FOCUS_NONE
 return label

static func render(host, parent: Node, compact: bool, data: Dictionary) -> Dictionary:
 var body: VBoxContainer=host._paper(parent,compact)
 body.name="StudioScene"
 copy(host,body,str(data.get("heading","STUDENT RADIO")),"StudioHeading",22)
 var row: Container=VBoxContainer.new() if compact else HBoxContainer.new()
 row.add_theme_constant_override("separation",12)
 row.mouse_filter=Control.MOUSE_FILTER_PASS
 body.add_child(row)
 var art:=TextureRect.new()
 art.name="StudioSceneArt"
 art.texture=data.get("texture") as Texture2D
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 art.focus_mode=Control.FOCUS_NONE
 art.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var available: float=maxf(160.0,host.size.y-430.0)
 var height: float=maxf(120.0,(host.size.x-80.0)*0.75) if compact else minf(390.0,available)
 art.custom_minimum_size=Vector2(0.0,height)
 art.size_flags_stretch_ratio=1.15
 art.set_meta("source",str(data.get("source","")))
 art.set_meta("raw_sha256",str(data.get("raw_sha256","")))
 art.set_meta("full_source_aspect",4.0/3.0)
 row.add_child(art)
 var words: VBoxContainer=host._box(6)
 words.size_flags_stretch_ratio=1.0
 row.add_child(words)
 copy(host,words,str(data.get("speaker","STUDENT PRESENTER")),"StudioSpeaker",16,true)
 if not str(data.get("progress","")).is_empty():copy(host,words,str(data["progress"]),"StudioProgress",16,true)
 var note: Label=Ink.new()
 note.name=str(data.get("note_name","StudioNote"))
 note.text=str(data.get("text",""))
 note.add_theme_color_override("font_color",Color("29241f"))
 var interactive: bool=bool(data.get("interactive",false))
 if not interactive:
  note.focus_mode=Control.FOCUS_NONE
  note.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if bool(data.get("fresh",false)):note.visible_characters=0
 words.add_child(note)
 return {"body":body,"words":words,"art":art,"note":note}

static func pills(host, parent: Node, before: Dictionary, after: Dictionary, projected: bool) -> void:
 copy(host,parent,"PROJECTED RESPONSE" if projected else "SAVED RESPONSE","PromotionProjectionHeading",16,true)
 var row:=HFlowContainer.new()
 row.name="PromotionDeltaPills"
 row.add_theme_constant_override("h_separation",6)
 row.add_theme_constant_override("v_separation",6)
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(row)
 for field in ["fans","press","buzz"]:
  var delta: int=int(after.get(field,0))-int(before.get(field,0))
  var panel:=PanelContainer.new()
  panel.name="PromotionPill_"+field
  panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
  panel.focus_mode=Control.FOCUS_NONE
  var stock:=StyleBoxFlat.new()
  stock.bg_color=Color("e0e9d9") if delta>0 else (Color("efddd7") if delta<0 else Color("e9e2d5"))
  stock.border_color=Color("819777") if delta>0 else (Color("b98171") if delta<0 else Color("aaa08f"))
  stock.set_border_width_all(1)
  stock.set_corner_radius_all(8)
  stock.set_content_margin_all(7.0)
  panel.add_theme_stylebox_override("panel",stock)
  row.add_child(panel)
  var label: Label=copy(host,panel,"%s %s%d" % [field.to_upper(),"+" if delta>=0 else "",delta],"PromotionDelta_"+field)
  label.autowrap_mode=TextServer.AUTOWRAP_OFF
  label.add_theme_color_override("font_color",Color("254d2f") if delta>0 else (Color("843c2c") if delta<0 else Color("625b50")))
  label.set_meta("field",field)
  label.set_meta("before",int(before.get(field,0)))
  label.set_meta("after",int(after.get(field,0)))
  label.set_meta("delta",delta)
