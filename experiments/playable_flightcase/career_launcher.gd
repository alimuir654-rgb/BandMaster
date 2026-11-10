extends RefCounted
## S63 owned presentation helper. Every tile routes one existing free action.
const C = preload("res://experiments/playable_flightcase/career_components.gd")
const ICON_ROOT := "res://experiments/playable_flightcase/art/icons/"
const APPROVED_REVISIONS := "res://experiments/playable_flightcase/art/owner_approved_revisions_v2.json"
const P=preload("res://experiments/playable_flightcase/poster_components.gd")
static var _icon_cache: Dictionary={}

static func icon_texture(path: String) -> Texture2D:
 if _icon_cache.has(path):return _icon_cache[path]
 var result: Texture2D
 if FileAccess.file_exists(path) and not FileAccess.file_exists(path+".import"):
  var image:=Image.load_from_file(path)
  if image!=null:result=ImageTexture.create_from_image(image)
 elif ResourceLoader.exists(path):result=load(path) as Texture2D
 if result!=null:_icon_cache[path]=result
 return result
const ROUTES := [
 {"label":"WRITE A SONG","destination":"create","node":"PosterWriteAction","icon":"notebook-pen.svg","color":"e7b83d"},
 {"label":"REHEARSE","destination":"practice","node":"CareerHomePracticeAction","icon":"drum.svg","color":"a64a32"},
 {"label":"PLAY LIVE","destination":"gigs","node":"CareerHomeLiveAction","icon":"ticket.svg","color":"456c82"},
 {"label":"RECORD A DEMO","destination":"recording","node":"PosterDemoAction","icon":"cassette-tape.svg","color":"eee8d8"},
 {"label":"SPREAD THE WORD","destination":"promotion","node":"PosterPromotionAction","icon":"megaphone.svg","color":"a64a32"},
 {"label":"OFFSTAGE","destination":"offstage","node":"CareerHome_offstage","icon":"coffee.svg","color":"e7b83d"},
 {"label":"BAND DIARY","destination":"calendar","node":"CareerHome_calendar","icon":"calendar-days.svg","color":"eee8d8"},
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
  var tile: Button=P.button("" if destination in ["create","practice","gigs","recording","promotion","offstage"] else entry.label,false,Color(entry.color));tile.name=entry.node;tile.disabled=host.busy;tile.pressed.connect(route)
  tile.custom_minimum_size.y=146 if destination in ["create","practice","gigs","recording","promotion","offstage"] else 54
  tile.set_meta("career_destination",destination);tile.tooltip_text=entry.label;grid.add_child(tile)
  if destination not in ["create","practice","gigs","recording","promotion","offstage"]:continue
  var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.mouse_filter=Control.MOUSE_FILTER_IGNORE
  for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
  tile.add_child(margin)
  var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;margin.add_child(box)
  var icon:=TextureRect.new();icon.name="CareerLauncherIcon_"+destination;icon.custom_minimum_size=Vector2(38,38);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;icon.modulate=P.PAPER if P.stock_index(Color(entry.color)) in [2,3] else P.INK
  var path: String=ICON_ROOT+"native48/"+str(entry.icon).replace(".svg",".png")
  icon.texture=icon_texture(path)
  if icon.texture==null:
   path=ICON_ROOT+entry.icon;icon.texture=icon_texture(path)
  icon.set_meta("source",path);box.add_child(icon)
  var words: String=str({"create":"WRITE\nA SONG","recording":"RECORD\nA DEMO","promotion":"SPREAD\nTHE WORD"}.get(destination,entry.label))
  var label: Label=P.label(words,28,P.PAPER if P.stock_index(Color(entry.color)) in [2,3] else P.INK)
  label.add_theme_font_override("font",P.FONT)
  label.name="CareerLauncherLabel_"+destination;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;label.size_flags_vertical=Control.SIZE_EXPAND_FILL;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;box.add_child(label)
