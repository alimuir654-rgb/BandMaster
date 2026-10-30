extends VBoxContainer
## S35: source-honest display of ACTUAL selected members, not a generated group photo.
## C25 individual previews are ~222–240px CONTACT-SHEET CROPS, not portrait masters.
## No writes to recruitment, budget, lead vocal assignment or saves.
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const Kit = preload("res://components/control_atlas/kit.gd")

var selected_ids: Array[String] = []
var vocalist_id: String = ""
var columns_used: int = 0

func configure(roster: Array, lead_id: String, viewport_width: float, available_width: float = 0.0) -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 selected_ids.clear()
 vocalist_id = lead_id
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",6)
 var count: int = mini(roster.size(),6)
 if count < 1:
  return
 # Small phone: three across, two rows if needed. Tablet: up to four;
 # desktop: one deliberate 3–6-person row.
 columns_used = mini(count,3 if (viewport_width < 480.0 and count >= 5) else (4 if viewport_width < 900.0 else 6))
 var gap: int = 6 if viewport_width < 720.0 else 10
 var usable: float = clampf(viewport_width - (104.0 if viewport_width < 720.0 else 152.0),262.0,660.0)
 if available_width > 0.0:
  usable = minf(usable,maxf(192.0,available_width))
 var width: float = minf(166.0,floorf((usable-float(gap*(columns_used-1)))/float(columns_used)))
 var portrait_height: float = minf(150.0,width)
 if viewport_width < 480.0 and count >= 5:
  portrait_height = minf(portrait_height,86.0)
 var grid := GridContainer.new()
 grid.name = "SelectedBandPortraitGrid"
 grid.columns = columns_used
 grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 grid.add_theme_constant_override("h_separation",gap)
 grid.add_theme_constant_override("v_separation",8 if viewport_width<720 else 12)
 add_child(grid)
 for person_variant in roster.slice(0,count):
  var person: Dictionary = person_variant
  var pid: String = str(person.get("id",""))
  if pid.is_empty() or selected_ids.has(pid):
   continue
  selected_ids.append(pid)
  var name: String = str(person.get("name","Musician"))
  var role: String = str(person.get("primary_role","Musician"))
  var cell := VBoxContainer.new()
  cell.name = "Member_"+pid
  cell.custom_minimum_size.x = width
  cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cell.focus_mode = Control.FOCUS_NONE
  cell.add_theme_constant_override("separation",2)
  grid.add_child(cell)
  var canonical: Dictionary = Cast.by_id(pid)
  var source: String = str(canonical.get("portrait_preview",""))
  if not source.is_empty() and ResourceLoader.exists(source):
   var texture: Texture2D = load(source) as Texture2D
   if texture != null and texture.get_width() >= 200 and texture.get_height() >= 200:
    var photo := TextureRect.new()
    photo.name = "LineupPortrait_"+pid
    photo.set_meta("cast_id",pid)
    photo.texture = texture
    photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    photo.custom_minimum_size = Vector2(width,portrait_height)
    photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    photo.focus_mode = Control.FOCUS_NONE
    cell.add_child(photo)
  else:
   # Legacy unpictured player: do not attribute another approved face to them.
   var placeholder: Label = Kit.label("IMAGE\nPENDING","flightcase",12)
   placeholder.name = "LineupUnpictured_"+pid
   placeholder.custom_minimum_size = Vector2(width,portrait_height)
   placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
   cell.add_child(placeholder)
  var caption: Label = Kit.label(name,"flightcase",13 if viewport_width >= 720 else 12)
  caption.name = "LineupName_"+pid
  caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  caption.custom_minimum_size.x = width
  caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cell.add_child(caption)
  var badge: Label = Kit.label(role.to_upper(),"flightcase",10)
  badge.name = "LineupRole_"+pid
  badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  badge.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cell.add_child(badge)
  if pid == lead_id:
   var vocal: Label = Kit.label("LEAD VOCALS","flightcase",10)
   vocal.name = "LineupLeadVocal"
   vocal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   vocal.mouse_filter = Control.MOUSE_FILTER_IGNORE
   cell.add_child(vocal)

func visible_ids() -> Array[String]:
 return selected_ids.duplicate()
