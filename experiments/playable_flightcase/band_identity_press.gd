extends VBoxContainer
## Native selected-roster cover. Raw C25 previews remain unchanged.
## New full-length sources are shared-origin generated layers, not photographs.
const Poster=preload("res://experiments/playable_flightcase/poster_components.gd")
const Kit = preload("res://components/control_atlas/kit.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const PAPER = preload("res://components/control_atlas/art/paper_surface.png")
const Style = preload("res://experiments/playable_flightcase/identity_style.gd")
const Mark = preload("res://experiments/playable_flightcase/band_mark.gd")
const Portraits=preload("res://experiments/playable_flightcase/formation_portraits.gd")
const CAST_PATH := "res://experiments/playable_flightcase/art/identity/CAST.json"
const APPROVED_REVISIONS := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
const POSE_COHORT := "res://experiments/playable_flightcase/art/identity/formation_pose_cohort_v1.json"
var cohort_registry_path := POSE_COHORT
var member_ids: Array[String] = []
var _full_length := false
var _regions: Dictionary = {}

func _portrait_preview(roster: Array,lead_id: String,band_name: String,logo: String,palette: String,viewport_width: float,style: Dictionary) -> void:
 _full_length=false
 var selected: Dictionary=Style.effective(style,palette)
 var dark: bool=Style.dark_paper(selected)
 var paper:=PanelContainer.new();paper.name="IdentityPressPaper"
 paper.mouse_filter=Control.MOUSE_FILTER_PASS
 paper.add_theme_stylebox_override("panel",Poster.stock(Poster.INK if dark else Poster.PAPER,14))
 add_child(paper)
 var content:=VBoxContainer.new();content.add_theme_constant_override("separation",10)
 content.mouse_filter=Control.MOUSE_FILTER_PASS;paper.add_child(content)
 var caption: Label=_ink("YOUR FIRST POSTER",14,true,dark);caption.name="IdentityPressMasthead";content.add_child(caption)
 var mark:=Mark.new();mark.name="IdentityLiveMark"
 mark.configure(band_name,logo,selected,46 if viewport_width<480 else 62,false,true)
 content.add_child(mark)
 if logo=="Monogram":
  var full: Label=_ink(band_name,16,false,dark)
  full.name="IdentityFullName"
  full.add_theme_font_override("font",Style.face({"version":1,"font":"mono","ink":selected["ink"]}))
  content.add_child(full)
 var grid:=GridContainer.new();grid.name="IdentitySelectedPortraitRow"
 grid.columns=mini(3,maxi(1,roster.size()));grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.mouse_filter=Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",12)
 content.add_child(grid)
 for raw in roster.slice(0,6):
  var person: Dictionary=raw
  var id: String=str(person.get("id",""))
  if id.is_empty() or member_ids.has(id):continue
  member_ids.append(id)
  var card:=VBoxContainer.new();card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  card.add_theme_constant_override("separation",3);card.mouse_filter=Control.MOUSE_FILTER_PASS;grid.add_child(card)
  var original: Dictionary=Cast.by_id(id)
  var path: String=str(original.get("portrait_preview",person.get("portrait_preview","")))
  var photo:=TextureRect.new();photo.name="IdentityPortrait_"+id
  photo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;photo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  photo.custom_minimum_size.y=110 if viewport_width<480 else 150
  photo.mouse_filter=Control.MOUSE_FILTER_IGNORE
  photo.set_meta("cast_id",id);photo.set_meta("full_length",false);photo.set_meta("source",path)
  photo.set_meta("full_source_contained",true)
  if not path.is_empty() and ResourceLoader.exists(path):photo.texture=load(path) as Texture2D
  card.add_child(photo)
  var name_label: Label=_ink(str(person.get("name","Musician")),17,false,dark);card.add_child(name_label)
  var role: String=str(person.get("primary_role","Musician"))
  card.add_child(_ink(role+(" · VOICE" if id==lead_id else ""),14,true,dark))
 content.add_child(_ink("THE PEOPLE BEHIND THE NAME",14,true,dark))

static func _whole(value: Variant) -> bool:
 return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==floorf(float(value))

static func cohort_entries(registry_path: String, ids: Array[String], variant: String) -> Dictionary:
 if variant not in ["preview","formation","milestone","complete","career"] or ids.size()!=3:return {}
 for pid in ["cast_arjun","cast_zoe","cast_ellis"]:
  if not ids.has(pid):return {}
 if not FileAccess.file_exists(registry_path):return {}
 var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(registry_path))
 if not parsed is Dictionary or not _whole(parsed.get("schema_version")) or parsed.schema_version!=1:return {}
 if typeof(parsed.get("owner_art_acceptance"))!=TYPE_BOOL or parsed.owner_art_acceptance!=false:return {}
 if typeof(parsed.get("integration_review_accepted"))!=TYPE_BOOL or parsed.integration_review_accepted!=true:return {}
 if typeof(parsed.get("integration_authority"))!=TYPE_STRING or parsed.integration_authority!="owner_delegation_20261104":return {}
 if not parsed.get("people") is Dictionary or parsed.people.size()!=3:return {}
 var result: Dictionary={}
 for pid in ids:
  var entry: Variant=parsed.people.get(pid)
  if not entry is Dictionary:return {}
  var path: Variant=entry.get("texture")
  var digest: Variant=entry.get("sha256")
  if typeof(path)!=TYPE_STRING or not path.begins_with("res://") or typeof(digest)!=TYPE_STRING or digest.length()!=64 or not ResourceLoader.exists(path):return {}
  if FileAccess.file_exists(path) and FileAccess.get_sha256(path)!=digest:return {}
  var texture: Texture2D=load(path) as Texture2D
  if texture==null or texture.get_size()!=Vector2(1536,1024):return {}
  var rect: Variant=entry.get("region")
  if not rect is Array or rect.size()!=4:return {}
  for value in rect:
   if not _whole(value):return {}
  if rect[0]<0 or rect[1]<0 or rect[2]<=8 or rect[3]<=8 or rect[0]+rect[2]>1536 or rect[1]+rect[3]>1024:return {}
  var ratio: Variant=entry.get("pose_height_ratio")
  if typeof(ratio) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(ratio)) or float(ratio)<=0.0 or float(ratio)>1.0:return {}
  result[pid]=entry.duplicate(true)
 return result

static func printed_height(label: Label, width: float) -> float:
 var font: Font=label.get_theme_font("font")
 var points: int=label.get_theme_font_size("font_size")
 var flags: int=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
 var measure: Vector2=font.get_multiline_string_size(label.text,HORIZONTAL_ALIGNMENT_CENTER,maxf(20.0,width),points,-1,flags)
 var lines: int=maxi(1,roundi(measure.y/maxf(1.0,font.get_height(points))))
 return ceilf(measure.y)+float(maxi(0,lines-1)*label.get_theme_constant("line_spacing"))

func _ink(value: String, points: int, muted: bool = false, dark: bool = false) -> Label:
 var result: Label = Poster.label(value,points,Poster.INK)
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
 if variant=="preview":
  _portrait_preview(roster,lead_id,band_name,logo,palette,viewport_width,style)
  return
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
 var mast: Label=_ink("FIRST PRESS / THE FOUNDING LINEUP" if variant=="formation" else ("TURN IT UP. THIS IS YOUR BAND." if variant=="complete" else ("THE NAME IS YOURS" if variant=="milestone" else "LIVE IDENTITY PROOF")),12,true,dark)
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
 rule.custom_minimum_size.y=4.0 if variant=="complete" else 1.0
 if variant=="complete":rule.color=Color("c64c30")
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
 var poses: Dictionary=cohort_entries(cohort_registry_path,member_ids,variant)
 if not poses.is_empty():manifest.merge(poses,true)
 # The approved new direction supersedes every old special-cohort bypass.
 manifest.merge(Portraits.entries(),true)
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
 if variant=="complete":body_height=300.0 if short else 380.0
 if hero: body_height=clampf(viewport_height-400.0,180.0,410.0)
 if layout_hint=="tall" and surface_budget.y>0.0:
  body_height=clampf(surface_budget.y*0.70,300.0,600.0)
 stage.custom_minimum_size.y=body_height if _full_length else (75.0 if compact else 120.0)
 stage.set_meta("height_cap",body_height)
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
  var pose_ratios: Array[float]=[]
  var max_full_ratio: float=1.0
  for view in views:
   var source: Vector2=view.texture.get_size()
   var visible_height: float=maxf(1.0,source.y-8.0)
   var pose_ratio: float=float(_regions.get(str(view.get_meta("cast_id")),{}).get("pose_height_ratio",1.0))
   pose_ratios.append(pose_ratio)
   ratios.append(source.x/visible_height*pose_ratio)
   heights.append(source.y)
   max_full_ratio=maxf(max_full_ratio,source.y/visible_height*pose_ratio)
  var overlap: float=0.16 if count<=3 else (0.20 if count==4 else (0.24 if count==5 else 0.28))
  var extent: float=0.0
  for i in range(count):
   extent+=ratios[i]
   if i>0:extent-=overlap*minf(ratios[i-1],ratios[i])
  # Reserve the height this exact-width lineup needs, not empty paper above it.
  var preferred: float=ceilf(minf(float(stage.get_meta("height_cap",body_height)),stage.size.x/maxf(0.01,extent)*max_full_ratio))+8.0
  if absf(stage.custom_minimum_size.y-preferred)>1.0:stage.custom_minimum_size.y=preferred
  var figure_height: float=maxf(0.0,minf((stage.size.y-8.0)/max_full_ratio,stage.size.x/maxf(0.01,extent)))
  var max_bleed: float=0.0
  for i in range(count):max_bleed=maxf(max_bleed,4.0*figure_height*pose_ratios[i]/maxf(1.0,heights[i]-8.0))
  var ground: float=stage.size.y-max_bleed
  var cursor: float=(stage.size.x-figure_height*extent)*0.5
  for i in range(count):
   var scale: float=figure_height*pose_ratios[i]/maxf(1.0,heights[i]-8.0)
   var width: float=ratios[i]*figure_height
   views[i].position=Vector2(cursor,ground-(heights[i]-4.0)*scale)
   views[i].size=Vector2(width,heights[i]*scale)
   views[i].set_meta("visible_figure_height",figure_height*pose_ratios[i])
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
 var footer: Label=_ink("THE PEOPLE ARE IN PLACE. THE NAME COMES NEXT." if variant=="formation" else ("FIRST REHEARSAL. FIRST SONG. FIRST GIG." if variant=="complete" else ("ONE NAME. ONE BAND." if variant=="milestone" else "YOUR NAME. YOUR LOOK.")),16,false,dark)
 if variant=="career":footer.text="THE LINEUP, AS IT STANDS."
 footer.name="IdentityPressFooter"
 content.add_child(footer)
 if surface_budget.x>0.0 and surface_budget.y>0.0 and _full_length:
  # Native text/copy keeps its size. The image row uses the exact remainder
  # after paper margins, real font wrapping and visible-child separation.
  var inner_width: float=maxf(20.0,surface_budget.x-stock.get_content_margin(SIDE_LEFT)-stock.get_content_margin(SIDE_RIGHT))
  var fixed_height: float=stock.get_content_margin(SIDE_TOP)+stock.get_content_margin(SIDE_BOTTOM)+printed_height(mast,inner_width)+ceilf(mark.custom_minimum_size.y)+rule.custom_minimum_size.y+printed_height(credit,inner_width)+printed_height(footer,inner_width)
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
  stage.set_meta("height_cap",stage.custom_minimum_size.y-8.0)

func visible_ids() -> Array[String]:
 return member_ids.duplicate()

func uses_full_length() -> bool:
 return _full_length

func source_regions() -> Dictionary:
 return _regions.duplicate(true)
