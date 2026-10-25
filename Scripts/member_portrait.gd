extends Control
# Portraits are artwork-first; missing files use premium typographic identity cards,
# never procedural cartoon faces. Existing save IDs remain compatible.
const Genres = preload("res://Scripts/genre_profiles.gd")
var person_id := ""
var display_name := ""
var initials := "?"
var genre_id := "indie"
var portrait_texture: Texture2D

func set_character(value: String, name: String, genre: String = "indie") -> void:
 person_id = value
 display_name = name
 initials = name.strip_edges().left(2).to_upper() if not name.strip_edges().is_empty() else "?"
 genre_id = Genres.normalize(genre)
 portrait_texture = _find_portrait(value,name,genre_id)
 queue_redraw()

func _safe_id(value: String) -> String:
 var safe := ""
 for character in value.to_lower():
  if character in "abcdefghijklmnopqrstuvwxyz0123456789_-":
   safe += character
 return safe

func _find_portrait(character_id: String, name: String, genre: String) -> Texture2D:
 var keys: Array[String] = []
 for value in [character_id,name.replace(" ","_")]:
  var safe := _safe_id(value)
  if not safe.is_empty() and not keys.has(safe):
   keys.append(safe)
 var safe_genre := _safe_id(Genres.normalize(genre))
 for key in keys:
  for path in ["res://Art/Portraits/%s/%s.webp" % [safe_genre,key],"res://Art/Portraits/shared/%s.webp" % key]:
   if ResourceLoader.exists(path):
    var resource = load(path)
    if resource is Texture2D and resource.get_width() >= 128 and resource.get_height() >= 128:
     return resource
 # Prototype portraits from the real Indie character art sheet.
 # Production-size individual portraits above always override these crops.
 if safe_genre == "indie":
  var atlas_path := "res://Art/Portraits/indie/roster_atlas.webp"
  if ResourceLoader.exists(atlas_path):
   var positions := {"jo":Vector2i(0,0),"alex":Vector2i(1,0),"sam":Vector2i(0,1),"dev":Vector2i(1,1)}
   var chosen := _safe_id(name)
   if positions.has(chosen):
    var sheet = load(atlas_path)
    if sheet is Texture2D and sheet.get_width() >= 192 and sheet.get_height() >= 192:
     var cell := Vector2i(sheet.get_width()/2,sheet.get_height()/2)
     var cropped := AtlasTexture.new()
     cropped.atlas = sheet
     cropped.region = Rect2(Vector2i(positions[chosen])*cell,cell)
     return cropped
 return null

func _ready() -> void:
 if custom_minimum_size == Vector2.ZERO:
  custom_minimum_size = Vector2(90,108)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 queue_redraw()

func _draw() -> void:
 var bounds := size
 if bounds.x <= 0.0 or bounds.y <= 0.0:
  return
 if portrait_texture != null:
  var image_size := portrait_texture.get_size()
  if image_size.x > 0 and image_size.y > 0:
   var source_width := minf(image_size.x,image_size.y*bounds.x/bounds.y)
   var source_height := minf(image_size.y,image_size.x*bounds.y/bounds.x)
   var crop := Rect2((image_size-Vector2(source_width,source_height))*0.5,Vector2(source_width,source_height))
   draw_texture_rect_region(portrait_texture,Rect2(Vector2.ZERO,bounds),crop)
   return
 var profile: Dictionary = Genres.PROFILES[genre_id]
 var bg := Color(str(profile["panel"]))
 var surface := Color(str(profile["surface"]))
 var accent := Color(str(profile["accent"]))
 draw_rect(Rect2(Vector2.ZERO,bounds),bg)
 draw_rect(Rect2(Vector2(5,5),bounds-Vector2(10,10)),surface)
 draw_rect(Rect2(Vector2(5,bounds.y-7),Vector2(maxf(1.0,bounds.x-10),3)),accent)
 var font := ThemeDB.fallback_font
 if font != null:
  var font_size := maxi(16,mini(40,int(bounds.x*0.32)))
  var center := font.get_string_size(initials,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
  var position := Vector2((bounds.x-center.x)*0.5,(bounds.y+font.get_ascent(font_size)-font.get_descent(font_size))*0.5)
  draw_string(font,position,initials,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("#F6EEE1"))
