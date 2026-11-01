extends VBoxContainer
## Pre-name first press. Actual people and lead, no invented saved band name.
## Reuses the same source-honest full-length compositor as the named cover.
const Kit=preload("res://components/control_atlas/kit.gd")
const Press=preload("res://experiments/playable_flightcase/band_identity_press.gd")
const Style=preload("res://experiments/playable_flightcase/identity_style.gd")
var member_ids: Array[String]=[]

func configure(roster: Array, lead_id: String, viewport_width: float, layout_hint: String="") -> void:
 for child in get_children():
  remove_child(child);child.queue_free()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 focus_mode=Control.FOCUS_NONE
 size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var cover:=Press.new()
 cover.name="SelectedBandLineup"
 add_child(cover)
 cover.configure(roster,lead_id,"YOU'VE GOT A BAND.","Wordmark","White / Ink","",viewport_width,"formation",Style.defaults(),layout_hint)
 member_ids=cover.visible_ids()
 var paper: PanelContainer=cover.find_child("IdentityPressPaper",true,false) as PanelContainer
 paper.name="BandPosterPaper"
 var headline: Label=cover.find_child("IdentityLiveMark",true,false) as Label
 headline.name="BandPosterHeadline"
 var mast: Label=cover.find_child("IdentityPressMasthead",true,false) as Label
 mast.text="FIRST PRESS / THE FOUNDING LINEUP"
 var footer: Label=cover.find_child("IdentityPressFooter",true,false) as Label
 footer.text="THE PEOPLE ARE IN PLACE. THE NAME COMES NEXT."
 var lead: Label=cover.find_child("IdentityLeadVocal",true,false) as Label
 lead.name="LineupLeadVocal"
 var row:=GridContainer.new()
 row.name="FoundingRoles"
 row.columns=mini(3,maxi(1,member_ids.size()))
 row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 row.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(row)
 for raw in roster.slice(0,6):
  var person: Dictionary=raw
  var pid: String=str(person.get("id",""))
  var image: TextureRect=cover.find_child("IdentityPortrait_"+pid,true,false) as TextureRect
  if image!=null: image.name="LineupPortrait_"+pid
  var role: Label=Kit.label(str(person.get("name","Musician"))+" / "+str(person.get("primary_role","Musician")),"flightcase",12)
  role.name="LineupRole_"+pid
  role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  role.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  role.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  role.mouse_filter=Control.MOUSE_FILTER_IGNORE
  role.focus_mode=Control.FOCUS_NONE
  row.add_child(role)

func visible_ids() -> Array[String]:
 return member_ids.duplicate()
