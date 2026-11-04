extends PanelContainer
## Original native screenprint compositions on the unchanged paper source.
## These abstract genre marks are presentation, never scores or new mechanics.
const Kit = preload("res://components/control_atlas/kit.gd")
const Paper = preload("res://experiments/playable_flightcase/session_paper.gd")
const Formation = preload("res://Scripts/formation_catalogue.gd")
const IdentityStyle = preload("res://experiments/playable_flightcase/identity_style.gd")
const AudioPreview = preload("res://experiments/playable_flightcase/audition_audio.gd")
const EXAMPLES_PATH := "res://experiments/playable_flightcase/audio/genre_examples.json"
var _preview_owner
var _preview_genre := ""
var _preview_material := ""
var _audio

const IMAGE_SOURCES := {
 "Indie rock":"genre_indie",
 "Punk":"genre_punk",
 "Post-punk":"genre_post_punk",
 "Britpop":"genre_britpop",
 "Shoegaze":"genre_shoegaze",
 "Synth-pop":"genre_synth",
 "Garage rock":"genre_garage",
 "Goth":"genre_goth",
 "Prog rock":"genre_prog",
 "Experimental":"genre_experimental",
 "Country / Americana":"genre_country",
 "Soul / Funk":"genre_soul",
 "Metal":"genre_metal",
 "Jazz / Fusion":"genre_jazz"
}
const EDITIONS := {
 "Indie rock": ["355448", "strings"],
 "Punk": ["913c2c", "cut"],
 "Post-punk": ["324b5a", "columns"],
 "Britpop": ["81502d", "sun"],
 "Shoegaze": ["61516e", "haze"],
 "Synth-pop": ["285b68", "sequence"],
 "Garage rock": ["70502c", "stripes"],
 "Goth": ["533950", "arch"],
 "Prog rock": ["31575c", "orbits"],
 "Experimental": ["814733", "collage"],
 "Country / Americana": ["625538", "horizon"],
 "Soul / Funk": ["87502f", "groove"],
 "Metal": ["3c4448", "chevron"],
 "Jazz / Fusion": ["344f68", "offbeat"]
}

func _ink(text: String, points: int, node_name: String) -> Label:
 var label: Label = Kit.label(text,"notepaper",points)
 label.name = node_name
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 label.add_theme_color_override("font_color",Color("28231e"))
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.focus_mode = Control.FOCUS_NONE
 return label

func configure(genre: String, viewport_size: Vector2, owner = null) -> void:
 _preview_owner = owner
 _preview_genre = genre
 _preview_material = ""
 _audio = null
 for child in get_children():
  remove_child(child)
  child.queue_free()
 name = "GenrePress"
 mouse_filter = Control.MOUSE_FILTER_PASS
 focus_mode = Control.FOCUS_NONE
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var compact: bool = viewport_size.x < 720.0
 var wide: bool = viewport_size.x >= 900.0 and viewport_size.x > viewport_size.y
 var stock: StyleBoxTexture = Paper.sheet(compact)
 stock.content_margin_top = 16
 stock.content_margin_bottom = 18
 add_theme_stylebox_override("panel",stock)
 var content := VBoxContainer.new()
 content.name = "GenrePressContent"
 content.add_theme_constant_override("separation",6 if compact else 10)
 content.mouse_filter = Control.MOUSE_FILTER_PASS
 add_child(content)
 var edition: Array = EDITIONS.get(genre,["355448","strings"])
 var color := Color(str(edition[0]))
 var mast: Label = _ink("LIVIN' THE DREAM  /  STARTING SOUND",11 if compact else 12,"GenrePressMasthead")
 content.add_child(mast)
 var rule := ColorRect.new()
 rule.name = "GenrePrintRule"
 rule.color = color
 rule.custom_minimum_size.y = 3
 rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var title: Label = _ink(genre.to_upper(),28 if compact else 40,"GenrePressTitle")
 title.add_theme_font_override("font",IdentityStyle.face(IdentityStyle.defaults()))
 content.add_child(title)
 var image_path: String = "res://experiments/playable_flightcase/art/"+str(IMAGE_SOURCES.get(genre,""))+".png"
 var artwork: Control
 if IMAGE_SOURCES.has(genre) and ResourceLoader.exists(image_path):
  var picture := TextureRect.new()
  picture.texture = load(image_path)
  picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  artwork = picture
  artwork.set_meta("source",image_path)
 else:
  var original := PrintArt.new()
  original.ink = color
  original.motif = str(edition[1])
  artwork = original
 artwork.name = "GenreArtwork"
 artwork.set_meta("genre",genre)
 artwork.set_meta("motif",str(edition[1]))
 artwork.custom_minimum_size.y = 100 if compact else (220 if wide else 160)
 artwork.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if wide:
  artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
 artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
 artwork.focus_mode = Control.FOCUS_NONE
 content.add_child(artwork)
 var descriptor: Dictionary = Formation.GENRES.get(genre,{})
 content.add_child(_ink(str(descriptor.get("description","Build a sound of your own.")),16,"GenrePressDescription"))
 var strength: Label = _ink("Strength: "+str(descriptor.get("strength","Your first gigs")),14,"GenrePressStrength")
 content.add_child(strength)
 _add_audio_preview(content)
 set_meta("genre",genre)
 set_meta("source","Independent image-generated instrument screenprint where supplied; original native motif fallback; unchanged session_paper.png")

func _audio_context() -> Dictionary:
 return {"allowed": _preview_owner != null and _preview_owner.screen == "genre" and _preview_owner.game.genre == _preview_genre,
  "material_id": _preview_material, "content_version": "genre_examples_v1"}

func _add_audio_preview(content: VBoxContainer) -> void:
 var catalogue: Dictionary = {}
 if FileAccess.file_exists(EXAMPLES_PATH):
  var parser := JSON.new()
  if parser.parse(FileAccess.get_file_as_string(EXAMPLES_PATH)) == OK and parser.data is Dictionary:
   catalogue = parser.data
 var entry: Dictionary = {}
 if catalogue.get("schema_version") == 1 and catalogue.get("content_version") == "genre_examples_v1":
  var genres = catalogue.get("genres",{})
  var materials = catalogue.get("materials",{})
  if genres is Dictionary and materials is Dictionary:
   var id = genres.get(_preview_genre, "")
   if id is String and materials.get(id) is Dictionary:
    var candidate: Dictionary = materials[id]
    if AudioPreview.entry_approved(candidate) and candidate.get("label") is String:
     _preview_material = id
     entry = candidate
 if entry.is_empty():
  content.add_child(_ink("No audio example available yet.",16,"GenreAudioUnavailable"))
  return
 content.add_child(_ink(str(entry["label"]),16,"GenreAudioCaption"))
 _audio = AudioPreview.new()
 _audio.manifest_path = EXAMPLES_PATH
 _audio.play_caption = "PLAY EXAMPLE"
 _audio.available_hint = "Hear the instrumental indie band example. This does not select a genre."
 _audio.unavailable_hint = "Audio example unavailable; all genre information and choices remain available."
 _audio.configure(_audio_context)
 _audio.set_clip(_preview_material)
 content.add_child(_audio)

class PrintArt extends Control:
 var ink := Color("355448")
 var motif := "strings"

 func _ready() -> void:
  resized.connect(queue_redraw)
  queue_redraw()

 func _line(points: Array, width: float = 2.0, alpha: float = 1.0) -> void:
  var packed := PackedVector2Array()
  for i in range(points.size()):
   var point: Vector2 = points[i]
   packed.append(point+Vector2(sin(point.y*0.37+i)*0.38,cos(point.x*0.31+i)*0.38))
  draw_polyline(packed,Color(ink,alpha),width,true)

 func _polygon(points: Array, alpha: float = 1.0) -> void:
  var packed := PackedVector2Array()
  for point in points:
   packed.append(point)
  draw_colored_polygon(packed,Color(ink,alpha))
  # Small registration/dropout marks stay INSIDE the ink shape. Native text
  # and the paper outside artwork receive no added noise or texture.
  for i in range(100):
   var point := Vector2(20+float((i*71)%280),12+float((i*43)%96))
   if Geometry2D.is_point_in_polygon(point,packed):
    draw_line(point,point+Vector2(0.8+float(i%3),-0.35),Color(0.93,0.90,0.84,0.65),0.65,true)

 func _ring(center: Vector2, radius: float, width: float = 2.0, alpha: float = 1.0) -> void:
  for i in range(96):
   if i%29==0:
    continue
   var angle: float = float(i)*TAU/96.0
   var next: float = float(i+1)*TAU/96.0
   var local_radius: float = radius+sin(float(i)*0.71)*0.35
   draw_line(center+Vector2.from_angle(angle)*local_radius,center+Vector2.from_angle(next)*local_radius,Color(ink,alpha),width*(0.93+0.07*sin(float(i)*0.4)),true)

 func _draw() -> void:
  # Fit the complete original composition rather than cropping a fixed image.
  # Deliberate print registration, repeated lines and sparse stippling share
  # a material grammar without presenting a chart, meter or editable control.
  var scale_factor: float = minf(size.x / 320.0,size.y / 120.0)
  var origin := Vector2((size.x-320.0*scale_factor)*0.5,(size.y-120.0*scale_factor)*0.5)
  draw_set_transform(origin,0,Vector2.ONE*scale_factor)
  match motif:
   "strings":
    for i in range(6):
     _line([Vector2(25,28+i*12),Vector2(293,16+i*15)],1.6)
    _ring(Vector2(160,60),43,8,0.75)
    _ring(Vector2(163,59),32,1.4)
   "cut":
    _polygon([Vector2(22,82),Vector2(95,18),Vector2(125,48),Vector2(206,8),Vector2(185,63),Vector2(301,34),Vector2(235,104),Vector2(145,75),Vector2(83,112),Vector2(104,68)],0.92)
    for i in range(7):
     _line([Vector2(35+i*40,5),Vector2(18+i*40,115)],1.1,0.5)
   "columns":
    for i in range(13):
     var x: float = 27+i*22
     var rise: float = 20+absf(6-i)*9
     _polygon([Vector2(x,112),Vector2(x,rise),Vector2(x+9,rise-8),Vector2(x+9,112)],0.87)
    _line([Vector2(18,86),Vector2(303,32)],2)
   "sun":
    for i in range(24):
     var a: float = float(i)*TAU/24.0
     _line([Vector2(160,60)+Vector2.from_angle(a)*31,Vector2(160,60)+Vector2.from_angle(a)*56],4.8)
    draw_circle(Vector2(160,60),23,ink)
    _line([Vector2(18,103),Vector2(300,103)],2)
   "haze":
    for i in range(16):
     var x: float = 32+i*17
     _ring(Vector2(x,60+sin(i*0.5)*13),27+i%4*3,5,0.12)
    for i in range(7):
     _line([Vector2(24,31+i*9),Vector2(296,46+i*8)],1.1,0.5)
   "sequence":
    for i in range(10):
     var x: float = 30+i*28
     var y: float = 25+float((i*3)%5)*12
     _line([Vector2(x,108),Vector2(x,12)],1,0.35)
     draw_rect(Rect2(x-5,y,11,14),ink)
     if i<9:
      _line([Vector2(x+6,y+7),Vector2(x+23,y+7),Vector2(x+23,25+float(((i+1)*3)%5)*12+7)],2)
    _line([Vector2(20,108),Vector2(303,108)],3)
   "stripes":
    for i in range(9):
     var x: float = 16+i*34
     _polygon([Vector2(x,110),Vector2(x+17,12),Vector2(x+34,12),Vector2(x+13,110)],0.84)
    _line([Vector2(12,51),Vector2(307,74)],6)
   "arch":
    for i in range(5):
     var x: float = 82+i*18
     _line([Vector2(x,111),Vector2(x,43+i*3),Vector2(160,8+i*11),Vector2(320-x,43+i*3),Vector2(320-x,111)],3.5 if i==0 else 1.5)
    _ring(Vector2(160,49),12,2)
   "orbits":
    for i in range(5):
     var points: Array = []
     for j in range(73):
      var a: float = float(j)*TAU/72.0
      points.append(Vector2(160+cos(a)*(47+i*20),60+sin(a)*(14+i*9)))
     _line(points,1.6,0.85)
    draw_circle(Vector2(160,60),10,ink)
    draw_circle(Vector2(245,34),5,ink)
   "collage":
    _polygon([Vector2(28,27),Vector2(110,14),Vector2(94,105),Vector2(18,87)],0.9)
    _ring(Vector2(181,61),43,12,0.7)
    _polygon([Vector2(231,16),Vector2(301,98),Vector2(218,113)],0.75)
    for i in range(8):
     _line([Vector2(50+i*28,10),Vector2(90+i*23,112)],1,0.65)
   "horizon":
    for i in range(7):
     var y: float = 52+i*9
     _line([Vector2(20,y),Vector2(93,y-9),Vector2(156,y+4),Vector2(217,y-7),Vector2(301,y+2)],2)
    _ring(Vector2(232,32),20,4)
    for i in range(7):
     _line([Vector2(61+i*22,10),Vector2(45+i*20,47)],1.3,0.65)
   "groove":
    for i in range(9):
     draw_arc(Vector2(160,116),20+i*11,PI,TAU,64,ink,4,true)
    draw_circle(Vector2(160,91),7,ink)
    _line([Vector2(22,113),Vector2(298,113)],2)
   "chevron":
    for i in range(6):
     var x: float = 23+i*48
     _polygon([Vector2(x,20),Vector2(x+22,60),Vector2(x,102),Vector2(x+14,102),Vector2(x+39,60),Vector2(x+14,20)],0.95)
    _line([Vector2(18,12),Vector2(306,12)],2)
    _line([Vector2(18,111),Vector2(306,111)],2)
   "offbeat":
    for i in range(6):
     var x: float = 45+i*46
     var y: float = 35+float((i*3)%4)*14
     draw_circle(Vector2(x,y),15 if i%2==0 else 11,ink)
     _line([Vector2(x+11,y),Vector2(x+11,107)],2)
    for i in range(4):
     _line([Vector2(20,24+i*21),Vector2(300,17+i*23)],1.2,0.4)
  # Restrained deterministic ink wear, not random noise or a raster texture.
  for i in range(62):
   var x: float = 18+float((i*73)%286)
   var y: float = 8+float((i*31)%105)
   draw_circle(Vector2(x,y),0.45 if i%3 else 0.8,Color(ink,0.22))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
