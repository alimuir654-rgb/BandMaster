extends VBoxContainer
## Native selected-roster cover. Raw C25 previews remain unchanged.
## New full-length sources are shared-origin generated layers, not photographs.
const Kit = preload("res://components/control_atlas/kit.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const PAPER = preload("res://components/control_atlas/art/paper_surface.png")
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
const Mark = preload("res://experiments/playable_flightcase/band_mark.gd")
const CAST_PATH := "res://experiments/playable_flightcase/art/identity/CAST.json"
const APPROVED_REVISIONS := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
var member_ids: Array[String] = []
var _full_length := false
var _regions: Dictionary = {}

static func printed_height(label: Label, width: float) -> float:
 var font: Font=label.get_theme_font("font")
 var points: int=label.get_theme_font_size("font_size")
 var flags: int=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
 var measure: Vector2=font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,maxf(20.0,width),points,-1,flags)
 var lines: int=maxi(1,roundi(measure.y/maxf(1.0,font.get_height(points))))
 return ceilf(measure.y)+float(maxi(0,lines-1)*label.get_theme_constant("line_spacing"))

func _ink(value: String, points: int, muted: bool = false, dark: bool = false) -> Label:
 var result: Label = Kit.label(value,"notepaper",points)
 result.add_theme_color_override("font_color",Color("c4bdaa") if dark and muted else (Color("f1e9d8") if dark else (Color("655b4e") if muted else Color("28231e"))))
 result.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 result.mouse_filter=Control.MOUSE_FILTER_IGNORE
 result.focus_mode=Control.FOCUS_NONE
 result.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 return result

func configure(roster: Array, lead_id: String, band_name: String, logo: String, palette: String, vibe: String, viewport_width: float, variant: String = "preview", style: Dictionary = {}, layout_hint: String = "", surface_budget: Vector2 = Vector2.ZERO) -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 member_ids.clear()
 _regions.clear()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",0)
 var compact: bool=variant=="preview"
 var tiny: bool=viewport_width<480.0
 var short: bool=is_inside_tree() and get_viewport_rect().size.y<800.0
 var hero: bool=layout_hint=="hero"
 var viewport_height: float=get_viewport_rect().size.y if is_inside_tree() else 844.0
 var selected_style: Dictionary=Style.effective(style,palette)
 var dark: bool=Style.dark_paper(selected_style)
 var paper:=PanelContainer.new()
 paper.name="IdentityPressPaper"
 paper.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 paper.focus_mode=Control.FOCUS_NONE
 var stock:=StyleBoxTexture.new()
 stock.texture=PAPER
 stock.set_texture_margin_all(8.0)
 stock.set_content_margin_all(12.0 if tiny else 18.0)
 if dark: stock.modulate_color=Color("30352f")
 paper.add_theme_stylebox_override("panel",stock)
 add_child(paper)
 var content:=VBoxContainer.new()
 content.add_theme_constant_override("separation",5 if tiny else 7)
 content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 paper.add_child(content)
 var mast: Label=_ink("FIRST PRESS / THE FOUNDING LINEUP" if variant=="formation" else ("YOUR FIRST PRESS" if variant=="complete" else ("THE NAME IS YOURS" if variant=="milestone" else "LIVE IDENTITY PROOF")),12,true,dark)
 if variant=="career":mast.text="YOUR BAND / CURRENT LINEUP"
 mast.name="IdentityPressMasthead"
 content.add_child(mast)
 var mark:=Mark.new()
 mark.name="IdentityLiveMark"
 var points: int=(46 if tiny else 62) if compact else (54 if tiny else 72)
 if short and not compact: points=54
 if hero: points=62 if viewport_height<700.0 else (72 if short else 84)
 mark.configure(band_name,logo,selected_style,points,false,true)
 content.add_child(mark)
 var full: Label=_ink(band_name,16,false,dark)
 full.add_theme_font_override("font",Style.face({"version":1,"font":"mono","ink":selected_style["ink"]}))
 full.name="IdentityFullName"
 full.visible=logo=="Monogram"
 content.add_child(full)
 var rule:=ColorRect.new()
 rule.name="IdentityPressRule"
 rule.color=Style.ink(selected_style)
 rule.custom_minimum_size.y=1.0
 rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var entries: Array=[]
 var names: PackedStringArray=PackedStringArray()
 var vocalist_name: String=""
 for raw in roster.slice(0,6):
  var person: Dictionary=raw
  var pid: String=str(person.get("id",""))
  if pid.is_empty() or member_ids.has(pid): continue
  member_ids.append(pid)
  names.append(str(person.get("name","Musician")))
  entries.append(person)
  if pid==lead_id: vocalist_name=str(person.get("name",""))
 var manifest: Dictionary={}
 if FileAccess.file_exists(CAST_PATH):
  var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(CAST_PATH))
  if parsed is Dictionary: manifest=parsed.get("people",{}) as Dictionary
 # The accepted replacement is one complete current-lineup cohort, never a
 # partial new/old cast mix or an unreviewed founding/milestone replacement.
 if variant=="career" and roster.size()==3 and member_ids.size()==3 and member_ids.has("cast_arjun") and member_ids.has("cast_zoe") and member_ids.has("cast_marcus") and FileAccess.file_exists(APPROVED_REVISIONS):
  var approved: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVED_REVISIONS))
  if approved is Dictionary:
   var replacements: Dictionary=approved.get("people",{})
   if replacements.has("cast_arjun") and replacements.has("cast_zoe") and replacements.has("cast_marcus"):
    manifest.merge(replacements,true)
 _full_length=not entries.is_empty()
 for person in entries:
  var entry: Dictionary=manifest.get(str(person["id"]),{})
  if entry.is_empty() or not ResourceLoader.exists(str(entry.get("texture",""))): _full_length=false
 var stage:=Control.new()
 stage.name="IdentitySelectedPortraitRow"
 stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
 stage.focus_mode=Control.FOCUS_NONE
 stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var body_height: float=(145.0 if tiny else 215.0) if compact else ((145.0 if short else 190.0) if variant=="milestone" else (190.0 if short else 270.0))
 if variant=="formation": body_height=210.0 if short else 240.0
 if hero: body_height=clampf(viewport_height-400.0,180.0,410.0)
 if layout_hint=="tall" and surface_budget.y>0.0:
  body_height=clampf(surface_budget.y*0.70,300.0,600.0)
 stage.custom_minimum_size.y=body_height if _full_length else (75.0 if compact else 120.0)
 content.add_child(stage)
 var views: Array[TextureRect]=[]
 for person in entries:
  var pid: String=str(person["id"])
  var photo:=TextureRect.new()
  photo.name="IdentityPortrait_"+pid
  photo.set_meta("cast_id",pid)
  photo.set_meta("full_length",_full_length)
  photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
  photo.focus_mode=Control.FOCUS_NONE
  photo.tooltip_text=str(person.get("name","Musician"))+(" — lead vocals" if pid==lead_id else " — "+str(person.get("primary_role","Musician")))
  if _full_length:
   var entry: Dictionary=manifest[pid]
   var rect: Array=entry["region"]
   var atlas:=AtlasTexture.new()
   atlas.atlas=load(str(entry["texture"])) as Texture2D
   atlas.region=Rect2(float(rect[0]),float(rect[1]),float(rect[2]),float(rect[3]))
   atlas.filter_clip=true
   photo.texture=atlas
   photo.set_meta("source_region",atlas.region)
   _regions[pid]=entry.duplicate(true)
  else:
   var original: Dictionary=Cast.by_id(pid)
   var source: String=str(original.get("portrait_preview",person.get("portrait_preview","")))
   if not source.is_empty() and ResourceLoader.exists(source): photo.texture=load(source) as Texture2D
  stage.add_child(photo)
  views.append(photo)
 var layout: Callable=func():
  if not is_instance_valid(stage) or not stage.is_inside_tree(): return
  var count: int=views.size()
  if count==0: return
  if not _full_length:
   # Existing contact-portrait fallback keeps its original geometry.
   var width: float=minf(stage.size.y,stage.size.x/float(count))
   var total: float=width*float(count)
   for i in range(count):
    views[i].position=Vector2((stage.size.x-total)*0.5+float(i)*width,0)
    views[i].size=Vector2(width,stage.size.y)
   return
  # The atlas crops all contain four pixels of measured top/bottom bleed.
  # Equal-width boxes made narrow figures much taller and centred their feet
  # lower. Fit the complete group from ONE visible head-to-sole height instead.
  var ratios: Array[float]=[]
  var heights: Array[float]=[]
  var max_full_ratio: float=1.0
  for view in views:
   var source: Vector2=view.texture.get_size()
   var visible_height: float=maxf(1.0,source.y-8.0)
   ratios.append(source.x/visible_height)
   heights.append(source.y)
   max_full_ratio=maxf(max_full_ratio,source.y/visible_height)
  var overlap: float=0.16 if count<=3 else (0.20 if count==4 else (0.24 if count==5 else 0.28))
  var extent: float=0.0
  for i in range(count):
   extent+=ratios[i]
   if i>0:extent-=overlap*minf(ratios[i-1],ratios[i])
  var figure_height: float=maxf(0.0,minf(stage.size.y/max_full_ratio,stage.size.x/maxf(0.01,extent)))
  var max_bleed: float=0.0
  for source_height in heights:max_bleed=maxf(max_bleed,4.0*figure_height/maxf(1.0,source_height-8.0))
  var ground: float=stage.size.y-max_bleed
  var cursor: float=(stage.size.x-figure_height*extent)*0.5
  for i in range(count):
   var scale: float=figure_height/maxf(1.0,heights[i]-8.0)
   var width: float=ratios[i]*figure_height
   views[i].position=Vector2(cursor,ground-(heights[i]-4.0)*scale)
   views[i].size=Vector2(width,heights[i]*scale)
   views[i].set_meta("visible_figure_height",figure_height)
   views[i].set_meta("ground_line",ground)
   if i<count-1:cursor+=width-overlap*minf(width,ratios[i+1]*figure_height)
 stage.resized.connect(layout)
 layout.call_deferred()
 var credit: Label=_ink(" · ".join(names).to_upper(),14,true,dark)
 credit.name="IdentityPressMembers"
 content.add_child(credit)
 var lead: Label
 if not compact:
  lead=_ink("LEAD VOCALS  /  "+vocalist_name.to_upper(),12,true,dark)
  if variant=="career" and vocalist_name.is_empty():lead.text="LEAD VOCAL CREDIT UNAVAILABLE"
  lead.name="IdentityLeadVocal"
  content.add_child(lead)
 var footer: Label=_ink("THE PEOPLE ARE IN PLACE. THE NAME COMES NEXT." if variant=="formation" else ("THE BAND IS FORMED." if variant=="complete" else ("ONE NAME. ONE BAND." if variant=="milestone" else "YOUR NAME. YOUR LOOK.")),16,false,dark)
 if variant=="career":footer.text="THE LINEUP, AS IT STANDS."
 footer.name="IdentityPressFooter"
 content.add_child(footer)
 if surface_budget.x>0.0 and surface_budget.y>0.0 and _full_length:
  # Native text/copy keeps its size. The image row uses the exact remainder
  # after paper margins, real font wrapping and visible-child separation.
  var inner_width: float=maxf(20.0,surface_budget.x-stock.get_content_margin(SIDE_LEFT)-stock.get_content_margin(SIDE_RIGHT))
  var fixed_height: float=stock.get_content_margin(SIDE_TOP)+stock.get_content_margin(SIDE_BOTTOM)+printed_height(mast,inner_width)+ceilf(mark.custom_minimum_size.y)+1.0+printed_height(credit,inner_width)+printed_height(footer,inner_width)
  var visible_count: int=6
  if logo=="Monogram":
   fixed_height+=printed_height(full,inner_width)
   visible_count+=1
  if lead!=null:
   fixed_height+=printed_height(lead,inner_width)
   visible_count+=1
  fixed_height+=float((visible_count-1)*content.get_theme_constant("separation"))
  var desired: float=body_height
  if compact and viewport_width>=1100.0: desired=350.0
  stage.custom_minimum_size.y=maxf(64.0,minf(desired,floorf(surface_budget.y-fixed_height)))

func visible_ids() -> Array[String]:
 return member_ids.duplicate()

func uses_full_length() -> bool:
 return _full_length

func source_regions() -> Dictionary:
 return _regions.duplicate(true)
