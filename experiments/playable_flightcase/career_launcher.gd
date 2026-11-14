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
 var group: String=str(host.launcher_group)
 var groups: Dictionary={"music":["create","practice","recording"],"out":["gigs","promotion","offstage"],"people":["band","songs","manage"],"manage":["calendar","gear","finance"]}
 var labels: Dictionary={"music":"MAKE MUSIC","out":"GET OUT THERE","people":"YOUR BAND","manage":"BAND ADMIN"}
 var choices: Array=groups.get(group,["music","out","people"])
 var grid:=VBoxContainer.new();grid.name="CareerLauncherGrid"
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.mouse_filter=Control.MOUSE_FILTER_PASS
 grid.add_theme_constant_override("separation",10);parent.add_child(grid)
 for destination in choices:
  if groups.has(destination):
   var category: Button=host._button(str(labels[destination]),"CareerLauncherGroup_"+str(destination),host._choose_launcher_group.bind(str(destination)))
   category.custom_minimum_size.y=64
   grid.add_child(category)
   preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(category,host)
   continue
  for entry in ROUTES:
   if entry.destination!=destination:continue
   var route: Callable=host._practice.bind("tighten") if destination=="practice" else (host._practice.bind("create") if destination=="create" else (host._open_poster_demo if destination in ["recording","promotion"] else host._navigate.bind(destination)))
   var tile: Button=host._button(str(entry.label),str(entry.node),route)
   tile.custom_minimum_size.y=64;tile.set_meta("career_destination",destination);grid.add_child(tile)
   preload("res://experiments/playable_flightcase/navigation_bar.gd").minimum(tile,host)
   break
