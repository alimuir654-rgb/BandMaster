extends VBoxContainer
## Pre-name first press. Actual people and lead, no invented saved band name.
## Reuses the same source-honest full-length compositor as the named cover.
const Kit=preload("res://components/control_atlas/kit.gd")
const Press=preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Style=preload("res://experiments/playable_flightcase/identity_style.gd")
var member_ids: Array[String]=[]

func configure(roster: Array, lead_id: String, viewport_width: float, layout_hint: String="", surface_budget: Vector2=Vector2.ZERO) -> void:
 for child in get_children():
  remove_child(child);child.queue_free()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",4)
 var row:=GridContainer.new()
 row.name="FoundingRoles"
 row.columns=mini(3,maxi(1,roster.size()))
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var column_width: float=maxf(40.0,(surface_budget.x-float((row.columns-1)*row.get_theme_constant("h_separation")))/float(row.columns)) if surface_budget.x>0.0 else 100.0
 var row_heights: Array[float]=[]
 for index in range(mini(6,roster.size())):
  var person: Dictionary=roster[index]
  var pid: String=str(person.get("id",""))
  var role: Label=Kit.label(str(person.get("name","Musician"))+" / "+str(person.get("primary_role","Musician")),"flightcase",12)
  role.name="LineupRole_"+pid
  role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  role.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  role.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  role.mouse_filter=Control.MOUSE_FILTER_IGNORE
  role.focus_mode=Control.FOCUS_NONE
  role.size.x=column_width
  var line: int=index/row.columns
  if row_heights.size()<=line: row_heights.append(0.0)
  row_heights[line]=maxf(row_heights[line],Press.printed_height(role,column_width))
  row.add_child(role)
 var role_height: float=float(maxi(0,row_heights.size()-1)*row.get_theme_constant("v_separation"))+4.0
 for value in row_heights: role_height+=value
 var cover_budget: Vector2=surface_budget
 if cover_budget.y>0.0: cover_budget.y=maxf(1.0,cover_budget.y-role_height)
 var cover:=Press.new()
 cover.name="SelectedBandLineup"
 add_child(cover)
 cover.configure(roster,lead_id,"YOU'VE GOT A BAND.","Wordmark","White / Ink","",viewport_width,"formation",Style.defaults(),layout_hint,cover_budget)
 member_ids=cover.visible_ids()
 var paper: PanelContainer=cover.find_child("IdentityPressPaper",true,false) as PanelContainer
 paper.name="BandPosterPaper"
 var headline: Label=cover.find_child("IdentityLiveMark",true,false) as Label
 headline.name="BandPosterHeadline"
 var lead: Label=cover.find_child("IdentityLeadVocal",true,false) as Label
 lead.name="LineupLeadVocal"
 # Credits are part of the real selected-lineup component, below its paper.
 # Keep the same visible four-pixel separation and native labels.
 cover.add_theme_constant_override("separation",4)
 cover.add_child(row)
 for person in roster.slice(0,6):
  var pid: String=str(person.get("id",""))
  var image: TextureRect=cover.find_child("IdentityPortrait_"+pid,true,false) as TextureRect
  if image!=null: image.name="LineupPortrait_"+pid

func visible_ids() -> Array[String]:
 return member_ids.duplicate()
