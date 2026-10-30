extends VBoxContainer
## S37: live editorial identity from the selected C25 previews only.
## C25 contact-sheet crops are NOT independent high-res portrait masters.
## Presentation-only: no game mutation, controls or save data.
const Kit = preload("res://components/control_atlas/kit.gd")
const Cast = preload("res://experiments/character_cast/catalogue.gd")
const PAPER = preload("res://components/control_atlas/art/paper_surface.png")
var member_ids: Array[String] = []

func _ink(value: String, points: int, subdued: bool = false) -> Label:
 var label: Label = Kit.label(value,"notepaper",points)
 label.add_theme_color_override("font_color",Color("63584d") if subdued else Color("28231e"))
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.focus_mode = Control.FOCUS_NONE
 return label

func configure(roster: Array, lead_id: String, band_name: String, logo: String, palette: String, vibe: String, viewport_width: float, variant: String = "preview") -> void:
 for old in get_children():
  remove_child(old)
  old.queue_free()
 member_ids.clear()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 focus_mode = Control.FOCUS_NONE
 size_flags_horizontal = Control.SIZE_EXPAND_FILL
 add_theme_constant_override("separation",0)
 var compact: bool = variant=="preview"
 var tiny: bool = viewport_width<480.0
 var narrow: bool = viewport_width<720.0
 var paper := PanelContainer.new()
 paper.name = "IdentityPressPaper"
 paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
 paper.focus_mode = Control.FOCUS_NONE
 var stock := StyleBoxTexture.new()
 stock.texture = PAPER
 stock.set_texture_margin_all(8.0)
 stock.set_content_margin_all(6.0 if compact else (9.0 if tiny else 14.0))
 paper.add_theme_stylebox_override("panel",stock)
 add_child(paper)
 var content := VBoxContainer.new()
 content.add_theme_constant_override("separation",2 if compact else (4 if tiny else 7))
 content.mouse_filter = Control.MOUSE_FILTER_IGNORE
 paper.add_child(content)
 # One truly bounded press masthead. Two shrinkable HBox labels made the
 # right-hand edition wrap one character per line at 390px in native GL.
 var edition_text: String = "FIRST PRESS / 002" if variant=="milestone" else ("BAND PROFILE / 001" if variant=="complete" else "IDENTITY PROOF")
 var mast: Label = _ink("LIVIN' THE DREAM   /   "+edition_text,9 if tiny else 11,true)
 mast.name = "IdentityPressMasthead"
 mast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 mast.autowrap_mode = TextServer.AUTOWRAP_OFF
 content.add_child(mast)
 var rule := ColorRect.new()
 rule.name = "IdentityPressRule"
 rule.color = Color("756654")
 rule.custom_minimum_size.y = 1.0
 rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(rule)
 var logo_text: String = band_name.to_upper()
 if logo=="Monogram":
  logo_text = ""
  for part in band_name.split(" ",false):
   if not part.is_empty():
    logo_text += part.substr(0,1).to_upper()
  logo_text = logo_text.substr(0,6)
 elif logo=="Stamp":
  logo_text = "— " + logo_text + " —"
 var mark: Label = _ink(logo_text,23 if tiny else (27 if narrow else 35))
 mark.name = "IdentityLiveMark"
 mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 mark.add_theme_color_override("font_color",Color("764c25") if palette=="Amber / Charcoal" else (Color("332e2b") if palette=="White / Ink" else Color("8b3737")))
 content.add_child(mark)
 # Monograms must always carry the complete player-entered Unicode name.
 var full: Label = _ink(band_name,10 if tiny else 12,true)
 full.name = "IdentityFullName"
 full.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 full.visible = logo=="Monogram"
 content.add_child(full)
 var row := HBoxContainer.new()
 row.name = "IdentitySelectedPortraitRow"
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.add_theme_constant_override("separation",3 if tiny else 7)
 row.mouse_filter = Control.MOUSE_FILTER_IGNORE
 content.add_child(row)
 var count: int = mini(roster.size(),6)
 var usable: float = maxf(190.0,minf(610.0,viewport_width-(98.0 if narrow else 158.0)))
 var photo_width: float = minf(44.0 if compact else (70.0 if tiny else 82.0),floorf((usable-float((count-1)*(3 if tiny else 7)))/float(maxi(count,1))))
 var names: PackedStringArray = PackedStringArray()
 var vocalist_name: String = ""
 for person_variant in roster.slice(0,count):
  var person: Dictionary = person_variant
  var pid: String = str(person.get("id",""))
  if pid.is_empty() or member_ids.has(pid):
   continue
  member_ids.append(pid)
  var display_name: String = str(person.get("name","Musician"))
  names.append(display_name)
  if pid==lead_id:
   vocalist_name = display_name
  var cell := VBoxContainer.new()
  cell.name = "IdentityMember_"+pid
  cell.custom_minimum_size.x = photo_width
  cell.add_theme_constant_override("separation",1)
  cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
  cell.focus_mode = Control.FOCUS_NONE
  row.add_child(cell)
  var canonical: Dictionary = Cast.by_id(pid)
  var source: String = str(canonical.get("portrait_preview",""))
  if not source.is_empty() and ResourceLoader.exists(source):
   var texture: Texture2D = load(source) as Texture2D
   if texture!=null and texture.get_width()>=200 and texture.get_height()>=200:
    var portrait := TextureRect.new()
    portrait.name = "IdentityPortrait_"+pid
    portrait.set_meta("cast_id",pid)
    portrait.texture = texture
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.custom_minimum_size = Vector2(photo_width,photo_width)
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portrait.focus_mode = Control.FOCUS_NONE
    portrait.tooltip_text = display_name+(" — lead vocals" if pid==lead_id else " — "+str(person.get("primary_role","Musician")))
    cell.add_child(portrait)
  else:
   var missing: Label = _ink("NO PHOTO",9,true)
   missing.custom_minimum_size = Vector2(photo_width,photo_width)
   missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
   cell.add_child(missing)
  if not compact:
   var credit: Label = _ink(display_name,10 if tiny else 11)
   credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   cell.add_child(credit)
   if pid==lead_id:
    var lead: Label = _ink("LEAD",9,true)
    lead.name = "IdentityLeadVocal"
    lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    cell.add_child(lead)
 var footer_text: String = " · ".join(names)+"  /  LEAD: "+vocalist_name if compact else "YOUR SOUND  /  "+palette.to_upper()+"  /  "+vibe.to_upper()
 var footer: Label = _ink(footer_text,9 if tiny else 11,true)
 footer.name = "IdentityPressFooter"
 footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 content.add_child(footer)

func visible_ids() -> Array[String]:
 return member_ids.duplicate()
