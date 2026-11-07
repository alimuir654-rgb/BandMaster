extends RefCounted
## S63 owned presentation helper. Every tile routes one existing free action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const ICON_ROOT := "res://experiments/playable_flightcase/art/icons/"
const APPROVED_REVISIONS := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
const ROUTES := [
 {"label":"WRITE SONGS","destination":"create","node":"PosterWriteAction","icon":"notebook-pen.svg","color":"e7b83d"},
 {"label":"PRACTISE","destination":"practice","node":"CareerHomePracticeAction","icon":"sliders-horizontal.svg","color":"eee8d8"},
 {"label":"PLAY LIVE","destination":"gigs","node":"CareerHomeLiveAction","icon":"ticket.svg","color":"c27453"},
 {"label":"THE DEMO","destination":"recording","node":"PosterDemoAction","icon":"notebook-pen.svg","color":"eee8d8"},
 {"label":"MAKE SOME NOISE","destination":"promotion","node":"PosterPromotionAction","icon":"users.svg","color":"a4b7b8"},
 {"label":"LIFE OUTSIDE","destination":"offstage","node":"CareerHome_offstage","icon":"heart-handshake.svg","color":"e7b83d"},
 {"label":"CALENDAR","destination":"calendar","node":"CareerHome_calendar","icon":"calendar-days.svg","color":"eee8d8"},
 {"label":"MUSIC SHOP","destination":"gear","node":"CareerHome_gear","icon":"guitar.svg","color":"eee8d8"},
 {"label":"THE BAND","destination":"band","node":"CareerHome_band","icon":"users.svg","color":"eee8d8"},
 {"label":"FINANCES","destination":"finance","node":"CareerHome_finance","icon":"wallet.svg","color":"eee8d8"},
 {"label":"SONGBOOK","destination":"songs","node":"CareerHome_songs","icon":"notebook-pen.svg","color":"eee8d8"}
]
static func render(host,parent: Node,compact: bool) -> void:
 var grid:=GridContainer.new();grid.name="CareerLauncherGrid";grid.columns=2 if compact else 3
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.mouse_filter=Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);parent.add_child(grid)
 for entry in ROUTES:
  var destination: String=entry.destination
  var route: Callable=host._practice.bind("tighten") if destination=="practice" else (host._practice.bind("create") if destination=="create" else (host._open_poster_demo if destination in ["recording","promotion"] else host._navigate.bind(destination)))
  var tile: Button=P.button("",false,Color(entry.color));tile.name=entry.node;tile.disabled=host.busy;tile.pressed.connect(route)
  tile.custom_minimum_size.y=110 if destination in ["create","practice","gigs","recording","promotion","offstage"] else 72
  tile.set_meta("career_destination",destination);tile.tooltip_text=entry.label;grid.add_child(tile)
  var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
  for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,10)
  tile.add_child(margin)
  var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(box)
  var icon:=TextureRect.new();icon.name="CareerLauncherIcon_"+destination;icon.custom_minimum_size=Vector2(28,28);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.modulate=P.INK
  var path: String=ICON_ROOT+entry.icon
  if ResourceLoader.exists(path):icon.texture=load(path) as Texture2D
  icon.set_meta("source",path);box.add_child(icon)
  var label: Label=P.label(entry.label,20);label.name="CareerLauncherLabel_"+destination;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.size_flags_vertical=Control.SIZE_EXPAND_FILL;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;box.add_child(label)
