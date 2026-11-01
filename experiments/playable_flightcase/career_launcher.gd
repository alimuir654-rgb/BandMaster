extends RefCounted
## S63 owned presentation helper. Every tile routes one existing free action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const ICON_ROOT := "res://experiments/playable_flightcase/art/icons/"
const APPROVED_REVISIONS := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
const ROUTES := [
 {"label":"THE PRACTICE ROOM","destination":"practice","node":"CareerHomePracticeAction","icon":"sliders-horizontal.svg"},
 {"label":"THE LIVE CIRCUIT","destination":"gigs","node":"CareerHomeLiveAction","icon":"ticket.svg"},
 {"label":"CALENDAR","destination":"calendar","node":"CareerHome_calendar","icon":"calendar-days.svg"},
 {"label":"FINANCES","destination":"finance","node":"CareerHome_finance","icon":"wallet.svg"},
 {"label":"LIFE OFFSTAGE","destination":"offstage","node":"CareerHome_offstage","icon":"heart-handshake.svg"},
 {"label":"THE MUSIC SHOP","destination":"gear","node":"CareerHome_gear","icon":"guitar.svg"},
 {"label":"MEET YOUR BAND","destination":"band","node":"CareerHome_band","icon":"users.svg"},
 {"label":"YOUR SONGBOOK","destination":"songs","node":"CareerHome_songs","icon":"notebook-pen.svg"}
]

static func render(host, parent: Node, compact: bool) -> void:
 var approved_icons: Dictionary={}
 if FileAccess.file_exists(APPROVED_REVISIONS):
  var approved: Variant=JSON.parse_string(FileAccess.get_file_as_string(APPROVED_REVISIONS))
  if approved is Dictionary:approved_icons=approved.get("icons",{})
 var grid := GridContainer.new()
 grid.name = "CareerLauncherGrid"
 grid.columns = 2 if compact else 4
 grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 grid.mouse_filter = Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("h_separation",8)
 grid.add_theme_constant_override("v_separation",8)
 parent.add_child(grid)
 for raw in ROUTES:
  var entry: Dictionary = raw
  var destination: String = str(entry["destination"])
  var route: Callable = host._practice.bind("") if destination=="practice" else host._navigate.bind(destination)
  var tile: Button = host._button("",str(entry["node"]),route,destination in ["practice","gigs"])
  tile.custom_minimum_size.y = 96.0
  tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tile.mouse_filter = Control.MOUSE_FILTER_PASS
  tile.tooltip_text = str(entry["label"])
  tile.set_meta("career_destination",destination)
  grid.add_child(tile)
  var margin := MarginContainer.new()
  margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
  for side in ["left","right"]:
   margin.add_theme_constant_override("margin_"+side,10)
  for side in ["top","bottom"]:
   margin.add_theme_constant_override("margin_"+side,6)
  tile.add_child(margin)
  var contents := VBoxContainer.new()
  contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
  # 96px housing retains32px icon plus room for two native16 text lines.
  contents.add_theme_constant_override("separation",2)
  margin.add_child(contents)
  var icon := TextureRect.new()
  icon.name = "CareerLauncherIcon_"+destination
  icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.custom_minimum_size = Vector2(32,32)
  icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
  icon.focus_mode = Control.FOCUS_NONE
  var path: String = ICON_ROOT+str(entry["icon"])
  if ResourceLoader.exists(path): icon.texture = load(path) as Texture2D
  icon.set_meta("source",path)
  var replacement: Dictionary=approved_icons.get(destination,{})
  var atlas_path: String=str(replacement.get("texture",""))
  var region: Array=replacement.get("region",[])
  if region.size()==4 and ResourceLoader.exists(atlas_path):
   var atlas:=AtlasTexture.new()
   atlas.atlas=load(atlas_path) as Texture2D
   atlas.region=Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
   atlas.filter_clip=true
   icon.texture=atlas
   icon.set_meta("source",atlas_path)
   icon.set_meta("source_region",atlas.region)
   icon.set_meta("raw_sha256",str(replacement.get("raw_sha256","")))
  contents.add_child(icon)
  var label: Label = C.label(str(entry["label"]),16)
  label.name = "CareerLauncherLabel_"+destination
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  label.size_flags_vertical = Control.SIZE_EXPAND_FILL
  label.mouse_filter = Control.MOUSE_FILTER_IGNORE
  label.focus_mode = Control.FOCUS_NONE
  contents.add_child(label)
